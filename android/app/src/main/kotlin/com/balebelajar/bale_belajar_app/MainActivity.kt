package com.balebelajar.bale_belajar_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(
        flutterEngine.dartExecutor.binaryMessenger,
        "com.balebelajar.bale_belajar_app/vocab_lock_wallpaper",
    ).setMethodCallHandler { call, result ->
      try {
        when (call.method) {
          "setCurrent" -> {
            VocabLockScreenWallpaper.renderCurrent(this)
            VocabLockScreenWallpaper.scheduleHourly(this)
            result.success(true)
          }
          "scheduleHourly" -> {
            VocabLockScreenWallpaper.scheduleHourly(this)
            result.success(true)
          }
          "cancelHourly" -> {
            VocabLockScreenWallpaper.cancelHourly(this)
            result.success(true)
          }
          else -> result.notImplemented()
        }
      } catch (error: Exception) {
        result.error("VOCAB_WALLPAPER_FAILED", error.message, null)
      }
    }
  }
}
