import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── Progress Ring (Done screen) ─────────────────────────────────────────────

class ProgressRing extends StatelessWidget {
  final double progress; // 0.0 – 1.0
  final double size;
  final double strokeWidth;
  final Widget? child;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 110,
    this.strokeWidth = 10,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress,
          strokeWidth: strokeWidth,
          trackColor: Theme.of(context).dividerColor,
          progressColor: AppColors.primary,
        ),
        child: child,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;

  const _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.progressColor != progressColor;
}

// ─── 7-Day Bar Chart (Done screen – UX improvement #9) ───────────────────────

class WeekBarChart extends StatelessWidget {
  final List<int> counts; // 7 values, oldest first
  final List<String> labels; // 7 day labels

  const WeekBarChart({super.key, required this.counts, required this.labels});

  @override
  Widget build(BuildContext context) {
    final max = counts.reduce(math.max).clamp(1, 99999);
    final textSecondary = Theme.of(context).textTheme.bodyMedium!.color!;
    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final isToday = i == 6;
          final ratio = counts[i] / max;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (counts[i] > 0)
                    Text('${counts[i]}',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isToday
                                ? AppColors.primary
                                : textSecondary)),
                  const SizedBox(height: 3),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    height: (ratio * 60).clamp(4.0, 60.0),
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[i],
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            isToday ? FontWeight.w700 : FontWeight.w400,
                        color: isToday ? AppColors.primary : textSecondary),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Week Strip (Calendar screen – UX improvement #8) ────────────────────────

class WeekStrip extends StatelessWidget {
  final DateTime selectedDate;
  final Map<DateTime, int> taskCounts; // date → count
  final ValueChanged<DateTime> onDateSelected;

  const WeekStrip({
    super.key,
    required this.selectedDate,
    required this.taskCounts,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    // Start of current week (Monday)
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return SizedBox(
      height: 68,
      child: Row(
        children: List.generate(7, (i) {
          final date = weekStart.add(Duration(days: i));
          final isSelected = date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;
          final isToday = date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
          final key = DateTime(date.year, date.month, date.day);
          final count = taskCounts[key] ?? 0;

          return Expanded(
            child: GestureDetector(
              onTap: () => onDateSelected(date),
              child: Column(
                children: [
                  Text(days[i],
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .color)),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : isToday
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .color),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (count > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(count.clamp(0, 3), (_) =>
                          Container(
                            width: 4, height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          )),
                    )
                  else
                    const SizedBox(height: 6),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}