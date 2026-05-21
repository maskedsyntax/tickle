import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tickle_core/tickle_core.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../cubits/counter_detail_cubit.dart';
import '../cubits/settings_cubit.dart';
import '../theme/theme.dart';
import '../widgets/bounce_tap.dart';
import '../utils/haptic_feedback.dart';

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

class CounterDetailView extends StatelessWidget {
  const CounterDetailView({super.key});

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
          final preset = AppColors.getPresetByHex(counter.colorHex);
          final hasGoal = counter.goalValue != null && counter.goalValue! > 0;
          final progress = hasGoal
              ? (counter.currentCount / counter.goalValue!).clamp(0.0, 1.0)
              : 0.0;
          final hapticLevel = settingsCubit.state.hapticLevel;

          return Scaffold(
            appBar: AppBar(
              title: Text(counter.title),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'reset') {
                      HapticsHelper.selectionClick(hapticLevel);
                      context.read<CounterDetailCubit>().reset();
                    } else if (val == 'clear_history') {
                      HapticsHelper.selectionClick(hapticLevel);
                      _confirmClearHistory(context);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'reset',
                      child: Text('Reset Count'),
                    ),
                    const PopupMenuItem(
                      value: 'clear_history',
                      child: Text('Clear History Logs',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroCountCard(
                    counter: counter,
                    preset: preset,
                    hasGoal: hasGoal,
                    progress: progress,
                    hapticLevel: hapticLevel,
                  ),
                  const SizedBox(height: 20),
                  _Controls(preset: preset, hapticLevel: hapticLevel),
                  const SizedBox(height: 28),
                  _AnalyticsSection(logs: logs, preset: preset),
                  const SizedBox(height: 28),
                  _HistorySection(logs: logs),
                ],
              ),
            ),
          );
        }

        return const Scaffold();
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
                'Clear',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Hero count card
// ---------------------------------------------------------------------------

class _HeroCountCard extends StatelessWidget {
  final Counter counter;
  final CounterColorPreset preset;
  final bool hasGoal;
  final double progress;
  final String hapticLevel;

  const _HeroCountCard({
    required this.counter,
    required this.preset,
    required this.hasGoal,
    required this.progress,
    required this.hapticLevel,
  });

  @override
  Widget build(BuildContext context) {
    final goalSuffix = hasGoal
        ? ', goal ${counter.currentCount} of ${counter.goalValue}'
        : '';
    return Semantics(
      button: true,
      label:
          '${counter.title}, count ${counter.currentCount}$goalSuffix',
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
            FittedBox(
              fit: BoxFit.scaleDown,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(scale: anim, child: child),
                ),
                child: Text(
                  '${counter.currentCount}',
                  key: ValueKey(counter.currentCount),
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 88,
                    height: 1.0,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap card to count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.75),
                letterSpacing: 0.4,
              ),
            ),
            if (hasGoal) ...[
              const SizedBox(height: 20),
              _GoalRow(
                current: counter.currentCount,
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

  const _Controls({required this.preset, required this.hapticLevel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.remove_rounded,
            label: 'Decrease',
            filled: false,
            preset: preset,
            onTap: () {
              HapticsHelper.trigger(hapticLevel);
              context.read<CounterDetailCubit>().decrement();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.add_rounded,
            label: 'Increase',
            filled: true,
            preset: preset,
            onTap: () {
              HapticsHelper.trigger(hapticLevel);
              context.read<CounterDetailCubit>().increment();
            },
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
