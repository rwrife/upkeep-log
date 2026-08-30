import Flutter
import AVFoundation
import PhotosUI
import UIKit
import UniformTypeIdentifiers
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate,
  UIImagePickerControllerDelegate, UINavigationControllerDelegate,
  PHPickerViewControllerDelegate, UIDocumentPickerDelegate {
  private var attachmentResult: FlutterResult?
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

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) { finishAttachment(nil) }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let url = urls.first else { finishAttachment(nil); return }
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
}
