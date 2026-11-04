import 'package:flutter/material.dart';

import '../../app/garage_store.dart';
import '../../domain/domain.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'sheet.dart';

/// Nowa naprawa albo edycja istniejącej ([repair]).
Future<void> showRepairSheet(BuildContext context, {RepairEntry? repair}) =>
    showAppSheet(context, RepairSheet(repair: repair));

class RepairSheet extends StatefulWidget {
  const RepairSheet({super.key, this.repair});

  final RepairEntry? repair;

  @override
  State<RepairSheet> createState() => _RepairSheetState();
}

class _RepairSheetState extends State<RepairSheet> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _odometer = TextEditingController();
  final _place = TextEditingController();
  final _cost = TextEditingController();
  final _note = TextEditingController();
  late DateTime _date;
  RepairCategory _category = RepairCategory.repair;
  String? _taskId;
  bool _initialized = false;

  bool get _isEdit => widget.repair != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final store = GarageScope.read(context);
    final r = widget.repair;
    if (r != null) {
      _title.text = r.title;
      _date = r.date;
      _odometer.text = r.odometerKm?.toString() ?? '';
      _place.text = r.place ?? '';
      _cost.text = r.cost == null ? '' : Fmt.decimal(r.cost!, 2);
      _note.text = r.note ?? '';
      _category = r.category;
      _taskId = r.taskId;
    } else {
      _date = dateOnly(store.now);
      _odometer.text = store.current?.odometerKm.toString() ?? '';
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _odometer, _place, _cost, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  void _linkTask(MaintenanceTask? task) {
    setState(() {
      _taskId = task?.id;
      if (task != null) {
        if (_title.text.trim().isEmpty) _title.text = task.name;
        _category = task.kind == MaintenanceKind.inspection || task.kind == MaintenanceKind.insurance
            ? RepairCategory.inspection
            : RepairCategory.service;
      }
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final store = GarageScope.read(context);
    final place = _place.text.trim();
    final note = _note.text.trim();
    final repair = RepairEntry(
      id: widget.repair?.id ?? store.newId(),
      vehicleId: store.current!.vehicle.id,
      title: _title.text.trim(),
      category: _category,
      date: _date,
      odometerKm: int.tryParse(_odometer.text),
      place: place.isEmpty ? null : place,
      cost: Fmt.parseDecimal(_cost.text),
      note: note.isEmpty ? null : note,
      taskId: _taskId,
    );
    await store.saveRepair(repair);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEdit ? 'Zmiany zapisane' : 'Naprawa zapisana')),
    );
  }

  Future<void> _delete() async {
    await GarageScope.read(context).deleteRepair(widget.repair!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = GarageScope.read(context);
    final snap = store.current!;
    final scheme = Theme.of(context).colorScheme;
    final places = RepairStats.recentPlaces(snap.repairs).where((p) => p != _place.text.trim()).toList();

    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(
            title: _isEdit ? 'Edytuj naprawę' : 'Nowa naprawa',
            subtitle: snap.vehicle.name,
            leading: IconBadge(Icons.handyman_rounded,
                background: scheme.tertiaryContainer, foreground: scheme.onTertiaryContainer),
          ),

          // Co
          TextFormField(
            controller: _title,
            autofocus: !_isEdit,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Co zrobiono',
              hintText: 'np. Wymiana klocków hamulcowych',
              prefixIcon: Icon(Icons.build_outlined),
            ),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Opisz, co zostało zrobione' : null,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in RepairCategory.values)
                ChoiceChip(
                  avatar: Icon(repairCategoryIcon(c), size: 18),
                  label: Text(repairCategoryLabel(c)),
                  selected: _category == c,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _category = c),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Kiedy
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: DateField(
                  label: 'Kiedy',
                  value: _date,
                  lastDate: store.now,
                  onChanged: (d) => setState(() => _date = d),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: TextFormField(
                  controller: _odometer,
                  keyboardType: TextInputType.number,
                  inputFormatters: digitsOnly,
                  decoration: const InputDecoration(labelText: 'Przebieg', suffixText: 'km'),
                ),
              ),
            ],
          ),
          fieldGap,

          // Gdzie
          TextFormField(
            controller: _place,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Gdzie (warsztat)',
              hintText: 'np. Auto-Serwis Kowalski',
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          SuggestionChips(values: places, onSelected: (v) => setState(() => _place.text = v)),
          fieldGap,

          // Za ile
          TextFormField(
            controller: _cost,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: decimalOnly,
            decoration: const InputDecoration(
              labelText: 'Koszt',
              suffixText: 'zł',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
          ),
          fieldGap,
          TextFormField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3,
            minLines: 1,
            decoration: const InputDecoration(
              labelText: 'Notatka (opcjonalnie)',
              hintText: 'np. użyte części, gwarancja',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),

          // Powiązanie z planem przeglądów
          if (snap.tasks.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Dotyczy pozycji z przeglądów?',
                style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Wybierz, a przesuniemy termin następnego przypomnienia.',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Nie'),
                  selected: _taskId == null,
                  onSelected: (_) => _linkTask(null),
                ),
                for (final t in snap.tasks)
                  ChoiceChip(
                    avatar: Icon(maintenanceIcon(t.kind), size: 18),
                    label: Text(t.name),
                    selected: _taskId == t.id,
                    showCheckmark: false,
                    onSelected: (_) => _linkTask(t),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: Text(_isEdit ? 'Zapisz zmiany' : 'Zapisz naprawę')),
          if (_isEdit)
            TextButton.icon(
              onPressed: _delete,
              style: TextButton.styleFrom(foregroundColor: scheme.error),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Usuń wpis'),
            ),
        ],
      ),
    );
  }
}
