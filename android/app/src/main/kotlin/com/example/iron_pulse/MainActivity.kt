package com.example.iron_pulse

import android.content.Intent
import android.provider.CalendarContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "iron_pulse/calendar"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "addToCalendar") {
                val title = call.argument<String>("title") ?: "Clase Iron Pulse"
                val description = call.argument<String>("description") ?: ""
                val location = call.argument<String>("location") ?: "Main Studio"
                val startTime = call.argument<Long>("startTime") ?: System.currentTimeMillis()
                val endTime = call.argument<Long>("endTime") ?: (startTime + 3600000)

                try {
                    val intent = Intent(Intent.ACTION_INSERT)
                        .setData(CalendarContract.Events.CONTENT_URI)
                        .putExtra(CalendarContract.Events.TITLE, title)
                        .putExtra(CalendarContract.Events.DESCRIPTION, description)
                        .putExtra(CalendarContract.Events.EVENT_LOCATION, location)
                        .putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, startTime)
                        .putExtra(CalendarContract.EXTRA_EVENT_END_TIME, endTime)
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("CALENDAR_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
