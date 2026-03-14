import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../services/providers.dart';

// ─────────────────────────────────────────────────────────────────────
// GNOTE — ADD TASK PAGE
//
// Category field removed from UI for v1.
// The model still stores category (defaults to 'other') and syncs
// to Supabase — no migration needed. We simply stopped surfacing it.
// Daily 3 is a forcing function: what + how you'll know + by when.
// That is all the user needs to think about.
// ─────────────────────────────────────────────────────────────────────

class AddTaskPage extends ConsumerStatefulWidget {
  const AddTaskPage({super.key});
  @override
  ConsumerState<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends ConsumerState<AddTaskPage> {
  final _whatCtrl = TextEditingController();
  final _doneWhenCtrl = TextEditingController();

  DateTime _byDate = DateTime.now();
  TimeOfDay _byTime = TimeOfDay.now();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _whatCtrl.dispose();
    _doneWhenCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _byDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
          data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(primary: GColors.orange)),
          child: child!),
    );
    if (picked != null) setState(() => _byDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _byTime,
      builder: (context, child) => Theme(
          data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(primary: GColors.orange)),
          child: child!),
    );
    if (picked != null) setState(() => _byTime = picked);
  }

  Future<void> _save() async {
    final what = _whatCtrl.text.trim();
    final doneWhen = _doneWhenCtrl.text.trim();

    if (what.isEmpty) {
      setState(() => _error = GStrings.addTaskErrWhat);
      return;
    }
    if (doneWhen.isEmpty) {
      setState(() => _error = GStrings.addTaskErrDone);
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

    final by = DateTime(
        _byDate.year, _byDate.month, _byDate.day, _byTime.hour, _byTime.minute);

    final err = await ref.read(daily3Provider.notifier).addTask(
          what: what,
          doneWhen: doneWhen,
          by: by,
          category: 'other', // category hidden from UI in v1
          userId: user.id,
        );

    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE d MMM').format(_byDate);
    final timeStr = _byTime.format(context);

    return Scaffold(
      backgroundColor: GColors.background,
      appBar: AppBar(
        backgroundColor: GColors.background,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: GColors.textPrimary),
            onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(GSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(GStrings.addTaskHeader,
                style: GText.label.copyWith(fontSize: 14)),
            const SizedBox(height: GSpacing.xs),
            Text(GStrings.addTaskTitle,
                style:
                    GText.heading.copyWith(fontSize: 22, color: GColors.orange)),
            const SizedBox(height: GSpacing.xl),

            // ── What ───────────────────────────────────────────
            Text(GStrings.smartWhat, style: GText.label),
            const SizedBox(height: GSpacing.sm),
            _Field(
                ctrl: _whatCtrl,
                hint: GStrings.addTaskWhatHint,
                maxLength: GLimits.taskTitleMax),

            const SizedBox(height: GSpacing.lg),

            // ── Done when ──────────────────────────────────────
            Text(GStrings.smartDoneWhen, style: GText.label),
            const SizedBox(height: GSpacing.sm),
            _Field(
                ctrl: _doneWhenCtrl,
                hint: GStrings.addTaskDoneHint,
                maxLines: 3,
                maxLength: GLimits.taskTitleMax),

            const SizedBox(height: GSpacing.lg),

            // ── By ─────────────────────────────────────────────
            Text(GStrings.addTaskByLabel, style: GText.label),
            const SizedBox(height: GSpacing.sm),
            Row(
              children: [
                Expanded(
                    flex: 2,
                    child: _PickerTile(
                        label: GStrings.addTaskDateLabel,
                        value: dateStr,
                        icon: Icons.calendar_today,
                        onTap: _pickDate)),
                const SizedBox(width: GSpacing.sm),
                Expanded(
                    flex: 1,
                    child: _PickerTile(
                        label: GStrings.addTaskTimeLabel,
                        value: timeStr,
                        icon: Icons.access_time,
                        onTap: _pickTime)),
              ],
            ),

            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: _error != null ? 40 : 16,
              child: _error != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: GSpacing.sm),
                      child: Text(_error!, style: GText.danger))
                  : const SizedBox.shrink(),
            ),

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
                    : Text(GStrings.addTaskSaveBtn,
                        style: GText.subheading.copyWith(
                            color: GColors.background,
                            fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: GSpacing.sm),
            SizedBox(
                width: double.infinity,
                child: TextButton(
                    onPressed: () => context.pop(),
                    child: Text(GStrings.cancel, style: GText.label))),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(
      {required this.ctrl,
      required this.hint,
      this.maxLines = 1,
      this.maxLength});
  final TextEditingController ctrl;
  final String hint;
  final int maxLines;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      style: GText.body,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GText.body.copyWith(color: GColors.textDisabled),
        filled: true,
        fillColor: GColors.surface,
        counterStyle: GText.muted.copyWith(fontSize: 10),
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

class _PickerTile extends StatelessWidget {
  const _PickerTile(
      {required this.label,
      required this.value,
      required this.icon,
      required this.onTap});
  final String label, value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GSpacing.inputRadius),
        child: Container(
          padding: const EdgeInsets.all(GSpacing.md),
          decoration: BoxDecoration(
              color: GColors.surface,
              borderRadius: BorderRadius.circular(GSpacing.inputRadius),
              border: Border.all(color: GColors.border)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GText.label.copyWith(fontSize: 10)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: GText.body, overflow: TextOverflow.ellipsis),
                ],
              ),
              Icon(icon, color: GColors.textMuted, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
