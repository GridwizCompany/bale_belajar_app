package com.balebelajar.bale_belajar_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class VocabWallpaperAlarmReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent) {
    when (intent.action) {
      Intent.ACTION_BOOT_COMPLETED,
      Intent.ACTION_MY_PACKAGE_REPLACED -> VocabLockScreenWallpaper.scheduleHourly(context)
      VocabLockScreenWallpaper.ACTION_UPDATE -> VocabLockScreenWallpaper.renderNext(context)
    }
  }
}
