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
// v3 changes (Premium UI Upgrade - Corrected Palette):
//   - Consolidated welcome header inspired by high-end dashboard UI.
//   - Dynamic time-of-day greeting to make the UI welcoming.
//   - Intent-driven progress indicator replacing bloated stat grids.
//   - Strict adherence to existing GColors.orange palette.
//   - Zero data or logic mutation.
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
    final today = DateFormat('EEE d MMM').format(localNow());
    final yesterday = localNow().subtract(const Duration(days: 1));
    final yesterdayAnchor = _db
        .getAllAnchors()
        .where((entry) => isSameLocalDay(asLocal(entry.date), yesterday))
        .firstOrNull;

    return Scaffold(
      backgroundColor: GColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: GSpacing.pagePadding,
            vertical: GSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PageHeader(dateText: today),
              SizedBox(height: isLocked ? GSpacing.md : GSpacing.lg),
              if (!isLocked) ...[
                Text(
                  GStrings.anchorTitle,
                  style: GText.heading.copyWith(
                    fontSize: 34,
                    height: 1.04,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.1,
                  ),
                ),
                const SizedBox(height: GSpacing.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    GStrings.anchorSub,
                    style: GText.body.copyWith(
                      fontSize: 15,
                      color: GColors.textMuted.withAlpha(220),
                    ),
                  ),
                ),
                const SizedBox(height: GSpacing.xl),
              ],

              if (isLocked) _LockedCard(anchor: anchor),
              if (!isLocked)
                _UnlockedInput(
                  controller: _controller,
                  canLock: canLock,
                  saving: _saving,
                  restored: _restored,
                  charCount: charCount,
                  onLock: _lock,
                ),
              if (yesterdayAnchor != null) ...[
                const SizedBox(height: GSpacing.xxl),
                _YesterdayAnchorCard(anchor: yesterdayAnchor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.dateText});

  final String dateText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          GStrings.anchorHeader,
          style: GText.label.copyWith(
            fontSize: 11,
            color: GColors.textMuted.withAlpha(190),
            letterSpacing: 2.6,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dateText,
              style: GText.muted.copyWith(
                fontSize: 12,
                color: GColors.textMuted.withAlpha(200),
              ),
            ),
            const SizedBox(width: GSpacing.sm),
            Material(
              color: GColors.surface.withAlpha(180),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: () => context.push(GRoutes.profile),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: GColors.border.withAlpha(170),
                    ),
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    color: GColors.textPrimary,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LockedCard extends StatelessWidget {
  const _LockedCard({required this.anchor});
  final GAnchor anchor;

  @override
  Widget build(BuildContext context) {
    final lockedAt = DateFormat('h:mm a').format(anchor.createdAt);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        GSpacing.md,
        GSpacing.sm,
        GSpacing.md,
        GSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(GSpacing.cardRadius),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: -10,
            child: Text(
              '“',
              style: GText.heading.copyWith(
                fontSize: 72,
                height: 0.9,
                fontWeight: FontWeight.w700,
                color: GColors.orange.withAlpha(72),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 26, top: 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  GStrings.anchorLockedLabel.toUpperCase(),
                  style: GText.label.copyWith(
                    fontSize: 10,
                    letterSpacing: 2.2,
                    color: GColors.textMuted.withAlpha(190),
                  ),
                ),
                const SizedBox(height: GSpacing.md),
                Text(
                  anchor.content,
                  style: GText.heading.copyWith(
                    fontSize: 24,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    color: GColors.textPrimary,
                  ),
                ),
                const SizedBox(height: GSpacing.lg),
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 3,
                      decoration: BoxDecoration(
                        color: GColors.orange,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: GSpacing.sm),
                    Flexible(
                      child: Text(
                        '${GStrings.anchorLockedLabel} · $lockedAt',
                        style: GText.muted.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: GColors.orange.withAlpha(210),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlockedInput extends StatelessWidget {
  const _UnlockedInput({
    required this.controller,
    required this.canLock,
    required this.saving,
    required this.restored,
    required this.charCount,
    required this.onLock,
  });

  final TextEditingController controller;
  final bool canLock;
  final bool saving;
  final bool restored;
  final int charCount;
  final VoidCallback onLock;

  @override
  Widget build(BuildContext context) {
    final showCount = charCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          style: GText.body.copyWith(
            fontSize: 17,
            height: 1.55,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 5,
          minLines: 5,
          maxLength: GLimits.anchorMaxChars,
          decoration: InputDecoration(
            hintText: GStrings.anchorHint,
            hintStyle: GText.body.copyWith(
              color: GColors.textMuted,
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
            filled: true,
            fillColor: GColors.surface.withAlpha(120),
            counterText: '',
            contentPadding: const EdgeInsets.all(GSpacing.lg),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: GColors.border.withAlpha(170),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: GColors.border.withAlpha(170),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: GColors.orange.withAlpha(160),
                width: 1.4,
              ),
            ),
          ),
        ),
        const SizedBox(height: GSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (restored)
              Text(
                GStrings.anchorRestored,
                style: GText.muted.copyWith(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              const SizedBox.shrink(),
            AnimatedOpacity(
              opacity: showCount ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                '$charCount / ${GLimits.anchorMaxChars}',
                style: GText.muted.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: GSpacing.xl),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: canLock ? onLock : null,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: GColors.orange,
              disabledBackgroundColor: Colors.white.withAlpha(110),
              foregroundColor: GColors.background,
              disabledForegroundColor: GColors.background.withAlpha(180),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: GColors.background,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    GStrings.anchorSave,
                    style: GText.subheading.copyWith(
                      color: GColors.background,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _YesterdayAnchorCard extends StatelessWidget {
  const _YesterdayAnchorCard({required this.anchor});

  final GAnchor anchor;

  @override
  Widget build(BuildContext context) {
    final lockedAt = DateFormat('h:mm a').format(anchor.createdAt);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GSpacing.lg),
      decoration: BoxDecoration(
        color: GColors.surface.withAlpha(120),
        borderRadius: BorderRadius.circular(GSpacing.cardRadius),
        border: Border.all(
          color: GColors.border.withAlpha(70),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YESTERDAY',
                style: GText.label.copyWith(
                  fontSize: 10,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w600,
                  color: GColors.textMuted.withAlpha(170),
                ),
              ),
              Text(
                DateFormat('EEE d MMM').format(anchor.date),
                style: GText.muted.copyWith(
                  fontSize: 11,
                  color: GColors.textMuted.withAlpha(150),
                ),
              ),
            ],
          ),
          const SizedBox(height: GSpacing.md),
          Text(
            anchor.content,
            style: GText.body.copyWith(
              fontSize: 15,
              height: 1.6,
              color: GColors.textPrimary.withAlpha(132),
            ),
          ),
          const SizedBox(height: GSpacing.md),
          Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 12,
                color: GColors.textMuted.withAlpha(145),
              ),
              const SizedBox(width: GSpacing.xs),
              Text(
                '${GStrings.anchorLockedAt}$lockedAt',
                style: GText.muted.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: GColors.textMuted.withAlpha(145),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
