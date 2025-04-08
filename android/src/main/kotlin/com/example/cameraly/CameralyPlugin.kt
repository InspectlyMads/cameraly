package com.example.cameraly

import android.content.Context
import android.view.Surface
import android.view.WindowManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.yourpackage.cameraly.VideoOrientationHandler

class CameralyPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var orientationChannel: MethodChannel
  private lateinit var videoOrientationChannel: MethodChannel
  private lateinit var context: Context

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    // Main plugin channel
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "cameraly")
    channel.setMethodCallHandler(this)
    
    // Orientation-specific channel
    orientationChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.cameraly/orientation")
    orientationChannel.setMethodCallHandler(OrientationHandler(context))
    
    // Setup video orientation channel
    videoOrientationChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.cameraly/video_orientation")
    VideoOrientationHandler.register(context, videoOrientationChannel)
    
    // Save context for later use
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getDeviceRotation" -> {
        try {
          val rotation = getDeviceRotation()
          println("🧭 Android returning rotation: $rotation")
          result.success(rotation)
        } catch (e: Exception) {
          println("❌ Error getting device rotation: ${e.message}")
          result.error("ROTATION_ERROR", "Failed to get device rotation", e.message)
        }
      }
      else -> result.notImplemented()
    }
  }

  private fun getDeviceRotation(): Int {
    val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    val rotation = windowManager.defaultDisplay.rotation
    println("🧭 Native device rotation: $rotation (${rotationToString(rotation)})")
    return rotation
  }

  private fun rotationToString(rotation: Int): String {
    return when (rotation) {
      Surface.ROTATION_0 -> "ROTATION_0 (Portrait Up)"
      Surface.ROTATION_90 -> "ROTATION_90 (Landscape Right)"
      Surface.ROTATION_180 -> "ROTATION_180 (Portrait Down)"
      Surface.ROTATION_270 -> "ROTATION_270 (Landscape Left)"
      else -> "Unknown Rotation"
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    orientationChannel.setMethodCallHandler(null)
    videoOrientationChannel.setMethodCallHandler(null)
  }
} 