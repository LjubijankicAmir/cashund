import 'package:cashund/core/di/injection.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/routing/app_router.dart';
import 'package:cashund/core/theme/cashund_theme.dart';
import 'package:cashund/presentation/app/bloc/app_theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CashundApp extends StatelessWidget {
  const CashundApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Built once, outside the theme builder, so a theme change doesn't
    // rebuild the router.
    final routerConfig = getIt<AppRouter>().config();

    return BlocProvider(
      create: (_) => getIt<AppThemeCubit>(),
      child: BlocBuilder<AppThemeCubit, ThemeMode>(
        builder: (context, themeMode) => MaterialApp.router(
          onGenerateTitle: (context) => context.l10n.appTitle,
          theme: CashundTheme.light,
          darkTheme: CashundTheme.dark,
          themeMode: themeMode,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: routerConfig,
        ),
      ),
    );
  }
}
