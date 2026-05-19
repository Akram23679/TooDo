import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

// ─── Entry point ──────────────────────────────────────────────────────────────

/// Call once at startup to decide whether to show onboarding.
Future<bool> shouldShowOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return !(prefs.getBool('onboarding_done') ?? false);
}

Future<void> markOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_done', true);
}

// ─── Main onboarding widget ───────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _pages = [
    _PageData(
      illustration: _IllustrationKind.tasks,
      headline: 'Your day,\norganized.',
      body: 'Too Do brings all your tasks, lists, and reminders into one calm, focused place.',
    ),
    _PageData(
      illustration: _IllustrationKind.gestures,
      headline: 'Swipe to\ntake action.',
      body: 'Swipe right to complete a task. Swipe left to delete it. Drag to reorder your lists.',
    ),
    _PageData(
      illustration: _IllustrationKind.screens,
      headline: 'Built around\nyour day.',
      body: 'My Day, Lists, Calendar, and Done — everything you need, nothing you don\'t.',
    ),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _ctrl.nextPage(
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  void _skip() => _finish();

  Future<void> _finish() async {
    await markOnboardingDone();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const MainShell(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip button row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page counter
                  Text(
                    '${_page + 1} / ${_pages.length}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary),
                  ),
                  // Skip (hidden on last page)
                  if (_page < _pages.length - 1)
                    TextButton(
                      onPressed: _skip,
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary),
                      child: const Text('Skip',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                    )
                  else
                    const SizedBox(width: 64),
                ],
              ),
            ),

            // ── Pages
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) =>
                    _OnboardingPage(data: _pages[i], isActive: _page == i),
              ),
            ),

            // ── Dot indicator + button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final isActive = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        width: isActive ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // CTA button
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: GestureDetector(
                        key: ValueKey(_page),
                        onTap: _next,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              _page < _pages.length - 1
                                  ? 'Next'
                                  : 'Get started',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Single onboarding page ───────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final _PageData data;
  final bool isActive;

  const _OnboardingPage({required this.data, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Illustration area
          Expanded(
            flex: 5,
            child: Center(
              child: _Illustration(kind: data.illustration, isActive: isActive),
            ),
          ),

          // Text area
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.headline,
                  style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 14),
                Text(
                  data.body,
                  style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Page data ────────────────────────────────────────────────────────────────

enum _IllustrationKind { tasks, gestures, screens }

class _PageData {
  final _IllustrationKind illustration;
  final String headline;
  final String body;
  const _PageData(
      {required this.illustration,
      required this.headline,
      required this.body});
}

// ─── Illustrations ────────────────────────────────────────────────────────────

class _Illustration extends StatefulWidget {
  final _IllustrationKind kind;
  final bool isActive;
  const _Illustration({required this.kind, required this.isActive});

  @override
  State<_Illustration> createState() => _IllustrationState();
}

class _IllustrationState extends State<_Illustration>
    with TickerProviderStateMixin {
  late AnimationController _floatCtrl;
  late AnimationController _entryCtrl;
  late AnimationController _swipeCtrl;
  late AnimationController _navCtrl;

  late Animation<double> _floatAnim;
  late Animation<double> _entryAnim;
  late Animation<double> _swipeAnim;
  late Animation<double> _navAnim;

  @override
  void initState() {
    super.initState();

    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
    _floatAnim =
        CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut);

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _entryAnim =
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    _swipeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: false);
    _swipeAnim =
        CurvedAnimation(parent: _swipeCtrl, curve: Curves.easeInOut);

    _navCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: false);
    _navAnim = CurvedAnimation(parent: _navCtrl, curve: Curves.easeInOut);

    if (widget.isActive) _entryCtrl.forward();
  }

  @override
  void didUpdateWidget(_Illustration old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _entryCtrl.reset();
      _entryCtrl.forward();
    }
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _entryCtrl.dispose();
    _swipeCtrl.dispose();
    _navCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.kind) {
      case _IllustrationKind.tasks:
        return _TasksIllustration(
            floatAnim: _floatAnim, entryAnim: _entryAnim);
      case _IllustrationKind.gestures:
        return _GesturesIllustration(
            swipeAnim: _swipeAnim, entryAnim: _entryAnim);
      case _IllustrationKind.screens:
        return _ScreensIllustration(
            navAnim: _navAnim, entryAnim: _entryAnim);
    }
  }
}

