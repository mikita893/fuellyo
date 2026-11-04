import 'package:flutter/material.dart';

import '../../app/garage_store.dart';
import '../../domain/domain.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'sheet.dart';

Future<void> showAddTaskSheet(BuildContext context) => showAppSheet(context, const AddTaskSheet());

/// Dodawanie zadania: z gotowych szablonów albo własnego.
class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  bool _custom = false;
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _km = TextEditingController();
  final _months = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _km.dispose();
    _months.dispose();
    super.dispose();
  }

  Future<void> _add({
    required MaintenanceKind kind,
    required String name,
    int? intervalKm,
    int? intervalMonths,
  }) async {
    final store = GarageScope.read(context);
    final snap = store.current!;
    await store.saveTask(MaintenanceTask(
      id: store.newId(),
      vehicleId: snap.vehicle.id,
      kind: kind,
      name: name,
      intervalKm: intervalKm,
      intervalMonths: intervalMonths,
      lastDoneDate: dateOnly(store.now),
      lastDoneOdometerKm: snap.odometerKm,
    ));
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Dodano „$name”. Ustaw datę ostatniego wykonania w szczegółach.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final snap = GarageScope.read(context).current!;
    final existing = snap.tasks.map((t) => t.kind).toSet();
    final templates = MaintenanceTemplate.defaults.where((t) => !existing.contains(t.kind)).toList();

    if (_custom) {
      return Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(
              title: 'Własne zadanie',
              leading: IconBadge(Icons.build_outlined,
                  background: scheme.primaryContainer, foreground: scheme.onPrimaryContainer),
            ),
            TextFormField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nazwa', hintText: 'np. Wymiana opon na zimowe'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Podaj nazwę' : null,
            ),
            fieldGap,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _km,
                    keyboardType: TextInputType.number,
                    inputFormatters: digitsOnly,
                    decoration: const InputDecoration(labelText: 'Co ile km', suffixText: 'km'),
                    validator: (_) => (int.tryParse(_km.text) ?? 0) <= 0 && (int.tryParse(_months.text) ?? 0) <= 0
                        ? 'Podaj km lub miesiące'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _months,
                    keyboardType: TextInputType.number,
                    inputFormatters: digitsOnly,
                    decoration: const InputDecoration(labelText: 'Co ile miesięcy', suffixText: 'mies.'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                if (!_form.currentState!.validate()) return;
                final km = int.tryParse(_km.text) ?? 0;
                final months = int.tryParse(_months.text) ?? 0;
                _add(
                  kind: MaintenanceKind.custom,
                  name: _name.text.trim(),
                  intervalKm: km > 0 ? km : null,
                  intervalMonths: months > 0 ? months : null,
                );
              },
              child: const Text('Dodaj zadanie'),
            ),
            TextButton(onPressed: () => setState(() => _custom = false), child: const Text('Wróć')),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader(title: 'Dodaj do planu', subtitle: 'Wybierz z listy lub utwórz własne zadanie'),
        Card(
          color: scheme.primaryContainer,
          child: ListTile(
            leading: Icon(Icons.add_circle_outline, color: scheme.onPrimaryContainer),
            title: Text('Własne zadanie',
                style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer)),
            subtitle: Text('Np. opony, rozrząd, klimatyzacja',
                style: TextStyle(color: scheme.onPrimaryContainer)),
            trailing: Icon(Icons.chevron_right, color: scheme.onPrimaryContainer),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onTap: () => setState(() => _custom = true),
          ),
        ),
        if (templates.isNotEmpty) const SectionHeader('Sugerowane'),
        for (final t in templates)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              child: ListTile(
                leading: Icon(maintenanceIcon(t.kind), color: scheme.primary),
                title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(Fmt.interval(MaintenanceTask(
                  id: '',
                  vehicleId: '',
                  kind: t.kind,
                  name: t.name,
                  intervalKm: t.intervalKm,
                  intervalMonths: t.intervalMonths,
                  lastDoneDate: DateTime(2000),
                  lastDoneOdometerKm: 0,
                ))),
                trailing: const Icon(Icons.add),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onTap: () => _add(
                  kind: t.kind,
                  name: t.name,
                  intervalKm: t.intervalKm,
                  intervalMonths: t.intervalMonths,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
