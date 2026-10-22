import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:cashund/data/repositories/dismissed_message_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DismissedMessageRepositoryImpl repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = DismissedMessageRepositoryImpl(database.dismissedMessagesDao);
  });
  tearDown(() => database.close());

  Future<Map<String, DateTime>> all() async =>
      (await repository.watchAll().first).getRight().toNullable()!;

  test('remembers the day each message was closed', () async {
    expect(await all(), isEmpty);

    await repository.dismiss('limit:5:near', DateTime(2026, 10, 8, 21, 30));
    await repository.dismiss('recap:week:2026-10-05', DateTime(2026, 10, 12));

    expect(await all(), {
      'limit:5:near': DateTime(2026, 10, 8),
      'recap:week:2026-10-05': DateTime(2026, 10, 12),
    });
  });

  test('closing again moves the day forward', () async {
    await repository.dismiss('limit:5:near', DateTime(2026, 10, 8));
    await repository.dismiss('limit:5:near', DateTime(2026, 10, 9));

    expect(await all(), {'limit:5:near': DateTime(2026, 10, 9)});
  });
}
