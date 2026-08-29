import Flutter
import AVFoundation
import PhotosUI
import UIKit
import UniformTypeIdentifiers

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
