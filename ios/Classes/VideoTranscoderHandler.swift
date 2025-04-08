import Flutter
import AVFoundation

class VideoTranscoderHandler {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.cameraly/video_transcoder", binaryMessenger: registrar.messenger())
        channel.setMethodCallHandler { (call, result) in
            if call.method == "transcodeToH264" {
                guard let args = call.arguments as? [String: Any],
                      let inputPath = args["inputPath"] as? String,
                      let outputPath = args["outputPath"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", 
                                       message: "Input and output paths are required", 
                                       details: nil))
                    return
                }
                
                let quality = args["quality"] as? String ?? "medium"
                
                VideoTranscoderHandler.transcodeToH264(
                    inputPath: inputPath,
                    outputPath: outputPath,
                    quality: quality,
                    completion: { path, error in
                        if let error = error {
                            result(FlutterError(code: "TRANSCODE_FAILED", 
                                              message: error.localizedDescription, 
                                              details: nil))
                        } else {
                            result(path)
                        }
                    }
                )
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    static func transcodeToH264(inputPath: String, outputPath: String, quality: String, completion: @escaping (String?, Error?) -> Void) {
        // Create file URL for input video
        let inputURL = URL(fileURLWithPath: inputPath)
        let outputURL = URL(fileURLWithPath: outputPath)
        
        // Remove any existing file at output path
        do {
            if FileManager.default.fileExists(atPath: outputPath) {
                try FileManager.default.removeItem(at: outputURL)
            }
        } catch {
            print("Error removing existing file: \(error)")
            // Continue anyway
        }
        
        // Create AVAsset for the input video
        let asset = AVAsset(url: inputURL)
        
        // Create export session
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: getExportPreset(for: quality)) else {
            print("Failed to create export session")
            completion(nil, NSError(domain: "VideoTranscoder", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session"]))
            return
        }
        
        // Configure export session
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        
        // Force H.264 encoding with explicit output configuration
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: getBitrate(for: quality),
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]
        exportSession.videoSettings = videoSettings
        
        // Set time range (full duration)
        exportSession.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
        
        // Start export
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                print("Video successfully transcoded to H.264")
                completion(outputPath, nil)
            case .failed:
                print("Export failed: \(exportSession.error?.localizedDescription ?? "Unknown error")")
                completion(nil, exportSession.error)
            case .cancelled:
                print("Export cancelled")
                completion(nil, NSError(domain: "VideoTranscoder", code: 2, userInfo: [NSLocalizedDescriptionKey: "Export cancelled"]))
            default:
                print("Export ended with status: \(exportSession.status.rawValue)")
                completion(nil, NSError(domain: "VideoTranscoder", code: 3, userInfo: [NSLocalizedDescriptionKey: "Export failed with status \(exportSession.status.rawValue)"]))
            }
        }
    }
    
    // Helper to get appropriate AVAssetExportPreset based on quality
    private static func getExportPreset(for quality: String) -> String {
        switch quality.lowercased() {
        case "low":
            return AVAssetExportPresetMediumQuality
        case "medium":
            return AVAssetExportPresetHighestQuality
        case "high":
            return AVAssetExportPresetHighestQuality
        default:
            return AVAssetExportPresetHighestQuality
        }
    }
    
    // Helper to get appropriate bitrate based on quality
    private static func getBitrate(for quality: String) -> Int {
        switch quality.lowercased() {
        case "low":
            return 2_000_000 // 2 Mbps
        case "medium":
            return 5_000_000 // 5 Mbps
        case "high":
            return 10_000_000 // 10 Mbps
        default:
            return 8_000_000 // 8 Mbps (default)
        }
    }
} 