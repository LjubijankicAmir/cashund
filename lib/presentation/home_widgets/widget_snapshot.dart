import 'package:cashund/domain/value_objects/category_color.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'widget_snapshot.freezed.dart';

/// What the home-screen widgets show, ready to draw: every text is already
/// worded and formatted, so the native widgets only lay it out.
///
/// Saved as JSON (see [toJson]). Its [entries] cover the coming period
/// boundaries, so the widgets stay right after midnight or a new week without
/// the app running.
@freezed
abstract class WidgetSnapshot with _$WidgetSnapshot {
  const factory WidgetSnapshot({required List<WidgetEntry> entries}) =
      _WidgetSnapshot;

  const WidgetSnapshot._();

  /// Raised when the JSON changes in a way older widgets can't read.
  static const version = 1;

  Map<String, Object?> toJson() => {
    'version': version,
    'entries': [for (final entry in entries) entry.toJson()],
  };
}

/// Biscuit's face on the widgets.
enum WidgetMood {
  /// Under all limits, or a good week.
  happy,
  listening,

  /// A limit at 80% or past it.
  worried,

  /// Nothing logged yet.
  sleeping,
}

/// What the widgets show from [from] on, until the next entry's [from].
@freezed
abstract class WidgetEntry with _$WidgetEntry {
  const factory WidgetEntry({
    required DateTime from,
    required WidgetMood mood,
    required SpendingTile spending,
    required TodayTile today,
    required TodayWeekTile todayWeek,
    required CompactTile compact,

    /// `null` without category limits; the limits widget then shows
    /// [todayWeek] instead.
    LimitsTile? limits,
  }) = _WidgetEntry;

  const WidgetEntry._();

  Map<String, Object?> toJson() => {
    'from': from.millisecondsSinceEpoch,
    'mood': mood.name,
    'spending': spending.toJson(),
    'today': today.toJson(),
    'todayWeek': todayWeek.toJson(),
    'compact': compact.toJson(),
    'limits': limits?.toJson(),
  };
}

/// Which layout the spending widget uses.
enum SpendingTileKind {
  /// This week's spending, against the overall limit if there is one.
  normal,

  /// Nothing logged yet: an invitation to add the first one.
  empty,

  /// A limit is past: by how much.
  over,
}

/// The cobalt spending widget: "This week · $412.35 · of $600 this week".
@freezed
abstract class SpendingTile with _$SpendingTile {
  const factory SpendingTile({
    required SpendingTileKind kind,
    required String title,
    required String hero,
    required String caption,

    /// How full the bar is, from 0 to 1; `null` hides the bar.
    double? fraction,
  }) = _SpendingTile;

  const SpendingTile._();

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'title': title,
    'hero': hero,
    'caption': caption,
    'fraction': fraction,
  };
}

/// The plain spending widget: "Today · −$42.75 · 2 transactions", with the
/// week's total below.
@freezed
abstract class TodayTile with _$TodayTile {
  const factory TodayTile({
    required String title,
    required String hero,
    required String caption,
    required String weekLabel,
    required String weekValue,
  }) = _TodayTile;

  const TodayTile._();

  Map<String, Object?> toJson() => {
    'title': title,
    'hero': hero,
    'caption': caption,
    'weekLabel': weekLabel,
    'weekValue': weekValue,
  };
}

/// The medium widget with today on the left and the week on the right.
@freezed
abstract class TodayWeekTile with _$TodayWeekTile {
  const factory TodayWeekTile({
    required String todayTitle,
    required String todayHero,
    required String todayCaption,
    required String weekTitle,
    required String outLabel,
    required String outValue,
    required String inLabel,
    required String inValue,
    required String topLabel,
    required String topValue,

    /// The top category's color; `null` before anything was spent.
    CategoryColor? topColor,
  }) = _TodayWeekTile;

  const TodayWeekTile._();

  Map<String, Object?> toJson() => {
    'todayTitle': todayTitle,
    'todayHero': todayHero,
    'todayCaption': todayCaption,
    'weekTitle': weekTitle,
    'outLabel': outLabel,
    'outValue': outValue,
    'inLabel': inLabel,
    'inValue': inValue,
    'topLabel': topLabel,
    'topValue': topValue,
    'topColor': topColor?.name,
  };
}

/// The medium limits widget: a header and the two most used limits.
@freezed
abstract class LimitsTile with _$LimitsTile {
  const factory LimitsTile({
    required String title,
    required String status,

    /// Whether [status] warns, e.g. "Over by $12.40".
    required bool warns,
    required List<LimitRowTile> rows,
  }) = _LimitsTile;

  const LimitsTile._();

  Map<String, Object?> toJson() => {
    'title': title,
    'status': status,
    'warns': warns,
    'rows': [for (final row in rows) row.toJson()],
  };
}

/// One limit on the limits widget: "🍔 Eating Out · $86.40 / $100.00".
@freezed
abstract class LimitRowTile with _$LimitRowTile {
  const factory LimitRowTile({
    required int limitId,
    required String emoji,
    required String name,
    required String spent,
    required String amount,

    /// How full the bar is, from 0 to 1.
    required double fraction,
    required LimitStatus status,
    required CategoryColor color,
  }) = _LimitRowTile;

  const LimitRowTile._();

  Map<String, Object?> toJson() => {
    'limitId': limitId,
    'emoji': emoji,
    'name': name,
    'spent': spent,
    'amount': amount,
    'fraction': fraction,
    'status': status.name,
    'color': color.name,
  };
}

/// The compact widget: one number and a ring, "$187.65 · left this week".
@freezed
abstract class CompactTile with _$CompactTile {
  const factory CompactTile({
    required String hero,
    required String caption,

    /// How full the ring is, from 0 to 1; `null` hides the ring.
    double? fraction,
  }) = _CompactTile;

  const CompactTile._();

  Map<String, Object?> toJson() => {
    'hero': hero,
    'caption': caption,
    'fraction': fraction,
  };
}
