import 'package:flutter/material.dart';

import '../../app/garage_store.dart';
import '../../domain/domain.dart';
import '../format.dart';
import '../sheets/sheet.dart';
import '../theme.dart';

Future<void> openVehicleForm(BuildContext context, {Vehicle? vehicle}) =>
    Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => VehicleFormScreen(vehicle: vehicle),
    ));

/// Dodawanie lub edycja pojazdu.
class VehicleFormScreen extends StatefulWidget {
  const VehicleFormScreen({super.key, this.vehicle});

  final Vehicle? vehicle;

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.vehicle?.name ?? '');
  late final _plate = TextEditingController(text: widget.vehicle?.plateNumber ?? '');
  late final _tank = TextEditingController(
      text: widget.vehicle == null ? '' : Fmt.decimal(widget.vehicle!.tankCapacityLiters, 0));
  late final _consumption = TextEditingController(
      text: widget.vehicle?.declaredConsumptionLPer100Km == null
          ? ''
          : Fmt.decimal(widget.vehicle!.declaredConsumptionLPer100Km!));
  final _odometer = TextEditingController();
  late FuelType _fuel = widget.vehicle?.fuelType ?? FuelType.petrol;
  late bool _company = widget.vehicle?.isCompanyCar ?? false;
  bool _defaultPlan = true;

  bool get _isEdit => widget.vehicle != null;

  @override
  void dispose() {
    for (final c in [_name, _plate, _tank, _consumption, _odometer]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final store = GarageScope.read(context);
    final plate = _plate.text.trim().toUpperCase();
    final vehicle = Vehicle(
      id: widget.vehicle?.id ?? store.newId(),
      name: _name.text.trim(),
      plateNumber: plate.isEmpty ? null : plate,
      fuelType: _fuel,
      tankCapacityLiters: Fmt.parseDecimal(_tank.text)!,
      declaredConsumptionLPer100Km: Fmt.parseDecimal(_consumption.text),
      isCompanyCar: _company,
    );
    if (_isEdit) {
      await store.updateVehicle(vehicle);
    } else {
      await store.addVehicle(vehicle, odometerKm: int.parse(_odometer.text), withDefaultPlan: _defaultPlan);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edytuj pojazd' : 'Nowy pojazd'),
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nazwa',
                hintText: 'np. Skoda Octavia',
                prefixIcon: Icon(Icons.directions_car_outlined),
              ),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Podaj nazwę' : null,
            ),
            fieldGap,
            TextFormField(
              controller: _plate,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Numer rejestracyjny (opcjonalnie)',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 20),
            Text('Rodzaj paliwa', style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in FuelType.values.where((f) => f != FuelType.electric))
                  ChoiceChip(
                    label: Text(fuelTypeLabel(f)),
                    selected: _fuel == f,
                    onSelected: (_) => setState(() => _fuel = f),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tank,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: decimalOnly,
                    decoration: const InputDecoration(labelText: 'Bak', suffixText: 'l'),
                    validator: (v) => (Fmt.parseDecimal(v ?? '') ?? 0) <= 0 ? 'Podaj pojemność' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _consumption,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: decimalOnly,
                    decoration: const InputDecoration(labelText: 'Spalanie', suffixText: 'l/100'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Spalanie katalogowe pomaga, dopóki nie zbierzemy historii tankowań.',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
            if (!_isEdit) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _odometer,
                keyboardType: TextInputType.number,
                inputFormatters: digitsOnly,
                decoration: const InputDecoration(
                  labelText: 'Aktualny przebieg',
                  suffixText: 'km',
                  prefixIcon: Icon(Icons.speed_rounded),
                ),
                validator: (v) => int.tryParse(v ?? '') == null ? 'Podaj przebieg' : null,
              ),
            ],
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    value: _company,
                    onChanged: (v) => setState(() => _company = v),
                    secondary: const Icon(Icons.business_center_outlined),
                    title: const Text('Auto firmowe'),
                  ),
                  if (!_isEdit)
                    SwitchListTile(
                      value: _defaultPlan,
                      onChanged: (v) => setState(() => _defaultPlan = v),
                      secondary: const Icon(Icons.checklist_rounded),
                      title: const Text('Standardowy plan serwisowy'),
                      subtitle: const Text('Olej, filtry, płyn hamulcowy, przegląd, OC'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: Text(_isEdit ? 'Zapisz zmiany' : 'Dodaj pojazd')),
          ],
        ),
      ),
    );
  }
}
