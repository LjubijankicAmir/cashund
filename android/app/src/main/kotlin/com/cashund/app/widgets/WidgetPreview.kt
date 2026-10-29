package com.cashund.app.widgets

import android.content.Context
import com.cashund.app.R
import java.text.NumberFormat

/**
 * What the widgets look like in the launcher's widget picker (Android 15 and
 * up): sample numbers, drawn by the widgets themselves, so they look right
 * even before onboarding.
 */
object WidgetPreview {
    /**
     * Raised whenever the sample changes, so home_widget registers the new
     * preview on the next app start instead of keeping the old one.
     */
    const val FINGERPRINT = "1"

    fun sample(context: Context): WidgetEntry {
        // In the phone's own currency, as a stand-in for the app's.
        val money = NumberFormat.getCurrencyInstance()
        fun amount(major: Double) = money.format(major)
        fun spent(major: Double) = "−${money.format(major)}"
        fun text(id: Int, vararg args: Any) = context.getString(id, *args)
        val home = "cashund://home"

        return WidgetEntry(
            from = 0,
            mood = "happy",
            spending = SpendingTile(
                kind = "normal",
                title = text(R.string.preview_this_week),
                hero = amount(412.35),
                caption = text(R.string.preview_of_limit, amount(600.0)),
                fraction = 0.69f,
                link = home,
            ),
            today = TodayTile(
                title = text(R.string.preview_today),
                hero = spent(42.75),
                caption = text(R.string.preview_transactions),
                weekLabel = text(R.string.preview_this_week),
                weekValue = spent(412.35),
                link = home,
            ),
            todayWeek = TodayWeekTile(
                todayTitle = text(R.string.preview_today),
                todayHero = spent(42.75),
                todayCaption = text(R.string.preview_transactions),
                weekTitle = text(R.string.preview_this_week),
                outLabel = text(R.string.preview_out),
                outValue = spent(412.35),
                inLabel = text(R.string.preview_in),
                inValue = "+${amount(2400.0)}",
                topLabel = text(R.string.preview_top),
                topValue = "🛒 ${text(R.string.preview_groceries)}",
                topColor = "olive",
                link = home,
            ),
            compact = CompactTile(
                hero = amount(187.65),
                caption = text(R.string.preview_left_this_week),
                fraction = 0.69f,
                link = home,
            ),
            limits = LimitsTile(
                title = text(R.string.preview_limits_title),
                status = text(R.string.preview_limit_close, text(R.string.preview_eating_out)),
                warns = true,
                link = home,
                rows = listOf(
                    LimitRowTile(
                        emoji = "🍔",
                        name = text(R.string.preview_eating_out),
                        spent = amount(86.40),
                        amount = amount(100.0),
                        fraction = 0.86f,
                        status = "near",
                        color = "apricot",
                        link = home,
                    ),
                    LimitRowTile(
                        emoji = "🛒",
                        name = text(R.string.preview_groceries),
                        spent = amount(148.20),
                        amount = amount(200.0),
                        fraction = 0.74f,
                        status = "under",
                        color = "olive",
                        link = home,
                    ),
                ),
            ),
        )
    }
}
