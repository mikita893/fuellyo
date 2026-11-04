import 'package:flutter/material.dart';

import '../../app/garage_store.dart';
import '../../domain/domain.dart';
import '../format.dart';
import '../widgets/common.dart';
import 'sheet.dart';

/// Nowe tankowanie albo edycja istniejącego ([entry]).
Future<void> showFuelEntrySheet(BuildContext context, {FuelEntry? entry}) =>
    showAppSheet(context, FuelEntrySheet(entry: entry));

enum _Amount { liters, price, total }

class FuelEntrySheet extends StatefulWidget {
  const FuelEntrySheet({super.key, this.entry});

  final FuelEntry? entry;

  @override
  State<FuelEntrySheet> createState() => _FuelEntrySheetState();
}

class _FuelEntrySheetState extends State<FuelEntrySheet> {
  final _form = GlobalKey<FormState>();
  final _odometer = TextEditingController();
  final _liters = TextEditingController();
  final _price = TextEditingController();
  final _total = TextEditingController();
  final _station = TextEditingController();
  final _note = TextEditingController();
  late DateTime _date;
  bool _fullTank = true;
  bool _missedPrevious = false;
  bool _initialized = false;

  /// Pola wpisane ręcznie, ostatnie na końcu – trzecie liczymy z dwóch ostatnich.
  final _edited = <_Amount>[];

