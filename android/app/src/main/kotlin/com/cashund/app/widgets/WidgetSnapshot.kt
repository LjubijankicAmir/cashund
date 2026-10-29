package com.cashund.app.widgets

import android.content.SharedPreferences
import org.json.JSONException
import org.json.JSONObject

// What the widgets show, worded and formatted by the app; the native side
// only lays it out. Mirrors lib/presentation/home_widgets/widget_snapshot.dart.

data class WidgetEntry(
    val from: Long,
    val mood: String,
    val spending: SpendingTile,
    val today: TodayTile,
    val todayWeek: TodayWeekTile,
    val compact: CompactTile,
    val limits: LimitsTile?,
)

data class SpendingTile(
    val kind: String,
    val title: String,
    val hero: String,
    val caption: String,
    val fraction: Float?,
    val link: String,
)

data class TodayTile(
    val title: String,
    val hero: String,
    val caption: String,
    val weekLabel: String,
    val weekValue: String,
    val link: String,
)

data class TodayWeekTile(
    val todayTitle: String,
    val todayHero: String,
    val todayCaption: String,
    val weekTitle: String,
    val outLabel: String,
    val outValue: String,
    val inLabel: String,
    val inValue: String,
    val topLabel: String,
    val topValue: String,
    val topColor: String?,
    val link: String,
)

data class LimitsTile(
    val title: String,
    val status: String,
    val warns: Boolean,
    val link: String,
    val rows: List<LimitRowTile>,
)

data class LimitRowTile(
    val emoji: String,
    val name: String,
    val spent: String,
    val amount: String,
    val fraction: Float,
    val status: String,
    val color: String,
    val link: String,
)

data class CompactTile(
    val hero: String,
    val caption: String,
    val fraction: Float?,
    val link: String,
)

object WidgetSnapshot {
    /** Where the app saves the snapshot, through home_widget. */
    private const val KEY = "snapshot"

    /** The JSON layout this code reads; a newer one waits for an app update. */
    private const val VERSION = 1

    /**
     * What to show at [now]: the latest entry that has started. `null` before
     * the app wrote a snapshot, before onboarding, or after deleting everything.
     */
    fun current(
        preferences: SharedPreferences,
        now: Long = System.currentTimeMillis(),
    ): WidgetEntry? {
        val json = preferences.getString(KEY, null) ?: return null
        return try {
            val root = JSONObject(json)
            if (root.optInt("version") != VERSION) return null
            val entries = root.getJSONArray("entries")
            var current: JSONObject? = null
            for (i in 0 until entries.length()) {
                val entry = entries.getJSONObject(i)
                if (entry.getLong("from") <= now) current = entry
            }
            current?.let(::entry)
        } catch (e: JSONException) {
            null
        }
    }

    private fun entry(json: JSONObject) = WidgetEntry(
        from = json.getLong("from"),
        mood = json.getString("mood"),
        spending = json.getJSONObject("spending").let {
            SpendingTile(
                kind = it.getString("kind"),
                title = it.getString("title"),
                hero = it.getString("hero"),
                caption = it.getString("caption"),
                fraction = it.fraction("fraction"),
                link = it.getString("link"),
            )
        },
        today = json.getJSONObject("today").let {
            TodayTile(
                title = it.getString("title"),
                hero = it.getString("hero"),
                caption = it.getString("caption"),
                weekLabel = it.getString("weekLabel"),
                weekValue = it.getString("weekValue"),
                link = it.getString("link"),
            )
        },
        todayWeek = json.getJSONObject("todayWeek").let {
            TodayWeekTile(
                todayTitle = it.getString("todayTitle"),
                todayHero = it.getString("todayHero"),
                todayCaption = it.getString("todayCaption"),
                weekTitle = it.getString("weekTitle"),
                outLabel = it.getString("outLabel"),
                outValue = it.getString("outValue"),
                inLabel = it.getString("inLabel"),
                inValue = it.getString("inValue"),
                topLabel = it.getString("topLabel"),
                topValue = it.getString("topValue"),
                topColor = it.text("topColor"),
                link = it.getString("link"),
            )
        },
        compact = json.getJSONObject("compact").let {
            CompactTile(
                hero = it.getString("hero"),
                caption = it.getString("caption"),
                fraction = it.fraction("fraction"),
                link = it.getString("link"),
            )
        },
        limits = json.optJSONObject("limits")?.let {
            val rows = it.getJSONArray("rows")
            LimitsTile(
                title = it.getString("title"),
                status = it.getString("status"),
                warns = it.getBoolean("warns"),
                link = it.getString("link"),
                rows = (0 until rows.length()).map { i ->
                    val row = rows.getJSONObject(i)
                    LimitRowTile(
                        emoji = row.getString("emoji"),
                        name = row.getString("name"),
                        spent = row.getString("spent"),
                        amount = row.getString("amount"),
                        fraction = row.getDouble("fraction").toFloat(),
                        status = row.getString("status"),
                        color = row.getString("color"),
                        link = row.getString("link"),
                    )
                },
            )
        },
    )

    private fun JSONObject.fraction(key: String): Float? =
        if (isNull(key)) null else getDouble(key).toFloat()

    private fun JSONObject.text(key: String): String? =
        if (isNull(key)) null else getString(key)
}
