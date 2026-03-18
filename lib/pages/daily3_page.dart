import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../core/timezone.dart';
import '../models/task.dart';
import 'add_tasks.dart';
import '../services/providers.dart';

class Daily3Page extends ConsumerStatefulWidget {
  const Daily3Page({super.key});

  @override
  ConsumerState<Daily3Page> createState() => _Daily3PageState();
}

class _Daily3PageState extends ConsumerState<Daily3Page> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String? _countdown() {
    final now = localNow();
    if (now.hour >= 9) return null;

    final lockTime = DateTime(now.year, now.month, now.day, 9, 0);
    final diff = lockTime.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);

    if (hours > 0) {
      return '${GStrings.daily3LocksIn}${hours}${GStrings.daily3H}${minutes}${GStrings.daily3M}';
    }
    return '${GStrings.daily3LocksIn}${minutes}${GStrings.daily3M}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(daily3Provider);
    final locked = state.locked;
    final isFull = state.isFull;
    final allDone = state.allDone;
    final tasks = state.tasks;
    final countdown = _countdown();

    return Scaffold(
      backgroundColor: GColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            GSpacing.pagePadding,
            GSpacing.pagePadding,
            GSpacing.pagePadding,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Daily3Header(
                locked: locked,
                countdown: countdown,
                doneCount: state.doneCount,
              ),
              const SizedBox(height: GSpacing.xl),
              if (allDone)
                Padding(
                  padding: const EdgeInsets.only(bottom: GSpacing.lg),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(GSpacing.md),
                    decoration: BoxDecoration(
                      color: GColors.successDim,
                      borderRadius: BorderRadius.circular(GSpacing.cardRadius),
                      border: Border.all(color: GColors.success.withAlpha(80)),
                    ),
                    child: Text(
                      GStrings.daily3Done,
                      style: GText.subheading.copyWith(color: GColors.success),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  itemCount: 3,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: GSpacing.md),
                  itemBuilder: (context, i) {
                    if (i < tasks.length) {
                      return _TaskCard(
                        index: i + 1,
                        task: tasks[i],
                        onToggle: () => ref
                            .read(daily3Provider.notifier)
                            .toggleDone(tasks[i].id),
                      );
                    }
                    return _GhostSlot(
                      index: i + 1,
                      label: [
                        GStrings.daily3Slot1,
                        GStrings.daily3Slot2,
                        GStrings.daily3Slot3,
                      ][i],
                      locked: locked || (i > 0 && tasks.length < i),
                      onTap: (locked || isFull)
                          ? null
                          : () => showAddTaskSheet(context),
                    );
                  },
                ),
              ),
              if (!locked && !isFull)
                Padding(
                  padding: const EdgeInsets.only(
                    top: GSpacing.md,
                    bottom: GSpacing.pagePadding,
                  ),
                  child: _BottomActionShell(
                    label: GStrings.daily3Add,
                    onTap: () => showAddTaskSheet(context),
                  ),
                )
              else
                const SizedBox(height: GSpacing.pagePadding),
            ],
          ),
        ),
      ),
    );
  }
}

class _Daily3Header extends StatelessWidget {
  const _Daily3Header({
    required this.locked,
    required this.countdown,
    required this.doneCount,
  });

  final bool locked;
  final String? countdown;
  final int doneCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GSpacing.lg),
      decoration: BoxDecoration(
        color: GColors.surface,
        borderRadius: BorderRadius.circular(GSpacing.cardRadius),
        border: Border.all(color: GColors.border.withAlpha(140)),
        boxShadow: [
          BoxShadow(
            color: GColors.orange.withAlpha(14),
            blurRadius: 24,
            spreadRadius: -6,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      GStrings.daily3Header,
                      style: GText.label.copyWith(
                        fontSize: 11,
                        color: GColors.orange,
                      ),
                    ),
                    const SizedBox(height: GSpacing.sm),
                    Text(
                      GStrings.daily3Limit,
                      style: GText.heading.copyWith(
                        fontSize: 30,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: GSpacing.sm),
                    Text(
                      '$doneCount of 3 complete',
                      style: GText.muted.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
              if (locked)
                _LockBadge(label: GStrings.daily3Locked, color: GColors.orange)
              else if (countdown != null)
                _LockBadge(label: countdown!, color: GColors.textMuted),
            ],
          ),
          const SizedBox(height: GSpacing.lg),
          Text(
            GStrings.daily3Sub,
            style: GText.muted.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _LockBadge extends StatelessWidget {
  const _LockBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: GSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: GText.label.copyWith(fontSize: 10, color: color),
      ),
    );
  }
}

// ── _TaskCard — category chip removed ────────────────────────────────
// Category is kept in the model and synced to Supabase.
// It is simply no longer surfaced in the UI for v1.
// This makes Daily 3 a pure forcing function: what + done-when + deadline.
// ─────────────────────────────────────────────────────────────────────
class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.index,
    required this.task,
    required this.onToggle,
  });

  final int index;
  final GTask task;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(GSpacing.cardRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(GSpacing.lg),
          decoration: BoxDecoration(
            color: task.isDone ? GColors.successDim : GColors.surface,
            borderRadius: BorderRadius.circular(GSpacing.cardRadius),
            border: Border.all(
              color:
                  task.isDone ? GColors.success.withAlpha(80) : GColors.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                task.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                color: task.isDone ? GColors.success : GColors.textMuted,
                size: 22,
              ),
              const SizedBox(width: GSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task $index',
                      style: GText.label.copyWith(
                        fontSize: 10,
                        color: task.isDone ? GColors.success : GColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: GSpacing.sm),
                    Text(
                      task.what,
                      style: GText.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration:
                            task.isDone ? TextDecoration.lineThrough : null,
                        color: task.isDone
                            ? GColors.textMuted
                            : GColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: GSpacing.sm),
                    Text(
                      task.doneWhen,
                      style: GText.muted.copyWith(
                        color: task.isDone
                            ? GColors.textDisabled
                            : GColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: GSpacing.sm),
                    Text(
                      'Due ${_formatDue(task.by)}',
                      style: GText.label.copyWith(
                        fontSize: 10,
                        color: task.isDone ? GColors.textDisabled : GColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GhostSlot extends StatelessWidget {
  const _GhostSlot({
    required this.index,
    required this.label,
    required this.locked,
    this.onTap,
  });

  final int index;
  final String label;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GSpacing.cardRadius),
        child: AnimatedOpacity(
          opacity: locked ? 0.35 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.all(GSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GSpacing.cardRadius),
              border: Border.all(
                color: GColors.border,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task $index',
                  style: GText.label.copyWith(fontSize: 10),
                ),
                const SizedBox(height: GSpacing.md),
                Row(
                  children: [
                    const Icon(Icons.add_circle_outline,
                        color: GColors.textMuted, size: 20),
                    const SizedBox(width: GSpacing.sm),
                    Expanded(child: Text(label, style: GText.muted)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomActionShell extends StatelessWidget {
  const _BottomActionShell({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GSpacing.sm),
      decoration: BoxDecoration(
        color: GColors.surface,
        borderRadius: BorderRadius.circular(GSpacing.cardRadius),
        border: Border.all(color: GColors.border),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.add, size: 18),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      ),
    );
  }
}

String _formatDue(DateTime by) {
  final hour = by.hour % 12 == 0 ? 12 : by.hour % 12;
  final minute = by.minute.toString().padLeft(2, '0');
  final suffix = by.hour >= 12 ? 'PM' : 'AM';
  return '${by.day}/${by.month} · $hour:$minute $suffix';
}
