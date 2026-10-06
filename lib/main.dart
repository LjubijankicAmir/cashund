import 'package:cashund/app.dart';
import 'package:cashund/core/di/injection.dart';
import 'package:flutter/material.dart';

void main() {
  configureDependencies();
  runApp(const CashundApp());
}
