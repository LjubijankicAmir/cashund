package com.cashund.app.widgets

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.glance.GlanceId
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.provideContent
import androidx.glance.currentState
import androidx.glance.state.GlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition

/**
 * A widget that draws the snapshot the app saved: [Content] gets the entry
 * for now, or the widget invites to open the app when there's none.
 */
abstract class SnapshotWidget : GlanceAppWidget() {
    override val stateDefinition: GlanceStateDefinition<*> = HomeWidgetGlanceStateDefinition()

    /** Laid out for the size it actually has, so text fits as it's resized. */
    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val preferences = currentState<HomeWidgetGlanceState>().preferences
            when (val entry = WidgetSnapshot.current(preferences)) {
                null -> NotSetUp()
                else -> Content(entry)
            }
        }
    }

    /** The widget picker's preview: the same layout, with sample numbers. */
    override suspend fun providePreview(context: Context, widgetCategory: Int) {
        provideContent { Content(WidgetPreview.sample(context)) }
    }

    @Composable
    abstract fun Content(entry: WidgetEntry)
}
