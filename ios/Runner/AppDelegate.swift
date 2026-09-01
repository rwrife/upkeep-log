import Flutter
import AVFoundation
import PhotosUI
import UIKit
import UniformTypeIdentifiers
import UserNotifications

private enum BackupImportError: Error { case tooLarge }

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate,
  UIImagePickerControllerDelegate, UINavigationControllerDelegate,
  PHPickerViewControllerDelegate, UIDocumentPickerDelegate {
  private var attachmentResult: FlutterResult?
  private var dataTransferResult: FlutterResult?
  private var importingBackup = false
  private let maxBackupArchiveBytes: Int64 = 256 * 1024 * 1024
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "UpkeepStoragePath"
    ) else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "upkeep_log/storage",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "getApplicationSupportPath" else {
        result(FlutterMethodNotImplemented)
        return
      }
      do {
        let support = try FileManager.default.url(
          for: .applicationSupportDirectory,
          in: .userDomainMask,
          appropriateFor: nil,
          create: true
        )
        result(support.path)
      } catch {
        result(
          FlutterError(
            code: "storage_path_unavailable",
            message: "Could not create app-private storage",
            details: error.localizedDescription
          )
        )
      }
    }
    let attachmentChannel = FlutterMethodChannel(
      name: "upkeep_log/attachments",
      binaryMessenger: registrar.messenger()
    )
    attachmentChannel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "pick",
        let arguments = call.arguments as? [String: Any],
        let source = arguments["source"] as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let self, self.attachmentResult == nil else {
        result(FlutterError(code: "picker_busy", message: "Another picker is open", details: nil))
        return
      }
      self.attachmentResult = result
      switch source {
      case "camera": self.openCamera()
      case "photoLibrary": self.openPhotos()
      case "document": self.openDocuments()
      default: self.finishAttachment(FlutterError(code: "invalid_source", message: "Unknown source", details: nil))
      }
    }
    let dataTransferChannel = FlutterMethodChannel(
      name: "upkeep_log/data_transfer",
      binaryMessenger: registrar.messenger()
    )
    dataTransferChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      switch call.method {
      case "export":
        guard self.dataTransferResult == nil else {
          result(FlutterError(code: "transfer_busy", message: "Another data transfer is active", details: nil)); return
        }
        guard let arguments = call.arguments as? [String: Any],
          let name = arguments["suggestedName"] as? String,
          let bytes = arguments["bytes"] as? FlutterStandardTypedData else {
          result(FlutterError(code: "invalid_export", message: "Export data is missing", details: nil)); return
        }
        do {
          let safeName = name.replacingOccurrences(of: "[^A-Za-z0-9._-]", with: "_", options: .regularExpression)
          let fileExtension = (safeName as NSString).pathExtension
          var url = FileManager.default.temporaryDirectory
            .appendingPathComponent("upkeep-export-\(UUID().uuidString)")
          if !fileExtension.isEmpty { url.appendPathExtension(fileExtension) }
          try bytes.data.write(to: url, options: .atomic)
          guard let presenter = self.presenter() else { throw CocoaError(.fileNoSuchFile) }
          let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
          if let popover = controller.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(
              x: presenter.view.bounds.midX,
              y: presenter.view.bounds.midY,
              width: 0,
              height: 0
            )
          }
          self.dataTransferResult = result
          controller.completionWithItemsHandler = { [weak self] _, completed, _, error in
            guard let self else { return }
            if let error {
              self.finishDataTransfer(FlutterError(code: "export_failed", message: error.localizedDescription, details: nil))
            } else {
              // This is only the locally prepared file; iOS cannot promise the
              // receiving activity retained it.
              self.finishDataTransfer(completed ? url.path : nil)
            }
          }
          presenter.present(controller, animated: true)
        } catch {
          self.dataTransferResult = nil
          self.importingBackup = false
          result(FlutterError(code: "export_failed", message: error.localizedDescription, details: nil))
        }
      case "import":
        guard self.dataTransferResult == nil else { result(FlutterError(code: "transfer_busy", message: "Another data transfer is active", details: nil)); return }
        self.dataTransferResult = result
        self.importingBackup = true
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.zip], asCopy: true)
        picker.delegate = self
        guard let presenter = self.presenter() else {
          self.finishDataTransfer(FlutterError(code: "picker_unavailable", message: "No view can present the picker", details: nil))
          return
        }
        presenter.present(picker, animated: true)
      default: result(FlutterMethodNotImplemented)
      }
    }
    let reminderChannel = FlutterMethodChannel(
      name: "upkeep_log/reminders",
      binaryMessenger: registrar.messenger()
    )
    reminderChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      switch call.method {
      case "getTimeZoneId":
        result(TimeZone.current.identifier)
      case "getPermissionStatus":
        self.notificationPermissionStatus(result)
      case "requestPermission":
        self.requestNotificationPermission(result)
      case "replaceAll":
        guard let arguments = call.arguments as? [String: Any],
          let reminders = arguments["reminders"] as? [[String: Any]] else {
          result(FlutterError(code: "invalid_reminders", message: "Missing reminders", details: nil))
          return
        }
        self.replaceReminders(reminders, result: result)
      case "openSettings":
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else {
          result(FlutterError(code: "settings_unavailable", message: "Notification settings are unavailable", details: nil))
          return
        }
        UIApplication.shared.open(url) { opened in
          opened ? result(nil) : result(FlutterError(code: "settings_unavailable", message: "Could not open notification settings", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func notificationPermissionStatus(_ result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      let value: String
      switch settings.authorizationStatus {
      case .authorized, .provisional, .ephemeral: value = "granted"
      case .denied: value = "denied"
      case .notDetermined: value = "notDetermined"
      @unknown default: value = "unsupported"
      }
      DispatchQueue.main.async { result(value) }
    }
  }

  private func requestNotificationPermission(_ result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] _, error in
      guard let self else { return }
      if let error {
        DispatchQueue.main.async {
          result(FlutterError(code: "permission_failed", message: error.localizedDescription, details: nil))
        }
      } else {
        self.notificationPermissionStatus(result)
      }
    }
  }

  private func replaceReminders(_ reminders: [[String: Any]], result: @escaping FlutterResult) {
    let center = UNUserNotificationCenter.current()
    center.getPendingNotificationRequests { requests in
      center.removePendingNotificationRequests(
        withIdentifiers: requests.map(\.identifier).filter { $0.hasPrefix("upkeep.") }
      )
      let group = DispatchGroup()
      let lock = NSLock()
      var scheduled = 0
      var failureMessage: String?
      for reminder in reminders {
        guard let id = reminder["id"] as? String,
          let title = reminder["title"] as? String,
          let year = reminder["year"] as? Int,
          let month = reminder["month"] as? Int,
          let day = reminder["day"] as? Int,
          let hour = reminder["hour"] as? Int,
          let minute = reminder["minute"] as? Int,
          let timeZoneId = reminder["timeZoneId"] as? String else {
          failureMessage = "A reminder field is missing"
          continue
        }
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(identifier: timeZoneId) ?? .current
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        guard let next = trigger.nextTriggerDate(), next > Date() else { continue }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = "Upkeep is due. Open Upkeep Log for current status. Reminders are convenience aids and may be delayed by iOS."
        content.sound = .default
        group.enter()
        center.add(
          UNNotificationRequest(identifier: "upkeep.\(id)", content: content, trigger: trigger)
        ) { error in
          lock.lock()
          if let error { failureMessage = error.localizedDescription } else { scheduled += 1 }
          lock.unlock()
          group.leave()
        }
      }
      group.notify(queue: .main) {
        if let failureMessage {
          result(FlutterError(code: "schedule_failed", message: failureMessage, details: nil))
        } else {
          result([
            "scheduledCount": scheduled,
            "limitation": "iOS controls final notification delivery and may delay or suppress alerts.",
          ])
        }
      }
    }
  }

  private func presenter() -> UIViewController? {
    var current = window?.rootViewController
    while let presented = current?.presentedViewController { current = presented }
    return current
  }

  private func openCamera() {
    guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
      finishAttachment(FlutterError(code: "camera_unavailable", message: "Camera is unavailable", details: nil))
      return
    }
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      presentCamera()
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
        DispatchQueue.main.async {
          guard let self else { return }
          if granted {
            self.presentCamera()
          } else {
            self.finishAttachment(FlutterError(code: "permission_denied", message: "Camera permission was denied", details: nil))
          }
        }
      }
    case .denied, .restricted:
      finishAttachment(FlutterError(code: "permission_denied", message: "Camera permission was denied", details: nil))
    @unknown default:
      finishAttachment(FlutterError(code: "permission_denied", message: "Camera permission is unavailable", details: nil))
    }
  }

  private func presentCamera() {
    let picker = UIImagePickerController()
    picker.delegate = self
    picker.sourceType = .camera
    present(picker)
  }

  private func openPhotos() {
    var configuration = PHPickerConfiguration(photoLibrary: .shared())
    configuration.filter = .images
    configuration.selectionLimit = 1
    let picker = PHPickerViewController(configuration: configuration)
    picker.delegate = self
    present(picker)
  }

  private func openDocuments() {
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
    picker.delegate = self
    present(picker)
  }

  private func present(_ picker: UIViewController) {
    guard let presenter = presenter() else {
      finishAttachment(FlutterError(code: "presentation_unavailable", message: "Could not open picker", details: nil))
      return
    }
    presenter.present(picker, animated: true)
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true)
    finishAttachment(nil)
  }

  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
    defer { picker.dismiss(animated: true) }
    guard let image = info[.originalImage] as? UIImage else {
      finishAttachment(FlutterError(code: "selection_unavailable", message: "Camera returned no image", details: nil))
      return
    }
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self else { return }
      guard let bytes = image.jpegData(compressionQuality: 0.95) else {
        self.finishAttachment(FlutterError(code: "selection_unavailable", message: "Could not encode camera image", details: nil))
        return
      }
      self.writeTemporary(bytes, extension: "jpg", mediaType: "image/jpeg")
    }
  }

  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)
    guard let provider = results.first?.itemProvider else { finishAttachment(nil); return }
    provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] url, error in
      guard let self else { return }
      guard let url else {
        DispatchQueue.main.async { self.finishAttachment(FlutterError(code: "selection_unavailable", message: error?.localizedDescription, details: nil)) }
        return
      }
      DispatchQueue.global(qos: .userInitiated).sync {
        self.copyTemporaryFileNow(
          from: url,
          extension: url.pathExtension.isEmpty ? "jpg" : url.pathExtension,
          mediaType: UTType(filenameExtension: url.pathExtension)?.preferredMIMEType ?? "image/jpeg"
        )
      }
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    if importingBackup { finishDataTransfer(nil) } else { finishAttachment(nil) }
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let url = urls.first else {
      if importingBackup { finishDataTransfer(nil) } else { finishAttachment(nil) }
      return
    }
    if importingBackup {
      let destination = FileManager.default.temporaryDirectory.appendingPathComponent("upkeep-import-\(UUID().uuidString).zip")
      do {
        let knownSize = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize
        if let knownSize, Int64(knownSize) > maxBackupArchiveBytes { throw BackupImportError.tooLarge }
        let input = try FileHandle(forReadingFrom: url)
        defer { try? input.close() }
        FileManager.default.createFile(atPath: destination.path, contents: nil)
        let output = try FileHandle(forWritingTo: destination)
        defer { try? output.close() }
        var total: Int64 = 0
        while let chunk = try input.read(upToCount: 64 * 1024), !chunk.isEmpty {
          total += Int64(chunk.count)
          if total > maxBackupArchiveBytes { throw BackupImportError.tooLarge }
          try output.write(contentsOf: chunk)
        }
        finishDataTransfer(destination.path)
      } catch {
        try? FileManager.default.removeItem(at: destination)
        let tooLarge = error is BackupImportError
        finishDataTransfer(FlutterError(
          code: tooLarge ? "archive_too_large" : "import_failed",
          message: tooLarge ? "Backup archive exceeds the 256 MiB size limit" : error.localizedDescription,
          details: nil
        ))
      }
      return
    }
    copyTemporaryFile(
      from: url,
      extension: url.pathExtension,
      mediaType: UTType(filenameExtension: url.pathExtension)?.preferredMIMEType ?? "application/octet-stream",
      securityScoped: true
    )
  }

  private func copyTemporaryFile(
    from source: URL,
    extension fileExtension: String,
    mediaType: String,
    securityScoped: Bool = false
  ) {
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      self?.copyTemporaryFileNow(
        from: source,
        extension: fileExtension,
        mediaType: mediaType,
        securityScoped: securityScoped
      )
    }
  }

  private func copyTemporaryFileNow(
    from source: URL,
    extension fileExtension: String,
    mediaType: String,
    securityScoped: Bool = false
  ) {
    let accessed = securityScoped && source.startAccessingSecurityScopedResource()
    defer { if accessed { source.stopAccessingSecurityScopedResource() } }
    let destination = FileManager.default.temporaryDirectory
      .appendingPathComponent("upkeep-selection-\(UUID().uuidString)")
      .appendingPathExtension(fileExtension)
    do {
      try FileManager.default.copyItem(at: source, to: destination)
      finishAttachment([
        "path": destination.path,
        "mediaType": mediaType,
        "ownedTemporary": true,
      ])
    } catch {
      try? FileManager.default.removeItem(at: destination)
      finishAttachment(FlutterError(code: "selection_unavailable", message: error.localizedDescription, details: nil))
    }
  }

  private func writeTemporary(_ data: Data, extension fileExtension: String, mediaType: String) {
    do {
      let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("upkeep-selection-\(UUID().uuidString)")
        .appendingPathExtension(fileExtension)
      try data.write(to: url, options: .atomic)
      finishAttachment(["path": url.path, "mediaType": mediaType, "ownedTemporary": true])
    } catch {
      finishAttachment(FlutterError(code: "selection_unavailable", message: error.localizedDescription, details: nil))
    }
  }

  private func finishAttachment(_ value: Any?) {
    guard Thread.isMainThread else {
      DispatchQueue.main.async { [weak self] in self?.finishAttachment(value) }
      return
    }
    attachmentResult?(value)
    attachmentResult = nil
  }

  private func finishDataTransfer(_ value: Any?) {
    dataTransferResult?(value)
    dataTransferResult = nil
    importingBackup = false
  }
}
