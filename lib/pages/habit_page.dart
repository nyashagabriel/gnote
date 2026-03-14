// ==========================================
// FILE: ./pages/habit_page.dart
// ==========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../models/habit.dart';
import '../services/providers.dart';

part 'habit_page_sections.dart';

class HabitPage extends ConsumerStatefulWidget {
  const HabitPage({super.key});
  @override
  ConsumerState<HabitPage> createState() => _HabitPageState();
}

class _HabitPageState extends ConsumerState<HabitPage> {
  final _habitController = TextEditingController();

  @override
  void dispose() {
    _habitController.dispose();
    super.dispose();
  }

  Future<void> _setHabit(String name) async {
    if (name.trim().isEmpty) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref.read(habitProvider.notifier).setHabit(name, user.id);
  }

  void _showSetHabitSheet(bool hasExisting) {
    _habitController.clear();
    showModalBottomSheet(
      context: context,
      backgroundColor: GColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            GSpacing.pagePadding,
            GSpacing.md,
            GSpacing.pagePadding,
            GSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: GColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: GSpacing.lg),
              Text(
                hasExisting
                    ? GStrings.habitChangeTitle
                    : GStrings.habitSetTitle,
                style: GText.label.copyWith(fontSize: 14),
              ),
              const SizedBox(height: GSpacing.xs),
              Text(
                GStrings.habitMakeItCount,
                style: GText.muted,
              ),
              const SizedBox(height: GSpacing.md),
              TextField(
                key: const Key('habit_input_field'),
                controller: _habitController,
                autofocus: true,
                style: GText.body,
                decoration: InputDecoration(
                  hintText: GStrings.habitHint,
                  hintStyle: GText.body.copyWith(color: GColors.textDisabled),
                  filled: true,
                  fillColor: GColors.surfaceHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(GSpacing.inputRadius),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(GSpacing.inputRadius),
                    borderSide:
                        const BorderSide(color: GColors.orange, width: 1.5),
                  ),
                ),
              ),
              if (hasExisting) ...[
                const SizedBox(height: GSpacing.md),
                Container(
                  padding: const EdgeInsets.all(GSpacing.sm),
                  decoration: BoxDecoration(
                    color: GColors.warningDim,
                    borderRadius: BorderRadius.circular(GSpacing.buttonRadius),
                    border: Border.all(color: GColors.warning.withAlpha(102)),
                  ),
                  child: Text(
                    GStrings.habitReplaceWarn,
                    style: GText.muted.copyWith(color: GColors.warning),
                  ),
                ),
              ],
              const SizedBox(height: GSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('save_habit_button'),
                  onPressed: () {
                    Navigator.pop(context);
                    _setHabit(_habitController.text);
                  },
                  child: const Text(GStrings.habitSetBtn),
                ),
              ),
              const SizedBox(height: GSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  key: const Key('cancel_habit_button'),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(GStrings.cancel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habit = ref.watch(habitProvider);
    return Scaffold(
      backgroundColor: GColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(GSpacing.pagePadding),
          child: habit == null
              ? _HabitEmptyState(onSetHabit: () => _showSetHabitSheet(false))
              : _HabitActiveState(
                  habit: habit,
                  onMarkDone: () => ref.read(habitProvider.notifier).markDone(),
                  onChangeHabit: () => _showSetHabitSheet(true),
                ),
        ),
      ),
    );
  }
}
