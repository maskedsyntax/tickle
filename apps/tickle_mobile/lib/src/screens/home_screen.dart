import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tickle_core/tickle_core.dart';
import '../cubits/counters_cubit.dart';
import '../cubits/counter_detail_cubit.dart';
import '../cubits/settings_cubit.dart';
import '../theme/theme.dart';
import '../widgets/bounce_tap.dart';
import '../utils/haptic_feedback.dart';
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
                          return ReorderableDelayedDragStartListener(
                            key: ValueKey(counter.id),
                            index: index,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                              child: _buildCounterCard(context, counter, hapticLevel, isReorderable: true),
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
  }) {
    final preset = AppColors.getPresetByHex(counter.colorHex);
    final cardColor = Theme.of(context).cardColor;
    final borderThemeColor = Theme.of(context).dividerColor;

    final progress = counter.goalValue != null && counter.goalValue! > 0
        ? (counter.currentCount / counter.goalValue!).clamp(0.0, 1.0)
        : 0.0;

    Widget cardBody = Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: cardColor,
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
      child: Row(
        children: [
          // Emoji badge with goal progress outer ring
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
          // Title & Goal
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
                    'Goal: ${counter.currentCount} / ${counter.goalValue}',
                    style: TextStyle(
                      fontSize: 13,
                      color: progress >= 1.0 ? preset.secondary : Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: progress >= 1.0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Count Number
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${counter.currentCount}',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: preset.primary,
                    ),
                  ),
                  if (counter.goalValue != null)
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
              if (isReorderable) ...[
                const SizedBox(width: 12),
                const Icon(Icons.menu_rounded, color: Colors.grey),
              ] else ...[
                const SizedBox(width: 8),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.withOpacity(0.5),
                    size: 24,
                  ),
                  onPressed: () {
                    HapticsHelper.selectionClick(hapticLevel);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CounterDetailScreen(counterId: counter.id),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (isReorderable) {
      return cardBody;
    }

    final goalSuffix = counter.goalValue != null
        ? ', goal ${counter.currentCount} of ${counter.goalValue}'
        : '';
    return Semantics(
      button: true,
      label: '${counter.title}, count ${counter.currentCount}$goalSuffix',
      hint: 'Double tap to increment, long press for options',
      excludeSemantics: true,
      child: BounceTap(
        onTap: () {
          HapticsHelper.trigger(hapticLevel);
          // Direct tap on card increments the count
          context.read<CountersCubit>().incrementCounter(counter.id);
        },
        onLongPress: () {
          HapticsHelper.selectionClick(hapticLevel);
          _showContextMenu(context, counter, hapticLevel);
        },
        child: cardBody,
      ),
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
                  icon: Icons.bar_chart_rounded,
                  label: 'View History & Details',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CounterDetailScreen(counterId: counter.id),
                      ),
                    );
                  },
                ),
                _buildMenuOption(
                  context,
                  icon: Icons.remove_rounded,
                  label: 'Decrement (-1)',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    HapticsHelper.trigger(hapticLevel);
                    context.read<CountersCubit>().decrementCounter(counter.id);
                  },
                ),
                _buildMenuOption(
                  context,
                  icon: Icons.refresh_rounded,
                  label: 'Reset to 0',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    HapticsHelper.trigger(hapticLevel);
                    context.read<CountersCubit>().resetCounter(counter.id);
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
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const AddCounterSheet();
      },
    );
  }
}

class AddCounterSheet extends StatefulWidget {
  const AddCounterSheet({super.key});

  @override
  State<AddCounterSheet> createState() => _AddCounterSheetState();
}

class _AddCounterSheetState extends State<AddCounterSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _goalController = TextEditingController();
  
  String _selectedEmoji = '💧';
  String _selectedColorHex = AppColors.presets[0].hex;
  bool _hasGoal = false;

  final List<String> _emojiPresets = ['💧', '🏃', '📚', '🧘', '🍎', '☕', '💊', '🔑', '🥦', '💪', '🚿', '💤', '📝', '🤝'];

  @override
  void dispose() {
    _titleController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: 20 + bottomInset,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'New Counter',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Title Field
                TextFormField(
                  controller: _titleController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g. Water Intake, Pushups',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Emoji Grid
                const Text(
                  'Select Emoji / Icon',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _emojiPresets.length,
                    itemBuilder: (context, index) {
                      final emoji = _emojiPresets[index];
                      final isSelected = _selectedEmoji == emoji;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedEmoji = emoji;
                          });
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).primaryColor.withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // Color Presets
                const Text(
                  'Select Color Theme',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: AppColors.presets.length,
                    itemBuilder: (context, index) {
                      final preset = AppColors.presets[index];
                      final isSelected = _selectedColorHex == preset.hex;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColorHex = preset.hex;
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: preset.primary,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                                    width: 3,
                                  )
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // Optional Goal Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Set a Daily/Session Goal',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    Switch.adaptive(
                      value: _hasGoal,
                      onChanged: (val) {
                        setState(() {
                          _hasGoal = val;
                        });
                      },
                    ),
                  ],
                ),
                if (_hasGoal) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _goalController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Goal Value',
                      hintText: 'e.g. 10',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (value) {
                      if (_hasGoal) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a goal value';
                        }
                        final num = int.tryParse(value);
                        if (num == null || num <= 0) {
                          return 'Please enter a number greater than 0';
                        }
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 32),
                // Create Button
                BounceTap(
                  onTap: () {
                    if (_formKey.currentState!.validate()) {
                      final title = _titleController.text.trim();
                      final goalVal = _hasGoal ? int.tryParse(_goalController.text) : null;
                      
                      context.read<CountersCubit>().createCounter(
                            title: title,
                            emoji: _selectedEmoji,
                            colorHex: _selectedColorHex,
                            goalValue: goalVal,
                          );
                      
                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Create Counter',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