// ─── Illustration 1: Floating task cards ──────────────────────────────────────

class _TasksIllustration extends StatelessWidget {
  final Animation<double> floatAnim;
  final Animation<double> entryAnim;

  const _TasksIllustration(
      {required this.floatAnim, required this.entryAnim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([floatAnim, entryAnim]),
      builder: (_, __) {
        final float = math.sin(floatAnim.value * math.pi) * 6;
        return FadeTransition(
          opacity: entryAnim,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.1), end: Offset.zero)
                .animate(entryAnim),
            child: SizedBox(
              width: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Back card (shadow card)
                  Transform.translate(
                    offset: Offset(14, -float - 8),
                    child: Transform.rotate(
                      angle: 0.05,
                      child: const _TaskCard(
                        title: 'Review Q3 report',
                        subtitle: 'Work · High',
                        isDone: false,
                        opacity: 0.45,
                        priorityColor: AppColors.priorityHigh,
                      ),
                    ),
                  ),
                  // Front card
                  Transform.translate(
                    offset: Offset(0, float.toDouble()),
                    child: const _TaskCard(
                      title: 'Design new onboarding',
                      subtitle: 'Projects · Medium',
                      isDone: true,
                      opacity: 1.0,
                      priorityColor: AppColors.priorityMedium,
                    ),
                  ),
                  // Bottom card
                  Transform.translate(
                    offset: Offset(-12, float + 88),
                    child: Transform.rotate(
                      angle: -0.04,
                      child: const _TaskCard(
                        title: 'Morning run',
                        subtitle: 'Personal',
                        isDone: false,
                        opacity: 0.55,
                        priorityColor: AppColors.priorityLow,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDone;
  final double opacity;
  final Color priorityColor;

  const _TaskCard({
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.opacity,
    required this.priorityColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 260,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark
                  ? AppColors.darkDivider
                  : Colors.grey.shade100,
              width: 0.5),
        ),
        child: Row(
          children: [
            // Priority stripe
            Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 12),
            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : Colors.transparent,
                border: isDone
                    ? null
                    : Border.all(color: Colors.grey.shade300, width: 1.5),
                borderRadius: BorderRadius.circular(5),
              ),
              child: isDone
                  ? const Icon(Icons.check_rounded,
                      size: 13, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDone
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        decoration:
                            isDone ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Illustration 2: Swipe gesture demo ──────────────────────────────────────

class _GesturesIllustration extends StatelessWidget {
  final Animation<double> swipeAnim;
  final Animation<double> entryAnim;

  const _GesturesIllustration(
      {required this.swipeAnim, required this.entryAnim});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([swipeAnim, entryAnim]),
      builder: (_, __) {
        // Cycle: 0→0.4 swipe right, 0.4→0.6 pause, 0.6→1.0 swipe left
        final t = swipeAnim.value;
        double offset = 0;
        Color bgColor = Colors.transparent;
        String hint = '';

        if (t < 0.4) {
          // Swipe right → complete
          final progress = t / 0.4;
          offset = progress * 80;
          bgColor = AppColors.priorityLow.withValues(alpha: progress * 0.3);
          hint = 'Complete';
        } else if (t < 0.6) {
          // Pause
          offset = 0;
          bgColor = Colors.transparent;
          hint = '';
        } else {
          // Swipe left → delete
          final progress = (t - 0.6) / 0.4;
          offset = -progress * 80;
          bgColor = AppColors.overdueRed.withValues(alpha: progress * 0.3);
          hint = 'Delete';
        }

        return FadeTransition(
          opacity: entryAnim,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.1), end: Offset.zero)
                .animate(entryAnim),
            child: SizedBox(
              width: 280,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Swipeable demo card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Background action hint
                        Container(
                          height: 68,
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: offset > 0
                                ? MainAxisAlignment.start
                                : MainAxisAlignment.end,
                            children: [
                              if (hint.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Row(
                                    children: [
                                      Icon(
                                        offset > 0
                                            ? Icons.check_circle_outline_rounded
                                            : Icons.delete_outline_rounded,
                                        size: 18,
                                        color: offset > 0
                                            ? AppColors.priorityLow
                                            : AppColors.overdueRed,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(hint,
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: offset > 0
                                                  ? AppColors.priorityLow
                                                  : AppColors.overdueRed)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Sliding card
                        Transform.translate(
                          offset: Offset(offset, 0),
                          child: Container(
                            height: 68,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCard
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: isDark
                                      ? AppColors.darkDivider
                                      : Colors.grey.shade100,
                                  width: 0.5),
                            ),
                            child: Row(
                              children: [
                                Container(
                                    width: 3,
                                    height: 34,
                                    decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius:
                                            BorderRadius.circular(2))),
                                const SizedBox(width: 12),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 1.5),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text('Morning standup',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Legend row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const _GestureHint(
                        icon: Icons.arrow_forward_rounded,
                        label: 'Swipe right',
                        sublabel: 'Complete',
                        color: AppColors.priorityLow,
                      ),
                      Container(
                          width: 0.5,
                          height: 36,
                          color: Colors.grey.shade200),
                      const _GestureHint(
                        icon: Icons.arrow_back_rounded,
                        label: 'Swipe left',
                        sublabel: 'Delete',
                        color: AppColors.overdueRed,
                      ),
                      Container(
                          width: 0.5,
                          height: 36,
                          color: Colors.grey.shade200),
                      const _GestureHint(
                        icon: Icons.drag_handle_rounded,
                        label: 'Long press',
                        sublabel: 'Reorder',
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GestureHint extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;

  const _GestureHint({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        Text(sublabel,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ─── Illustration 3: Animated nav tabs ───────────────────────────────────────

class _ScreensIllustration extends StatelessWidget {
  final Animation<double> navAnim;
  final Animation<double> entryAnim;

  const _ScreensIllustration(
      {required this.navAnim, required this.entryAnim});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Cycle through 4 tabs, 0.25 each
    final t = navAnim.value;
    final activeTab = (t * 4).floor().clamp(0, 3);

    final tabs = [
      const _TabInfo(Icons.calendar_today, 'My Day', 'Start fresh\nevery morning'),
      const _TabInfo(Icons.format_list_bulleted_rounded, 'Lists', 'Group tasks\ninto projects'),
      const _TabInfo(Icons.calendar_month, 'Calendar', 'Plan your\nweek ahead'),
      const _TabInfo(Icons.check_circle_rounded, 'Done', 'Track your\nprogress'),
    ];

    return AnimatedBuilder(
      animation: Listenable.merge([navAnim, entryAnim]),
      builder: (_, __) {
        return FadeTransition(
          opacity: entryAnim,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.1), end: Offset.zero)
                .animate(entryAnim),
            child: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Active tab showcase
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: Container(
                      key: ValueKey(activeTab),
                      height: 110,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(tabs[activeTab].icon,
                                color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(tabs[activeTab].label,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary)),
                                const SizedBox(height: 4),
                                Text(tabs[activeTab].description,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Mini bottom nav
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isDark
                              ? AppColors.darkDivider
                              : Colors.grey.shade100,
                          width: 0.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(4, (i) {
                        final isActive = i == activeTab;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            tabs[i].icon,
                            size: 22,
                            color: isActive
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TabInfo {
  final IconData icon;
  final String label;
  final String description;
  const _TabInfo(this.icon, this.label, this.description);
}