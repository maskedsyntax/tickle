import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tickle_core/tickle_core.dart';
import '../cubits/settings_cubit.dart';
import '../cubits/counters_cubit.dart';
import '../theme/theme.dart';
import '../widgets/bounce_tap.dart';
import '../utils/haptic_feedback.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsCubit = context.read<SettingsCubit>();
    final countersCubit = context.read<CountersCubit>();
    final repo = RepositoryProvider.of<CountersRepository>(context);

    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          const SliverAppBar.medium(
            title: Text('Settings'),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Theme Selection
                _buildSectionHeader('Appearance'),
                _buildThemeSelector(context, settingsCubit),
                const SizedBox(height: 28),

                // Haptics Selection
                _buildSectionHeader('Haptics & Tactile Feel'),
                _buildHapticsSelector(context, settingsCubit),
                const SizedBox(height: 28),

                // Data Backup Section
                _buildSectionHeader('Data Portability'),
                _buildBackupCard(context, repo, countersCubit),
                const SizedBox(height: 28),

                // Archived Counters Section
                _buildSectionHeader('Archived Counters'),
                _buildArchivedCountersList(context, countersCubit),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, SettingsCubit settingsCubit) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: [
              _buildSelectorRow(
                context,
                title: 'System Default',
                isSelected: state.themeMode == ThemeMode.system,
                icon: Icons.brightness_auto_rounded,
                onTap: () {
                  HapticsHelper.selectionClick(state.hapticLevel);
                  settingsCubit.updateThemeMode(ThemeMode.system);
                },
              ),
              _buildDivider(context),
              _buildSelectorRow(
                context,
                title: 'Light Mode',
                isSelected: state.themeMode == ThemeMode.light,
                icon: Icons.light_mode_rounded,
                onTap: () {
                  HapticsHelper.selectionClick(state.hapticLevel);
                  settingsCubit.updateThemeMode(ThemeMode.light);
                },
              ),
              _buildDivider(context),
              _buildSelectorRow(
                context,
                title: 'Dark Mode',
                isSelected: state.themeMode == ThemeMode.dark,
                icon: Icons.dark_mode_rounded,
                onTap: () {
                  HapticsHelper.selectionClick(state.hapticLevel);
                  settingsCubit.updateThemeMode(ThemeMode.dark);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHapticsSelector(BuildContext context, SettingsCubit settingsCubit) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: [
              _buildSelectorRow(
                context,
                title: 'Off',
                isSelected: state.hapticLevel == 'off',
                icon: Icons.volume_mute_rounded,
                onTap: () {
                  settingsCubit.updateHapticLevel('off');
                },
              ),
              _buildDivider(context),
              _buildSelectorRow(
                context,
                title: 'Light Tap',
                isSelected: state.hapticLevel == 'light',
                icon: Icons.vibration_rounded,
                onTap: () {
                  HapticsHelper.trigger('light');
                  settingsCubit.updateHapticLevel('light');
                },
              ),
              _buildDivider(context),
              _buildSelectorRow(
                context,
                title: 'Medium Click',
                isSelected: state.hapticLevel == 'medium',
                icon: Icons.vibration_rounded,
                onTap: () {
                  HapticsHelper.trigger('medium');
                  settingsCubit.updateHapticLevel('medium');
                },
              ),
              _buildDivider(context),
              _buildSelectorRow(
                context,
                title: 'Heavy Thud',
                isSelected: state.hapticLevel == 'heavy',
                icon: Icons.vibration_rounded,
                onTap: () {
                  HapticsHelper.trigger('heavy');
                  settingsCubit.updateHapticLevel('heavy');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectorRow(
    BuildContext context, {
    required String title,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: Theme.of(context).primaryColor)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor);
  }

  Widget _buildBackupCard(
    BuildContext context,
    CountersRepository repo,
    CountersCubit countersCubit,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.copy_all_rounded, color: Colors.blue),
            title: const Text('Export Backup to Clipboard'),
            subtitle: const Text('Copies a full JSON backup of all counters & logs'),
            onTap: () async {
              HapticsHelper.selectionClick(context.read<SettingsCubit>().state.hapticLevel);
              await _exportBackup(context, repo);
            },
          ),
          _buildDivider(context),
          ListTile(
            leading: const Icon(Icons.download_rounded, color: Colors.green),
            title: const Text('Import Backup from Clipboard'),
            subtitle: const Text('Restore all counters and logs from clipboard JSON'),
            onTap: () async {
              HapticsHelper.selectionClick(context.read<SettingsCubit>().state.hapticLevel);
              await _importBackup(context, repo, countersCubit);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context, CountersRepository repo) async {
    try {
      final counters = await repo.getCounters(includeArchived: true);
      final logs = await repo.getAllLogs();

      final backupData = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'counters': counters.map((c) => {
          'id': c.id,
          'title': c.title,
          'emoji': c.emoji,
          'colorHex': c.colorHex,
          'currentCount': c.currentCount,
          'goalValue': c.goalValue,
          'isArchived': c.isArchived,
          'createdAt': c.createdAt.toIso8601String(),
          'sortOrder': c.sortOrder,
        }).toList(),
        'logs': logs.map((l) => {
          'id': l.id,
          'counterId': l.counterId,
          'timestamp': l.timestamp.toIso8601String(),
          'actionType': l.actionType.toJson(),
          'delta': l.delta,
          'resultingCount': l.resultingCount,
        }).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      await Clipboard.setData(ClipboardData(text: jsonString));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Backup JSON copied to clipboard! Share it to save your data.'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importBackup(
    BuildContext context,
    CountersRepository repo,
    CountersCubit countersCubit,
  ) async {
    try {
      final clipData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipData == null || clipData.text == null || clipData.text!.trim().isEmpty) {
        throw Exception('Clipboard is empty. Copy backup JSON first.');
      }

      final dynamic data = json.decode(clipData.text!);
      if (data is! Map || data['counters'] == null || data['logs'] == null) {
        throw Exception('Invalid backup format. Make sure you copied a Tickle backup JSON.');
      }

      // Show confirmation
      if (context.mounted) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (diagContext) => AlertDialog.adaptive(
            title: const Text('Import Backup?'),
            content: const Text(
              'Importing this backup will overwrite existing database records. Do you wish to proceed?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(diagContext, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(diagContext, true),
                child: const Text('Import', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );

        if (confirm != true) return;

        // Perform Import
        final List<dynamic> jsonCounters = data['counters'];
        final List<dynamic> jsonLogs = data['logs'];

        // Write to repo
        for (final item in jsonCounters) {
          final c = Counter(
            id: item['id'],
            title: item['title'],
            emoji: item['emoji'],
            colorHex: item['colorHex'],
            currentCount: item['currentCount'],
            goalValue: item['goalValue'],
            isArchived: item['isArchived'] ?? false,
            createdAt: DateTime.parse(item['createdAt']),
            sortOrder: item['sortOrder'] ?? 0,
          );
          await repo.saveCounter(c);
        }

        for (final item in jsonLogs) {
          final l = CounterLog(
            id: item['id'],
            counterId: item['counterId'],
            timestamp: DateTime.parse(item['timestamp']),
            actionType: CounterActionType.fromJson(item['actionType']),
            delta: item['delta'],
            resultingCount: item['resultingCount'],
          );
          await repo.addLog(l);
        }

        // Reload UI cubit
        countersCubit.loadCounters();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Backup successfully imported!'),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (errContext) => AlertDialog.adaptive(
            title: const Text('Import Failed'),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(errContext),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildArchivedCountersList(BuildContext context, CountersCubit countersCubit) {
    return BlocBuilder<CountersCubit, CountersState>(
      builder: (context, state) {
        if (state is CountersLoaded) {
          final archived = state.archivedCounters;
          if (archived.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: const Center(
                child: Text(
                  'No archived counters.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: archived.length,
              itemBuilder: (context, index) {
                final counter = archived[index];
                return Column(
                  children: [
                    if (index > 0) _buildDivider(context),
                    ListTile(
                      leading: Text(counter.emoji ?? '🔢', style: const TextStyle(fontSize: 22)),
                      title: Text(counter.title),
                      subtitle: Text('Count: ${counter.currentCount}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.unarchive_outlined, color: Colors.green),
                            tooltip: 'Restore',
                            onPressed: () {
                              countersCubit.restoreCounter(counter.id);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                            tooltip: 'Delete',
                            onPressed: () {
                              _confirmDelete(context, counter, countersCubit);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _confirmDelete(BuildContext context, Counter counter, CountersCubit countersCubit) {
    showDialog(
      context: context,
      builder: (diagContext) => AlertDialog.adaptive(
        title: Text('Delete "${counter.title}"?'),
        content: const Text(
          'This will permanently delete the counter and all its logs. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(diagContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(diagContext);
              countersCubit.deleteCounter(counter.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
