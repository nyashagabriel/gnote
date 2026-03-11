// ==========================================
// FILE: ./pages/capture_page.dart
// ==========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../services/providers.dart';

class CapturePage extends ConsumerStatefulWidget {
  const CapturePage({super.key});
  @override
  ConsumerState<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends ConsumerState<CapturePage> {
  final _controller = TextEditingController();

  bool get _isSunday => DateTime.now().weekday == DateTime.sunday;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref.read(captureProvider.notifier).addItem(text, user.id);
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(captureProvider);
    return Scaffold(
      backgroundColor: GColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                GSpacing.pagePadding,
                GSpacing.pagePadding,
                GSpacing.pagePadding,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(GStrings.captureHeader, style: GText.label.copyWith(fontSize: 14)),
                      if (items.isNotEmpty)
                        IconButton(
                          onPressed: () =>
                              ref.read(captureProvider.notifier).shareList(),
                          icon: const Icon(Icons.share,
                              color: GColors.textMuted, size: 20),
                          padding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                  if (_isSunday) ...[
                    const SizedBox(height: GSpacing.sm),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: GSpacing.md,
                        vertical: GSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: GColors.azureDim,
                        borderRadius:
                            BorderRadius.circular(GSpacing.cardRadius),
                        border: Border.all(
                            color: GColors.azure.withAlpha(80)),
                      ),
                      child: Text(
                        GStrings.captureReviewMsg,
                        style: GText.muted
                            .copyWith(color: GColors.azure, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
                child: items.isEmpty ? _buildEmpty() : _buildList(items)),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(GSpacing.xl),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GColors.surface,
              border: Border.all(color: GColors.border),
            ),
            child: const Icon(Icons.inbox_outlined,
                size: 48, color: GColors.textMuted),
          ),
          const SizedBox(height: GSpacing.lg),
          Text(GStrings.captureEmpty,
              style: GText.subheading, textAlign: TextAlign.center),
          const SizedBox(height: GSpacing.xs),
          Text(GStrings.captureEmptySub,
              style: GText.muted, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildList(List items) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
          horizontal: GSpacing.pagePadding, vertical: GSpacing.md),
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const Divider(color: GColors.border, height: 1),
      itemBuilder: (context, i) {
        final item = items[i];
        return Dismissible(
          key: Key(item.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) =>
              ref.read(captureProvider.notifier).deleteItem(item.id),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: GSpacing.md),
            color: GColors.dangerDim,
            child: const Icon(Icons.delete_outline, color: GColors.danger),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: GSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(item.what,
                      style: GText.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: GSpacing.sm),
                Text(
                  DateFormat('d MMM').format(item.createdAt),
                  style: GText.muted.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(GSpacing.pagePadding),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: GColors.border)),
        color: GColors.background,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: GText.body,
              onSubmitted: (_) => _add(),
              decoration: InputDecoration(
                hintText: GStrings.captureHint,
                hintStyle:
                  GText.body.copyWith(color: GColors.textDisabled),
                filled: true,
                fillColor: GColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: GSpacing.md, vertical: GSpacing.sm),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(GSpacing.inputRadius),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: GSpacing.sm),
          IconButton(
            onPressed: _add,
            icon: const Icon(Icons.arrow_upward, color: GColors.orange),
            style: IconButton.styleFrom(
              backgroundColor: GColors.orangeDim,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(GSpacing.inputRadius),
              ),
            ),
          ),
        ],
      ),
    );
  }
}