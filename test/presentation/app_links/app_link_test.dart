import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/presentation/app_links/app_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AppLink? parse(String link) => AppLink.parse(Uri.parse(link));

  test('reads every link the widgets and shortcuts use', () {
    expect(parse('cashund://add'), const AppLink.add(TransactionType.expense));
    expect(
      parse('cashund://add?type=income'),
      const AppLink.add(TransactionType.income),
    );
    expect(parse('cashund://home'), const AppLink.home());
    expect(parse('cashund://activity'), const AppLink.activity());
    expect(parse('cashund://limits'), const AppLink.limits(LimitPeriod.week));
    expect(
      parse('cashund://limits?period=month'),
      const AppLink.limits(LimitPeriod.month),
    );
    expect(parse('cashund://limits/12'), const AppLink.limitDetail(12));
  });

  test('ignores links that aren’t ours or that it can’t read', () {
    for (final link in [
      'https://cashund.app/add',
      'cashund://settings',
      'cashund://add?type=gift',
      'cashund://limits?period=day',
      'cashund://limits/twelve',
      'cashund://limits/1/2',
      'cashund://home/extra',
    ]) {
      expect(parse(link), isNull, reason: link);
    }
  });

  test('writes each link so it reads back the same', () {
    for (final link in const [
      AppLink.add(TransactionType.expense),
      AppLink.add(TransactionType.income),
      AppLink.home(),
      AppLink.activity(),
      AppLink.limits(LimitPeriod.week),
      AppLink.limits(LimitPeriod.month),
      AppLink.limitDetail(7),
    ]) {
      expect(AppLink.parse(link.toUri()), link, reason: '${link.toUri()}');
    }
    expect(
      const AppLink.add(TransactionType.income).toUri().toString(),
      'cashund://add?type=income',
    );
    expect(
      const AppLink.limitDetail(7).toUri().toString(),
      'cashund://limits/7',
    );
  });
}
