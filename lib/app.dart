import 'package:cashund/core/di/injection.dart';
import 'package:cashund/core/routing/app_router.dart';
import 'package:cashund/core/theme/cashund_theme.dart';
import 'package:flutter/material.dart';

class CashundApp extends StatelessWidget {
  const CashundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cashund',
      theme: CashundTheme.light,
      darkTheme: CashundTheme.dark,
      routerConfig: getIt<AppRouter>().config(),
    );
  }
}
