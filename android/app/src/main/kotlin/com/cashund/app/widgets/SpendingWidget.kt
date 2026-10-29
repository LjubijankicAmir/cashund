package com.cashund.app.widgets

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceModifier
import androidx.glance.LocalContext
import androidx.glance.LocalSize
import androidx.glance.appwidget.cornerRadius
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import com.cashund.app.R
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

/**
 * 2×2, cobalt: this week's spending against the overall limit. Also invites
 * the first transaction, and calls out a limit that's past.
 */
class SpendingWidget : SnapshotWidget() {
    @Composable
    override fun Content(entry: WidgetEntry) {
        val tile = entry.spending
        val width = LocalSize.current.width - 32.dp
        WidgetCard(link = tile.link, background = WidgetColors.brand) {
            Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Label(tile.title, WidgetColors.onBrand, fontSizeSp = 15f, modifier = GlanceModifier.defaultWeight())
                BuddyAvatar(entry.mood)
            }
            Spacer(modifier = GlanceModifier.defaultWeight())
            if (tile.kind == "empty") {
                Label(tile.hero, WidgetColors.onBrand, fontSizeSp = 20f, bold = true)
                Label(tile.caption, WidgetColors.onBrandMuted)
                Spacer(modifier = GlanceModifier.height(12.dp))
                AddPill()
            } else {
                HeroText(tile.hero, WidgetColors.onBrand, fontSizeSp = 34f, maxWidth = width)
                Label(tile.caption, WidgetColors.onBrandMuted, maxLines = 2)
                tile.fraction?.let {
                    Spacer(modifier = GlanceModifier.height(12.dp))
                    Bar(it, WidgetColors.onBrand, WidgetColors.onBrandTrack)
                }
            }
        }
    }
}

/** The white "+ Add" pill of the empty state; the whole widget opens the sheet. */
@Composable
private fun AddPill() {
    val context = LocalContext.current
    Box(
        modifier = GlanceModifier
            .fillMaxWidth()
            .height(36.dp)
            .cornerRadius(18.dp)
            .background(WidgetColors.onBrand),
        contentAlignment = Alignment.Center,
    ) {
        Label(context.getString(R.string.widget_add), WidgetColors.brand, fontSizeSp = 15f, bold = true)
    }
}

class SpendingWidgetReceiver : HomeWidgetGlanceWidgetReceiver<SpendingWidget>() {
    override val glanceAppWidget = SpendingWidget()

    override fun previewFingerprint(context: Context) = WidgetPreview.FINGERPRINT
}
