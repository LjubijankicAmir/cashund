package com.cashund.app.widgets

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceModifier
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

/** 2×2, plain: what went out today, with the week's total below. */
class TodayWidget : SnapshotWidget() {
    @Composable
    override fun Content(entry: WidgetEntry) {
        val tile = entry.today
        WidgetCard(link = tile.link, background = WidgetColors.surface) {
            Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Label(tile.title, WidgetColors.inkMuted, fontSizeSp = 15f, modifier = GlanceModifier.defaultWeight())
                BuddyAvatar(entry.mood)
            }
            Spacer(modifier = GlanceModifier.defaultWeight())
            Label(tile.hero, WidgetColors.ink, fontSizeSp = 28f, bold = true)
            Label(tile.caption, WidgetColors.inkMuted)
            Spacer(modifier = GlanceModifier.height(10.dp))
            Box(modifier = GlanceModifier.fillMaxWidth().height(1.dp).background(WidgetColors.line)) {}
            Spacer(modifier = GlanceModifier.height(10.dp))
            Row(modifier = GlanceModifier.fillMaxWidth()) {
                Label(tile.weekLabel, WidgetColors.inkMuted, modifier = GlanceModifier.defaultWeight())
                Label(tile.weekValue, WidgetColors.ink, bold = true)
            }
        }
    }
}

class TodayWidgetReceiver : HomeWidgetGlanceWidgetReceiver<TodayWidget>() {
    override val glanceAppWidget = TodayWidget()

    override fun previewFingerprint(context: Context) = WidgetPreview.FINGERPRINT
}
