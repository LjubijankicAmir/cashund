package com.cashund.app.widgets

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceModifier
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.layout.width
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

/** 2×1: one number and a ring, "$187.65 left this week". */
class CompactWidget : SnapshotWidget() {
    @Composable
    override fun Content(entry: WidgetEntry) {
        val tile = entry.compact
        WidgetCard(link = tile.link, background = WidgetColors.surface, modifier = GlanceModifier) {
            Row(
                modifier = GlanceModifier.fillMaxSize().padding(horizontal = 16.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                // Without an overall limit there's nothing to fill, so Biscuit sits in.
                tile.fraction?.let { Ring(it) } ?: BuddyAvatar(entry.mood, size = 40.dp)
                Spacer(modifier = GlanceModifier.width(12.dp))
                Column {
                    Label(tile.hero, WidgetColors.ink, fontSizeSp = 20f, bold = true)
                    Label(tile.caption, WidgetColors.inkMuted)
                }
            }
        }
    }
}

class CompactWidgetReceiver : HomeWidgetGlanceWidgetReceiver<CompactWidget>() {
    override val glanceAppWidget = CompactWidget()

    override fun previewFingerprint(context: Context) = WidgetPreview.FINGERPRINT
}
