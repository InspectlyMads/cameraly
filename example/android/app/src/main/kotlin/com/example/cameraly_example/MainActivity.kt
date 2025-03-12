package com.example.cameraly_example

import android.view.Surface
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.cameraly/orientation"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getDeviceRotation") {
                val rotation = getDeviceRotation()
                result.success(rotation)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getDeviceRotation(): Int {
        // Get the rotation value from the window manager
        val windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        val rotation = windowManager.defaultDisplay.rotation
        
        // Log the rotation value for debugging
        println("📱 Native Android rotation: $rotation")
        
        // Surface.ROTATION_0 = 0 (Portrait - default)
        // Surface.ROTATION_90 = 1 (Landscape Right - home button on right)
        // Surface.ROTATION_180 = 2 (Portrait upside down)
        // Surface.ROTATION_270 = 3 (Landscape Left - home button on left)
        return rotation
    }
}
