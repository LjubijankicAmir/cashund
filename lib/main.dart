import 'package:cashund/core/theme/cashund_theme.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const CashundApp());
}

class CashundApp extends StatelessWidget {
  const CashundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cashund',
      theme: CashundTheme.light,
      darkTheme: CashundTheme.dark,
      home: const Scaffold(body: Center(child: Text('Cashund'))),
    );
  }
}
