import 'package:flutter/material.dart';

import '../../app/garage_store.dart';
import '../../domain/domain.dart';
import '../format.dart';
import '../widgets/common.dart';
import 'sheet.dart';

Future<void> showFuelEntrySheet(BuildContext context) =>
    showAppSheet(context, const FuelEntrySheet());

class FuelEntrySheet extends StatefulWidget {
  const FuelEntrySheet({super.key});

  @override
  State<FuelEntrySheet> createState() => _FuelEntrySheetState();
}

class _FuelEntrySheetState extends State<FuelEntrySheet> {
  final _form = GlobalKey<FormState>();
  final _odometer = TextEditingController();
  final _liters = TextEditingController();
  final _price = TextEditingController();
  late DateTime _date;
  bool _fullTank = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final store = GarageScope.read(context);
    _date = dateOnly(store.now);
    final snap = store.current;
    if (snap != null) {
      _odometer.text = snap.odometerKm.toString();
      final lastPrice = snap.fuelEntries.where((e) => e.pricePerLiter != null).firstOrNull?.pricePerLiter;
      if (lastPrice != null) _price.text = Fmt.decimal(lastPrice, 2);
    }
    _liters.addListener(_refresh);
    _price.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _odometer.dispose();
    _liters.dispose();
    _price.dispose();
    super.dispose();
  }

  double? get _total {
    final l = Fmt.parseDecimal(_liters.text);
    final p = Fmt.parseDecimal(_price.text);
    return l == null || p == null ? null : l * p;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final store = GarageScope.read(context);
    await store.addFuelEntry(FuelEntry(
      date: _date,
      odometerKm: int.parse(_odometer.text),
      liters: Fmt.parseDecimal(_liters.text)!,
      pricePerLiter: Fmt.parseDecimal(_price.text),
      isFullTank: _fullTank,
    ));
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tankowanie zapisane')));
  }

  @override
  Widget build(BuildContext context) {
    final store = GarageScope.read(context);
    final snap = store.current!;
    final scheme = Theme.of(context).colorScheme;
    final total = _total;

    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(
            title: 'Nowe tankowanie',
            subtitle: snap.vehicle.name,
            leading: IconBadge(Icons.local_gas_station_rounded,
                background: scheme.primaryContainer, foreground: scheme.onPrimaryContainer),
          ),
          DateField(
            label: 'Data',
            value: _date,
            lastDate: store.now,
            onChanged: (d) => setState(() => _date = d),
          ),
          fieldGap,
          TextFormField(
            controller: _liters,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: decimalOnly,
            decoration: const InputDecoration(
              labelText: 'Zatankowano',
              suffixText: 'litrów',
              prefixIcon: Icon(Icons.water_drop_outlined),
            ),
            validator: (v) {
              final l = Fmt.parseDecimal(v ?? '');
              if (l == null || l <= 0) return 'Podaj liczbę litrów';
              if (l > snap.vehicle.tankCapacityLiters * 1.2) {
                return 'Więcej niż pojemność baku (${Fmt.liters(snap.vehicle.tankCapacityLiters)})';
              }
              return null;
            },
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
                  decoration: const InputDecoration(labelText: 'Cena za litr', suffixText: 'zł'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _odometer,
                  keyboardType: TextInputType.number,
                  inputFormatters: digitsOnly,
                  decoration: const InputDecoration(labelText: 'Przebieg', suffixText: 'km'),
                  validator: (v) {
                    final km = int.tryParse(v ?? '');
                    if (km == null || km <= 0) return 'Podaj przebieg';
                    final earlier = snap.fuelEntries.where((e) => !e.date.isAfter(_date));
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
          Card(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: SwitchListTile(
              value: _fullTank,
              onChanged: (v) => setState(() => _fullTank = v),
              title: const Text('Do pełna', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Tankowania do pełna dają najdokładniejszą prognozę'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          const SizedBox(height: 20),
          if (total != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text('Do zapłaty', style: TextStyle(color: scheme.onSurfaceVariant)),
                  const Spacer(),
                  Text(Fmt.money(total),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          FilledButton(onPressed: _save, child: const Text('Zapisz tankowanie')),
        ],
      ),
    );
  }
}
