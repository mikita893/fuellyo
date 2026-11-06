import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:fuellyo/data/garage_repository.dart';
import 'package:fuellyo/main.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pl');
  });

  testWidgets('ekran główny pokazuje nazwę aplikacji', (tester) async {
    final repo = await InMemoryGarageRepository.withDemoData(DateTime(2026, 4, 11));
    await tester.pumpWidget(FuellYoApp(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('FuellYo!'), findsOneWidget);
  });
}
