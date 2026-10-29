package com.cashund.app.widgets

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceModifier
import androidx.glance.LocalContext
import androidx.glance.action.clickable
import androidx.glance.appwidget.cornerRadius
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

/**
 * 4×2: a cobalt header with how it stands, then the two most used limits.
 * Without category limits, today and this week instead.
 */
class LimitsWidget : SnapshotWidget() {
    @Composable
    override fun Content(entry: WidgetEntry) {
        val tile = entry.limits ?: return TodayWeekContent(entry)
        WidgetCard(link = tile.link, background = WidgetColors.surface, modifier = GlanceModifier) {
            Row(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .height(48.dp)
                    .background(WidgetColors.brand)
                    .padding(horizontal = 16.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                BuddyAvatar(entry.mood, size = 28.dp)
                Spacer(modifier = GlanceModifier.width(8.dp))
                Label(tile.title, WidgetColors.onBrand, fontSizeSp = 15f, bold = true, modifier = GlanceModifier.defaultWeight())
                Label(tile.status, WidgetColors.onBrandMuted)
            }
            Column(modifier = GlanceModifier.fillMaxWidth().padding(16.dp)) {
                tile.rows.forEachIndexed { index, row ->
                    if (index > 0) Spacer(modifier = GlanceModifier.height(12.dp))
                    LimitRow(row)
                }
            }
        }
    }
}

/** "▍🍔 Eating Out   $86.40 / $100.00", over a bar; a row opens its limit. */
@Composable
private fun LimitRow(row: LimitRowTile) {
    val context = LocalContext.current
    val warns = row.status != "under"
    Column(modifier = GlanceModifier.fillMaxWidth().clickable(openLink(context, row.link))) {
        Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Box(
                modifier = GlanceModifier
                    .width(4.dp)
                    .height(16.dp)
                    .cornerRadius(2.dp)
                    .background(WidgetColors.mark(row.color)),
            ) {}
            Spacer(modifier = GlanceModifier.width(8.dp))
            Label("${row.emoji} ${row.name}", WidgetColors.ink, fontSizeSp = 15f, modifier = GlanceModifier.defaultWeight())
            Label(
                if (row.status == "over") "⚠${row.spent}" else row.spent,
                if (warns) WidgetColors.warning else WidgetColors.ink,
                bold = true,
            )
            Label(
                " / ${row.amount}",
                if (warns) WidgetColors.warning else WidgetColors.inkMuted,
                bold = warns,
            )
        }
        Spacer(modifier = GlanceModifier.height(6.dp))
        Bar(
            row.fraction,
            if (warns) WidgetColors.warningFill else WidgetColors.mark(row.color),
            WidgetColors.track,
        )
    }
}

class LimitsWidgetReceiver : HomeWidgetGlanceWidgetReceiver<LimitsWidget>() {
    override val glanceAppWidget = LimitsWidget()

    override fun previewFingerprint(context: Context) = WidgetPreview.FINGERPRINT
}
