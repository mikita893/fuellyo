import 'package:flutter/material.dart';

import '../../app/garage_store.dart';
import '../../domain/domain.dart';
import '../format.dart';
import '../sheets/add_task_sheet.dart';
import '../sheets/task_sheet.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'dashboard_screen.dart';

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  bool _onlyAttention = false;

  @override
  Widget build(BuildContext context) {
    final snap = GarageScope.of(context).current!;
    final all = snap.reminders;
    final list = _onlyAttention ? snap.attention : all;
    final overdue = all.where((r) => r.status == ReminderStatus.overdue).length;
    final soon = all.where((r) => r.status == ReminderStatus.dueSoon).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Serwis')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => showAddTaskSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Zadanie'),
      ),
      body: all.isEmpty
          ? Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  icon: Icons.build_rounded,
                  title: 'Brak planu serwisowego',
                  message: 'Dodaj czynności, o których mamy pamiętać: olej, filtry, przegląd, ubezpieczenie…',
                  actionLabel: 'Dodaj zadanie',
                  onAction: () => showAddTaskSheet(context),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              children: [
                _SummaryCard(overdue: overdue, soon: soon, ok: all.length - overdue - soon),
                const SizedBox(height: 16),
                SegmentedButton<bool>(
                  segments: [
                    const ButtonSegment(value: false, label: Text('Wszystkie')),
                    ButtonSegment(value: true, label: Text('Pilne (${overdue + soon})')),
                  ],
                  selected: {_onlyAttention},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _onlyAttention = s.first),
                ),
                const SizedBox(height: 12),
                if (list.isEmpty)
                  const EmptyState(
                    icon: Icons.verified_rounded,
                    title: 'Nic pilnego',
                    message: 'Wszystkie czynności są aktualne. Damy znać, gdy coś się zbliży.',
                  ),
                for (final r in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ReminderCard(reminder: r, now: snap.now),
                  ),
              ],
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.overdue, required this.soon, required this.ok});

  final int overdue;
  final int soon;
  final int ok;

  @override
  Widget build(BuildContext context) {
    Widget cell(ReminderStatus s, int n, String label) {
      final c = StatusColors.of(context, s);
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: c.background, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Text('$n', style: TextStyle(color: c.foreground, fontSize: 24, fontWeight: FontWeight.w800)),
              Text(label, style: TextStyle(color: c.foreground, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        cell(ReminderStatus.overdue, overdue, 'po terminie'),
        const SizedBox(width: 8),
        cell(ReminderStatus.dueSoon, soon, 'wkrótce'),
        const SizedBox(width: 8),
        cell(ReminderStatus.ok, ok, 'aktualne'),
      ],
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.reminder, required this.now});

  final MaintenanceReminder reminder;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = StatusColors.of(context, reminder.status);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showTaskSheet(context, reminder),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text(Fmt.interval(reminder.task),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(reminder.status),
                ],
              ),
              const SizedBox(height: 14),
              TaskProgressBar(reminder),
              const SizedBox(height: 8),
              Text(reminderSummary(reminder, now),
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
