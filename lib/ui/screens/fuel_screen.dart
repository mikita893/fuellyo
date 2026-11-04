import 'package:flutter/material.dart';

import '../../app/garage_store.dart';
import '../../domain/domain.dart';
import '../format.dart';
import '../sheets/fuel_entry_sheet.dart';
import '../widgets/common.dart';

class FuelScreen extends StatelessWidget {
  const FuelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = GarageScope.of(context);
    final snap = store.current!;
    final months = FuelStats.byMonth(snap.fuelEntries);
    final distances = FuelStats.distanceSincePrevious(snap.fuelEntries);
    final totalCost = snap.fuelEntries.fold(0.0, (s, e) => s + (e.totalCost ?? 0));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Tankowania')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => showFuelEntrySheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Tankowanie'),
      ),
      body: snap.fuelEntries.isEmpty
          ? Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  icon: Icons.local_gas_station_rounded,
                  title: 'Brak tankowań',
                  message: 'Zapisuj tankowania, a FuellYo! policzy spalanie, koszty i podpowie, kiedy znowu zatankować.',
                  actionLabel: 'Dodaj pierwsze tankowanie',
                  onAction: () => showFuelEntrySheet(context),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        icon: Icons.eco_outlined,
                        label: 'Średnie spalanie',
                        value: snap.consumption == null ? '–' : '${Fmt.decimal(snap.consumption!)} l/100',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        icon: Icons.payments_outlined,
                        label: 'Łącznie (${snap.fuelEntries.length})',
                        value: Fmt.money(totalCost),
                      ),
                    ),
                  ],
                ),
                for (final m in months) ...[
                  _MonthHeader(summary: m),
                  for (final e in m.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _FuelEntryTile(entry: e, distance: distances[e], now: snap.now),
                    ),
                ],
              ],
            ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.summary});

  final MonthlyFuelSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(Fmt.month(summary.year, summary.month),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ),
          Text(
            summary.cost > 0 ? Fmt.money(summary.cost) : Fmt.liters(summary.liters),
            style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _FuelEntryTile extends StatelessWidget {
  const _FuelEntryTile({required this.entry, required this.distance, required this.now});

  final FuelEntry entry;
  final int? distance;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final store = GarageScope.read(context);
    final cost = entry.totalCost;

    return Dismissible(
      key: ObjectKey(entry),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(20)),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      onDismissed: (_) async {
        final messenger = ScaffoldMessenger.of(context);
        await store.deleteFuelEntry(entry);
        messenger.showSnackBar(SnackBar(
          content: const Text('Usunięto tankowanie'),
          action: SnackBarAction(label: 'Cofnij', onPressed: () => store.addFuelEntry(entry)),
        ));
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              IconBadge(
                entry.isFullTank ? Icons.local_gas_station_rounded : Icons.water_drop_outlined,
                background: entry.isFullTank ? scheme.primaryContainer : scheme.secondaryContainer,
                foreground: entry.isFullTank ? scheme.onPrimaryContainer : scheme.onSecondaryContainer,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${Fmt.liters(entry.liters)}${entry.isFullTank ? '' : ' · dolewka'}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        Fmt.date(entry.date, now: now),
                        Fmt.km(entry.odometerKm),
                        if (distance != null) '+${Fmt.number(distance!)}',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(cost == null ? '–' : Fmt.money(cost), style: const TextStyle(fontWeight: FontWeight.w800)),
                  if (entry.pricePerLiter != null)
                    Text('${Fmt.decimal(entry.pricePerLiter!, 2)} zł/l',
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
