package com.balebelajar.bale_belajar_app

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
  // Render bitmap + WallpaperManager.setBitmap berat (ratusan ms - detik).
  // Kalau jalan di main thread, UI Flutter macet saat resume -> layar putih.
  private val wallpaperExecutor = Executors.newSingleThreadExecutor()
  private val mainHandler = Handler(Looper.getMainLooper())

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(
        flutterEngine.dartExecutor.binaryMessenger,
        "com.balebelajar.bale_belajar_app/vocab_lock_wallpaper",
    ).setMethodCallHandler { call, result ->
      try {
        when (call.method) {
          "setCurrent" -> {
            val wordsJson = call.argument<String>("wordsJson")
            val appContext = applicationContext
            wallpaperExecutor.execute {
              try {
                if (!wordsJson.isNullOrBlank()) {
                  VocabLockScreenWallpaper.saveWords(appContext, wordsJson)
                }
                val changed = VocabLockScreenWallpaper.renderCurrent(appContext)
                if (changed) VocabLockScreenWallpaper.scheduleHourly(appContext)
                mainHandler.post { result.success(changed) }
              } catch (error: Exception) {
                mainHandler.post {
                  result.error("VOCAB_WALLPAPER_FAILED", error.message, null)
                }
              }
            }
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
