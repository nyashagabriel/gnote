import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../core/timezone.dart';
import '../models/anchor.dart';
import '../services/local_db.dart';
import '../services/providers.dart';

// ─────────────────────────────────────────────────────────────────────
// GNOTE — ANCHOR PAGE
//
// v1 changes:
//   - Sun icon removed. The anchor is the focus — no decoration competes.
//   - Orange CircleAvatar replaced with a muted settings icon.
//     Profile access is preserved but de-emphasised.
//     The anchor screen belongs to the user's intent, not the app's chrome.
// ─────────────────────────────────────────────────────────────────────

class AnchorPage extends ConsumerStatefulWidget {
  const AnchorPage({super.key});
  @override
  ConsumerState<AnchorPage> createState() => _AnchorPageState();
}

class _AnchorPageState extends ConsumerState<AnchorPage> {
  final _controller = TextEditingController();

  bool _saving = false;
  bool _restored = false;

  LocalDb get _db => ref.read(localDbProvider);

  @override
  void initState() {
    super.initState();
    _restoreDraft();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _restoreDraft() {
    if (ref.read(anchorProvider) != null) return;

    final savedDate = _db.getDraftDate();
    if (savedDate == null) return;

    final now = localNow();
    final isToday = savedDate.year == now.year &&
        savedDate.month == now.month &&
        savedDate.day == now.day;

    if (!isToday) {
      _db.clearAnchorDraft();
      return;
    }

    final draft = _db.getAnchorDraft();
    if (draft != null && draft.isNotEmpty) {
      _controller.text = draft;
      _controller.selection = TextSelection.collapsed(offset: draft.length);
      _restored = true;
    }
  }

  void _onTextChanged() {
    if (ref.read(anchorProvider) != null) return;

    final text = _controller.text;
    if (text.isEmpty) {
      _db.clearAnchorDraft();
    } else {
      _db.saveAnchorDraft(text);
      _db.saveDraftDate(localNow());
    }
    setState(() {});
  }

  Future<void> _lock() async {
    final text = _controller.text.trim();
    if (text.length < 10) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _saving = true);
    await ref.read(anchorProvider.notifier).lockAnchor(text, user.id);
    await _db.clearAnchorDraft();

    if (mounted) {
      setState(() {
        _saving = false;
        _restored = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final anchor = ref.watch(anchorProvider);
    final isLocked = anchor != null;
    final charCount = _controller.text.trim().length;
    final canLock = charCount >= 10 && !_saving;
    final today = DateFormat('EEEE, d MMMM').format(localNow());

    return Scaffold(
      backgroundColor: GColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(GSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row — label + muted settings icon ───────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(GStrings.anchorHeader,
                      style: GText.label.copyWith(fontSize: 14)),
                  IconButton(
                    onPressed: () => context.push(GRoutes.profile),
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: GColors.textMuted,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Profile & settings',
                  ),
                ],
              ),
              const SizedBox(height: GSpacing.xs),
              Text(today, style: GText.muted),
              const SizedBox(height: GSpacing.xxl),

              // ── Content — no sun icon ───────────────────────────
              if (isLocked) _LockedCard(anchor: anchor),
              if (!isLocked)
                _UnlockedInput(
                  controller: _controller,
                  canLock: canLock,
                  saving: _saving,
                  restored: _restored,
                  onLock: _lock,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedCard extends StatelessWidget {
  const _LockedCard({required this.anchor});
  final GAnchor anchor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(GSpacing.md),
          decoration: BoxDecoration(
            color: GColors.surface,
            borderRadius: BorderRadius.circular(GSpacing.cardRadius),
            border: const Border(
              left: BorderSide(color: GColors.orange, width: 3),
            ),
          ),
          child: Text(
            anchor.content,
            style: GText.body.copyWith(fontSize: 18, height: 1.6),
          ),
        ),
        const SizedBox(height: GSpacing.sm),
        Text(
          '${GStrings.anchorLockedAt}${DateFormat('h:mm a').format(anchor.createdAt)}',
          style: GText.muted.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

class _UnlockedInput extends StatelessWidget {
  const _UnlockedInput({
    required this.controller,
    required this.canLock,
    required this.saving,
    required this.restored,
    required this.onLock,
  });

  final TextEditingController controller;
  final bool canLock;
  final bool saving;
  final bool restored;
  final VoidCallback onLock;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(GStrings.anchorTitle, style: GText.heading),
        const SizedBox(height: GSpacing.xs),
        Text(GStrings.anchorSub, style: GText.muted),
        const SizedBox(height: GSpacing.lg),
        TextField(
          controller: controller,
          style: GText.body,
          maxLines: 3,
          maxLength: GLimits.anchorMaxChars,
          decoration: InputDecoration(
            hintText: GStrings.anchorHint,
            hintStyle: GText.body.copyWith(color: GColors.textDisabled),
            filled: true,
            fillColor: GColors.surface,
            counterStyle: GText.muted.copyWith(fontSize: 10),
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
        const SizedBox(height: GSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canLock ? onLock : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: GColors.orange,
              disabledBackgroundColor: GColors.surfaceHigh,
              foregroundColor: GColors.background,
              padding: const EdgeInsets.symmetric(vertical: GSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(GSpacing.buttonRadius),
              ),
            ),
            child: saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      color: GColors.background,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    GStrings.anchorSave,
                    style: GText.subheading.copyWith(
                      color: GColors.background,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        if (restored)
          Padding(
            padding: const EdgeInsets.only(top: GSpacing.sm),
            child: Center(
              child: Text(
                GStrings.anchorRestored,
                style: GText.muted.copyWith(fontSize: 11),
              ),
            ),
          ),
      ],
    );
  }
}
