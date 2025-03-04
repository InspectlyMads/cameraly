import Flutter
import UIKit

public class CameralyPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "cameraly", binaryMessenger: registrar.messenger())
    let instance = CameralyPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    // We don't need to implement any methods here since we're using the official camera plugin
    result(FlutterMethodNotImplemented)
  }
} 