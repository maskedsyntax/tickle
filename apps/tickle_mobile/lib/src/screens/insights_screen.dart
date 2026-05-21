import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubits/stats_cubit.dart';
import '../theme/theme.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<StatsCubit>().loadStats();

    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          const SliverAppBar.medium(
            title: Text('Insights'),
          ),
          BlocBuilder<StatsCubit, StatsState>(
            builder: (context, state) {
              if (state is StatsLoading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator.adaptive()),
                );
              }

              if (state is StatsError) {
                return SliverFillRemaining(
                  child: Center(child: Text('Error: ${state.message}')),
                );
              }

              if (state is StatsLoaded) {
                final stats = state.stats;

                if (stats.heatmapData.isEmpty &&
                    stats.counterDistributions.isEmpty) {
                  return const _EmptyState();
                }

                return SliverPadding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _TodayHero(stats: stats),
                      const SizedBox(height: 16),
                      _StatGrid(stats: stats),
                      const SizedBox(height: 28),
                      _HeatmapSection(heatmapData: stats.heatmapData),
                      const SizedBox(height: 28),
                      _DistributionSection(
                          distributions: stats.counterDistributions),
                    ]),
                  ),
                );
              }

              return const SliverFillRemaining(child: SizedBox.shrink());
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.insights_rounded,
                size: 38,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No insights yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Log a few counts and you\'ll see streaks, activity maps and more here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Today hero
// ---------------------------------------------------------------------------

class _TodayHero extends StatelessWidget {
  final AppStats stats;

