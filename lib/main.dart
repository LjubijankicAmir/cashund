import 'package:flutter/material.dart';

void main() {
  runApp(const CashundApp());
}

class CashundApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Cashund',
      home: Scaffold(body: Center(child: Text('Cashund'))),
    );
  }
}
