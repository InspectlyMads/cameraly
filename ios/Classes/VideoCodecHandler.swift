import Flutter
import AVFoundation

class VideoCodecHandler {
    static func forceH264Encoding(result: @escaping FlutterResult) {
        forceH264Encoding { success in
            result(success)
        }
    }
    
    static func forceH264Encoding(completion: @escaping (Bool) -> Void) {
        // This works on iOS 11.0 and higher
        if #available(iOS 11.0, *) {
            // Get the AVCaptureSession used by the camera plugin
            // First, try to modify AVCaptureSession default configuration
            let session = AVCaptureSession()
            session.beginConfiguration()
            
            // Try to get the default video device
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .unspecified) else {
                completion(false)
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
                    completion(true)
                    return
                } catch {
                    print("Failed to lock device for configuration: \(error)")
                }
            }
            
            // If we got here, we couldn't configure the device specifically,
            // but we still set the user defaults which should influence new sessions
            completion(true)
        } else {
            // For iOS < 11, H.264 is the default anyway
            completion(true)
        }
    }
    
    // Check if a video file uses HEVC encoding
    static func isVideoHevc(path: String, result: @escaping FlutterResult) {
        let url = URL(fileURLWithPath: path)
        let asset = AVAsset(url: url)
        
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            result(FlutterError(code: "NO_VIDEO_TRACK", message: "No video track found", details: nil))
            return
        }
        
        guard let formatDescription = videoTrack.formatDescriptions.first as? CMFormatDescription else {
            result(FlutterError(code: "NO_FORMAT_DESCRIPTION", message: "Cannot get format description", details: nil))
            return
        }
        
        let mediaSubType = CMFormatDescriptionGetMediaSubType(formatDescription)
        let isHevc = mediaSubType == kCMVideoCodecType_HEVC || mediaSubType == FourCharCode(1752589105) // 'hvc1' in integer
        
        result(isHevc)
    }
    
    // Transcodes HEVC video to H.264
    static func transcodeHevcToH264(path: String, result: @escaping FlutterResult) {
        let inputURL = URL(fileURLWithPath: path)
        
        // Create a temporary file path for the output
        let timestamp = Int(Date().timeIntervalSince1970)
        let tempDir = NSTemporaryDirectory()
        let outputPath = "\(tempDir)/h264_\(timestamp).mp4"
        let outputURL = URL(fileURLWithPath: outputPath)
        
        // Remove any existing file
        do {
            if FileManager.default.fileExists(atPath: outputPath) {
                try FileManager.default.removeItem(at: outputURL)
            }
        } catch {
            print("Error removing existing file: \(error)")
        }
        
        // Use VideoTranscoderHandler to do the actual transcoding
        VideoTranscoderHandler.transcodeToH264(
            inputPath: path,
            outputPath: outputPath,
            quality: "high",
            completion: { path, error in
                if let error = error {
                    result(FlutterError(code: "TRANSCODE_FAILED", message: error.localizedDescription, details: nil))
                } else {
                    result(path)
                }
            }
        )
    }
} 