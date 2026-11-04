import 'package:flutter/material.dart';

import '../../app/garage_store.dart';
import '../theme.dart';
import 'vehicle_form_screen.dart';

/// Ekran powitalny, gdy w garażu nie ma jeszcze żadnego auta.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(colors: [brandSeed, brandDeep]),
                      ),
                      child: const Icon(Icons.local_gas_station_rounded, color: Colors.white, size: 38),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text('Witaj w FuellYo!',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Text(
                    'Twój samochód pod kontrolą – bez arkuszy, karteczek i pamiętania o wszystkim samemu.',
                    style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant, height: 1.4),
                  ),
                  const SizedBox(height: 32),
                  const _Feature(
                    icon: Icons.notifications_active_outlined,
                    title: 'Przeglądy i naprawy',
                    text: 'Przypomnienia o oleju, filtrach, przeglądzie i OC oraz pełna historia napraw.',
                  ),
                  const _Feature(
                    icon: Icons.insights_rounded,
                    title: 'Prognoza tankowania',
                    text: 'Na podstawie Twojej historii wiemy, kiedy bak będzie pusty.',
                  ),
                  const _Feature(
                    icon: Icons.lock_outline_rounded,
                    title: 'W 100% offline',
                    text: 'Dane zostają na telefonie. Bez kont i bez śledzenia.',
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () => openVehicleForm(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Dodaj pierwsze auto'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => GarageScope.read(context).loadDemo(),
                    child: const Text('Zobacz na przykładowych danych'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 2),
                Text(text, style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
