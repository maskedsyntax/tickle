import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tickle_core/tickle_core.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pull_down_button/pull_down_button.dart';
import '../cubits/counter_detail_cubit.dart';
import '../cubits/settings_cubit.dart';
import '../theme/theme.dart';
import '../widgets/bounce_tap.dart';
import '../widgets/ios_sliver_app_bar.dart';
import '../widgets/rapid_count_button.dart';
import '../widgets/counter_form_sheet.dart';
import '../utils/haptic_feedback.dart';
import '../cubits/premium_cubit.dart';
import '../services/notification_service.dart';

class CounterDetailScreen extends StatelessWidget {
  final String counterId;

  const CounterDetailScreen({super.key, required this.counterId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CounterDetailCubit(
        RepositoryProvider.of<CountersRepository>(context),
        counterId,
      )..loadDetails(),
      child: const CounterDetailView(),
    );
  }
}

class CounterDetailView extends StatefulWidget {
  const CounterDetailView({super.key});

  @override
  State<CounterDetailView> createState() => _CounterDetailViewState();
}

class _CounterDetailViewState extends State<CounterDetailView> {
  void _showEditCounterSheet(BuildContext context, Counter counter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CounterFormSheet(initialCounter: counter);
      },
    );
  }

  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (diagContext) {
        return AlertDialog.adaptive(
          title: const Text('Clear History?'),
          content: const Text(
            'This will clear all logs and reset the count back to 0. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(diagContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(diagContext);
                context.read<CounterDetailCubit>().clearHistory();
              },
              child: const Text(
                'Clear Everything',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  int _rapidDelta = 0;

  Future<void> _handleSetReminder(BuildContext context, Counter counter) async {
    final isPro = context.read<PremiumCubit>().state.isPro;
    if (!isPro) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminders are a Tickle Pro feature!')),
      );
      return;
    }

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null && context.mounted) {
      await context.read<NotificationService>().scheduleDailyReminder(
        counter, 
        time.hour, 
        time.minute,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Daily reminder set for ${time.format(context)}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsCubit = context.read<SettingsCubit>();

    return BlocBuilder<CounterDetailCubit, CounterDetailState>(
      builder: (context, state) {
        if (state is CounterDetailLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        if (state is CounterDetailError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('Error: ${state.message}')),
          );
        }

        if (state is CounterDetailLoaded) {
          final counter = state.counter;
          final logs = state.logs;
          final stats = state.stats;
          final preset = AppColors.getPresetByHex(counter.colorHex);
          
          final optimisticCount = counter.currentCount + _rapidDelta;
          final hasGoal = counter.goalValue != null && counter.goalValue! > 0;
          final progress = hasGoal
              ? (optimisticCount / counter.goalValue!).clamp(0.0, 1.0)
              : 0.0;
          final hapticLevel = settingsCubit.state.hapticLevel;

          return Scaffold(
            body: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                IOSSliverAppBar(
                  title: counter.title,
                  actions: [
                    Builder(
                      builder: (context) {
                        final platform = Theme.of(context).platform;
                        final isApple = platform == TargetPlatform.iOS ||
                            platform == TargetPlatform.macOS;

                        if (isApple) {
                          return PullDownButton(
                            itemBuilder: (context) => [
                              PullDownMenuItem(
                                title: 'Edit Counter',
                                icon: CupertinoIcons.pencil,
                                onTap: () {
                                  HapticsHelper.selectionClick(hapticLevel);
                                  _showEditCounterSheet(context, counter);
                                },
                              ),
                              PullDownMenuItem(
                                title: 'Reset Count',
                                icon: CupertinoIcons.arrow_counterclockwise,
                                onTap: () {
                                  HapticsHelper.selectionClick(hapticLevel);
                                  context.read<CounterDetailCubit>().reset();
                                },
                              ),
                              PullDownMenuItem(
                                title: 'Set Daily Reminder',
                                icon: CupertinoIcons.bell,
                                onTap: () {
                                  HapticsHelper.selectionClick(hapticLevel);
                                  _handleSetReminder(context, counter);
                                },
                              ),
                              PullDownMenuItem(
                                title: 'Clear History Logs',
                                icon: CupertinoIcons.delete,
                                isDestructive: true,
                                onTap: () {
                                  HapticsHelper.selectionClick(hapticLevel);
                                  _confirmClearHistory(context);
                                },
                              ),
                            ],
                            buttonBuilder: (context, showMenu) => IconButton(
                              icon: const Icon(CupertinoIcons.ellipsis_circle),
                              onPressed: showMenu,
                            ),
                          );
                        }

                        return PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded),
                          onSelected: (val) {
                            if (val == 'edit') {
                              HapticsHelper.selectionClick(hapticLevel);
                              _showEditCounterSheet(context, counter);
                            } else if (val == 'reset') {
                              HapticsHelper.selectionClick(hapticLevel);
                              context.read<CounterDetailCubit>().reset();
                            } else if (val == 'reminder') {
                              HapticsHelper.selectionClick(hapticLevel);
                              _handleSetReminder(context, counter);
                            } else if (val == 'clear_history') {
                              HapticsHelper.selectionClick(hapticLevel);
                              _confirmClearHistory(context);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit Counter'),
                            ),
                            const PopupMenuItem(
                              value: 'reset',
                              child: Text('Reset Count'),
                            ),
                            const PopupMenuItem(
                              value: 'reminder',
                              child: Text('Set Daily Reminder'),
                            ),
                            const PopupMenuItem(
                              value: 'clear_history',
                              child: Text(
                                'Clear History Logs',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _HeroCountCard(
                        counter: counter,
                        optimisticCount: optimisticCount,
                        preset: preset,
                        hasGoal: hasGoal,
                        progress: progress,
                        hapticLevel: hapticLevel,
                      ),
                      const SizedBox(height: 20),
                      _Controls(
                        preset: preset,
                        hapticLevel: hapticLevel,
                        onTickDecrement: (delta) => setState(() => _rapidDelta = -delta),
                        onTickIncrement: (delta) => setState(() => _rapidDelta = delta),
                      ),
                      const SizedBox(height: 28),
                      _StreaksSection(stats: stats, preset: preset),
                      const SizedBox(height: 28),
                      _HeatmapSection(heatmapData: stats.heatmapData, preset: preset),
                      const SizedBox(height: 28),
                      _AnalyticsSection(logs: logs, preset: preset),
                      const SizedBox(height: 28),
                      _HistorySection(logs: logs),
                    ]),
                  ),
                ),
              ],
            ),
          );
        }

        return const Scaffold();
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Hero count card
// ---------------------------------------------------------------------------

class _HeroCountCard extends StatelessWidget {
  final Counter counter;
  final int optimisticCount;
  final CounterColorPreset preset;
  final bool hasGoal;
  final double progress;
  final String hapticLevel;

  const _HeroCountCard({
    required this.counter,
    required this.optimisticCount,
    required this.preset,
    required this.hasGoal,
    required this.progress,
    required this.hapticLevel,
  });

  @override
  Widget build(BuildContext context) {
    final rapidDelta = optimisticCount - counter.currentCount;
    final isRapid = rapidDelta != 0;
    final goalSuffix = hasGoal
        ? ', goal $optimisticCount of ${counter.goalValue}'
        : '';
    final countStyle = const TextStyle(
      fontSize: 88,
      height: 1.0,
      fontWeight: FontWeight.w800,
      color: Colors.white,
      letterSpacing: -3,
    );

    // While rapid-counting we render the number directly so it ticks in
    // real time. The AnimatedSwitcher's 220ms transition is slower than the
    // 150ms tick interval and would smear values together.
    final countText = isRapid
        ? Text('$optimisticCount', maxLines: 1, style: countStyle)
        : AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(scale: anim, child: child),
            ),
            child: Text(
              '$optimisticCount',
              key: ValueKey(optimisticCount),
              maxLines: 1,
              style: countStyle,
            ),
          );

    return Semantics(
      button: true,
      label:
          '${counter.title}, count $optimisticCount$goalSuffix',
      hint: 'Double tap to increment',
      excludeSemantics: true,
      child: BounceTap(
      scaleFactor: 0.97,
      onTap: () {
        HapticsHelper.trigger(hapticLevel);
        context.read<CounterDetailCubit>().increment();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              preset.primary,
              preset.secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: preset.primary.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            _EmojiRing(
              emoji: counter.emoji ?? '🔢',
              progress: hasGoal ? progress : null,
            ),
            const SizedBox(height: 24),
            FittedBox(fit: BoxFit.scaleDown, child: countText),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SizeTransition(
                  sizeFactor: anim,
                  axisAlignment: -1,
                  child: child,
                ),
              ),
              child: isRapid
                  ? _RapidDeltaPill(
                      key: const ValueKey('rapid'),
                      delta: rapidDelta,
                    )
                  : Text(
                      'Tap card to count',
                      key: const ValueKey('hint'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.75),
                        letterSpacing: 0.4,
                      ),
                    ),
            ),
            if (hasGoal) ...[
              const SizedBox(height: 20),
              _GoalRow(
                current: optimisticCount,
                goal: counter.goalValue!,
                progress: progress,
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }
}

class _RapidDeltaPill extends StatelessWidget {
  final int delta;

  const _RapidDeltaPill({super.key, required this.delta});

  @override
  Widget build(BuildContext context) {
    final sign = delta > 0 ? '+' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$sign$delta',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontFeatures: [FontFeature.tabularFigures()],
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _EmojiRing extends StatelessWidget {
  final String emoji;
  final double? progress;

  const _EmojiRing({required this.emoji, this.progress});

  @override
  Widget build(BuildContext context) {
    const ringSize = 92.0;
    return SizedBox(
      width: ringSize,
      height: ringSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (progress != null) ...[
            SizedBox(
              width: ringSize,
              height: ringSize,
              child: CircularProgressIndicator(
                value: 1,
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(0.18)),
              ),
            ),
            SizedBox(
              width: ringSize,
              height: ringSize,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0, end: progress),
                builder: (_, val, __) => CircularProgressIndicator(
                  value: val,
                  strokeWidth: 4,
                  strokeCap: StrokeCap.round,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ),
          ],
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 34)),
          ),
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final int current;
  final int goal;
  final double progress;

  const _GoalRow({
    required this.current,
    required this.goal,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = current >= goal;
    final label = isComplete
        ? 'Goal reached · $current / $goal'
        : '$current / $goal · ${(progress * 100).round()}%';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isComplete ? Icons.check_circle_rounded : Icons.flag_rounded,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Controls
// ---------------------------------------------------------------------------

class _Controls extends StatelessWidget {
  final CounterColorPreset preset;
  final String hapticLevel;
  final void Function(int delta) onTickDecrement;
  final void Function(int delta) onTickIncrement;

  const _Controls({
    required this.preset, 
    required this.hapticLevel,
    required this.onTickDecrement,
    required this.onTickIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RapidCountButton(
          isDecrement: true,
          hapticLevel: hapticLevel,
          onTap: () {
            HapticsHelper.trigger(hapticLevel);
            context.read<CounterDetailCubit>().decrement();
          },
          onTick: onTickDecrement,
          onCommit: (delta) {
            context.read<CounterDetailCubit>().decrementBy(delta);
          },
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: preset.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.remove_rounded, color: preset.primary, size: 36),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: RapidCountButton(
            hapticLevel: hapticLevel,
            onTap: () {
              HapticsHelper.trigger(hapticLevel);
              context.read<CounterDetailCubit>().increment();
            },
            onTick: onTickIncrement,
            onCommit: (delta) {
              context.read<CounterDetailCubit>().incrementBy(delta);
            },
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: preset.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: preset.primary.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 40),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final CounterColorPreset preset;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.preset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BounceTap(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: filled ? preset.primary : theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: filled
              ? null
              : Border.all(color: theme.dividerColor, width: 1),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: preset.primary.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: filled ? Colors.white : preset.primary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: filled
                    ? Colors.white
                    : theme.textTheme.bodyLarge?.color,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Analytics
// ---------------------------------------------------------------------------

class _AnalyticsSection extends StatelessWidget {
  final List<CounterLog> logs;
  final CounterColorPreset preset;

  const _AnalyticsSection({required this.logs, required this.preset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final Map<DateTime, int> last7DaysMap = {
      for (int i = 6; i >= 0; i--) today.subtract(Duration(days: i)): 0,
    };

    for (final log in logs) {
      if (log.actionType != CounterActionType.increment &&
          log.actionType != CounterActionType.set) continue;
      if (log.delta <= 0) continue;
      final d = DateTime(
          log.timestamp.year, log.timestamp.month, log.timestamp.day);
      if (last7DaysMap.containsKey(d)) {
        last7DaysMap[d] = last7DaysMap[d]! + log.delta;
      }
    }

    final dateKeys = last7DaysMap.keys.toList();
    final totalThisWeek =
        last7DaysMap.values.fold<int>(0, (a, b) => a + b);
    double maxVal = 5;
    for (final v in last7DaysMap.values) {
      if (v > maxVal) maxVal = v.toDouble();
    }

    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < dateKeys.length; i++) {
      final isToday = dateKeys[i] == today;
      final count = last7DaysMap[dateKeys[i]]!;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: isToday ? preset.primary : preset.primary.withOpacity(0.35),
              width: 16,
              borderRadius: BorderRadius.circular(6),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxVal * 1.1,
                color: preset.primary.withOpacity(0.06),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Last 7 Days',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: preset.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$totalThisWeek total',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: preset.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          height: 180,
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal * 1.2,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => preset.secondary,
                  getTooltipItem: (group, _, rod, __) {
                    return BarTooltipItem(
                      '${rod.toY.toInt()}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= dateKeys.length) {
                        return const SizedBox.shrink();
                      }
                      final isToday = dateKeys[i] == today;
                      final text =
                          DateFormat('E').format(dateKeys[i]).substring(0, 1);
                      return SideTitleWidget(
                        meta: meta,
                        space: 6,
                        child: Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isToday
                                ? preset.primary
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            text,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isToday
                                  ? Colors.white
                                  : theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// History
// ---------------------------------------------------------------------------

class _HistorySection extends StatelessWidget {
  final List<CounterLog> logs;

  const _HistorySection({required this.logs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Exclude basic initialization log (set to 0 with 0 delta).
    final listLogs = logs
        .where((l) =>
            !(l.actionType == CounterActionType.set && l.delta == 0))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'History',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2),
            ),
            if (listLogs.isNotEmpty)
              Text(
                '${listLogs.length} ${listLogs.length == 1 ? "entry" : "entries"}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (listLogs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Center(
              child: Text(
                'No activity logged yet.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: listLogs.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                thickness: 0.6,
                color: theme.dividerColor,
                indent: 56,
              ),
              itemBuilder: (context, index) =>
                  _HistoryTile(log: listLogs[index]),
            ),
          ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final CounterLog log;

  const _HistoryTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color, label) = _logDisplay(log);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM d · h:mm a').format(log.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${log.resultingCount}',
              style: TextStyle(
                fontFeatures: const [FontFeature.tabularFigures()],
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, String) _logDisplay(CounterLog log) {
    switch (log.actionType) {
      case CounterActionType.increment:
        return (
          Icons.add_rounded,
          const Color(0xFF10B981),
          'Incremented (+${log.delta})',
        );
      case CounterActionType.decrement:
        return (
          Icons.remove_rounded,
          const Color(0xFFF59E0B),
          'Decremented (${log.delta})',
        );
      case CounterActionType.reset:
        return (
          Icons.refresh_rounded,
          const Color(0xFFEF4444),
          'Reset count',
        );
      case CounterActionType.set:
        if (log.delta == 0) {
          return (
            Icons.flag_rounded,
            const Color(0xFF3B82F6),
            'Created counter',
          );
        }
        return (
          Icons.edit_note_rounded,
          const Color(0xFF3B82F6),
          'Set value (${log.delta > 0 ? "+${log.delta}" : "${log.delta}"})',
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Streaks
// ---------------------------------------------------------------------------

class _StreaksSection extends StatelessWidget {
  final CounterStats stats;
  final CounterColorPreset preset;

  const _StreaksSection({required this.stats, required this.preset});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Active Streak',
            value: '${stats.activeStreak}d',
            icon: Icons.local_fire_department_rounded,
            preset: preset,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'Best Streak',
            value: '${stats.longestStreak}d',
            icon: Icons.emoji_events_rounded,
            preset: preset,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final CounterColorPreset preset;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.preset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: preset.primary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: preset.primary, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyMedium?.color,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Activity heatmap
// ---------------------------------------------------------------------------

class _HeatmapSection extends StatelessWidget {
  final Map<DateTime, int> heatmapData;
  final CounterColorPreset preset;

  const _HeatmapSection({required this.heatmapData, required this.preset});

  static const int _weeks = 16;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final startDayOffset = today.weekday % 7;
    final currentWeekSunday = today.subtract(Duration(days: startDayOffset));
    final startDate = currentWeekSunday.subtract(const Duration(days: (_weeks - 1) * 7));

    final weeks = <List<DateTime>>[];
    for (int col = 0; col < _weeks; col++) {
      final week = <DateTime>[];
      for (int row = 0; row < 7; row++) {
        week.add(startDate.add(Duration(days: col * 7 + row)));
      }
      weeks.add(week);
    }

    int maxCount = 0;
    for (final v in heatmapData.values) {
      if (v > maxCount) maxCount = v;
    }
    final totalActiveDays = heatmapData.values.where((v) => v > 0).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Activity Map',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2),
            ),
            Text(
              '$totalActiveDays active days',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MonthLabels(weeks: weeks),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _DayLabels(),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _HeatmapGrid(
                      weeks: weeks,
                      heatmapData: heatmapData,
                      today: today,
                      maxCount: maxCount,
                      preset: preset,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Less',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  for (final level in [0, 1, 2, 3, 4])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: _heatmapColor(context, level, 4, preset),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  Text(
                    'More',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthLabels extends StatelessWidget {
  final List<List<DateTime>> weeks;

  const _MonthLabels({required this.weeks});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 22),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final labels = <Widget>[];
          String? lastMonth;
          for (int i = 0; i < weeks.length; i++) {
            final first = weeks[i].first;
            final month = DateFormat('MMM').format(first);
            if (lastMonth != month) {
              labels.add(Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    month,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ));
              lastMonth = month;
            } else {
              labels.add(const Expanded(child: SizedBox()));
            }
          }
          return Row(children: labels);
        },
      ),
    );
  }
}

class _DayLabels extends StatelessWidget {
  static const labels = ['', 'M', '', 'W', '', 'F', ''];

  const _DayLabels();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final l in labels)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1.5),
            child: SizedBox(
              width: 14,
              height: 13,
              child: Text(
                l,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  final List<List<DateTime>> weeks;
  final Map<DateTime, int> heatmapData;
  final DateTime today;
  final int maxCount;
  final CounterColorPreset preset;

  const _HeatmapGrid({
    required this.weeks,
    required this.heatmapData,
    required this.today,
    required this.maxCount,
    required this.preset,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 3.0;
        final available = constraints.maxWidth;
        final cell = ((available - spacing * (weeks.length - 1)) / weeks.length).floorToDouble();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final week in weeks)
              Column(
                children: [
                  for (final date in week) ...[
                    _HeatmapCell(
                      date: date,
                      count: heatmapData[date] ?? 0,
                      isFuture: date.isAfter(today),
                      isToday: date == today,
                      size: cell,
                      maxCount: maxCount,
                      preset: preset,
                    ),
                    if (date != week.last) const SizedBox(height: spacing),
                  ],
                ],
              ),
          ],
        );
      },
    );
  }
}

class _HeatmapCell extends StatelessWidget {
  final DateTime date;
  final int count;
  final bool isFuture;
  final bool isToday;
  final double size;
  final int maxCount;
  final CounterColorPreset preset;

  const _HeatmapCell({
    required this.date,
    required this.count,
    required this.isFuture,
    required this.isToday,
    required this.size,
    required this.maxCount,
    required this.preset,
  });

  @override
  Widget build(BuildContext context) {
    if (isFuture) {
      return SizedBox(width: size, height: size);
    }
    final color = _heatmapColor(context, count, maxCount, preset);
    return GestureDetector(
      onTap: count > 0 ? () => _showCellInfo(context) : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          border: isToday
              ? Border.all(
                  color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                  width: 1.2,
                )
              : null,
        ),
      ),
    );
  }

  void _showCellInfo(BuildContext context) {
    final formatted = DateFormat('MMM d, yyyy').format(date);
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text('$count ${count == 1 ? "tap" : "taps"} on $formatted'),
      ),
    );
  }
}

Color _heatmapColor(BuildContext context, int count, int maxCount, CounterColorPreset preset) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  if (count == 0) {
    return isDark ? const Color(0xFF1F1F22) : const Color(0xFFEEF0F3);
  }
  final effectiveMax = maxCount < 4 ? 4 : maxCount;
  final ratio = (count / effectiveMax).clamp(0.0, 1.0);
  if (ratio <= 0.25) return preset.primary.withOpacity(0.22);
  if (ratio <= 0.5) return preset.primary.withOpacity(0.45);
  if (ratio <= 0.75) return preset.primary.withOpacity(0.7);
  return preset.primary;
}
