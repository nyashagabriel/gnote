// ==========================================
// FILE: ./pages/responsibility_page.dart
// ==========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../core/timezone.dart';
import '../models/person.dart';
import '../services/providers.dart';

part 'responsibility_page_sections.dart';

class ResponsibilityPage extends ConsumerStatefulWidget {
  const ResponsibilityPage({super.key});

  @override
  ConsumerState<ResponsibilityPage> createState() => _ResponsibilityPageState();
}

class _ResponsibilityPageState extends ConsumerState<ResponsibilityPage> {
  Future<void> _sendPerson(GPerson person) async {
    final sent =
        await ref.read(responsibilityProvider.notifier).sendWhatsApp(person);
    if (!mounted || sent) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(GStrings.respSendFailed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(responsibilityProvider);
    final motivators = state.motivators;
    final meditators = state.meditators;
    final pickedMot = state.selectedMotivator;
    final pickedMed = state.selectedMeditator;

    return Scaffold(
      backgroundColor: GColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(GSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(GStrings.respHeader,
                  style: GText.label.copyWith(fontSize: 14)),
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
                      person: p,
                      isPicked: pickedMot?.id == p.id,
                      roleColor: GColors.orange,
                      onSend: () => _sendPerson(p),
                    )),
              const SizedBox(height: GSpacing.sm),
              _PickButton(
                label: GStrings.respPickMotivatorBtn,
                color: GColors.orange,
                onTap: motivators.isEmpty
                    ? null
                    : () => ref
                        .read(responsibilityProvider.notifier)
                        .pickMotivator(),
                picked: pickedMot != null,
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
                      person: p,
                      isPicked: pickedMed?.id == p.id,
                      roleColor: GColors.azure,
                      onSend: () => _sendPerson(p),
                    )),
              const SizedBox(height: GSpacing.sm),
              _PickButton(
                label: GStrings.respPickMeditatorBtn,
                color: GColors.azure,
                onTap: meditators.isEmpty
                    ? null
                    : () => ref
                        .read(responsibilityProvider.notifier)
                        .pickMeditator(),
                picked: pickedMed != null,
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