  const _TodayHero({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final delta = stats.totalTapsToday - stats.totalTapsYesterday;
    final dominantColor = _dominantColor(stats) ?? theme.primaryColor;

    String subtitle;
    if (stats.totalTapsToday == 0 && stats.totalTapsYesterday == 0) {
      subtitle = 'Tap a counter to start the day';
    } else if (delta == 0) {
      subtitle = 'Same as yesterday';
    } else if (delta > 0) {
      subtitle = '+$delta vs yesterday';
    } else {
      subtitle = '$delta vs yesterday';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            dominantColor,
            HSLColor.fromColor(dominantColor)
                .withLightness(
                    (HSLColor.fromColor(dominantColor).lightness - 0.12)
                        .clamp(0.0, 1.0))
                .toColor(),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: dominantColor.withOpacity(0.3),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMM d').format(DateTime.now()),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stats.totalTapsToday}',
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -2,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'taps today',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (stats.activeStreak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        '${stats.activeStreak}d',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color? _dominantColor(AppStats stats) {
    if (stats.counterDistributions.isEmpty) return null;
    return AppColors.getPresetByHex(stats.counterDistributions.first.colorHex)
        .primary;
  }
}

// ---------------------------------------------------------------------------
// Stat grid
// ---------------------------------------------------------------------------

class _StatGrid extends StatelessWidget {
  final AppStats stats;

  const _StatGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'This Week',
                value: '${stats.totalTapsThisWeek}',
                accent: const Color(0xFF3B82F6),
                icon: Icons.calendar_view_week_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: 'This Month',
                value: '${stats.totalTapsThisMonth}',
                accent: const Color(0xFF10B981),
                icon: Icons.calendar_month_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Daily Avg',
                value: '${stats.averageTapsPerDay}',
                accent: const Color(0xFF8B5CF6),
                icon: Icons.show_chart_rounded,
                subtitle: stats.peakDay != null
                    ? 'Peak ${stats.peakDayCount} · ${DateFormat('MMM d').format(stats.peakDay!)}'
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: 'Best Streak',
                value: '${stats.longestStreak}d',
                accent: const Color(0xFFF59E0B),
                icon: Icons.local_fire_department_rounded,
                subtitle: stats.activeStreak > 0
                    ? 'Active: ${stats.activeStreak}d'
                    : 'No active streak',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final IconData icon;
  final String? subtitle;

  const _StatTile({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
    this.subtitle,
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
                  color: accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: accent, size: 16),
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
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Activity heatmap (GitHub-style)
// ---------------------------------------------------------------------------

class _HeatmapSection extends StatelessWidget {
  final Map<DateTime, int> heatmapData;

  const _HeatmapSection({required this.heatmapData});

  static const int _weeks = 16;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Start from the Sunday that puts `today` in the rightmost column.
    final startDayOffset = today.weekday % 7; // Sunday is 0
    final currentWeekSunday = today.subtract(Duration(days: startDayOffset));
    final startDate =
        currentWeekSunday.subtract(Duration(days: (_weeks - 1) * 7));

    // Build week columns
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
                  _DayLabels(),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _HeatmapGrid(
                      weeks: weeks,
                      heatmapData: heatmapData,
                      today: today,
                      maxCount: maxCount,
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
                          color: _heatmapColor(context, level, 4),
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
          // Determine which weeks show a new month label
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

  const _HeatmapGrid({
    required this.weeks,
    required this.heatmapData,
    required this.today,
    required this.maxCount,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Compute square size so weeks fit horizontally.
        const spacing = 3.0;
        final available = constraints.maxWidth;
        final cell =
            ((available - spacing * (weeks.length - 1)) / weeks.length)
                .floorToDouble();
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

  const _HeatmapCell({
    required this.date,
    required this.count,
    required this.isFuture,
    required this.isToday,
    required this.size,
    required this.maxCount,
  });

  @override
  Widget build(BuildContext context) {
    if (isFuture) {
      return SizedBox(width: size, height: size);
    }
    final color = _heatmapColor(context, count, maxCount);
    return GestureDetector(
      onTap: count > 0
          ? () => _showCellInfo(context)
          : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          border: isToday
              ? Border.all(
                  color: Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.black,
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        content: Text('$count ${count == 1 ? "tap" : "taps"} on $formatted'),
      ),
    );
  }
}

Color _heatmapColor(BuildContext context, int count, int maxCount) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final primary = theme.primaryColor;

  if (count == 0) {
    return isDark ? const Color(0xFF1F1F22) : const Color(0xFFEEF0F3);
  }
  // Bucket into 4 levels based on max value (or absolute if small).
  final effectiveMax = maxCount < 4 ? 4 : maxCount;
  final ratio = (count / effectiveMax).clamp(0.0, 1.0);
  if (ratio <= 0.25) return primary.withOpacity(0.22);
  if (ratio <= 0.5) return primary.withOpacity(0.45);
  if (ratio <= 0.75) return primary.withOpacity(0.7);
  return primary;
}

// ---------------------------------------------------------------------------
// Counter distribution
// ---------------------------------------------------------------------------

class _DistributionSection extends StatelessWidget {
  final List<CounterDistribution> distributions;

  const _DistributionSection({required this.distributions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total =
        distributions.fold<int>(0, (sum, d) => sum + d.count);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Counter Distribution',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2),
            ),
            if (total > 0)
              Text(
                '$total total',
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
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor),
          ),
          child: distributions.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'No counts logged yet.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                )
              : Column(
                  children: [
                    if (distributions.length >= 2) ...[
                      _StackedBar(
                          distributions: distributions, total: total),
                      const SizedBox(height: 18),
                    ],
                    for (int i = 0; i < distributions.length; i++) ...[
                      _DistributionRow(
                        distribution: distributions[i],
                        total: total,
                      ),
                      if (i != distributions.length - 1)
                        const SizedBox(height: 14),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _StackedBar extends StatelessWidget {
  final List<CounterDistribution> distributions;
  final int total;

  const _StackedBar({required this.distributions, required this.total});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 14,
        child: Row(
          children: [
            for (final d in distributions)
              Expanded(
                flex: d.count,
                child: Container(
                  color: AppColors.getPresetByHex(d.colorHex).primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  final CounterDistribution distribution;
  final int total;

  const _DistributionRow({
    required this.distribution,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preset = AppColors.getPresetByHex(distribution.colorHex);
    final pct = total > 0 ? distribution.count / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: preset.primary.withOpacity(0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Text(
                distribution.emoji ?? '🔢',
                style: const TextStyle(fontSize: 15),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                distribution.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            Text(
              '${distribution.count}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${(pct * 100).round()}%',
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 480),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0, end: pct),
            builder: (context, val, _) {
              return LinearProgressIndicator(
                value: val,
                minHeight: 8,
                color: preset.primary,
                backgroundColor: preset.primary.withOpacity(0.12),
              );
            },
          ),
        ),
      ],
    );
  }
}
