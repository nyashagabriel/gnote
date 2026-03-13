// ==========================================
// FILE: ./pages/daily3_page.dart
// ==========================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../models/task.dart';
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
    final now = DateTime.now();
    if (now.hour >= 9) return null;

    final lockTime = DateTime(now.year, now.month, now.day, 9, 0);
    final diff = lockTime.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);

    if (hours > 0)
      return '${GStrings.daily3LocksIn}${hours}${GStrings.daily3H}${minutes}${GStrings.daily3M}';
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
          padding: const EdgeInsets.all(GSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(GStrings.daily3Header,
                      style: GText.label.copyWith(fontSize: 14)),
                  if (locked)
                    _LockBadge(
                        label: GStrings.daily3Locked, color: GColors.orange)
                  else if (countdown != null)
                    _LockBadge(label: countdown, color: GColors.textMuted),
                ],
              ),
              const SizedBox(height: GSpacing.xs),
              Text(GStrings.daily3Limit, style: GText.muted),
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
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: GSpacing.md),
                  itemBuilder: (context, i) {
                    if (i < tasks.length) {
                      return _TaskCard(
                        task: tasks[i],
                        onToggle: () => ref
                            .read(daily3Provider.notifier)
                            .toggleDone(tasks[i].id),
                      );
                    }
                    return _GhostSlot(
                      label: [
                        GStrings.daily3Slot1,
                        GStrings.daily3Slot2,
                        GStrings.daily3Slot3
                      ][i],
                      locked: locked || (i > 0 && tasks.length < i),
                      onTap: (locked || isFull)
                          ? null
                          : () => context.push(GRoutes.addTask),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: (!locked && !isFull)
          ? FloatingActionButton(
              onPressed: () => context.push(GRoutes.addTask),
              backgroundColor: GColors.orange,
              child: const Icon(Icons.add, color: GColors.background),
            )
          : null,
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

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.onToggle});
  final GTask task;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final catColor =
        GColors.category[task.category.toLowerCase()] ?? GColors.textMuted;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(GSpacing.cardRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(GSpacing.md),
          decoration: BoxDecoration(
            color: task.isDone ? GColors.successDim : GColors.surface,
            borderRadius: BorderRadius.circular(GSpacing.cardRadius),
            border: Border.all(
              color:
                  task.isDone ? GColors.success.withAlpha(80) : GColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                task.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                color: task.isDone ? GColors.success : GColors.textMuted,
                size: 22,
              ),
              const SizedBox(width: GSpacing.md),
              Expanded(
                child: Text(
                  task.what,
                  style: GText.body.copyWith(
                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                    color:
                        task.isDone ? GColors.textMuted : GColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: catColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  task.category.toUpperCase(),
                  style: GText.label.copyWith(fontSize: 9, color: catColor),
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
  const _GhostSlot({required this.label, required this.locked, this.onTap});
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
            padding: const EdgeInsets.all(GSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GSpacing.cardRadius),
              border: Border.all(color: GColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle_outline,
                    color: GColors.textMuted, size: 20),
                const SizedBox(width: GSpacing.sm),
                Text(label, style: GText.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
