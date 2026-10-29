package com.cashund.app.widgets

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceModifier
import androidx.glance.LocalContext
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.appWidgetBackground
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

/** 4×2: today on cobalt to the left, the week's out, in and top category to the right. */
class TodayWeekWidget : SnapshotWidget() {
    @Composable
    override fun Content(entry: WidgetEntry) = TodayWeekContent(entry)
}

/** Also what the limits widget shows while no category limit is set. */
@Composable
fun TodayWeekContent(entry: WidgetEntry) {
    val tile = entry.todayWeek
    val context = LocalContext.current
    val half = LocalSize.current.width / 2
    Row(
        modifier = GlanceModifier
            .fillMaxSize()
            .appWidgetBackground()
            .platformCorners()
            .background(WidgetColors.surface)
            .clickable(openLink(context, tile.link)),
    ) {
        Column(
            modifier = GlanceModifier
                .defaultWeight()
                .fillMaxHeight()
                .background(WidgetColors.brand)
                .padding(16.dp),
        ) {
            Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Label(tile.todayTitle, WidgetColors.onBrand, fontSizeSp = 15f, modifier = GlanceModifier.defaultWeight())
                BuddyAvatar(entry.mood)
            }
            Spacer(modifier = GlanceModifier.defaultWeight())
            HeroText(tile.todayHero, WidgetColors.onBrand, fontSizeSp = 30f, maxWidth = half - 32.dp)
            Label(tile.todayCaption, WidgetColors.onBrandMuted)
        }
        Column(
            modifier = GlanceModifier.defaultWeight().fillMaxHeight().padding(16.dp),
        ) {
            Label(tile.weekTitle, WidgetColors.inkMuted)
            Spacer(modifier = GlanceModifier.defaultWeight())
            Figure(tile.outLabel, tile.outValue, WidgetColors.ink)
            Spacer(modifier = GlanceModifier.height(4.dp))
            Figure(tile.inLabel, tile.inValue, WidgetColors.positive)
            Spacer(modifier = GlanceModifier.height(4.dp))
            Figure(tile.topLabel, tile.topValue, WidgetColors.mark(tile.topColor))
        }
    }
}

/** "Out   −$412.35": a label and its value at the end of the row. */
@Composable
private fun Figure(label: String, value: String, color: androidx.glance.unit.ColorProvider) {
    Row(modifier = GlanceModifier.fillMaxWidth()) {
        Label(label, WidgetColors.inkMuted, modifier = GlanceModifier.defaultWeight())
        Label(value, color, bold = true)
    }
}

class TodayWeekWidgetReceiver : HomeWidgetGlanceWidgetReceiver<TodayWeekWidget>() {
    override val glanceAppWidget = TodayWeekWidget()

    override fun previewFingerprint(context: Context) = WidgetPreview.FINGERPRINT
}
