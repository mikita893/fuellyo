import 'package:flutter/material.dart';

import '../../app/garage_store.dart';
import '../format.dart';
import '../widgets/common.dart';
import 'sheet.dart';

Future<void> showOdometerSheet(BuildContext context) => showAppSheet(context, const OdometerSheet());

class OdometerSheet extends StatefulWidget {
  const OdometerSheet({super.key});

  @override
  State<OdometerSheet> createState() => _OdometerSheetState();
}

class _OdometerSheetState extends State<OdometerSheet> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _km =
      TextEditingController(text: GarageScope.read(context).current?.odometerKm.toString() ?? '');

  @override
  void dispose() {
    _km.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    await GarageScope.read(context).updateOdometer(int.parse(_km.text));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final snap = GarageScope.read(context).current;
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(
            title: 'Stan licznika',
            subtitle: snap == null ? null : 'Szacujemy ok. ${Fmt.km(snap.odometerKm)}',
            leading: IconBadge(Icons.speed_rounded,
                background: scheme.secondaryContainer, foreground: scheme.onSecondaryContainer),
          ),
          TextFormField(
            controller: _km,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: digitsOnly,
            decoration: const InputDecoration(labelText: 'Aktualny przebieg', suffixText: 'km'),
            validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Podaj przebieg' : null,
          ),
          const SizedBox(height: 8),
          Text(
            'Dokładny przebieg poprawia terminy przypomnień i prognozę tankowania.',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _save, child: const Text('Zapisz')),
        ],
      ),
    );
  }
}
