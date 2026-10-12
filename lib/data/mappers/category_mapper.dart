import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:cashund/domain/entities/category.dart';

extension CategoryRowMapper on CategoryRow {
  Category toEntity() {
    return Category(
      id: id,
      type: type,
      predefinedKey: predefinedKey,
      customName: customName,
      emoji: emoji,
      color: color,
      isArchived: isArchived,
      sortOrder: sortOrder,
    );
  }
}
