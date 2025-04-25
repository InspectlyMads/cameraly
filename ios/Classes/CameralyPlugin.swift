import Flutter
import UIKit
import AVFoundation

public class CameralyPlugin: NSObject, FlutterPlugin {
  // Main plugin instance that can be accessed from other parts of the code
  static var sharedInstance: CameralyPlugin?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    print("🔌 CameralyPlugin.register called with registrar: \(registrar)")
    
    // Create main instance and store it
    let instance = CameralyPlugin()
    sharedInstance = instance
    
    // Main plugin channel
    let channel = FlutterMethodChannel(name: "cameraly", binaryMessenger: registrar.messenger())
    print("🔌 Created main channel: cameraly")
    
    // Orientation-specific channel
    let orientationChannel = FlutterMethodChannel(name: "com.cameraly/orientation", binaryMessenger: registrar.messenger())
    print("🔌 Created orientation channel: com.cameraly/orientation")
    
    // Register codec channel
    let codecChannel = FlutterMethodChannel(name: "com.cameraly/video_codec", binaryMessenger: registrar.messenger())
    print("🔌 Created codec channel: com.cameraly/video_codec")
    
    // Register transcoder channel
    let transcoderChannel = FlutterMethodChannel(name: "com.cameraly/video_transcoder", binaryMessenger: registrar.messenger())
    print("🔌 Created transcoder channel: com.cameraly/video_transcoder")
    
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addMethodCallDelegate(instance, channel: orientationChannel)
    print("🔌 Added method call delegate for main and orientation channels")
    
    // Handle codec channel manually
    codecChannel.setMethodCallHandler { (call, result) in
      print("🔌 Codec channel received call: \(call.method)")
      if call.method == "forceH264Encoding" {
        print("🔌 Handling forceH264Encoding")
        VideoCodecHandler.forceH264Encoding(result: result)
      } else if call.method == "isVideoHevc" {
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Path is required", details: nil))
            return
        }
        print("🔌 Handling isVideoHevc for path: \(path)")
        VideoCodecHandler.isVideoHevc(path: path, result: result)
      } else if call.method == "transcodeHevcToH264" {
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Path is required", details: nil))
            return
        }
        print("🔌 Handling transcodeHevcToH264 for path: \(path)")
        VideoCodecHandler.transcodeHevcToH264(path: path, result: result)
      } else {
        print("🔌 Unimplemented method on codec channel: \(call.method)")
        result(FlutterMethodNotImplemented)
      }
    }
    print("🔌 Set method call handler for codec channel")
    
    // Handle transcoder channel manually
    transcoderChannel.setMethodCallHandler { (call, result) in
      print("🔌 Transcoder channel received call: \(call.method)")
      if call.method == "transcodeToH264" {
        guard let args = call.arguments as? [String: Any],
              let inputPath = args["inputPath"] as? String,
              let outputPath = args["outputPath"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Input and output paths are required", details: nil))
            return
        }
        
        let quality = args["quality"] as? String ?? "medium"
        print("🔌 Handling transcodeToH264 with input: \(inputPath), output: \(outputPath), quality: \(quality)")
        
        VideoTranscoderHandler.transcodeToH264(
            inputPath: inputPath,
            outputPath: outputPath,
            quality: quality,
            completion: { path, error in
                if let error = error {
                    print("🔌 Transcoding failed with error: \(error)")
                    result(FlutterError(code: "TRANSCODE_FAILED", message: error.localizedDescription, details: nil))
                } else {
                    print("🔌 Transcoding succeeded with path: \(path ?? "nil")")
                    result(path)
                }
            }
        )
      } else {
        print("🔌 Unimplemented method on transcoder channel: \(call.method)")
        result(FlutterMethodNotImplemented)
      }
    }
    print("🔌 Set method call handler for transcoder channel")
    
    // Add plugin to Info.plist to ensure it's loaded
    CameralyPlugin.ensurePluginRegistrationInInfoPlist()
    
    // Force H.264 encoding by default for iOS camera recording
    if #available(iOS 11.0, *) {
      // This ensures all videos recorded on this device will use H.264 if possible
      print("🔌 Attempting to force H.264 encoding")
      VideoCodecHandler.forceH264Encoding { success in
        print("🎥 Force H.264 encoding for camera: \(success ? "successful" : "failed")")
      }
    } else {
      print("🔌 iOS version < 11.0, not forcing H.264 encoding")
    }
    
    print("🔌 CameralyPlugin.register completed")
  }
  
  /// Method to reactivate codec handler if needed
  public static func reactivateCodecHandler(completion: @escaping (Bool) -> Void) {
    print("🔌 Attempting to reactivate codec handler")
    VideoCodecHandler.forceH264Encoding { success in
      print("🔌 Reactivation result: \(success)")
      completion(success)
    }
  }
  
  /// Helper method to ensure plugin is correctly registered in Info.plist
  private static func ensurePluginRegistrationInInfoPlist() {
    // This is just a debug method to check if plugin is in Info.plist
    if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
      if let dict = NSDictionary(contentsOfFile: path) as? [String: Any] {
        if let plugins = dict["FlutterPluginRegistrant"] as? [String: Any] {
          print("🔌 Plugin registry found in Info.plist: \(plugins)")
          
          if let _ = plugins["cameraly"] as? String {
            print("🔌 cameraly plugin found in registry!")
          } else {
            print("🔌 cameraly plugin NOT found in registry")
          }
        } else {
          print("🔌 No FlutterPluginRegistrant key found in Info.plist")
        }
      }
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    print("🔌 CameralyPlugin.handle called with method: \(call.method)")
    if call.method == "getDeviceRotation" {
      let rotation = getDeviceRotation()
      print("🧭 iOS returning rotation: \(rotation)")
      result(rotation)
    } else if call.method == "ping" {
      print("🔌 Received ping, responding with true")
      result(true)
    } else {
      print("🔌 Unimplemented method: \(call.method)")
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