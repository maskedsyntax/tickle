import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tickle_core/tickle_core.dart';
import '../cubits/counters_cubit.dart';
import '../cubits/settings_cubit.dart';
import '../theme/theme.dart';
import '../widgets/bounce_tap.dart';
import '../widgets/rapid_count_button.dart';
import '../widgets/counter_form_sheet.dart';
import '../utils/haptic_feedback.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'counter_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isReordering = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        final hapticLevel = settingsState.hapticLevel;
        return Scaffold(
          body: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverAppBar.medium(
                title: const Text('Tickle'),
                actions: [
                  IconButton(
                    icon: Icon(_isReordering ? Icons.done : Icons.sort_rounded),
                    onPressed: () {
                      HapticsHelper.selectionClick(hapticLevel);
                      setState(() {
                        _isReordering = !_isReordering;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 28),
                    onPressed: () {
                      HapticsHelper.selectionClick(hapticLevel);
                      _showAddCounterSheet(context);
                    },
                  ),
                ],
              ),
              BlocBuilder<CountersCubit, CountersState>(
                builder: (context, state) {
                  if (state is CountersLoading) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator.adaptive()),
                    );
                  }

                  if (state is CountersError) {
                    return SliverFillRemaining(
                      child: Center(child: Text('Error: ${state.message}')),
                    );
                  }

                  if (state is CountersLoaded) {
                    final counters = state.activeCounters;

                    if (counters.isEmpty) {
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
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.onetwothree_rounded,
                                  size: 48,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Count anything. Instantly.',
                                style: Theme.of(context).textTheme.titleLarge,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create your first counter to start tracking habits, tasks, or actions.',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              BounceTap(
                                onTap: () => _showAddCounterSheet(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Text(
                                    'Create a Counter',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (_isReordering) {
                      return SliverReorderableList(
                        itemCount: counters.length,
                        onReorder: (oldIndex, newIndex) {
                          context.read<CountersCubit>().reorderCounters(oldIndex, newIndex);
                        },
                        itemBuilder: (context, index) {
                          final counter = counters[index];
                          return Padding(
                            key: ValueKey(counter.id),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                            child: _buildCounterCard(
                              context,
                              counter,
                              hapticLevel,
                              isReorderable: true,
                              reorderIndex: index,
                            ),
                          );
                        },
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final counter = counters[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: _buildCounterCard(context, counter, hapticLevel),
                            );
                          },
                          childCount: counters.length,
                        ),
                      ),
                    );
                  }

                  return const SliverFillRemaining(child: SizedBox.shrink());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCounterCard(
    BuildContext context,
    Counter counter,
    String hapticLevel, {
    bool isReorderable = false,
    int? reorderIndex,
  }) {
    return _CounterCard(
      key: ValueKey('card-${counter.id}'),
      counter: counter,
      hapticLevel: hapticLevel,
      isReorderable: isReorderable,
      reorderIndex: reorderIndex,
      onOpenDetails: () {
        HapticsHelper.selectionClick(hapticLevel);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CounterDetailScreen(counterId: counter.id),
          ),
        );
      },
      onLongPressOptions: () {
        HapticsHelper.selectionClick(hapticLevel);
        _showContextMenu(context, counter, hapticLevel);
      },
      onSlideOptions: () {
        HapticsHelper.selectionClick(hapticLevel);
        _showContextMenu(context, counter, hapticLevel);
      },
    );
  }

  void _showContextMenu(BuildContext context, Counter counter, String hapticLevel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  counter.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildMenuOption(
                  context,
                  icon: Icons.edit_rounded,
                  label: 'Edit Counter',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _showEditCounterSheet(context, counter);
                  },
                ),
                _buildMenuOption(
                  context,
                  icon: Icons.copy_rounded,
                  label: 'Duplicate Counter',
                  color: Colors.teal,
                  onTap: () {
                    Navigator.pop(context);
                    context.read<CountersCubit>().duplicateCounter(counter.id);
                  },
                ),
                _buildMenuOption(
                  context,
                  icon: Icons.archive_outlined,
                  label: 'Archive Counter',
                  color: Colors.grey,
                  onTap: () {
                    Navigator.pop(context);
                    context.read<CountersCubit>().archiveCounter(counter.id);
                  },
                ),
                _buildMenuOption(
                  context,
                  icon: Icons.delete_forever_rounded,
                  label: 'Delete Counter',
                  color: Colors.red,
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(context, counter);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isDestructive ? Colors.red : Theme.of(context).textTheme.bodyLarge?.color,
          fontWeight: isDestructive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      onTap: onTap,
    );
  }

  void _confirmDelete(BuildContext context, Counter counter) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog.adaptive(
          title: Text('Delete "${counter.title}"?'),
          content: const Text(
            'This action is permanent and will delete all the history logs associated with this counter.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<CountersCubit>().deleteCounter(counter.id);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddCounterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const CounterFormSheet();
      },
    );
  }

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
}

