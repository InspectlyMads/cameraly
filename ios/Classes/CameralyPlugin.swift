import Flutter
import UIKit

public class CameralyPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // Main plugin channel
    let channel = FlutterMethodChannel(name: "cameraly", binaryMessenger: registrar.messenger())
    
    // Orientation-specific channel
    let orientationChannel = FlutterMethodChannel(name: "com.cameraly/orientation", binaryMessenger: registrar.messenger())
    
    // Register video codec handler for H.264 support
    VideoCodecHandler.register(with: registrar)
    
    // Register video transcoder for converting HEVC videos
    VideoTranscoderHandler.register(with: registrar)
    
    let instance = CameralyPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addMethodCallDelegate(instance, channel: orientationChannel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "getDeviceRotation" {
      let rotation = getDeviceRotation()
      print("🧭 iOS returning rotation: \(rotation)")
      result(rotation)
    } else {
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func getDeviceRotation() -> Int {
    let orientation = UIDevice.current.orientation
    
    switch orientation {
    case .portrait:
      print("🧭 iOS device orientation: portrait (0)")
      return 0
    case .landscapeRight:
      print("🧭 iOS device orientation: landscapeRight (1)")
      return 1
    case .portraitUpsideDown:
      print("🧭 iOS device orientation: portraitUpsideDown (2)")
      return 2
    case .landscapeLeft:
      print("🧭 iOS device orientation: landscapeLeft (3)")
      return 3
    default:
      // If we can't determine the orientation or it's face up/down, use the status bar orientation
      print("🧭 iOS device orientation unknown, using interface orientation")
      
      let statusBarOrientation = UIApplication.shared.statusBarOrientation
      
      switch statusBarOrientation {
      case .portrait:
        return 0
      case .landscapeRight:
        return 1
      case .portraitUpsideDown:
        return 2
      case .landscapeLeft:
        return 3
      default:
        print("🧭 iOS interface orientation unknown, defaulting to portrait (0)")
        return 0
      }
    }
  }
} 