// ==========================================
// FILE: ./pages/add_persons.dart
// ==========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../services/providers.dart';

class AddPersonPage extends ConsumerStatefulWidget {
  const AddPersonPage({super.key});
  @override
  ConsumerState<AddPersonPage> createState() => _AddPersonPageState();
}

class _AddPersonPageState extends ConsumerState<AddPersonPage> {
  final _nameCtrl    = TextEditingController();
  final _numberCtrl  = TextEditingController();
  final _messageCtrl = TextEditingController();

  String  _role    = GStrings.roleMotivator;
  bool    _loading = false;
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
    final current = _messageCtrl.text.replaceAll(_nameCtrl.text.trim(), '{name}');
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
    if (cleaned.isEmpty)                          return GStrings.errPhoneRequired;
    if (!cleaned.startsWith('+'))                 return GStrings.errPhonePlus;
    if (cleaned.length < 10)                      return GStrings.errPhoneShort;
    if (!RegExp(r'^\+\d+$').hasMatch(cleaned))    return GStrings.errPhoneDigits;
    return null;
  }

  Future<void> _save() async {
    final name    = _nameCtrl.text.trim();
    final number  = _numberCtrl.text.trim();
    final message = _messageCtrl.text.trim();

    if (name.isEmpty)                    { setState(() => _error = GStrings.errNameRequired); return; }
    final numErr = _validateNumber(number);
    if (numErr != null)                  { setState(() => _error = numErr); return; }
    if (message.isEmpty)                 { setState(() => _error = GStrings.errMsgRequired); return; }

    final user = ref.read(currentUserProvider);
    if (user == null)                    { setState(() => _error = GStrings.errNotSignedIn); return; }

    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(responsibilityProvider.notifier).addPerson(
        name: name, whatsappNumber: number.replaceAll(' ', ''),
        role: _role, messageTemplate: message, userId: user.id,
      );
      if (!mounted) return;
      context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = GStrings.errorGeneric; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GColors.background,
      appBar: AppBar(
        backgroundColor: GColors.background, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: GColors.textPrimary), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(GSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(GStrings.addPersonHeader, style: GText.label.copyWith(fontSize: 14)),
            const SizedBox(height: GSpacing.xs),
            Text(GStrings.addPersonTitle, style: GText.heading.copyWith(fontSize: 22, color: GColors.azure)),
            const SizedBox(height: GSpacing.xl),

            Text(GStrings.addPersonNameLabel, style: GText.muted),
            const SizedBox(height: GSpacing.sm),
            _field(_nameCtrl, GStrings.addPersonNameHint),
            const SizedBox(height: GSpacing.lg),

            Text(GStrings.addPersonPhoneLabel, style: GText.muted),
            const SizedBox(height: GSpacing.xs),
            Text(GStrings.addPersonPhoneHint1, style: GText.muted.copyWith(fontSize: 11)),
            const SizedBox(height: GSpacing.sm),
            _field(_numberCtrl, GStrings.addPersonPhoneHint2, type: TextInputType.phone),
            const SizedBox(height: GSpacing.lg),

            Text(GStrings.addPersonRoleLabel, style: GText.label),
            const SizedBox(height: GSpacing.sm),
            Row(
              children: [
                _RoleChip(label: GStrings.roleMotivator, color: GColors.orange, selected: _role == GStrings.roleMotivator, onTap: () => _selectRole(GStrings.roleMotivator)),
                const SizedBox(width: GSpacing.sm),
                _RoleChip(label: GStrings.roleMeditator, color: GColors.azure,  selected: _role == GStrings.roleMeditator, onTap: () => _selectRole(GStrings.roleMeditator)),
              ],
            ),
            const SizedBox(height: GSpacing.lg),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(GStrings.addPersonMsgLabel, style: GText.muted),
                Text('${_messageCtrl.text.length}/${GLimits.templateMaxChars}', style: GText.muted.copyWith(fontSize: 11)),
              ],
            ),
            const SizedBox(height: GSpacing.xs),
            Text(GStrings.addPersonMsgSub, style: GText.muted.copyWith(fontSize: 11)),
            const SizedBox(height: GSpacing.sm),
            TextField(
              controller: _messageCtrl, style: GText.body, maxLines: 5, maxLength: GLimits.templateMaxChars,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: GStrings.addPersonMsgHint,
                hintStyle: GText.body.copyWith(color: GColors.textDisabled),
                filled: true, fillColor: GColors.surface,
                counterStyle: GText.muted.copyWith(fontSize: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(GSpacing.inputRadius), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(GSpacing.inputRadius), borderSide: const BorderSide(color: GColors.azure, width: 1.5)),
              ),
            ),

            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: _error != null ? 36 : 8,
              child: _error != null
                  ? Padding(padding: const EdgeInsets.only(top: GSpacing.xs), child: Text(_error!, style: GText.danger))
                  : const SizedBox.shrink(),
            ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GColors.orange, disabledBackgroundColor: GColors.surfaceHigh,
                  padding: const EdgeInsets.symmetric(vertical: GSpacing.md),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GSpacing.buttonRadius)),
                ),
                child: _loading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: GColors.background, strokeWidth: 2))
                    : Text(GStrings.addPersonSaveBtn, style: GText.subheading.copyWith(color: GColors.background, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: GSpacing.sm),
            SizedBox(width: double.infinity, child: TextButton(onPressed: () => context.pop(), child: Text(GStrings.cancel, style: GText.label))),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl, style: GText.body, keyboardType: type, onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint, hintStyle: GText.body.copyWith(color: GColors.textDisabled),
        filled: true, fillColor: GColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(GSpacing.inputRadius), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(GSpacing.inputRadius), borderSide: const BorderSide(color: GColors.orange, width: 1.5)),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label, required this.color, required this.selected, required this.onTap});
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: GSpacing.lg, vertical: GSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(40) : GColors.surface,
          border: Border.all(color: selected ? color : GColors.border),
          borderRadius: BorderRadius.circular(GSpacing.buttonRadius),
        ),
        child: Text(label, style: GText.body.copyWith(color: selected ? color : GColors.textMuted, fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
      ),
    );
  }
}