class _CounterCard extends StatefulWidget {
  final Counter counter;
  final String hapticLevel;
  final bool isReorderable;
  final int? reorderIndex;
  final VoidCallback onOpenDetails;
  final VoidCallback onLongPressOptions;
  final VoidCallback onSlideOptions;

  const _CounterCard({
    super.key,
    required this.counter,
    required this.hapticLevel,
    required this.isReorderable,
    this.reorderIndex,
    required this.onOpenDetails,
    required this.onLongPressOptions,
    required this.onSlideOptions,
  });

  @override
  State<_CounterCard> createState() => _CounterCardState();
}

class _CounterCardState extends State<_CounterCard> {
  int _rapidDelta = 0;

  @override
  Widget build(BuildContext context) {
    final counter = widget.counter;
    final preset = AppColors.getPresetByHex(counter.colorHex);
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final borderThemeColor = theme.dividerColor;

    final optimisticCount = counter.currentCount + _rapidDelta;
    final isRapid = _rapidDelta != 0;

    final progress = counter.goalValue != null && counter.goalValue! > 0
        ? (optimisticCount / counter.goalValue!).clamp(0.0, 1.0)
        : 0.0;

    final Widget cardContent = Container(
      padding: const EdgeInsets.all(18.0),
      color: cardColor,
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (counter.goalValue != null)
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    color: preset.primary,
                    backgroundColor: preset.primary.withOpacity(0.1),
                  ),
                ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: preset.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  counter.emoji ?? '🔢',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  counter.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (counter.goalValue != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Goal: $optimisticCount / ${counter.goalValue}',
                    style: TextStyle(
                      fontSize: 13,
                      color: progress >= 1.0
                          ? preset.secondary
                          : theme.textTheme.bodyMedium?.color,
                      fontWeight: progress >= 1.0
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$optimisticCount',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: preset.primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (isRapid)
                    Text(
                      _rapidDelta > 0 ? '+$_rapidDelta' : '$_rapidDelta',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: preset.primary.withOpacity(0.75),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    )
                  else if (counter.goalValue != null)
                    Text(
                      '${(progress * 100).round()}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: preset.primary.withOpacity(0.5),
                      ),
                    ),
                ],
              ),
              if (widget.isReorderable) ...[
                const SizedBox(width: 4),
                ReorderableDragStartListener(
                  index: widget.reorderIndex ?? 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 14,
                    ),
                    child: const Icon(
                      Icons.drag_indicator_rounded,
                      color: Colors.grey,
                      size: 26,
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(width: 12),
                RapidCountButton(
                  hapticLevel: widget.hapticLevel,
                  onTap: () {
                    HapticsHelper.trigger(widget.hapticLevel);
                    context
                        .read<CountersCubit>()
                        .incrementCounter(counter.id);
                  },
                  onTick: (delta) {
                    setState(() {
                      _rapidDelta = delta;
                    });
                  },
                  onCommit: (delta) {
                    context
                        .read<CountersCubit>()
                        .incrementCounterBy(counter.id, delta);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: preset.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: preset.primary,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (widget.isReorderable) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderThemeColor, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: cardContent,
        ),
      );
    }

    final goalSuffix = counter.goalValue != null
        ? ', goal $optimisticCount of ${counter.goalValue}'
        : '';

    final interactiveCard = Semantics(
      button: true,
      label: '${counter.title}, count $optimisticCount$goalSuffix',
      hint: 'Tap to view details, swipe for options',
      excludeSemantics: true,
      child: BounceTap(
        onTap: widget.onOpenDetails,
        onLongPress: widget.onLongPressOptions,
        child: cardContent,
      ),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderThemeColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Slidable(
          key: ValueKey(counter.id),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.25,
            children: [
              SlidableAction(
                onPressed: (_) => widget.onSlideOptions(),
                backgroundColor: theme.brightness == Brightness.dark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFE5E5EA),
                foregroundColor:
                    theme.textTheme.bodyLarge?.color ?? Colors.black,
                icon: Icons.more_horiz_rounded,
                label: 'Options',
              ),
            ],
          ),
          child: interactiveCard,
        ),
      ),
    );
  }
}
