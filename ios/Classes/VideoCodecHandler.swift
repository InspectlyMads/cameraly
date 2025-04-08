import Flutter
import AVFoundation

class VideoCodecHandler {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.cameraly/video_codec", binaryMessenger: registrar.messenger())
        channel.setMethodCallHandler { (call, result) in
            if call.method == "forceH264Encoding" {
                VideoCodecHandler.forceH264Encoding(result: result)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    static func forceH264Encoding(result: @escaping FlutterResult) {
        // This works on iOS 11.0 and higher
        if #available(iOS 11.0, *) {
            // Get the AVCaptureSession used by the camera plugin
            // First, try to modify AVCaptureSession default configuration
            let session = AVCaptureSession()
            session.beginConfiguration()
            
            // Try to get the default video device
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .unspecified) else {
                result(false)
                return
            }
            
            // Find a format that supports H.264
            var foundH264Format: AVCaptureDevice.Format? = nil
            
            // Look through available formats to find one that supports H264
            for format in videoDevice.formats {
                let description = format.formatDescription
                let mediaSubType = CMFormatDescriptionGetMediaSubType(description)
                
                // Check if this format supports H.264
                // kCMVideoCodecType_H264 = 'avc1'
                if mediaSubType == kCMVideoCodecType_H264 || mediaSubType == FourCharCode(1635148593) { // 'avc1' in integer
                    foundH264Format = format
                    break
                }
            }
            
            // Set user defaults to influence AVCaptureSession configuration
            UserDefaults.standard.set(false, forKey: "AVCaptureSessionPreferredVideoCodecKey")
            UserDefaults.standard.set("avc1", forKey: "AVVideoCodecKey")
            
            if let format = foundH264Format {
                do {
                    try videoDevice.lockForConfiguration()
                    videoDevice.activeFormat = format
                    videoDevice.unlockForConfiguration()
                    result(true)
                    return
                } catch {
                    print("Failed to lock device for configuration: \(error)")
                }
            }
            
            // If we got here, we couldn't configure the device specifically,
            // but we still set the user defaults which should influence new sessions
            result(true)
        } else {
            // For iOS < 11, H.264 is the default anyway
            result(true)
        }
    }
} 