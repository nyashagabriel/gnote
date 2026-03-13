// ==========================================
// FILE: ./pages/responsibility_page.dart
// ==========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../models/person.dart';
import '../services/providers.dart';

class ResponsibilityPage extends ConsumerWidget {
  const ResponsibilityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state      = ref.watch(responsibilityProvider);
    final motivators = state.motivators;
    final meditators = state.meditators;
    final pickedMot  = state.selectedMotivator;
    final pickedMed  = state.selectedMeditator;

    return Scaffold(
      backgroundColor: GColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(GSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(GStrings.respHeader, style: GText.label.copyWith(fontSize: 14)),
              const SizedBox(height: GSpacing.xs),
              Text(GStrings.respSub, style: GText.muted),
              const SizedBox(height: GSpacing.xl),

              // ── MOTIVATORS ──────────────────────────────────
              _SectionHeader(
                label: GStrings.respMotivatorsHeader,
                count: motivators.length,
                color: GColors.orange,
              ),
              const SizedBox(height: GSpacing.md),
              if (motivators.isEmpty)
                _EmptySection(
                  label: GStrings.respNoMotivators,
                  onAdd: () => context.push(GRoutes.addPerson),
                )
              else
                ...motivators.map((p) => _PersonCard(
                  person:    p,
                  isPicked:  pickedMot?.id == p.id,
                  roleColor: GColors.orange,
                  onSend:    () => ref.read(responsibilityProvider.notifier).sendWhatsApp(p),
                )),
              const SizedBox(height: GSpacing.sm),
              _PickButton(
                label:      GStrings.respPickMotivatorBtn,
                color:      GColors.orange,
                onTap:      motivators.isEmpty ? null : () => ref.read(responsibilityProvider.notifier).pickMotivator(),
                picked:     pickedMot != null,
                pickedName: pickedMot?.name,
              ),
              const SizedBox(height: GSpacing.xl),

              // ── MEDITATORS ──────────────────────────────────
              _SectionHeader(
                label: GStrings.respMeditatorsHeader,
                count: meditators.length,
                color: GColors.azure,
              ),
              const SizedBox(height: GSpacing.md),
              if (meditators.isEmpty)
                _EmptySection(
                  label: GStrings.respNoMeditators,
                  onAdd: () => context.push(GRoutes.addPerson),
                )
              else
                ...meditators.map((p) => _PersonCard(
                  person:    p,
                  isPicked:  pickedMed?.id == p.id,
                  roleColor: GColors.azure,
                  onSend:    () => ref.read(responsibilityProvider.notifier).sendWhatsApp(p),
                )),
              const SizedBox(height: GSpacing.sm),
              _PickButton(
                label:      GStrings.respPickMeditatorBtn,
                color:      GColors.azure,
                onTap:      meditators.isEmpty ? null : () => ref.read(responsibilityProvider.notifier).pickMeditator(),
                picked:     pickedMed != null,
                pickedName: pickedMed?.name,
              ),

              const SizedBox(height: GSpacing.xxl),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(GRoutes.addPerson),
        backgroundColor: GColors.orange,
        child: const Icon(Icons.add, color: GColors.background),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int    count;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GText.label.copyWith(color: color, fontSize: 12)),
        Text('$count${GStrings.respActiveCount}', style: GText.muted),
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.label, required this.onAdd});

  final String        label;
  final VoidCallback  onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GSpacing.sm),
      child: Row(
        children: [
          Text(label, style: GText.muted),
          const Spacer(),
          TextButton(
            onPressed: onAdd,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              GStrings.respAddOne,
              style: GText.muted.copyWith(color: GColors.orange, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.person,
    required this.isPicked,
    required this.roleColor,
    required this.onSend,
  });

  final GPerson      person;
  final bool         isPicked;
  final Color        roleColor;
  final VoidCallback onSend;

  String get _recencyLabel {
    final last = person.lastSelectedAt;
    if (last == null) return GStrings.respNeverPicked;
    final diff = DateTime.now().difference(last).inDays;
    if (diff == 0) return GStrings.respPickedToday;
    if (diff == 1) return GStrings.respLastYesterday;
    return '${GStrings.respLastPrefix}$diff${GStrings.respDaysAgoSuffix}';
  }

  @override
  Widget build(BuildContext context) {
    final initials = person.name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isPicked ? onSend : null,
        borderRadius: BorderRadius.circular(GSpacing.cardRadius),
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: GSpacing.sm),
        padding: const EdgeInsets.all(GSpacing.md),
        decoration: BoxDecoration(
          color: GColors.surface,
          borderRadius: BorderRadius.circular(GSpacing.cardRadius),
          border: Border.all(
            color:  isPicked ? roleColor.withAlpha(200) : GColors.border,
            width:  isPicked ? 1.5 : 1.0,
          ),
          boxShadow: isPicked
              ? [BoxShadow(color: roleColor.withAlpha(50), blurRadius: 12, spreadRadius: 2)]
              : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: roleColor.withAlpha(40),
              child: Text(
                initials,
                style: GText.label.copyWith(color: roleColor, fontSize: 13),
              ),
            ),
            const SizedBox(width: GSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(person.name, style: GText.subheading),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: roleColor.withAlpha(40),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          person.role.toUpperCase(),
                          style: GText.label.copyWith(fontSize: 9, color: roleColor),
                        ),
                      ),
                      const SizedBox(width: GSpacing.sm),
                      Text(
                        _recencyLabel,
                        style: GText.muted.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isPicked)
              Padding(
                padding: const EdgeInsets.only(left: GSpacing.sm),
                child: Icon(Icons.send_rounded, color: roleColor, size: 18),
              ),
          ],
        ),
        ),
      ),
    );
  }
}

class _PickButton extends StatelessWidget {
  const _PickButton({
    required this.label,
    required this.color,
    required this.onTap,
    required this.picked,
    this.pickedName,
  });

  final String        label;
  final Color         color;
  final VoidCallback? onTap;
  final bool          picked;
  final String?       pickedName;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GSpacing.buttonRadius),
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: GSpacing.md),
        decoration: BoxDecoration(
          color: picked ? color.withAlpha(30) : Colors.transparent,
          border: Border.all(
            color: enabled ? color.withAlpha(picked ? 200 : 140) : GColors.border,
            width: picked ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(GSpacing.buttonRadius),
        ),
        child: Center(
          child: Text(
            (picked && pickedName != null)
                ? '${GStrings.respPickedPrefix}$pickedName${GStrings.respPickedSuffix}'
                : label,
            style: GText.label.copyWith(
              fontSize: 12,
              color: enabled ? color : GColors.textMuted,
              letterSpacing: picked ? 0.5 : 1.5,
            ),
          ),
        ),
        ),
      ),
    );
  }
}
