import 'package:cashund/app.dart';
import 'package:cashund/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() {
  // Keeps the native splash up until the first screen is decided.
  FlutterNativeSplash.preserve(
    widgetsBinding: WidgetsFlutterBinding.ensureInitialized(),
  );
  configureDependencies();
  runApp(const CashundApp());
}
