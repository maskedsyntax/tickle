import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tickle_core/tickle_core.dart';
import '../cubits/counters_cubit.dart';
import '../theme/theme.dart';
import 'bounce_tap.dart';

class CounterFormSheet extends StatefulWidget {
  final Counter? initialCounter;

  const CounterFormSheet({super.key, this.initialCounter});

  @override
  State<CounterFormSheet> createState() => _CounterFormSheetState();
}

class _CounterFormSheetState extends State<CounterFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _goalController;
  
  late String _selectedEmoji;
  late String _selectedColorHex;
  late bool _hasGoal;

  final List<String> _emojiPresets = ['💧', '🏃', '📚', '🧘', '🍎', '☕', '💊', '🔑', '🥦', '💪', '🚿', '💤', '📝', '🤝'];

  @override
  void initState() {
    super.initState();
    final c = widget.initialCounter;
    _titleController = TextEditingController(text: c?.title ?? '');
    _goalController = TextEditingController(text: c?.goalValue?.toString() ?? '');
    _selectedEmoji = c?.emoji ?? '💧';
    _selectedColorHex = c?.colorHex ?? AppColors.presets[0].hex;
    _hasGoal = c?.goalValue != null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditMode = widget.initialCounter != null;

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
                      isEditMode ? 'Edit Counter' : 'New Counter',
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
                  autofocus: !isEditMode,
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
                // Submit Button
                BounceTap(
                  onTap: () {
                    if (_formKey.currentState!.validate()) {
                      final title = _titleController.text.trim();
                      final goalVal = _hasGoal ? int.tryParse(_goalController.text) : null;
                      
                      if (isEditMode) {
                        context.read<CountersCubit>().updateCounter(
                              id: widget.initialCounter!.id,
                              title: title,
                              emoji: _selectedEmoji,
                              colorHex: _selectedColorHex,
                              goalValue: goalVal,
                            );
                      } else {
                        context.read<CountersCubit>().createCounter(
                              title: title,
                              emoji: _selectedEmoji,
                              colorHex: _selectedColorHex,
                              goalValue: goalVal,
                            );
                      }
                      
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
                    child: Text(
                      isEditMode ? 'Save Changes' : 'Create Counter',
                      style: const TextStyle(
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
