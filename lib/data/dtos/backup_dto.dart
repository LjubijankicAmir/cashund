import 'package:cashund/data/datasources/local/app_database.dart';

/// The contents of a backup file: every table, as JSON.
///
/// [schemaVersion] is the database version it was made with, so an app can
/// tell a backup from a newer version it can't read yet.
class BackupDto {
  const BackupDto({
    required this.schemaVersion,
    required this.createdAt,
    required this.preferences,
    required this.categories,
    required this.transactions,
    required this.limits,
    required this.limitAmounts,
    required this.dismissedMessages,
  });

  /// Reads a backup's JSON. Throws [BackupFormatException] when it isn't a
  /// Cashund backup, and the usual errors when it's damaged.
  factory BackupDto.fromJson(Map<String, Object?> json) {
    if (json['format'] != format) throw const BackupFormatException();
    final version = json['formatVersion'];
    if (version is! int) throw const BackupFormatException();
    if (version > formatVersion) throw const BackupTooNewException();

    final tables = json['tables']! as Map<String, Object?>;
    List<T> rows<T>(String table, T Function(Map<String, dynamic>) fromJson) =>
        [
          for (final row in tables[table]! as List<Object?>)
            fromJson(row! as Map<String, dynamic>),
        ];

    return BackupDto(
      schemaVersion: json['schemaVersion']! as int,
      createdAt: DateTime.parse(json['createdAt']! as String).toLocal(),
      preferences: rows('preferences', PreferencesRow.fromJson),
      categories: rows('categories', CategoryRow.fromJson),
      transactions: rows('transactions', TransactionRow.fromJson),
      limits: rows('limits', LimitRow.fromJson),
      limitAmounts: rows('limitAmounts', LimitAmountRow.fromJson),
      dismissedMessages: rows(
        'dismissedMessages',
        DismissedMessageRow.fromJson,
      ),
    );
  }

  /// What every backup file says it is.
  static const format = 'cashund-backup';

  /// The layout of this file; bumped when it changes in a way older apps
  /// can't read.
  static const formatVersion = 1;

  final int schemaVersion;
  final DateTime createdAt;
  final List<PreferencesRow> preferences;
  final List<CategoryRow> categories;
  final List<TransactionRow> transactions;
  final List<LimitRow> limits;
  final List<LimitAmountRow> limitAmounts;
  final List<DismissedMessageRow> dismissedMessages;

  Map<String, Object?> toJson() => {
    'format': format,
    'formatVersion': formatVersion,
    'schemaVersion': schemaVersion,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'tables': {
      'preferences': [for (final row in preferences) row.toJson()],
      'categories': [for (final row in categories) row.toJson()],
      'transactions': [for (final row in transactions) row.toJson()],
      'limits': [for (final row in limits) row.toJson()],
      'limitAmounts': [for (final row in limitAmounts) row.toJson()],
      'dismissedMessages': [for (final row in dismissedMessages) row.toJson()],
    },
  };
}

/// The file isn't a Cashund backup.
class BackupFormatException implements Exception {
  const BackupFormatException();
}

/// The backup comes from a newer version of the app.
class BackupTooNewException implements Exception {
  const BackupTooNewException();
}
