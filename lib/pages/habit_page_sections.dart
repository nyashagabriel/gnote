part of 'habit_page.dart';

class _HabitEmptyState extends StatelessWidget {
  const _HabitEmptyState({required this.onSetHabit});

  final VoidCallback onSetHabit;

  @override
  Widget build(BuildContext context) {
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
          Text(
            GStrings.habitEmpty,
            style: GText.subheading,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: GSpacing.xs),
          Text(
            GStrings.habitOneAtATime,
            style: GText.muted,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: GSpacing.xl),
          ElevatedButton(
            key: const Key('empty_set_habit_button'),
            onPressed: onSetHabit,
            child: const Text(GStrings.habitSetBtn),
          ),
        ],
      ),
    );
  }
}

class _HabitActiveState extends StatelessWidget {
  const _HabitActiveState({
    required this.habit,
    required this.onMarkDone,
    required this.onChangeHabit,
  });

  final GHabit habit;
  final VoidCallback onMarkDone;
  final VoidCallback onChangeHabit;

  @override
  Widget build(BuildContext context) {
    final streak = habit.currentStreak;
    final doneToday = habit.doneToday;
    final broken = habit.isBroken;
    final streakColor = broken ? GColors.danger : GColors.orange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            GStrings.habitTitle,
            style: GText.label.copyWith(fontSize: 14),
          ),
        ),
        const SizedBox(height: GSpacing.xxl),
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
                habit.name,
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
        SizedBox(
          width: double.infinity,
          child: doneToday
              ? Container(
                  key: const Key('habit_done_container'),
                  padding:
                      const EdgeInsets.symmetric(vertical: GSpacing.md + 2),
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
                  onPressed: onMarkDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: broken ? GColors.danger : GColors.orange,
                    foregroundColor: GColors.background,
                    padding:
                        const EdgeInsets.symmetric(vertical: GSpacing.md + 2),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(GSpacing.buttonRadius),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    broken
                        ? GStrings.habitBeginAgain
                        : GStrings.habitDidItToday,
                    style: GText.subheading.copyWith(
                      color: GColors.background,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
        ),
        const Spacer(),
        TextButton(
          key: const Key('change_habit_button'),
          onPressed: onChangeHabit,
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
