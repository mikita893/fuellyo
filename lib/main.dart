import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/garage_store.dart';
import 'data/garage_repository.dart';
import 'ui/app_shell.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pl');
  final store = GarageStore(InMemoryGarageRepository());
  await store.load();
  runApp(FuellYoApp(store: store));
}

class FuellYoApp extends StatelessWidget {
  const FuellYoApp({super.key, required this.store});

  final GarageStore store;

  @override
  Widget build(BuildContext context) {
    return GarageScope(
      store: store,
      child: MaterialApp(
        title: 'FuellYo!',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        locale: const Locale('pl'),
        supportedLocales: const [Locale('pl'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final store = GarageScope.of(context);
    if (store.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: store.current == null ? const OnboardingScreen() : const AppShell(),
    );
  }
}
