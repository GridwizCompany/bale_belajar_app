package com.balebelajar.bale_belajar_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

/**
 * Widget home-screen yang menampilkan kosakata Inggris-Korea hari ini. Data
 * (kata + pengaturan tampilan) ditulis dari Dart lewat package `home_widget`
 * (lihat VocabSyncService._updateWidget) ke SharedPreferences bernama
 * "HomeWidgetPreferences" - [widgetData] di bawah adalah preferences itu.
 *
 * Ketuk kartu = pindah ke kata berikutnya di daftar hari ini (index disimpan
 * balik ke preferences yang sama supaya tetap sinkron kalau widget di-resize/
 * di-recreate). Ketuk "Buka App" = buka MainActivity seperti biasa.
 */
class VocabWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      val views = RemoteViews(context.packageName, R.layout.vocab_widget_layout)
      applyWordToViews(views, widgetData)

      views.setOnClickPendingIntent(R.id.vocab_widget_root, nextWordPendingIntent(context))
      views.setOnClickPendingIntent(
          R.id.vocab_widget_open_app,
          HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
      )

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }

  override fun onReceive(context: Context, intent: Intent) {
    super.onReceive(context, intent)
    if (intent.action != ACTION_NEXT_WORD) return

    val widgetData = context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
    val words = parseWords(widgetData.getString(KEY_WORDS_JSON, null))
    if (words.isNotEmpty()) {
      val current = widgetData.getInt(KEY_WORD_INDEX, 0)
      widgetData.edit().putInt(KEY_WORD_INDEX, (current + 1) % words.size).apply()
    }

    val appWidgetManager = AppWidgetManager.getInstance(context)
    val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, VocabWidgetProvider::class.java))
    if (ids.isNotEmpty()) {
      onUpdate(context, appWidgetManager, ids)
    }
  }

  private fun applyWordToViews(
      views: RemoteViews,
      widgetData: SharedPreferences,
  ) {
    val enabled = widgetData.getBoolean(KEY_WIDGET_ENABLED, true)
    val words = parseWords(widgetData.getString(KEY_WORDS_JSON, null))

    if (!enabled || words.isEmpty()) {
      views.setTextViewText(R.id.vocab_widget_title, "Kata Korea Hari Ini")
      views.setTextViewText(R.id.vocab_widget_english, "Siap belajar?")
      views.setTextViewText(R.id.vocab_widget_korean, "Buka BaleBelajar dulu")
      views.setTextViewText(R.id.vocab_widget_footer, "Kosakata harian akan muncul di sini")
      return
    }

    val index = widgetData.getInt(KEY_WORD_INDEX, 0).let { if (it < 0) 0 else it % words.size }
    val word = words[index]
    val displayLanguage = widgetData.getString(KEY_DISPLAY_LANGUAGE, "BOTH") ?: "BOTH"
    val koreanText = if (word.romanized.isNotEmpty()) {
      "${word.korean} (${word.romanized})"
    } else {
      word.korean
    }

    when (displayLanguage) {
      "KO_TO_EN" -> {
        views.setTextViewText(R.id.vocab_widget_english, koreanText)
        views.setTextViewText(R.id.vocab_widget_korean, word.english)
      }
      else -> {
        views.setTextViewText(R.id.vocab_widget_english, word.english)
        views.setTextViewText(R.id.vocab_widget_korean, koreanText)
      }
    }
    views.setTextViewText(
        R.id.vocab_widget_footer,
        "${index + 1}/${words.size} • ketuk kartu untuk kata berikutnya",
    )
  }

  private fun nextWordPendingIntent(context: Context): PendingIntent {
    val intent = Intent(context, VocabWidgetProvider::class.java).apply { action = ACTION_NEXT_WORD }
    var flags = PendingIntent.FLAG_UPDATE_CURRENT
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      flags = flags or PendingIntent.FLAG_IMMUTABLE
    }
    return PendingIntent.getBroadcast(context, 0, intent, flags)
  }

  private fun parseWords(json: String?): List<VocabWordEntry> {
    if (json.isNullOrEmpty()) return emptyList()
    return try {
      val array = JSONArray(json)
      (0 until array.length()).map { i ->
        val obj = array.getJSONObject(i)
        VocabWordEntry(
            english = obj.optString("english"),
            korean = obj.optString("korean"),
            romanized = obj.optString("koreanRomanized", ""),
        )
      }
    } catch (error: Exception) {
      emptyList()
    }
  }

  private data class VocabWordEntry(val english: String, val korean: String, val romanized: String)

  companion object {
    private const val ACTION_NEXT_WORD = "com.balebelajar.bale_belajar_app.VOCAB_WIDGET_NEXT"

    // Nilai-nilai ini HARUS sama persis dengan key yang dipakai
    // VocabSyncService._updateWidget di sisi Dart.
    private const val PREFERENCES_NAME = "HomeWidgetPreferences"
    private const val KEY_WIDGET_ENABLED = "vocab_widget_enabled"
    private const val KEY_WORDS_JSON = "vocab_words_json"
    private const val KEY_WORD_INDEX = "vocab_word_index"
    private const val KEY_DISPLAY_LANGUAGE = "vocab_display_language"
  }
}
