import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
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
  }
}
