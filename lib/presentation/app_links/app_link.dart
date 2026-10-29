import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_link.freezed.dart';

/// A place in the app that a home-screen widget or an app shortcut opens,
/// written as a `cashund://` link, e.g. `cashund://add?type=income`.
@freezed
sealed class AppLink with _$AppLink {
  /// The sheet to log a new transaction of [type].
  const factory AppLink.add(TransactionType type) = AddLink;

  const factory AppLink.home() = HomeLink;

  const factory AppLink.activity() = ActivityLink;

  /// The Limits page, on its [period] tab.
  const factory AppLink.limits(LimitPeriod period) = LimitsLink;

  /// The detail page of the limit with [id].
  const factory AppLink.limitDetail(int id) = LimitDetailLink;

  const AppLink._();

  static const scheme = 'cashund';

  /// The link [uri] stands for; `null` when it isn't one of ours.
  static AppLink? parse(Uri uri) {
    if (uri.scheme != scheme) return null;
    final rest = uri.pathSegments;

    return switch (uri.host) {
      'add' when rest.isEmpty => switch (uri.queryParameters['type']) {
        null || 'expense' => const AppLink.add(TransactionType.expense),
        'income' => const AppLink.add(TransactionType.income),
        _ => null,
      },
      'home' when rest.isEmpty => const AppLink.home(),
      'activity' when rest.isEmpty => const AppLink.activity(),
      'limits' when rest.isEmpty => switch (uri.queryParameters['period']) {
        null || 'week' => const AppLink.limits(LimitPeriod.week),
        'month' => const AppLink.limits(LimitPeriod.month),
        _ => null,
      },
      'limits' when rest.length == 1 => switch (int.tryParse(rest.single)) {
        final id? => AppLink.limitDetail(id),
        null => null,
      },
      _ => null,
    };
  }

  Uri toUri() => switch (this) {
    AddLink(:final type) => _uri('add', query: {'type': type.name}),
    HomeLink() => _uri('home'),
    ActivityLink() => _uri('activity'),
    LimitsLink(:final period) => _uri('limits', query: {'period': period.name}),
    LimitDetailLink(:final id) => _uri('limits', path: '/$id'),
  };

  static Uri _uri(String host, {String? path, Map<String, String>? query}) =>
      Uri(scheme: scheme, host: host, path: path, queryParameters: query);
}
