import 'package:flutter/material.dart';

import '../../app/garage_store.dart';
import '../format.dart';
import '../screens/vehicle_form_screen.dart';
import '../sheets/odometer_sheet.dart';
import '../sheets/sheet.dart';
import '../theme.dart';
import 'common.dart';

/// Nazwa wybranego auta z możliwością przełączenia na inne.
class VehicleHeader extends StatelessWidget {
  const VehicleHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final store = GarageScope.of(context);
    final snap = store.current!;
    final scheme = Theme.of(context).colorScheme;
    final v = snap.vehicle;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => showVehiclePicker(context),
            child: Row(
              children: [
                Flexible(
                  child: Text(v.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 4),
                Icon(Icons.expand_more_rounded, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (v.plateNumber != null) _PlateBadge(v.plateNumber!),
              ActionChip(
                avatar: const Icon(Icons.speed_rounded, size: 18),
                label: Text(Fmt.km(snap.odometerKm)),
                tooltip: 'Zaktualizuj licznik',
                onPressed: () => showOdometerSheet(context),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlateBadge extends StatelessWidget {
  const _PlateBadge(this.plate);

  final String plate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: const Color(0xFF1E4FB4),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
            child: const Text('PL', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(plate, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }
}

Future<void> showVehiclePicker(BuildContext context) => showAppSheet(context, const _VehiclePicker());

class _VehiclePicker extends StatelessWidget {
  const _VehiclePicker();

  @override
  Widget build(BuildContext context) {
    final store = GarageScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final selected = store.current?.vehicle.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader(title: 'Twoje pojazdy'),
        for (final v in store.vehicles)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              color: v.id == selected ? scheme.primaryContainer : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                leading: IconBadge(
                  v.isCompanyCar ? Icons.local_shipping_outlined : Icons.directions_car_filled_outlined,
                  background: scheme.surface,
                  foreground: scheme.primary,
                ),
                title: Text(v.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text([v.plateNumber, fuelTypeLabel(v.fuelType)].whereType<String>().join(' · ')),
                trailing: v.id == selected ? Icon(Icons.check_circle, color: scheme.primary) : null,
                onTap: () async {
                  Navigator.of(context).pop();
                  await store.selectVehicle(v.id);
                },
              ),
            ),
          ),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: () {
            final nav = Navigator.of(context);
            nav.pop();
            nav.push(MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => const VehicleFormScreen()));
          },
          icon: const Icon(Icons.add),
          label: const Text('Dodaj pojazd'),
        ),
      ],
    );
  }
}
