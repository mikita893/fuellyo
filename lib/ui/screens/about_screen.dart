import 'package:flutter/material.dart';

import '../../app/garage_store.dart';
import '../../domain/domain.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'vehicle_form_screen.dart';

const appVersion = '0.3.0';

/// O aplikacji: pojazdy, prywatność, jak liczymy, licencje.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = GarageScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final selected = store.current?.vehicle.id;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('O aplikacji')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          // Nagłówek z logo
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [brandSeed, brandDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.local_gas_station_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('FuellYo!',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                      Text('Wersja $appVersion · działa offline',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Pojazdy
          const SectionHeader('Twoje pojazdy'),
          for (final v in store.vehicles)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _VehicleCard(vehicle: v, selected: v.id == selected),
            ),
          OutlinedButton.icon(
            onPressed: () => openVehicleForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Dodaj pojazd'),
          ),

          // Prywatność
          const SectionHeader('Prywatność'),
          const _InfoCard(
            icon: Icons.lock_outline_rounded,
            title: 'Twoje dane zostają na tym telefonie',
            text: 'Bez kont, bez chmury, bez analityki i reklam. Nikt poza Tobą nie widzi '
                'Twoich tankowań, napraw ani przebiegów.',
          ),

          // Jak to działa
          const SectionHeader('Jak liczymy'),
          const _InfoCard(
            icon: Icons.local_gas_station_outlined,
            title: 'Prognoza tankowania',
            text: 'Spalanie liczymy z tankowań „do pełna”. Na tej podstawie i średniego dziennego '
                'przebiegu szacujemy, kiedy w baku zostanie rezerwa (15%).',
          ),
          const SizedBox(height: 10),
          const _InfoCard(
            icon: Icons.fact_check_outlined,
            title: 'Przeglądy i wymiany',
            text: 'Każda pozycja ma interwał w kilometrach i/lub miesiącach – liczy się to, '
                'co nastąpi pierwsze. „Wkrótce” oznacza mniej niż 30 dni lub 1000 km.',
          ),

          // Dane
          const SectionHeader('Dane'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.file_download_outlined),
                  title: Text('Kopia zapasowa do pliku'),
                  subtitle: Text('Wkrótce'),
                  enabled: false,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Licencje open source'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'FuellYo!',
                    applicationVersion: appVersion,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('Zrobione z myślą o kierowcach i małych flotach',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBadge(icon, background: scheme.primaryContainer, foreground: scheme.onPrimaryContainer),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(text, style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle, required this.selected});

  final Vehicle vehicle;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final store = GarageScope.read(context);
    final details = [
      fuelTypeLabel(vehicle.fuelType),
      'bak ${Fmt.liters(vehicle.tankCapacityLiters)}',
      if (vehicle.isCompanyCar) 'firmowe',
    ].join(' · ');

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: selected ? BorderSide(color: scheme.primary, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => store.selectVehicle(vehicle.id),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
          child: Row(
            children: [
              IconBadge(
                vehicle.isCompanyCar ? Icons.local_shipping_outlined : Icons.directions_car_filled_outlined,
                background: selected ? scheme.primary : scheme.primaryContainer,
                foreground: selected ? scheme.onPrimary : scheme.onPrimaryContainer,
                size: 52,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                    if (vehicle.plateNumber != null)
                      Text(vehicle.plateNumber!, style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1)),
                    const SizedBox(height: 2),
                    Text(details,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (action) async {
                  if (action == 'edit') {
                    openVehicleForm(context, vehicle: vehicle);
                  } else if (action == 'delete') {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Usunąć pojazd?'),
                        content: Text('Usuniemy „${vehicle.name}” razem z tankowaniami, naprawami i przeglądami.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Anuluj')),
                          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Usuń')),
                        ],
                      ),
                    );
                    if (ok == true) await store.deleteVehicle(vehicle.id);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edytuj')),
                  PopupMenuItem(value: 'delete', child: Text('Usuń')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
