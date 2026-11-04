import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/garage_store.dart';
import '../../domain/domain.dart';
import '../format.dart';
import '../sheets/fuel_entry_sheet.dart';
import '../sheets/odometer_sheet.dart';
import '../sheets/repair_sheet.dart';
import '../sheets/task_sheet.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/vehicle_picker.dart';

/// Zakładka startowa: co się kończy, co nadchodzi, ostatnie wpisy i koszty.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenTab});

  /// Przełącza zakładkę (1 – tankowania, 2 – naprawy, 3 – przeglądy).
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final snap = GarageScope.of(context).current!;
    final scheme = Theme.of(context).colorScheme;
    final ending = snap.attention;
    final upcoming = snap.upcoming.take(5).toList();
    final costs = snap.yearCosts;
    final lastFuel = snap.fuelEntries.firstOrNull;
    final lastRepair = snap.repairs.firstOrNull;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(Fmt.weekdayDate(snap.now), style: TextStyle(color: scheme.onSurfaceVariant)),
          ),
          const SizedBox(height: 4),
          const VehicleHeader(),
          const SizedBox(height: 16),
          _FuelHeroCard(snap: snap),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.local_gas_station_rounded,
                  label: 'Tankowanie',
                  onTap: () => showFuelEntrySheet(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.handyman_rounded,
                  label: 'Naprawa',
                  onTap: () => showRepairSheet(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.speed_rounded,
                  label: 'Licznik',
                  onTap: () => showOdometerSheet(context),
                ),
              ),
            ],
          ),

          // --- Co się kończy ---
          SectionHeader('Kończy się', actionLabel: 'Przeglądy', onAction: () => onOpenTab(3)),
          if (ending.isEmpty)
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: IconBadge(
                  Icons.verified_rounded,
                  background: StatusColors.of(context, ReminderStatus.ok).background,
                  foreground: StatusColors.of(context, ReminderStatus.ok).foreground,
                ),
                title: const Text('Nic się nie kończy', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Przeglądy, OC i wymiany są aktualne.'),
              ),
            )
          else
            for (final r in ending.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _EndingTile(reminder: r, now: snap.now),
              ),

          // --- Co nadchodzi ---
          const SectionHeader('Nadchodzi'),
          Card(
            child: upcoming.isEmpty
                ? const ListTile(
                    leading: Icon(Icons.event_available_outlined),
                    title: Text('Brak zaplanowanych wydarzeń'),
                    subtitle: Text('Dodaj tankowania i plan przeglądów, a pokażemy, co Cię czeka.'),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        for (var i = 0; i < upcoming.length; i++) ...[
                          if (i > 0) const Divider(height: 1, indent: 76),
                          _UpcomingRow(event: upcoming[i], now: snap.now),
                        ],
                      ],
                    ),
                  ),
          ),

          // --- Ostatnio ---
          if (lastFuel != null || lastRepair != null) ...[
            const SectionHeader('Ostatnio'),
            if (lastFuel != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RecentTile(
                  icon: Icons.local_gas_station_rounded,
                  title: '${Fmt.liters(lastFuel.liters)}'
                      '${lastFuel.totalCost == null ? '' : ' · ${Fmt.money(lastFuel.totalCost!)}'}',
                  subtitle: [Fmt.date(lastFuel.date, now: snap.now), lastFuel.station]
                      .whereType<String>()
                      .join(' · '),
                  onTap: () => onOpenTab(1),
                ),
              ),
            if (lastRepair != null)
              _RecentTile(
                icon: repairCategoryIcon(lastRepair.category),
                title: lastRepair.title,
                subtitle: [
                  Fmt.date(lastRepair.date, now: snap.now),
                  lastRepair.place,
                  if (lastRepair.cost != null) Fmt.money(lastRepair.cost!),
                ].whereType<String>().join(' · '),
                onTap: () => onOpenTab(2),
              ),
          ],

          // --- Koszty ---
          SectionHeader('Koszty w ${snap.now.year}'),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  icon: Icons.local_gas_station_outlined,
                  label: 'Paliwo',
                  value: Fmt.money(costs.fuel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  icon: Icons.handyman_outlined,
                  label: 'Naprawy i serwis',
                  value: Fmt.money(costs.repairs),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FuelHeroCard extends StatelessWidget {
  const _FuelHeroCard({required this.snap});

  final VehicleSnapshot snap;

  @override
  Widget build(BuildContext context) {
    final p = snap.prediction;
    const onHero = Colors.white;
    final muted = Colors.white.withValues(alpha: 0.75);

    final String headline;
    final String detail;
    if (p == null) {
      headline = 'Brak prognozy';
      detail = 'Dodaj dwa tankowania do pełna, a przewidzę następne.';
    } else {
      final days = daysBetween(snap.now, p.predictedRefuelDate);
      headline = days <= 0 ? 'Zatankuj dziś' : 'Zatankuj ${Fmt.relativeDays(days)}';
      detail = '${Fmt.date(p.predictedRefuelDate, now: snap.now)} · zasięg ok. ${Fmt.km(p.estimatedRangeKm)}';
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [brandSeed, brandDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          FuelGauge(
            level: snap.fuelLevel,
            size: 104,
            color: onHero,
            trackColor: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PALIWO',
                    style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                const SizedBox(height: 6),
                Text(headline,
                    style: const TextStyle(color: onHero, fontSize: 22, fontWeight: FontWeight.w800, height: 1.15)),
                const SizedBox(height: 6),
                Text(detail, style: TextStyle(color: muted, fontSize: 13, height: 1.35)),
                if (p != null) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _HeroPill('${Fmt.decimal(p.consumptionLPer100Km)} l/100 km'),
                      if (snap.dailyKm != null) _HeroPill('${Fmt.km(snap.dailyKm!)}/dzień'),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              IconBadge(icon, background: scheme.primaryContainer, foreground: scheme.onPrimaryContainer, size: 40),
              const SizedBox(height: 8),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EndingTile extends StatelessWidget {
  const _EndingTile({required this.reminder, required this.now});

  final MaintenanceReminder reminder;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = StatusColors.of(context, reminder.status);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showTaskSheet(context, reminder),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              IconBadge(maintenanceIcon(reminder.task.kind), background: c.background, foreground: c.foreground),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reminder.task.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(reminderSummary(reminder, now),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(reminder.status),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({required this.event, required this.now});

  final UpcomingEvent event;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isRefuel = event.kind == UpcomingKind.refuel;
    final reminder = event.reminder;
    return InkWell(
      onTap: reminder == null ? null : () => showTaskSheet(context, reminder),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isRefuel ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text('${event.date.day}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.1)),
                  Text(DateFormat('MMM', 'pl').format(event.date),
                      style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                    Fmt.capitalize(Fmt.relativeTo(event.date, now)),
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(
              isRefuel ? Icons.local_gas_station_outlined : maintenanceIcon(reminder!.task.kind),
              color: scheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: IconBadge(icon, background: scheme.secondaryContainer, foreground: scheme.onSecondaryContainer),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
