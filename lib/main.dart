import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/garage_repository.dart';
import 'ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pl');
  final repo = await InMemoryGarageRepository.withDemoData(DateTime.now());
  runApp(FuellYoApp(repository: repo));
}

class FuellYoApp extends StatelessWidget {
  const FuellYoApp({super.key, required this.repository});

  final GarageRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FuellYo!',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0E7C66),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF0E7C66),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: HomeScreen(repository: repository),
    );
  }
}
