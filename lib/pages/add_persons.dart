import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../services/providers.dart';

// ─────────────────────────────────────────────────────────────────────
// GNOTE — ADD PERSON SHEET
//
// Converted from full-page Scaffold to a bottom sheet widget.
// Use showAddPersonSheet(context) to present it.
//
// Message template editing is simplified:
//   - Template auto-fills on role selection and name entry.
//   - The textarea is shown but not the sub-label or char counter.
//     This keeps the flow focused on name + number + role.
//
// The route at /responsibility/add still exists in the router as a
// fallback, but all internal navigation uses showAddPersonSheet().
// ─────────────────────────────────────────────────────────────────────

Future<void> showAddPersonSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: GColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _AddPersonSheetContent(),
  );
}

class AddPersonPage extends StatelessWidget {
  const AddPersonPage({super.key});

  // Kept as a route-compatible page so the router entry at
  // /responsibility/add continues to resolve without error.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(GSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back,
                        color: GColors.textPrimary, size: 20),
                  ),
                  Text(GStrings.addPersonHeader,
                      style: GText.label.copyWith(fontSize: 14)),
                ],
              ),
              const _AddPersonSheetContent(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sheet content — shared between sheet and page ─────────────────────

class _AddPersonSheetContent extends ConsumerStatefulWidget {
  const _AddPersonSheetContent();

  @override
  ConsumerState<_AddPersonSheetContent> createState() =>
      _AddPersonSheetContentState();
}

class _AddPersonSheetContentState
    extends ConsumerState<_AddPersonSheetContent> {
  final _nameCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  String _role = GStrings.roleMotivator;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _messageCtrl.text = _templateFor(_role);
    _nameCtrl.addListener(_refreshMessage);
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_refreshMessage);
    _nameCtrl.dispose();
    _numberCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  String _templateFor(String role) {
    final template = GStrings.messageTemplates[role] ?? '';
    final name = _nameCtrl.text.trim();
    return name.isEmpty ? template : template.replaceAll('{name}', name);
  }

  void _refreshMessage() {
    final base = GStrings.messageTemplates[_role] ?? '';
    final current =
        _messageCtrl.text.replaceAll(_nameCtrl.text.trim(), '{name}');
    if (current == base || _messageCtrl.text.isEmpty) {
      _messageCtrl.text = _templateFor(_role);
    }
  }

  void _selectRole(String role) {
    setState(() {
      _role = role;
      _messageCtrl.text = _templateFor(role);
    });
  }

  String? _validateNumber(String value) {
    final cleaned = value.replaceAll(' ', '');
    if (cleaned.isEmpty) return GStrings.errPhoneRequired;
    if (!cleaned.startsWith('+')) return GStrings.errPhonePlus;
    if (cleaned.length < 10) return GStrings.errPhoneShort;
    if (!RegExp(r'^\+\d+$').hasMatch(cleaned)) return GStrings.errPhoneDigits;
    return null;
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final number = _numberCtrl.text.trim();
    final message = _messageCtrl.text.trim();

    if (name.isEmpty) {
      setState(() => _error = GStrings.errNameRequired);
      return;
    }
    final numErr = _validateNumber(number);
    if (numErr != null) {
      setState(() => _error = numErr);
      return;
    }
    if (message.isEmpty) {
      setState(() => _error = GStrings.errMsgRequired);
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _error = GStrings.errNotSignedIn);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    await ref.read(responsibilityProvider.notifier).addPerson(
          name: name,
          whatsappNumber: number.replaceAll(' ', ''),
          role: _role,
          messageTemplate: message,
          userId: user.id,
        );

    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: GSpacing.pagePadding,
        right: GSpacing.pagePadding,
        top: GSpacing.md,
        bottom: GSpacing.pagePadding +
            MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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

          Text(GStrings.addPersonHeader,
              style: GText.label.copyWith(fontSize: 14)),
          const SizedBox(height: GSpacing.xs),
          Text(
            GStrings.addPersonTitle,
            style: GText.heading.copyWith(fontSize: 20, color: GColors.azure),
          ),
          const SizedBox(height: GSpacing.xl),

          // ── Name ─────────────────────────────────────────────
          Text(GStrings.addPersonNameLabel, style: GText.muted),
          const SizedBox(height: GSpacing.sm),
          _field(_nameCtrl, GStrings.addPersonNameHint),

          const SizedBox(height: GSpacing.lg),

          // ── WhatsApp number ──────────────────────────────────
          Text(GStrings.addPersonPhoneLabel, style: GText.muted),
          const SizedBox(height: GSpacing.xs),
          Text(GStrings.addPersonPhoneHint1,
              style: GText.muted.copyWith(fontSize: 11)),
          const SizedBox(height: GSpacing.sm),
          _field(_numberCtrl, GStrings.addPersonPhoneHint2,
              type: TextInputType.phone),

          const SizedBox(height: GSpacing.lg),

          // ── Role ─────────────────────────────────────────────
          Text(GStrings.addPersonRoleLabel, style: GText.label),
          const SizedBox(height: GSpacing.sm),
          Row(
            children: [
              _RoleChip(
                  label: GStrings.roleMotivator,
                  color: GColors.orange,
                  selected: _role == GStrings.roleMotivator,
                  onTap: () => _selectRole(GStrings.roleMotivator)),
              const SizedBox(width: GSpacing.sm),
              _RoleChip(
                  label: GStrings.roleMeditator,
                  color: GColors.azure,
                  selected: _role == GStrings.roleMeditator,
                  onTap: () => _selectRole(GStrings.roleMeditator)),
            ],
          ),

          const SizedBox(height: GSpacing.xl),

          // ── Error ─────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _error != null ? 36 : 0,
            child: _error != null
                ? Padding(
                    padding: const EdgeInsets.only(bottom: GSpacing.xs),
                    child: Text(_error!, style: GText.danger))
                : const SizedBox.shrink(),
          ),

          // ── Save ──────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: GColors.orange,
                disabledBackgroundColor: GColors.surfaceHigh,
                padding: const EdgeInsets.symmetric(vertical: GSpacing.md),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(GSpacing.buttonRadius)),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          color: GColors.background, strokeWidth: 2))
                  : Text(GStrings.addPersonSaveBtn,
                      style: GText.subheading.copyWith(
                          color: GColors.background,
                          fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: GSpacing.sm),
          SizedBox(
              width: double.infinity,
              child: TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(GStrings.cancel, style: GText.label))),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      style: GText.body,
      keyboardType: type,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GText.body.copyWith(color: GColors.textDisabled),
        filled: true,
        fillColor: GColors.surfaceHigh,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GSpacing.inputRadius),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GSpacing.inputRadius),
            borderSide: const BorderSide(color: GColors.orange, width: 1.5)),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip(
      {required this.label,
      required this.color,
      required this.selected,
      required this.onTap});
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GSpacing.buttonRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
              horizontal: GSpacing.lg, vertical: GSpacing.sm),
          decoration: BoxDecoration(
            color: selected ? color.withAlpha(40) : GColors.surface,
            border: Border.all(color: selected ? color : GColors.border),
            borderRadius: BorderRadius.circular(GSpacing.buttonRadius),
          ),
          child: Text(label,
              style: GText.body.copyWith(
                  color: selected ? color : GColors.textMuted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
        ),
      ),
    );
  }
}
