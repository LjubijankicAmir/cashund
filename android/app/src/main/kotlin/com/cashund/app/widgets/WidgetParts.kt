package com.cashund.app.widgets

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.net.Uri
import android.os.Build
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.ColorFilter
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalContext
import androidx.glance.action.Action
import androidx.glance.action.clickable
import androidx.glance.appwidget.LinearProgressIndicator
import androidx.glance.appwidget.appWidgetBackground
import androidx.glance.appwidget.cornerRadius
import androidx.glance.background
import androidx.glance.color.ColorProvider
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.ColumnScope
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.cashund.app.MainActivity
import com.cashund.app.R
import es.antonborri.home_widget.HomeWidgetFonts
import es.antonborri.home_widget.actionStartActivity

/** The app's color tokens, light and dark (design system tokens.json). */
object WidgetColors {
    private fun token(light: Long, dark: Long) = ColorProvider(day = Color(light), night = Color(dark))

    val brand = token(0xFF2F4BFF, 0xFF2A3FD6)
    val onBrand = token(0xFFFFFFFF, 0xFFFFFFFF)
    val onBrandMuted = token(0xFFE6E9FF, 0xFFCCD3FF)

    /** `on-brand` at 22%, for tracks on cobalt (proposed `on-brand-track`). */
    val onBrandTrack = token(0x38FFFFFF, 0x38FFFFFF)
    val primary = token(0xFF2F4BFF, 0xFF8D9CFF)
    val surface = token(0xFFFFFFFF, 0xFF151A3A)
    val line = token(0xFFE3E6F2, 0xFF2B315E)
    val ink = token(0xFF14183A, 0xFFEEF0FF)
    val inkMuted = token(0xFF4A5072, 0xFFA9AFD6)
    val positive = token(0xFF17784A, 0xFF6FD49A)
    val warning = token(0xFF975800, 0xFFF5B44A)
    val warningFill = token(0xFFAD6400, 0xFFF5B44A)
    val track = token(0xFFDCE1FA, 0xFF2E3672)

    private val categoryMarks = mapOf(
        "coral" to token(0xFFCF756D, 0xFFA46560),
        "sky" to token(0xFF6EB7DF, 0xFF86C7EF),
        "mustard" to token(0xFFB8AE4B, 0xFFA9A745),
        "plum" to token(0xFFBF8AD5, 0xFFD89BE4),
        "olive" to token(0xFF6E944E, 0xFF678D62),
        "periwinkle" to token(0xFF4D69B3, 0xFF557EC6),
        "apricot" to token(0xFFD68C4D, 0xFFD08647),
        "teal" to token(0xFF039396, 0xFF00ADB9),
        "rose" to token(0xFFEC96B9, 0xFFEDB9D6),
        "slate" to token(0xFF505E6D, 0xFF66747E),
        "lavender" to token(0xFF9173AF, 0xFFAE78C1),
        "cocoa" to token(0xFFCAAE9D, 0xFFBFACA1),
    )

    /** A category's mark color, by the name the app stores. */
    fun mark(name: String?): ColorProvider = categoryMarks[name] ?: inkMuted
}

/** What a tap on [link], a `cashund://` link from the snapshot, does. */
fun openLink(context: Context, link: String): Action =
    actionStartActivity<MainActivity>(context, Uri.parse(link))

/**
 * The widget's own shell: the platform's corner radius, the background and
 * the tap target for the whole widget.
 */
@Composable
fun WidgetCard(
    link: String,
    background: ColorProvider,
    modifier: GlanceModifier = GlanceModifier.padding(16.dp),
    content: @Composable ColumnScope.() -> Unit,
) {
    val context = LocalContext.current
    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .appWidgetBackground()
            .platformCorners()
            .background(background)
            .clickable(openLink(context, link))
            .then(modifier),
        content = content,
    )
}

/** The launcher's widget corner radius where the platform has one. */
fun GlanceModifier.platformCorners(): GlanceModifier =
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        cornerRadius(android.R.dimen.system_app_widget_background_radius)
    } else {
        cornerRadius(24.dp)
    }

