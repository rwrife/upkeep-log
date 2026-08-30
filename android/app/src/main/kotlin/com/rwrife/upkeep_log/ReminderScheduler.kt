package com.rwrife.upkeeplog

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import org.json.JSONArray
import org.json.JSONObject
import java.time.DateTimeException
import java.time.LocalDateTime
import java.time.ZoneId

internal data class ReminderRecord(
    val id: String,
    val title: String,
    val year: Int,
    val month: Int,
    val day: Int,
    val hour: Int,
    val minute: Int,
    val timeZoneId: String,
) {
    fun toJson(): JSONObject = JSONObject()
        .put("id", id)
        .put("title", title)
        .put("year", year)
        .put("month", month)
        .put("day", day)
        .put("hour", hour)
        .put("minute", minute)
        .put("timeZoneId", timeZoneId)

    companion object {
        fun fromMap(value: Map<String, Any?>): ReminderRecord = ReminderRecord(
            id = requireNotNull(value["id"] as? String),
            title = requireNotNull(value["title"] as? String),
            year = (value["year"] as Number).toInt(),
            month = (value["month"] as Number).toInt(),
            day = (value["day"] as Number).toInt(),
            hour = (value["hour"] as Number).toInt(),
            minute = (value["minute"] as Number).toInt(),
            timeZoneId = requireNotNull(value["timeZoneId"] as? String),
        )

        fun fromJson(value: JSONObject): ReminderRecord = ReminderRecord(
            id = value.getString("id"),
            title = value.getString("title"),
            year = value.getInt("year"),
            month = value.getInt("month"),
            day = value.getInt("day"),
            hour = value.getInt("hour"),
            minute = value.getInt("minute"),
            timeZoneId = value.getString("timeZoneId"),
        )
    }
}

internal object ReminderScheduler {
    private const val CHANNEL_ID = "upkeep_reminders"
    private const val PREFERENCES = "upkeep_reminders"
    private const val RECORDS = "records"

    fun replaceAll(context: Context, values: List<Map<String, Any?>>): Int {
        val previous = stored(context)
        previous.forEach { cancel(context, it.id) }
        val records = values.map(ReminderRecord::fromMap)
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            .edit()
            .putString(RECORDS, JSONArray(records.map { it.toJson() }).toString())
            .apply()
        createChannel(context)
        return records.count { schedule(context, it) }
    }

    fun rescheduleStored(context: Context) {
        createChannel(context)
        stored(context).forEach {
            cancel(context, it.id)
            schedule(context, it)
        }
    }

    fun show(context: Context, id: String, title: String) {
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) return
        createChannel(context)
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val launch = launchIntent?.let {
            PendingIntent.getActivity(
                context,
                0,
                it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_popup_reminder)
            .setContentTitle(title)
            .setContentText("Upkeep is due. Open Upkeep Log for current status.")
            .setStyle(
                NotificationCompat.BigTextStyle().bigText(
                    "Upkeep is due. Open Upkeep Log for current status. Reminders are convenience aids and may be delayed by the operating system.",
                ),
            )
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .setContentIntent(launch)
            .build()
        NotificationManagerCompat.from(context).notify(notificationId(id), notification)
    }

    private fun schedule(context: Context, record: ReminderRecord): Boolean {
        val zone = try {
            ZoneId.of(record.timeZoneId)
        } catch (_: DateTimeException) {
            ZoneId.systemDefault()
        }
        val trigger = try {
            LocalDateTime.of(
                record.year,
                record.month,
                record.day,
                record.hour,
                record.minute,
            ).atZone(zone).toInstant().toEpochMilli()
        } catch (_: DateTimeException) {
            return false
        }
        if (trigger <= System.currentTimeMillis()) return false
        val alarm = context.getSystemService(AlarmManager::class.java) ?: return false
        alarm.setAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            trigger,
            pendingIntent(context, record),
        )
        return true
    }

    private fun cancel(context: Context, id: String) {
        val intent = Intent(context, ReminderReceiver::class.java).setAction("upkeep.reminder.$id")
        val pending = PendingIntent.getBroadcast(
            context,
            notificationId(id),
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        ) ?: return
        context.getSystemService(AlarmManager::class.java)?.cancel(pending)
        pending.cancel()
        NotificationManagerCompat.from(context).cancel(notificationId(id))
    }

    private fun pendingIntent(context: Context, record: ReminderRecord): PendingIntent {
        val intent = Intent(context, ReminderReceiver::class.java)
            .setAction("upkeep.reminder.${record.id}")
            .putExtra("id", record.id)
            .putExtra("title", record.title)
        return PendingIntent.getBroadcast(
            context,
            notificationId(record.id),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun stored(context: Context): List<ReminderRecord> {
        val raw = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            .getString(RECORDS, "[]") ?: "[]"
        return try {
            val array = JSONArray(raw)
            List(array.length()) { ReminderRecord.fromJson(array.getJSONObject(it)) }
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT < 26) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                "Upkeep reminders",
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply {
                description = "Optional reminders for upkeep due dates"
            },
        )
    }

    private fun notificationId(id: String): Int = id.hashCode() and 0x7fffffff
}
