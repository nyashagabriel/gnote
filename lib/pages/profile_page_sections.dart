part of 'profile_page.dart';

class _ProfileViewData {
  const _ProfileViewData({
    required this.displayName,
    required this.email,
    required this.timezone,
    required this.initials,
    required this.themeLabel,
  });

  final String displayName;
  final String email;
  final String timezone;
  final String initials;
  final String themeLabel;

  factory _ProfileViewData.fromUser({
    required GUser? user,
    required ThemeMode themeMode,
  }) {
    final displayName = _safeText(user?.displayName);
    return _ProfileViewData(
      displayName: displayName,
      email: _safeText(user?.email),
      timezone: _safeText(
        user?.timezone,
        fallback: deviceTimezone(),
      ),
      initials: _buildInitials(displayName),
      themeLabel: switch (themeMode) {
        ThemeMode.light => GStrings.profileThemeLight,
        ThemeMode.dark => GStrings.profileThemeDark,
        ThemeMode.system => GStrings.profileThemeSystem,
      },
    );
  }

  static String _safeText(String? value, {String fallback = '—'}) {
    final clean = value?.trim() ?? '';
    return clean.isEmpty ? fallback : clean;
  }

  static String _buildInitials(String displayName) {
    final clean = displayName.trim();
    if (clean.isEmpty || clean == '—') return 'GN';

    final parts =
        clean.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();

    if (parts.isEmpty) return 'GN';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();

    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GSpacing.sm,
        GSpacing.sm,
        GSpacing.pagePadding,
        GSpacing.md,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: GColors.textPrimary,
            ),
          ),
          const SizedBox(width: GSpacing.xs),
          Expanded(
            child: Text(
              GStrings.profileHeader,
              style: GText.heading.copyWith(
                fontSize: 28,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.initials,
    required this.displayName,
    required this.email,
  });

  final String initials;
  final String displayName;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(GSpacing.lg),
      decoration: BoxDecoration(
        color: GColors.surface,
        borderRadius: BorderRadius.circular(GSpacing.cardRadius),
        border: Border.all(color: GColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: GColors.orange,
            child: Text(
              initials,
              style: GText.heading.copyWith(
                fontSize: 22,
                height: 1.0,
                color: GColors.background,
              ),
            ),
          ),
          const SizedBox(width: GSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GText.subheading.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GText.muted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: GText.label.copyWith(
        fontSize: 12,
        color: GColors.textMuted,
      ),
    );
  }
}

class _CardSection extends StatelessWidget {
  const _CardSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GColors.surface,
        borderRadius: BorderRadius.circular(GSpacing.cardRadius),
        border: Border.all(color: GColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GSpacing.md,
        vertical: GSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: GColors.textMuted),
          const SizedBox(width: GSpacing.md),
          Expanded(
            child: Text(label, style: GText.muted),
          ),
          const SizedBox(width: GSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GText.subheading.copyWith(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GSpacing.md,
            vertical: GSpacing.md,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: GSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: GText.subheading.copyWith(fontSize: 15),
                ),
              ),
              const SizedBox(width: GSpacing.md),
              Text(
                value,
                style: GText.subheading.copyWith(
                  fontSize: 15,
                  color: accent,
                ),
              ),
              const SizedBox(width: GSpacing.xs),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DangerRow extends StatelessWidget {
  const _DangerRow({
    required this.icon,
    required this.label,
    required this.loading,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GSpacing.md,
            vertical: GSpacing.md,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: GColors.danger),
              const SizedBox(width: GSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: GText.subheading.copyWith(
                    fontSize: 15,
                    color: GColors.danger,
                  ),
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: GColors.danger,
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: GColors.danger,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: GColors.border,
    );
  }
}

class _HelpSheet extends StatelessWidget {
  const _HelpSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          GSpacing.pagePadding,
          GSpacing.md,
          GSpacing.pagePadding,
          GSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Text(
              GStrings.profileHelpFaq,
              style: GText.heading.copyWith(fontSize: 22),
            ),
            const SizedBox(height: GSpacing.lg),
            const _HelpItem(
              title: GStrings.profileHelpAnchorTitle,
              body: GStrings.profileHelpAnchorBody,
            ),
            const SizedBox(height: GSpacing.md),
            const _HelpItem(
              title: GStrings.profileHelpDaily3Title,
              body: GStrings.profileHelpDaily3Body,
            ),
            const SizedBox(height: GSpacing.md),
            const _HelpItem(
              title: GStrings.profileHelpCaptureTitle,
              body: GStrings.profileHelpCaptureBody,
            ),
            const SizedBox(height: GSpacing.md),
            const _HelpItem(
              title: GStrings.profileHelpHabitTitle,
              body: GStrings.profileHelpHabitBody,
            ),
            const SizedBox(height: GSpacing.md),
            const _HelpItem(
              title: GStrings.profileHelpPeopleTitle,
              body: GStrings.profileHelpPeopleBody,
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  const _HelpItem({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GSpacing.md),
      decoration: BoxDecoration(
        color: GColors.surfaceHigh,
        borderRadius: BorderRadius.circular(GSpacing.cardRadius),
        border: Border.all(color: GColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GText.subheading.copyWith(fontSize: 16)),
          const SizedBox(height: GSpacing.xs),
          Text(body, style: GText.muted),
        ],
      ),
    );
  }
}
