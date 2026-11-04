import 'package:flutter/material.dart';

import '../domain/domain.dart';

const brandSeed = Color(0xFF0E7C66);
const brandDeep = Color(0xFF07513F);

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: brandSeed, brightness: brightness);
  final isLight = brightness == Brightness.light;
  final radius = BorderRadius.circular(20);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Manrope',
    scaffoldBackgroundColor: isLight ? const Color(0xFFF3F6F4) : scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: isLight ? Colors.white : scheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: radius),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isLight ? Colors.white : scheme.surfaceContainer,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'Manrope',
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isLight ? const Color(0xFFF0F3F1) : scheme.surfaceContainerHighest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontFamily: 'Manrope', fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontFamily: 'Manrope', fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(showDragHandle: true),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

/// Kolory statusów przypomnień – spójne w jasnym i ciemnym motywie.
class StatusColors {
  const StatusColors(this.background, this.foreground);

  final Color background;
  final Color foreground;

  static StatusColors of(BuildContext context, ReminderStatus status) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (status) {
      ReminderStatus.ok => StatusColors(
          dark ? const Color(0xFF1F3B2E) : const Color(0xFFDDF3E6),
          dark ? const Color(0xFF8FDCB0) : const Color(0xFF1B6B43),
        ),
      ReminderStatus.dueSoon => StatusColors(
          dark ? const Color(0xFF4A3A12) : const Color(0xFFFFEDC2),
          dark ? const Color(0xFFFFD27A) : const Color(0xFF7A4E00),
        ),
      ReminderStatus.overdue => StatusColors(scheme.errorContainer, scheme.onErrorContainer),
    };
  }
}

IconData maintenanceIcon(MaintenanceKind kind) => switch (kind) {
      MaintenanceKind.oilChange => Icons.oil_barrel_outlined,
      MaintenanceKind.oilFilter => Icons.filter_alt_outlined,
      MaintenanceKind.airFilter => Icons.air,
      MaintenanceKind.cabinFilter => Icons.hvac,
      MaintenanceKind.fuelFilter => Icons.local_gas_station_outlined,
      MaintenanceKind.brakeFluid => Icons.water_drop_outlined,
      MaintenanceKind.timingBelt => Icons.settings_outlined,
      MaintenanceKind.tires => Icons.tire_repair,
      MaintenanceKind.inspection => Icons.fact_check_outlined,
      MaintenanceKind.insurance => Icons.shield_outlined,
      MaintenanceKind.custom => Icons.build_outlined,
    };

String fuelTypeLabel(FuelType t) => switch (t) {
      FuelType.petrol => 'Benzyna',
      FuelType.diesel => 'Diesel',
      FuelType.lpg => 'LPG',
      FuelType.hybrid => 'Hybryda',
      FuelType.electric => 'Elektryczny',
    };

String repairCategoryLabel(RepairCategory c) => switch (c) {
      RepairCategory.repair => 'Naprawa',
      RepairCategory.service => 'Serwis',
      RepairCategory.inspection => 'Przegląd',
      RepairCategory.tires => 'Opony',
      RepairCategory.parts => 'Części',
      RepairCategory.other => 'Inne',
    };

IconData repairCategoryIcon(RepairCategory c) => switch (c) {
      RepairCategory.repair => Icons.handyman_outlined,
      RepairCategory.service => Icons.build_circle_outlined,
      RepairCategory.inspection => Icons.fact_check_outlined,
      RepairCategory.tires => Icons.tire_repair,
      RepairCategory.parts => Icons.settings_input_component_outlined,
      RepairCategory.other => Icons.receipt_long_outlined,
    };
