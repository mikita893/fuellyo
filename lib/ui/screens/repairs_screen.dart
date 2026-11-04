import 'package:flutter/material.dart';

import '../../app/garage_store.dart';
import '../../domain/domain.dart';
import '../format.dart';
import '../sheets/repair_sheet.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Historia napraw i serwisów: co, kiedy, gdzie, za ile.
class RepairsScreen extends StatefulWidget {
  const RepairsScreen({super.key});

  @override
  State<RepairsScreen> createState() => _RepairsScreenState();
}

class _RepairsScreenState extends State<RepairsScreen> {
  RepairCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final snap = GarageScope.of(context).current!;
    final all = snap.repairs;
    final filtered = _filter == null ? all : all.where((r) => r.category == _filter).toList();
    final months = RepairStats.byMonth(filtered);
    final yearCost = snap.yearCosts.repairs;
    final usedCategories = RepairCategory.values.where((c) => all.any((r) => r.category == c)).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Naprawy')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => showRepairSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Naprawa'),
      ),
      body: all.isEmpty
          ? Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  icon: Icons.handyman_rounded,
                  title: 'Brak napraw',
                  message: 'Zapisuj naprawy i serwisy: co, kiedy, gdzie i za ile. '
                      'Przyda się przy sprzedaży auta i kontroli kosztów.',
                  actionLabel: 'Dodaj naprawę',
                  onAction: () => showRepairSheet(context),
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
                        icon: Icons.payments_outlined,
                        label: 'Koszt w ${snap.now.year}',
                        value: Fmt.money(yearCost),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        icon: Icons.receipt_long_outlined,
                        label: 'Wszystkie wpisy',
                        value: '${all.length}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Wszystkie'),
                        selected: _filter == null,
                        onSelected: (_) => setState(() => _filter = null),
                      ),
                      for (final c in usedCategories) ...[
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(repairCategoryLabel(c)),
                          selected: _filter == c,
                          onSelected: (_) => setState(() => _filter = c),
                        ),
                      ],
                    ],
                  ),
                ),
                for (final m in months) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(Fmt.month(m.year, m.month),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        ),
                        if (m.cost > 0)
                          Text(Fmt.money(m.cost),
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  for (final r in m.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RepairTile(repair: r, now: snap.now),
                    ),
                ],
              ],
            ),
    );
  }
}

class RepairTile extends StatelessWidget {
  const RepairTile({super.key, required this.repair, required this.now});

  final RepairEntry repair;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final details = [
      Fmt.date(repair.date, now: now),
      if (repair.odometerKm != null) Fmt.km(repair.odometerKm!),
    ].join(' · ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showRepairSheet(context, repair: repair),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(
                repairCategoryIcon(repair.category),
                background: scheme.tertiaryContainer,
                foreground: scheme.onTertiaryContainer,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(repair.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(details, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                    if (repair.place != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(Icons.place_outlined, size: 14, color: scheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(repair.place!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(repair.cost == null ? '–' : Fmt.money(repair.cost!),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(repairCategoryLabel(repair.category),
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