/** Biscuit in his round disc, with the face the snapshot's mood calls for. */
@Composable
fun BuddyAvatar(mood: String, size: Dp = 32.dp) {
    Image(
        provider = ImageProvider(
            when (mood) {
                "happy" -> R.drawable.buddy_happy
                "worried" -> R.drawable.buddy_worried
                "sleeping" -> R.drawable.buddy_sleeping
                else -> R.drawable.buddy_listening
            },
        ),
        // Decorative: the text next to him says what's going on.
        contentDescription = null,
        modifier = GlanceModifier.size(size),
    )
}

/**
 * A hero number in Fredoka. Glance can't use the app's fonts, so it's drawn
 * into a bitmap and tinted.
 */
@Composable
fun HeroText(text: String, color: ColorProvider, fontSizeSp: Float, maxWidth: Dp) {
    val context = LocalContext.current
    Image(
        provider = ImageProvider(
            HomeWidgetFonts.textBitmap(
                context,
                HomeWidgetFonts.typeface(context, "Fredoka", weight = 600),
                text,
                fontSizeSp = fontSizeSp,
                maxLines = 1,
                maxWidthDp = maxWidth.value,
            ),
        ),
        contentDescription = text,
        colorFilter = ColorFilter.tint(color),
    )
}

/** Text in the system font; the design never goes below 13sp on widgets. */
@Composable
fun Label(
    text: String,
    color: ColorProvider,
    fontSizeSp: Float = 14f,
    bold: Boolean = false,
    maxLines: Int = 1,
    modifier: GlanceModifier = GlanceModifier,
) {
    Text(
        text = text,
        maxLines = maxLines,
        modifier = modifier,
        style = TextStyle(
            color = color,
            fontSize = fontSizeSp.sp,
            fontWeight = if (bold) FontWeight.Bold else FontWeight.Medium,
        ),
    )
}

/** A 6dp progress bar, filled up to [fraction]. */
@Composable
fun Bar(fraction: Float, color: ColorProvider, track: ColorProvider) {
    LinearProgressIndicator(
        progress = fraction.coerceIn(0f, 1f),
        modifier = GlanceModifier.fillMaxWidth().height(6.dp).cornerRadius(3.dp),
        color = color,
        backgroundColor = track,
    )
}

/** A ring of [size], filled clockwise from the top up to [fraction]. */
@Composable
fun Ring(fraction: Float, size: Dp = 44.dp, stroke: Dp = 5.dp) {
    val context = LocalContext.current
    Box(modifier = GlanceModifier.size(size)) {
        Image(
            provider = ImageProvider(ringBitmap(context, size, stroke, 1f)),
            contentDescription = null,
            colorFilter = ColorFilter.tint(WidgetColors.track),
            modifier = GlanceModifier.size(size),
        )
        Image(
            provider = ImageProvider(ringBitmap(context, size, stroke, fraction)),
            contentDescription = null,
            colorFilter = ColorFilter.tint(WidgetColors.primary),
            modifier = GlanceModifier.size(size),
        )
    }
}

/** A white ring mask, to tint; Glance has no ring of its own. */
private fun ringBitmap(context: Context, size: Dp, stroke: Dp, fraction: Float): Bitmap {
    val density = context.resources.displayMetrics.density
    val pixels = (size.value * density).toInt()
    val strokePixels = stroke.value * density
    val bitmap = Bitmap.createBitmap(pixels, pixels, Bitmap.Config.ARGB_8888)
    val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = strokePixels
        strokeCap = Paint.Cap.ROUND
        color = android.graphics.Color.WHITE
    }
    val inset = strokePixels / 2
    val bounds = RectF(inset, inset, pixels - inset, pixels - inset)
    val sweep = fraction.coerceIn(0f, 1f)
    if (sweep >= 1f) {
        Canvas(bitmap).drawOval(bounds, paint)
    } else if (sweep > 0f) {
        Canvas(bitmap).drawArc(bounds, -90f, 360f * sweep, false, paint)
    }
    return bitmap
}

/** Before onboarding, or after deleting everything: an invitation to open the app. */
@Composable
fun NotSetUp() {
    val context = LocalContext.current
    WidgetCard(link = "cashund://home", background = WidgetColors.surface) {
        BuddyAvatar("sleeping")
        Spacer(modifier = GlanceModifier.height(8.dp))
        Label(
            context.getString(R.string.widget_not_set_up),
            WidgetColors.ink,
            bold = true,
            maxLines = 3,
        )
    }
}
