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
    final theme = Theme.of(context);
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
          final progress = counter.goalValue != null && counter.goalValue! > 0
              ? (counter.currentCount / counter.goalValue!).clamp(0.0, 1.0)
              : 0.0;

          return Scaffold(
            appBar: AppBar(
              title: Text(counter.title),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'reset') {
                      HapticsHelper.selectionClick(settingsCubit.state.hapticLevel);
                      context.read<CounterDetailCubit>().reset();
                    } else if (val == 'clear_history') {
                      HapticsHelper.selectionClick(settingsCubit.state.hapticLevel);
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
                      child: Text('Clear History Logs', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header card with emoji & giant count
                  _buildHeaderCard(context, counter, preset, progress, settingsCubit.state.hapticLevel),
                  const SizedBox(height: 24),
                  
                  // Incrementor / Decrementor controls
                  _buildControls(context, preset, settingsCubit.state.hapticLevel),
                  const SizedBox(height: 32),

                  // Analytics Chart (Last 7 Days)
                  _buildAnalyticsSection(context, logs, preset),
                  const SizedBox(height: 32),

                  // History Log Section
                  _buildHistorySection(context, logs),
                ],
              ),
            ),
          );
        }

        return const Scaffold();
      },
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    Counter counter,
    CounterColorPreset preset,
    double progress,
    String hapticLevel,
  ) {
    return BounceTap(
      onTap: () {
        HapticsHelper.trigger(hapticLevel);
        context.read<CounterDetailCubit>().increment();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: preset.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                counter.emoji ?? '🔢',
                style: const TextStyle(fontSize: 36),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${counter.currentCount}',
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: preset.primary,
                letterSpacing: -2,
              ),
            ),
            if (counter.goalValue != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: preset.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Goal progress: ${(progress * 100).round()}% (${counter.currentCount}/${counter.goalValue})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: preset.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  color: preset.primary,
                  backgroundColor: preset.primary.withOpacity(0.15),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, CounterColorPreset preset, String hapticLevel) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Decrement
          Expanded(
            child: BounceTap(
              onTap: () {
                HapticsHelper.trigger(hapticLevel);
                context.read<CounterDetailCubit>().decrement();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.remove_rounded, color: preset.primary, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Decrease',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Increment
          Expanded(
            flex: 2,
            child: BounceTap(
              onTap: () {
                HapticsHelper.trigger(hapticLevel);
                context.read<CounterDetailCubit>().increment();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: preset.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: preset.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Count',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection(
    BuildContext context,
    List<CounterLog> logs,
    CounterColorPreset preset,
  ) {
    // Generate data for the last 7 days
    final Map<DateTime, int> last7DaysMap = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      last7DaysMap[day] = 0;
    }

    // Populate data from logs (sum positive deltas, e.g. increments)
    for (final log in logs) {
      if (log.actionType != CounterActionType.increment && log.actionType != CounterActionType.set) {
        continue;
      }
      if (log.delta <= 0) continue;

      final logDate = DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
      if (last7DaysMap.containsKey(logDate)) {
        last7DaysMap[logDate] = last7DaysMap[logDate]! + log.delta;
      }
    }

    final barGroups = <BarChartGroupData>[];
    final dateKeys = last7DaysMap.keys.toList();
    double maxVal = 5.0;

    for (int i = 0; i < dateKeys.length; i++) {
      final count = last7DaysMap[dateKeys[i]]!;
      if (count > maxVal) {
        maxVal = count.toDouble();
      }
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: preset.primary,
              width: 14,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
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
        const Text(
          'Last 7 Days Activity',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.2),
        ),
        const SizedBox(height: 16),
        Container(
          height: 180,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal * 1.2,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= dateKeys.length) {
                        return const SizedBox.shrink();
                      }
                      final date = dateKeys[index];
                      final text = DateFormat('E').format(date).substring(0, 1);
                      return SideTitleWidget(
                        meta: meta,
                        space: 4,
                        child: Text(
                          text,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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

  Widget _buildHistorySection(BuildContext context, List<CounterLog> logs) {
    // Exclude basic initialization log (set to 0 with 0 delta) to clean up log list
    // Sort logs by timestamp descending (newest first)
    final listLogs = logs.where((l) => !(l.actionType == CounterActionType.set && l.delta == 0)).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'History Log',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.2),
        ),
        const SizedBox(height: 12),
        if (listLogs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Center(
              child: Text(
                'No activity logged yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: listLogs.length,
            itemBuilder: (context, index) {
              final log = listLogs[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    _getLogIcon(log.actionType, log.delta),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getLogText(log.actionType, log.delta),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('MMM d, y h:mm a').format(log.timestamp),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Result: ${log.resultingCount}',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _getLogIcon(CounterActionType type, int delta) {
    IconData icon;
    Color color;
    switch (type) {
      case CounterActionType.increment:
        icon = Icons.add_circle_outline_rounded;
        color = Colors.green;
        break;
      case CounterActionType.decrement:
        icon = Icons.remove_circle_outline_rounded;
        color = Colors.orange;
        break;
      case CounterActionType.reset:
        icon = Icons.refresh_rounded;
        color = Colors.red;
        break;
      case CounterActionType.set:
        icon = delta > 0 ? Icons.add_circle_outline_rounded : Icons.edit_note_rounded;
        color = Colors.blue;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  String _getLogText(CounterActionType type, int delta) {
    switch (type) {
      case CounterActionType.increment:
        return 'Incremented (+1)';
      case CounterActionType.decrement:
        return 'Decremented (-1)';
      case CounterActionType.reset:
        return 'Reset count';
      case CounterActionType.set:
        if (delta == 0) return 'Created counter';
        return 'Set value (change of ${delta > 0 ? "+$delta" : "$delta"})';
    }
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
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
