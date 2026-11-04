import 'package:flutter/material.dart';

import '../../app/garage_store.dart';
import '../../domain/domain.dart';
import '../format.dart';
import '../sheets/fuel_entry_sheet.dart';
import '../sheets/odometer_sheet.dart';
import '../sheets/task_sheet.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/vehicle_picker.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onOpenService});

  final VoidCallback onOpenService;

  @override
  Widget build(BuildContext context) {
    final store = GarageScope.of(context);
    final snap = store.current!;
    final scheme = Theme.of(context).colorScheme;
    final month = FuelStats.forMonth(snap.fuelEntries, snap.now);
    final attention = snap.attention;

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
                  icon: Icons.build_rounded,
                  label: 'Serwis',
                  onTap: onOpenService,
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
          SectionHeader(
            'Wymaga uwagi',
            actionLabel: 'Wszystkie',
            onAction: onOpenService,
          ),
          if (attention.isEmpty)
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: IconBadge(
                  Icons.verified_rounded,
                  background: StatusColors.of(context, ReminderStatus.ok).background,
                  foreground: StatusColors.of(context, ReminderStatus.ok).foreground,
                ),
                title: const Text('Wszystko w porządku', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(_nextTaskText(snap)),
              ),
            )
          else
            for (final r in attention.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AttentionTile(reminder: r, now: snap.now),
              ),
          const SectionHeader('Ten miesiąc'),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  icon: Icons.payments_outlined,
                  label: 'Wydatki na paliwo',
                  value: Fmt.money(month.cost),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  icon: Icons.water_drop_outlined,
                  label: '${month.entries.length} × tankowanie',
                  value: Fmt.liters(month.liters),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  icon: Icons.eco_outlined,
                  label: 'Średnie spalanie',
                  value: snap.consumption == null ? '–' : '${Fmt.decimal(snap.consumption!)} l',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  icon: Icons.route_outlined,
                  label: 'Dziennie średnio',
                  value: snap.dailyKm == null ? '–' : Fmt.km(snap.dailyKm!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _nextTaskText(VehicleSnapshot snap) {
    final next = snap.reminders.where((r) => r.estimatedDueDate != null).firstOrNull;
    if (next == null) return 'Brak zaplanowanych czynności';
    return 'Najbliżej: ${next.task.name.toLowerCase()} ${Fmt.relativeTo(next.estimatedDueDate!, snap.now)}';
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
                Text('NASTĘPNE TANKOWANIE',
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
                      _HeroPill(switch (p.confidence) {
                        PredictionConfidence.high => 'pewna prognoza',
                        PredictionConfidence.medium => 'dobra prognoza',
                        PredictionConfidence.low => 'wstępna prognoza',
                      }),
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

class _AttentionTile extends StatelessWidget {
  const _AttentionTile({required this.reminder, required this.now});

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
                        maxLines: 1,
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

/// Krótki opis terminu zadania, np. „za 520 km · 15 sty”.
String reminderSummary(MaintenanceReminder r, DateTime now) {
  final parts = <String>[];
  if (r.kmLeft != null) {
    parts.add(r.kmLeft! <= 0 ? '${Fmt.km(-r.kmLeft!)} po terminie' : 'za ${Fmt.km(r.kmLeft!)}');
  }
  if (r.nextDueDate != null) {
    final days = daysBetween(now, r.nextDueDate!);
    parts.add(days < 0 ? 'termin minął ${Fmt.date(r.nextDueDate!, now: now)}' : Fmt.relativeDays(days));
  }
  return parts.join(' · ');
}
