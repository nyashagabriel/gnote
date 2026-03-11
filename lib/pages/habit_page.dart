// ==========================================
// FILE: ./pages/habit_page.dart
// ==========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../services/providers.dart';

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
            GSpacing.pagePadding, GSpacing.md,
            GSpacing.pagePadding, GSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32, height: 4,
                  decoration: BoxDecoration(
                    color: GColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: GSpacing.lg),
              Text(
                hasExisting ? GStrings.habitChangeTitle : GStrings.habitSetTitle,
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
                  filled: true, fillColor: GColors.surfaceHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(GSpacing.inputRadius),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(GSpacing.inputRadius),
                    borderSide: const BorderSide(color: GColors.orange, width: 1.5),
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
          child: habit == null ? _buildEmpty() : _buildActive(habit),
        ),
      ),
    );
  }

  // ── State A: No habit ────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_outlined,
            size: 56,
            color: GColors.textMuted,
          ),
          const SizedBox(height: GSpacing.lg),
          Text(GStrings.habitEmpty, style: GText.subheading, textAlign: TextAlign.center),
          const SizedBox(height: GSpacing.xs),
          Text(GStrings.habitOneAtATime, style: GText.muted, textAlign: TextAlign.center),
          const SizedBox(height: GSpacing.xl),
          ElevatedButton(
            key: const Key('empty_set_habit_button'),
            onPressed: () => _showSetHabitSheet(false),
            child: const Text(GStrings.habitSetBtn),
          ),
        ],
      ),
    );
  }

  // ── States B / C / D: Active, Done, Broken ──────────────────
  Widget _buildActive(habit) {
    final String name      = habit.name;
    final int    streak    = habit.streak;
    final bool   doneToday = habit.doneToday;
    final bool   broken    = !habit.streakAlive && streak > 0;

    final Color streakColor = broken ? GColors.danger : GColors.orange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Page label (quiet) ─────────────────────────────────
        Align(
          alignment: Alignment.centerLeft,
          child: Text(GStrings.habitTitle, style: GText.label.copyWith(fontSize: 14)),
        ),
        const SizedBox(height: GSpacing.xxl),

        // ── STREAK — dominant element ──────────────────────────
        FittedBox(
          fit: BoxFit.scaleDown,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: GText.heading.copyWith(
              fontSize: 96,
              color: streakColor,
              height: 1.0,
              fontWeight: FontWeight.w900,
            ),
            child: Text(
              '$streak',
              key: const Key('habit_streak_text'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Text(
          GStrings.habitStreakLabel,
          style: GText.muted.copyWith(
            fontSize: 13,
            letterSpacing: 2,
            color: streakColor.withAlpha(160),
          ),
        ),
        const SizedBox(height: GSpacing.xxl),

        // ── Habit name ─────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: GSpacing.md,
            vertical: GSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: GColors.surface,
            borderRadius: BorderRadius.circular(GSpacing.cardRadius),
            border: Border.all(
              color: broken
                  ? GColors.danger.withAlpha(120)
                  : doneToday
                      ? GColors.success.withAlpha(120)
                      : GColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                key: const Key('habit_name_text'),
                style: GText.heading.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 4),
              Text(
                doneToday
                    ? GStrings.habitDone
                    : broken
                        ? GStrings.habitMissed
                        : GStrings.habitNotDoneYet,
                key: const Key('habit_status_text'),
                style: GText.muted.copyWith(
                  fontSize: 13,
                  color: doneToday
                      ? GColors.success
                      : broken
                          ? GColors.danger
                          : GColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: GSpacing.lg),

        // ── Check-in button — full width, significant ──────────
        SizedBox(
          width: double.infinity,
          child: doneToday
              ? Container(
                  key: const Key('habit_done_container'),
                  padding: const EdgeInsets.symmetric(vertical: GSpacing.md + 2),
                  decoration: BoxDecoration(
                    color: GColors.successDim,
                    borderRadius: BorderRadius.circular(GSpacing.buttonRadius),
                    border: Border.all(color: GColors.success.withAlpha(102)),
                  ),
                  child: Center(
                    child: Text(
                      GStrings.habitDoneForToday,
                      style: GText.subheading.copyWith(
                        color: GColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              : ElevatedButton(
                  key: const Key('habit_check_in_button'),
                  onPressed: () => ref.read(habitProvider.notifier).markDone(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: broken ? GColors.danger : GColors.orange,
                    foregroundColor: GColors.background,
                    padding: const EdgeInsets.symmetric(vertical: GSpacing.md + 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(GSpacing.buttonRadius),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    broken ? GStrings.habitBeginAgain : GStrings.habitDidItToday,
                    style: GText.subheading.copyWith(
                      color: GColors.background,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
        ),

        const Spacer(),

        // ── Change habit — quiet, present, not prominent ───────
        TextButton(
          key: const Key('change_habit_button'),
          onPressed: () => _showSetHabitSheet(true),
          child: Text(
            GStrings.habitChangeBtn,
            style: GText.muted.copyWith(fontSize: 12),
          ),
        ),
        const SizedBox(height: GSpacing.sm),
      ],
    );
  }
}