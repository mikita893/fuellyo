import 'package:flutter/material.dart';

import '../../app/garage_store.dart';
import '../../domain/domain.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'sheet.dart';

Future<void> showTaskSheet(BuildContext context, MaintenanceReminder reminder) =>
    showAppSheet(context, TaskSheet(reminder: reminder));

enum _Mode { details, done, edit }

/// Szczegóły zadania serwisowego: oznaczanie jako wykonane i edycja interwałów.
class TaskSheet extends StatefulWidget {
  const TaskSheet({super.key, required this.reminder});

  final MaintenanceReminder reminder;

  @override
  State<TaskSheet> createState() => _TaskSheetState();
}

class _TaskSheetState extends State<TaskSheet> {
  _Mode _mode = _Mode.details;
  final _form = GlobalKey<FormState>();
  late DateTime _doneDate;
  late final TextEditingController _doneKm;
  late final TextEditingController _name;
  late final TextEditingController _intervalKm;
  late final TextEditingController _intervalMonths;

  MaintenanceTask get _task => widget.reminder.task;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: _task.name);
    _intervalKm = TextEditingController(text: _task.intervalKm?.toString() ?? '');
    _intervalMonths = TextEditingController(text: _task.intervalMonths?.toString() ?? '');
    _doneKm = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = GarageScope.read(context);
    if (_doneKm.text.isEmpty) {
      _doneDate = dateOnly(store.now);
      _doneKm.text = (store.current?.odometerKm ?? _task.lastDoneOdometerKm).toString();
    }
  }

  @override
  void dispose() {
    _doneKm.dispose();
    _name.dispose();
    _intervalKm.dispose();
    _intervalMonths.dispose();
    super.dispose();
  }

  Future<void> _markDone() async {
    if (!_form.currentState!.validate()) return;
    await GarageScope.read(context)
        .markTaskDone(_task, date: _doneDate, odometerKm: int.parse(_doneKm.text));
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_task.name} – zapisano wykonanie')));
  }

  Future<void> _saveEdit() async {
    if (!_form.currentState!.validate()) return;
    final km = int.tryParse(_intervalKm.text);
    final months = int.tryParse(_intervalMonths.text);
    await GarageScope.read(context).saveTask(MaintenanceTask(
      id: _task.id,
      vehicleId: _task.vehicleId,
      kind: _task.kind,
      name: _name.text.trim(),
      intervalKm: km == 0 ? null : km,
      intervalMonths: months == 0 ? null : months,
      lastDoneDate: _task.lastDoneDate,
      lastDoneOdometerKm: _task.lastDoneOdometerKm,
    ));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć zadanie?'),
        content: Text('„${_task.name}” zniknie z listy przypomnień.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Anuluj')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Usuń')),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    await GarageScope.read(context).deleteTask(_task);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = widget.reminder;
    final c = StatusColors.of(context, r.status);

    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(
            title: _task.name,
            subtitle: Fmt.interval(_task),
            leading: IconBadge(maintenanceIcon(_task.kind), background: c.background, foreground: c.foreground),
          ),
          ...switch (_mode) {
            _Mode.details => _details(context, r, scheme),
            _Mode.done => _doneForm(context),
            _Mode.edit => _editForm(context),
          },
        ],
      ),
    );
  }

  List<Widget> _details(BuildContext context, MaintenanceReminder r, ColorScheme scheme) {
    final now = GarageScope.read(context).now;
    return [
      Card(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(children: [
                StatusChip(r.status),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${(r.progress * 100).round()}% interwału',
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                ),
              ]),
              const SizedBox(height: 12),
              TaskProgressBar(r),
              const SizedBox(height: 16),
              if (r.kmLeft != null)
                _InfoRow(
                  icon: Icons.route_outlined,
                  label: 'Kilometry',
                  value: r.kmLeft! <= 0 ? 'przekroczono o ${Fmt.km(-r.kmLeft!)}' : 'zostało ${Fmt.km(r.kmLeft!)}',
                ),
              if (r.nextDueDate != null)
                _InfoRow(
                  icon: Icons.event_outlined,
                  label: 'Termin',
                  value: '${Fmt.date(r.nextDueDate!, now: now)} (${Fmt.relativeTo(r.nextDueDate!, now)})',
                ),
              if (r.estimatedDueDate != null && r.estimatedDueDate != r.nextDueDate)
                _InfoRow(
                  icon: Icons.insights_outlined,
                  label: 'Szacunkowo',
                  value: Fmt.date(r.estimatedDueDate!, now: now),
                ),
              _InfoRow(
                icon: Icons.history,
                label: 'Ostatnio',
                value: '${Fmt.date(_task.lastDoneDate, now: now)} · ${Fmt.km(_task.lastDoneOdometerKm)}',
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: () => setState(() => _mode = _Mode.done),
        icon: const Icon(Icons.check_rounded),
        label: const Text('Oznacz jako wykonane'),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: () => setState(() => _mode = _Mode.edit),
        icon: const Icon(Icons.tune_rounded),
        label: const Text('Zmień interwał'),
      ),
      TextButton.icon(
        onPressed: _delete,
        style: TextButton.styleFrom(foregroundColor: scheme.error),
        icon: const Icon(Icons.delete_outline),
        label: const Text('Usuń zadanie'),
      ),
    ];
  }

  List<Widget> _doneForm(BuildContext context) => [
        DateField(
          label: 'Kiedy wykonano',
          value: _doneDate,
          lastDate: GarageScope.read(context).now,
          onChanged: (d) => setState(() => _doneDate = d),
        ),
        fieldGap,
        TextFormField(
          controller: _doneKm,
          keyboardType: TextInputType.number,
          inputFormatters: digitsOnly,
          decoration: const InputDecoration(
            labelText: 'Przebieg w dniu wykonania',
            suffixText: 'km',
            prefixIcon: Icon(Icons.speed_rounded),
          ),
          validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Podaj przebieg' : null,
        ),
        const SizedBox(height: 20),
        FilledButton(onPressed: _markDone, child: const Text('Zapisz wykonanie')),
        TextButton(onPressed: () => setState(() => _mode = _Mode.details), child: const Text('Wróć')),
      ];

  List<Widget> _editForm(BuildContext context) => [
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Nazwa'),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Podaj nazwę' : null,
        ),
        fieldGap,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _intervalKm,
                keyboardType: TextInputType.number,
                inputFormatters: digitsOnly,
                decoration: const InputDecoration(labelText: 'Co ile km', suffixText: 'km'),
                validator: (_) => _intervalValidator(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _intervalMonths,
                keyboardType: TextInputType.number,
                inputFormatters: digitsOnly,
                decoration: const InputDecoration(labelText: 'Co ile miesięcy', suffixText: 'mies.'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Zostaw jedno pole puste, jeśli liczy się tylko czas albo tylko kilometry.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
        const SizedBox(height: 20),
        FilledButton(onPressed: _saveEdit, child: const Text('Zapisz zmiany')),
        TextButton(onPressed: () => setState(() => _mode = _Mode.details), child: const Text('Wróć')),
      ];

  String? _intervalValidator() {
    final km = int.tryParse(_intervalKm.text) ?? 0;
    final months = int.tryParse(_intervalMonths.text) ?? 0;
    return km <= 0 && months <= 0 ? 'Podaj km lub miesiące' : null;
  }
}

/// Pasek postępu zadania – używany też na liście serwisu.
class TaskProgressBar extends StatelessWidget {
  const TaskProgressBar(this.reminder, {super.key});

  final MaintenanceReminder reminder;

  @override
  Widget build(BuildContext context) {
    final c = StatusColors.of(context, reminder.status);
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: reminder.progress,
        minHeight: 8,
        color: c.foreground,
        backgroundColor: c.background,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
