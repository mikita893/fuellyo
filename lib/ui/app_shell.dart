import 'package:flutter/material.dart';

import '../app/garage_store.dart';
import 'screens/dashboard_screen.dart';
import 'screens/fuel_screen.dart';
import 'screens/garage_screen.dart';
import 'screens/service_screen.dart';

/// Główny układ z dolną nawigacją.
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
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          DashboardScreen(onOpenService: () => _go(2)),
          const FuelScreen(),
          const ServiceScreen(),
          const GarageScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _go,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Pulpit',
          ),
          const NavigationDestination(
            icon: Icon(Icons.local_gas_station_outlined),
            selectedIcon: Icon(Icons.local_gas_station_rounded),
            label: 'Tankowania',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: attention > 0,
              label: Text('$attention'),
              child: const Icon(Icons.build_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: attention > 0,
              label: Text('$attention'),
              child: const Icon(Icons.build_rounded),
            ),
            label: 'Serwis',
          ),
          const NavigationDestination(
            icon: Icon(Icons.garage_outlined),
            selectedIcon: Icon(Icons.garage_rounded),
            label: 'Garaż',
          ),
        ],
      ),
    );
  }
}
