package com.balebelajar.bale_belajar_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.app.WallpaperManager
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.os.Build
import org.json.JSONArray
import kotlin.math.max
import kotlin.random.Random

object VocabLockScreenWallpaper {
  const val ACTION_UPDATE = "com.balebelajar.bale_belajar_app.VOCAB_WALLPAPER_UPDATE"

  private const val PREFERENCES_NAME = "HomeWidgetPreferences"
  private const val KEY_WORDS_JSON = "vocab_words_json"
  private const val KEY_LOCK_INDEX = "vocab_lock_wallpaper_index"
  private const val WALLPAPER_INTERVAL_MS = 30L * 60L * 1000L

  fun saveWords(context: Context, wordsJson: String) {
    context
        .getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
        .edit()
        .putString(KEY_WORDS_JSON, wordsJson)
        .putInt(KEY_LOCK_INDEX, 0)
        .apply()
  }

  fun renderCurrent(context: Context, word: VocabWallpaperWord? = null): Boolean {
    val prefs = context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
    val words = parseWords(prefs.getString(KEY_WORDS_JSON, null))
    val selected = word ?: words.firstOrNull() ?: return false
    val bitmap = drawWallpaper(context, selected)
    val wallpaperManager = WallpaperManager.getInstance(context)
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
      wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_LOCK)
    } else {
      wallpaperManager.setBitmap(bitmap)
    }
    return true
  }

  fun renderNext(context: Context) {
    val prefs = context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
    val words = parseWords(prefs.getString(KEY_WORDS_JSON, null))
    if (words.isEmpty()) return
    val current = prefs.getInt(KEY_LOCK_INDEX, -1)
    val next = (current + 1) % words.size
    prefs.edit().putInt(KEY_LOCK_INDEX, next).apply()
    renderCurrent(context, words[next])
  }

  fun scheduleHourly(context: Context) {
    val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    val pendingIntent = updatePendingIntent(context)
    val nextUpdate = System.currentTimeMillis() + WALLPAPER_INTERVAL_MS
    alarmManager.setInexactRepeating(
        AlarmManager.RTC_WAKEUP,
        nextUpdate,
        WALLPAPER_INTERVAL_MS,
        pendingIntent,
    )
  }

  fun cancelHourly(context: Context) {
    val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    alarmManager.cancel(updatePendingIntent(context))
  }

  private fun updatePendingIntent(context: Context): PendingIntent {
    val intent = Intent(context, VocabWallpaperAlarmReceiver::class.java).apply {
      action = ACTION_UPDATE
    }
    var flags = PendingIntent.FLAG_UPDATE_CURRENT
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      flags = flags or PendingIntent.FLAG_IMMUTABLE
    }
    return PendingIntent.getBroadcast(context, 7001, intent, flags)
  }

  private fun drawWallpaper(context: Context, word: VocabWallpaperWord): Bitmap {
    val metrics = context.resources.displayMetrics
    val width = max(metrics.widthPixels, 1080)
    val height = max(metrics.heightPixels, 1920)
    val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)

    val seed = word.korean.hashCode()
    val random = Random(seed)
    val skyTop = intArrayOf(0xFF6E86A8.toInt(), 0xFF6B7FA4.toInt(), 0xFF7E91AA.toInt())
    val skyMid = intArrayOf(0xFFD7C8B1.toInt(), 0xFFE2C9A5.toInt(), 0xFFD5B6A0.toInt())
    val horizon = intArrayOf(0xFFC67763.toInt(), 0xFFB86F5D.toInt(), 0xFFC9966D.toInt())
    val gradientPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
      shader = LinearGradient(
          0f,
          0f,
          0f,
          height.toFloat(),
          intArrayOf(
              skyTop[random.nextInt(skyTop.size)],
              skyMid[random.nextInt(skyMid.size)],
              horizon[random.nextInt(horizon.size)],
              0xFF111827.toInt(),
          ),
          floatArrayOf(0f, 0.52f, 0.74f, 1f),
          Shader.TileMode.CLAMP,
      )
    }
    canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), gradientPaint)

    val haze = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = 0x33FFFFFF }
    canvas.drawCircle(width * 0.72f, height * 0.24f, width * 0.42f, haze)

    drawMountains(canvas, width, height)
    drawCity(canvas, width, height)
    drawWater(canvas, width, height)
    drawVocabulary(canvas, width, height, word)

    return bitmap
  }

  private fun drawVocabulary(canvas: Canvas, width: Int, height: Int, word: VocabWallpaperWord) {
    val cardLeft = width * 0.60f
    val cardRight = width * 0.96f
    val cardTop = height * 0.215f
    val cardBottom = height * 0.335f
    val card = RectF(cardLeft, cardTop, cardRight, cardBottom)
    val cardPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = 0x24000000 }
    val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
      color = 0x26FFFFFF
      style = Paint.Style.STROKE
      strokeWidth = max(1.5f, width * 0.0018f)
    }
    val radius = width * 0.030f
    canvas.drawRoundRect(card, radius, radius, cardPaint)
    canvas.drawRoundRect(card, radius, radius, strokePaint)

    val left = cardLeft + width * 0.030f
    val right = cardRight - width * 0.030f
    val top = cardTop + height * 0.040f
    val shadow = Paint(Paint.ANTI_ALIAS_FLAG).apply {
      color = 0x66000000
      textAlign = Paint.Align.LEFT
      typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
    }
    val hangul = Paint(shadow).apply {
      color = Color.WHITE
      textSize = fitTextSize(word.korean, this, right - left, width * 0.060f, width * 0.036f)
    }
    shadow.textSize = hangul.textSize
    drawEllipsized(canvas, word.korean, left + 3f, top + 5f, shadow, right - left)
    drawEllipsized(canvas, word.korean, left, top, hangul, right - left)

    val body = Paint(Paint.ANTI_ALIAS_FLAG).apply {
      color = 0xEEFFFFFF.toInt()
      textSize = width * 0.025f
      typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
      textAlign = Paint.Align.LEFT
    }
    val small = Paint(body).apply {
      color = 0xDFFFFFFF.toInt()
      textSize = width * 0.022f
      typeface = Typeface.create(Typeface.DEFAULT, Typeface.NORMAL)
    }

    var cursor = top + hangul.textSize * 0.70f
    if (word.romanized.isNotBlank()) {
      drawEllipsized(canvas, word.romanized, left, cursor, small, right - left)
      cursor += small.textSize * 1.20f
    }
    drawEllipsized(canvas, word.indonesian, left, cursor, body, right - left)
  }

  private fun fitTextSize(
      text: String,
      paint: Paint,
      maxWidth: Float,
      preferred: Float,
      minimum: Float,
  ): Float {
    var size = preferred
    paint.textSize = size
    while (size > minimum && paint.measureText(text) > maxWidth) {
      size *= 0.92f
      paint.textSize = size
    }
    return max(size, minimum)
  }

  private fun drawEllipsized(
      canvas: Canvas,
      text: String,
      x: Float,
      y: Float,
      paint: Paint,
      maxWidth: Float,
  ) {
    if (paint.measureText(text) <= maxWidth) {
      canvas.drawText(text, x, y, paint)
      return
    }

    val ellipsis = "..."
    var clipped = text.trim()
    while (clipped.isNotEmpty() && paint.measureText(clipped + ellipsis) > maxWidth) {
      clipped = clipped.dropLast(1).trimEnd()
    }
    if (clipped.isNotEmpty()) {
      canvas.drawText(clipped + ellipsis, x, y, paint)
    }
  }

  private fun drawMountains(canvas: Canvas, width: Int, height: Int) {
    val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = 0xAA111827.toInt() }
    val y = height * 0.72f
    val path = Path().apply {
      moveTo(0f, y)
      lineTo(width * 0.16f, y - height * 0.05f)
      lineTo(width * 0.34f, y - height * 0.03f)
      lineTo(width * 0.48f, y - height * 0.11f)
      lineTo(width * 0.70f, y - height * 0.04f)
      lineTo(width.toFloat(), y - height * 0.07f)
      lineTo(width.toFloat(), height.toFloat())
      lineTo(0f, height.toFloat())
      close()
    }
    canvas.drawPath(path, paint)
  }

  private fun drawCity(canvas: Canvas, width: Int, height: Int) {
    val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = 0xDD0B1220.toInt() }
    val base = height * 0.73f
    for (i in 0 until 18) {
      val buildingWidth = width * (0.022f + (i % 3) * 0.006f)
      val x = width * 0.46f + i * width * 0.032f
      val h = height * (0.035f + (i % 5) * 0.008f)
      canvas.drawRect(x, base - h, x + buildingWidth, base, paint)
    }
    val tower = Paint(paint).apply { strokeWidth = width * 0.005f }
    val tx = width * 0.31f
    canvas.drawLine(tx, base, tx, base - height * 0.18f, tower)
    canvas.drawCircle(tx, base - height * 0.115f, width * 0.018f, tower)
  }

  private fun drawWater(canvas: Canvas, width: Int, height: Int) {
    val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = 0x55111827 }
    canvas.drawRect(0f, height * 0.74f, width.toFloat(), height.toFloat(), paint)
    val line = Paint(Paint.ANTI_ALIAS_FLAG).apply {
      color = 0x22FFFFFF
      strokeWidth = 2f
    }
    for (i in 0 until 9) {
      val y = height * (0.77f + i * 0.022f)
      canvas.drawLine(width * 0.08f, y, width * 0.92f, y + (i % 2) * 4f, line)
    }
  }

  private fun parseWords(json: String?): List<VocabWallpaperWord> {
    if (json.isNullOrEmpty()) return emptyList()
    return try {
      val array = JSONArray(json)
      (0 until array.length()).map { i ->
        val obj = array.getJSONObject(i)
        VocabWallpaperWord(
            korean = obj.optString("korean"),
            romanized = obj.optString("koreanRomanized", ""),
            english = obj.optString("english"),
            indonesian = obj.optString("indonesian", obj.optString("english")),
        )
      }.filter { it.korean.isNotBlank() }
    } catch (error: Exception) {
      emptyList()
    }
  }
}

data class VocabWallpaperWord(
    val korean: String,
    val romanized: String,
    val english: String,
    val indonesian: String,
)