  bool get _isEdit => widget.entry != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final store = GarageScope.read(context);
    final snap = store.current;
    final e = widget.entry;
    if (e != null) {
      _date = e.date;
      _odometer.text = e.odometerKm.toString();
      _liters.text = Fmt.decimal(e.liters, 2);
      if (e.pricePerLiter != null) {
        _price.text = Fmt.decimal(e.pricePerLiter!, 2);
        _total.text = Fmt.decimal(e.totalCost!, 2);
      }
      _station.text = e.station ?? '';
      _note.text = e.note ?? '';
      _fullTank = e.isFullTank;
      _missedPrevious = e.missedPrevious;
      _edited.addAll([_Amount.liters, _Amount.price]);
    } else {
      _date = dateOnly(store.now);
      if (snap != null) {
        _odometer.text = snap.odometerKm.toString();
        final last = snap.fuelEntries.where((x) => x.pricePerLiter != null).firstOrNull;
        if (last != null) {
          _price.text = Fmt.decimal(last.pricePerLiter!, 2);
          _edited.add(_Amount.price);
        }
      }
    }
  }

  @override
  void dispose() {
    for (final c in [_odometer, _liters, _price, _total, _station, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controller(_Amount a) => switch (a) {
        _Amount.liters => _liters,
        _Amount.price => _price,
        _Amount.total => _total,
      };

  /// Użytkownik zmienił jedno z pól kwot – przelicz trzecie.
  void _onAmountChanged(_Amount field) {
    _edited
      ..remove(field)
      ..add(field);
    if (_edited.length > 2) _edited.removeAt(0);
    if (_edited.length == 2) {
      final missing = _Amount.values.firstWhere((a) => !_edited.contains(a));
      final result = FuelStats.completeAmounts(
        liters: missing == _Amount.liters ? null : Fmt.parseDecimal(_liters.text),
        price: missing == _Amount.price ? null : Fmt.parseDecimal(_price.text),
        total: missing == _Amount.total ? null : Fmt.parseDecimal(_total.text),
      );
      if (result != null) {
        final value = switch (missing) {
          _Amount.liters => result.liters,
          _Amount.price => result.price,
          _Amount.total => result.total,
        };
        _controller(missing).text = Fmt.decimal(value, 2);
      }
    }
    setState(() {});
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final store = GarageScope.read(context);
    final amounts = FuelStats.completeAmounts(
      liters: Fmt.parseDecimal(_liters.text),
      price: Fmt.parseDecimal(_price.text),
      total: Fmt.parseDecimal(_total.text),
    );
    final liters = amounts?.liters ?? Fmt.parseDecimal(_liters.text)!;
    final station = _station.text.trim();
    final note = _note.text.trim();
    final entry = FuelEntry(
      date: _date,
      odometerKm: int.parse(_odometer.text),
      liters: liters,
      pricePerLiter: amounts?.price,
      isFullTank: _fullTank,
      missedPrevious: _missedPrevious,
      station: station.isEmpty ? null : station,
      note: note.isEmpty ? null : note,
    );
    if (_isEdit) {
      await store.updateFuelEntry(widget.entry!, entry);
    } else {
      await store.addFuelEntry(entry);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEdit ? 'Zmiany zapisane' : 'Tankowanie zapisane')),
    );
  }

  Future<void> _delete() async {
    final store = GarageScope.read(context);
    await store.deleteFuelEntry(widget.entry!);
    if (mounted) Navigator.of(context).pop();
  }

  String? _litersValidator(Vehicle vehicle) {
    final l = Fmt.parseDecimal(_liters.text) ??
        FuelStats.completeAmounts(
          price: Fmt.parseDecimal(_price.text),
          total: Fmt.parseDecimal(_total.text),
        )?.liters;
    if (l == null || l <= 0) return 'Podaj litry albo kwotę i cenę';
    if (l > vehicle.tankCapacityLiters * 1.2) {
      return 'Więcej niż bak (${Fmt.liters(vehicle.tankCapacityLiters)})';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final store = GarageScope.read(context);
    final snap = store.current!;
    final scheme = Theme.of(context).colorScheme;
    final others = snap.fuelEntries.where((e) => !identical(e, widget.entry)).toList();
    final stations = FuelStats.recentStations(snap.fuelEntries)
        .where((s) => s != _station.text.trim())
        .toList();

    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(
            title: _isEdit ? 'Edytuj tankowanie' : 'Nowe tankowanie',
            subtitle: snap.vehicle.name,
            leading: IconBadge(Icons.local_gas_station_rounded,
                background: scheme.primaryContainer, foreground: scheme.onPrimaryContainer),
          ),

          // Kiedy i przebieg
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
                  validator: (v) {
                    final km = int.tryParse(v ?? '');
                    if (km == null || km <= 0) return 'Podaj przebieg';
                    final earlier = others.where((e) => !e.date.isAfter(_date));
                    final maxKm = earlier.isEmpty
                        ? 0
                        : earlier.map((e) => e.odometerKm).reduce((a, b) => a > b ? a : b);
                    if (km < maxKm) return 'Mniej niż ostatnio';
                    return null;
                  },
                ),
              ),
            ],
          ),
          fieldGap,

          // Ile i za ile – dowolne dwa pola wyliczają trzecie
          TextFormField(
            controller: _liters,
            autofocus: !_isEdit,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: decimalOnly,
            onChanged: (_) => _onAmountChanged(_Amount.liters),
            decoration: const InputDecoration(
              labelText: 'Ilość paliwa',
              suffixText: 'litrów',
              prefixIcon: Icon(Icons.water_drop_outlined),
            ),
            validator: (_) => _litersValidator(snap.vehicle),
          ),
          fieldGap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: decimalOnly,
                  onChanged: (_) => _onAmountChanged(_Amount.price),
                  decoration: const InputDecoration(labelText: 'Cena za litr', suffixText: 'zł'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _total,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: decimalOnly,
                  onChanged: (_) => _onAmountChanged(_Amount.total),
                  decoration: const InputDecoration(labelText: 'Kwota', suffixText: 'zł'),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
            child: Text('Wpisz dowolne dwie wartości – trzecią policzymy sami.',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
          ),
          fieldGap,

          // Gdzie
          TextFormField(
            controller: _station,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Stacja (opcjonalnie)',
              hintText: 'np. Orlen, Puławska',
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          SuggestionChips(
            values: stations,
            onSelected: (v) => setState(() => _station.text = v),
          ),
          const SizedBox(height: 12),

          Card(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Column(
              children: [
                SwitchListTile(
                  value: _fullTank,
                  onChanged: (v) => setState(() => _fullTank = v),
                  title: const Text('Do pełna', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Daje najdokładniejsze spalanie i prognozę'),
                ),
                SwitchListTile(
                  value: _missedPrevious,
                  onChanged: (v) => setState(() => _missedPrevious = v),
                  title: const Text('Pominięte poprzednie tankowanie',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Zaznacz, jeśli nie wpisałeś któregoś tankowania'),
                ),
              ],
            ),
          ),
          fieldGap,
          TextFormField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            minLines: 1,
            decoration: const InputDecoration(
              labelText: 'Notatka (opcjonalnie)',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            child: Text(_isEdit ? 'Zapisz zmiany' : 'Zapisz tankowanie'),
          ),
          if (_isEdit)
            TextButton.icon(
              onPressed: _delete,
              style: TextButton.styleFrom(foregroundColor: scheme.error),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Usuń tankowanie'),
            ),
        ],
      ),
    );
  }
}
