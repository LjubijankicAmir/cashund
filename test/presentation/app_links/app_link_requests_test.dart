import 'dart:async';
import 'dart:ui';

import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/domain/repositories/home_screen_repository.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/presentation/app_links/app_link.dart';
import 'package:cashund/presentation/app_links/app_link_requests.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockHomeScreen extends Mock implements HomeScreenRepository;

void main() {
  late _MockHomeScreen homeScreen;
  late StreamController<Uri> launches;
  late AppLinkRequests requests;

  setUp(() {
    homeScreen = _MockHomeScreen();
    launches = StreamController<Uri>();
    when(() => homeScreen.launches).thenAnswer((_) => launches.stream);
    when(() => homeScreen.setShortcuts(any()))
        .thenAnswer((_) async => right(unit));
    requests = AppLinkRequests(
      homeScreen,
      lookupAppLocalizations(const Locale('en')),
    );
  });

  tearDown(() async {
    await requests.dispose();
    await launches.close();
  });

  test('puts the three shortcuts on the app icon', () async {
    await requests.start();

    final shortcuts =
        verify(() => homeScreen.setShortcuts(captureAny())).captured.single
            as List<AppShortcut>;
    expect(
      [for (final shortcut in shortcuts) (shortcut.title, '${shortcut.link}')],
      [
        ('Add expense', 'cashund://add?type=expense'),
        ('Add income', 'cashund://add?type=income'),
        ('Activity', 'cashund://activity'),
      ],
    );
  });

  test('keeps a link that came before anyone listened, once', () async {
    await requests.start();

    launches.add(Uri.parse('cashund://add?type=income'));
    await pumpEventQueue();

    expect(requests.take(), const AppLink.add(TransactionType.income));
    expect(requests.take(), isNull);
  });

  test('passes on links as they come and skips unknown ones', () async {
    await requests.start();
    final opened = <AppLink>[];
    final subscription = requests.requests.listen(opened.add);

    launches
      ..add(Uri.parse('cashund://somewhere'))
      ..add(Uri.parse('cashund://limits/3'));
    await pumpEventQueue();

    expect(opened, [const AppLink.limitDetail(3)]);
    await subscription.cancel();
  });
}
