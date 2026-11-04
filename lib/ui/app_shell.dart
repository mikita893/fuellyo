import 'package:flutter/material.dart';

import '../app/garage_store.dart';
import 'screens/about_screen.dart';
import 'screens/fuel_screen.dart';
import 'screens/home_screen.dart';
import 'screens/inspections_screen.dart';
import 'screens/repairs_screen.dart';

/// Główny układ z dolnym paskiem nawigacji (5 zakładek).
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  void _go(int tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final attention = GarageScope.of(context).current?.attention.length ?? 0;

    Widget inspectionsIcon(IconData icon) => Badge(
          isLabelVisible: attention > 0,
          label: Text('$attention'),
          child: Icon(icon),
        );

    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          HomeScreen(onOpenTab: _go),
          const FuelScreen(),
          const RepairsScreen(),
          const InspectionsScreen(),
          const AboutScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _go,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Start',
          ),
          const NavigationDestination(
            icon: Icon(Icons.local_gas_station_outlined),
            selectedIcon: Icon(Icons.local_gas_station_rounded),
            label: 'Tankowania',
          ),
          const NavigationDestination(
            icon: Icon(Icons.handyman_outlined),
            selectedIcon: Icon(Icons.handyman_rounded),
            label: 'Naprawy',
          ),
          NavigationDestination(
            icon: inspectionsIcon(Icons.fact_check_outlined),
            selectedIcon: inspectionsIcon(Icons.fact_check_rounded),
            label: 'Przeglądy',
          ),
          const NavigationDestination(
            icon: Icon(Icons.info_outline_rounded),
            selectedIcon: Icon(Icons.info_rounded),
            label: 'O aplikacji',
          ),
        ],
      ),
    );
  }
}
