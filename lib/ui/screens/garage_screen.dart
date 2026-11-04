import 'package:flutter/material.dart';

import '../../app/garage_store.dart';
import '../../domain/domain.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'vehicle_form_screen.dart';

class GarageScreen extends StatelessWidget {
  const GarageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = GarageScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final selected = store.current?.vehicle.id;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Garaż')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
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
          const SectionHeader('Prywatność'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconBadge(Icons.lock_outline_rounded,
                      background: scheme.primaryContainer, foreground: scheme.onPrimaryContainer),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Twoje dane zostają na tym telefonie',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                          'FuellYo! działa w pełni offline. Bez kont, bez chmury, bez analityki – '
                          'nikt poza Tobą nie widzi Twoich tankowań ani przebiegów.',
                          style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('Kopia zapasowa'),
                  subtitle: const Text('Eksport do pliku – wkrótce'),
                  enabled: false,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('FuellYo!'),
                  subtitle: Text('Wersja 0.2.0'),
                ),
              ],
            ),
          ),
        ],
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
                        content: Text('Usuniemy „${vehicle.name}” razem z historią tankowań i serwisu.'),
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
