import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../format.dart';
import '../theme.dart';

/// Nagłówek sekcji z opcjonalną akcją po prawej.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 0, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ),
          if (actionLabel != null) TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final ReminderStatus status;

  @override
  Widget build(BuildContext context) {
    final c = StatusColors.of(context, status);
    final label = switch (status) {
      ReminderStatus.ok => 'OK',
      ReminderStatus.dueSoon => 'Wkrótce',
      ReminderStatus.overdue => 'Po terminie',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.background, borderRadius: BorderRadius.circular(99)),
      child: Text(label, style: TextStyle(color: c.foreground, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

/// Ikona w zaokrąglonym, kolorowym kwadracie.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, required this.background, required this.foreground, this.size = 44});

  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(size * 0.32)),
      child: Icon(icon, color: foreground, size: size * 0.52),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconBadge(icon, background: scheme.primaryContainer, foreground: scheme.onPrimaryContainer, size: 72),
          const SizedBox(height: 20),
          Text(title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4)),
          if (actionLabel != null) ...[
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: onAction, icon: const Icon(Icons.add), label: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Mała karta ze statystyką.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: scheme.primary, size: 22),
            const SizedBox(height: 12),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

/// Okrągły wskaźnik poziomu paliwa (łuk 270°).
class FuelGauge extends StatelessWidget {
  const FuelGauge({super.key, required this.level, this.size = 112, required this.color, required this.trackColor});

  /// 0.0–1.0 albo null, gdy nie wiadomo.
  final double? level;
  final double size;
  final Color color;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final pct = level == null ? '–' : '${(level! * 100).round()}%';
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GaugePainter(level ?? 0, color, trackColor),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_gas_station_rounded, color: color, size: size * 0.2),
              Text(pct, style: TextStyle(color: color, fontSize: size * 0.2, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.level, this.color, this.track);

  final double level;
  final Color color;
  final Color track;

  static const _start = math.pi * 0.75;
  static const _sweep = math.pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.09;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, _start, _sweep, false, base..color = track);
    if (level > 0) {
      canvas.drawArc(rect, _start, _sweep * level, false, base..color = color);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.level != level || old.color != color || old.track != track;
}

/// Podpowiedzi pod polem tekstowym (np. ostatnie stacje czy warsztaty).
class SuggestionChips extends StatelessWidget {
  const SuggestionChips({super.key, required this.values, required this.onSelected});

  final List<String> values;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final v in values)
            ActionChip(
              avatar: const Icon(Icons.history, size: 16),
              label: Text(v),
              visualDensity: VisualDensity.compact,
              onPressed: () => onSelected(v),
            ),
        ],
      ),
    );
  }
}

/// Krótki opis terminu zadania, np. „za 520 km · za 51 dni”.
String reminderSummary(MaintenanceReminder r, DateTime now) {
  final parts = <String>[];
  if (r.kmLeft != null) {
    parts.add(r.kmLeft! <= 0 ? '${Fmt.km(-r.kmLeft!)} po terminie' : 'za ${Fmt.km(r.kmLeft!)}');
  }
  if (r.nextDueDate != null) {
    final days = daysBetween(now, r.nextDueDate!);
    parts.add(days < 0 ? 'termin minął ${Fmt.date(r.nextDueDate!, now: now)}' : Fmt.relativeDays(days));
  }
  return parts.join(' · ');
}
