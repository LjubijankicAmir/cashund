package com.cashund.app.widgets

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.ColorFilter
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.size
import androidx.glance.layout.width
import com.cashund.app.R
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

/** Opens the sheet to log an expense; the same link as the app shortcut. */
private const val ADD_EXPENSE = "cashund://add?type=expense"

/** 1×1: a cobalt square with a white plus. */
class QuickAddWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent { Content(context) }
    }

    /** The picker shows it as it is; there's nothing to fill in. */
    override suspend fun providePreview(context: Context, widgetCategory: Int) {
        provideContent { Content(context) }
    }

    @Composable
    private fun Content(context: Context) {
        WidgetCard(link = ADD_EXPENSE, background = WidgetColors.brand, modifier = GlanceModifier) {
            Box(modifier = GlanceModifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Image(
                    provider = ImageProvider(R.drawable.shortcut_add),
                    contentDescription = context.getString(R.string.widget_add_expense),
                    colorFilter = ColorFilter.tint(WidgetColors.onBrand),
                    modifier = GlanceModifier.size(28.dp),
                )
            }
        }
    }
}

/** 2×1: a cobalt pill with Biscuit and "Add expense". */
class QuickAddPillWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent { Content(context) }
    }

    override suspend fun providePreview(context: Context, widgetCategory: Int) {
        provideContent { Content(context) }
    }

    @Composable
    private fun Content(context: Context) {
        WidgetCard(link = ADD_EXPENSE, background = WidgetColors.brand, modifier = GlanceModifier) {
            Row(
                modifier = GlanceModifier.fillMaxSize(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                BuddyAvatar("listening")
                Spacer(modifier = GlanceModifier.width(12.dp))
                Label(
                    context.getString(R.string.widget_add_expense),
                    WidgetColors.onBrand,
                    fontSizeSp = 16f,
                    bold = true,
                )
            }
        }
    }
}

class QuickAddWidgetReceiver : HomeWidgetGlanceWidgetReceiver<QuickAddWidget>() {
    override val glanceAppWidget = QuickAddWidget()

    override fun previewFingerprint(context: Context) = WidgetPreview.FINGERPRINT
}

class QuickAddPillWidgetReceiver : HomeWidgetGlanceWidgetReceiver<QuickAddPillWidget>() {
    override val glanceAppWidget = QuickAddPillWidget()

    override fun previewFingerprint(context: Context) = WidgetPreview.FINGERPRINT
}
