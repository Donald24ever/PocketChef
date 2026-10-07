import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme_extensions.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/misc.dart';
import '../../core/widgets/text_fields.dart';
import '../../data/models/user.dart';
import '../../data/services/security_service.dart';
import '../../state/app_state_provider.dart';
import '../../state/domain_providers.dart';
import '../../state/security_providers.dart';

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  String _timeOf(DateTime at) {
    final local = at.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final app = ref.watch(appStateProvider).value;
    final profile = app?.profile ?? UserProfile.guest;
    final settings = ref.watch(securitySettingsProvider).value ??
        const SecuritySettings();
    final audit = ref.watch(securityAuditProvider);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.only(bottom: 40),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(context.hPad, 6, context.hPad, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      'Privacy & security',
                      style: context.serif(22),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(context.hPad, 8, context.hPad, 4),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.oliveSoft.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined, size: 20, color: c.olive),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'We keep the minimum we need and encrypt it in '
                        'transit and at rest. You stay in control — export '
                        'or erase everything, any time.',
                        style: context.ui(
                          13.5,
                          color: c.inkSecondary,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SectionHeader(title: 'Account', padding: const EdgeInsets.fromLTRB(20, 24, 12, 4)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.hPad),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: c.hairline),
                ),
                child: Column(
                  children: [
                    _InfoRow(label: 'Signed in with', value: profile.provider),
                    const Divider(height: 24),
                    _InfoRow(label: 'Email', value: profile.email.isEmpty ? 'Guest session' : profile.email),
                    const Divider(height: 24),
                    _InfoRow(
                      label: 'Email verified',
                      value: settings.emailVerified ? 'Verified' : 'Not yet',
                      valueColor: settings.emailVerified ? c.olive : c.gold,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _verifyEmail(context, ref, profile.email),
                            icon: Icon(
                              settings.emailVerified
                                  ? Icons.check_circle_rounded
                                  : Icons.mark_email_read_outlined,
                              size: 18,
                            ),
                            label: Text(
                              settings.emailVerified ? 'Re-send code' : 'Verify email',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Change password',
                        style: context.ui(14, weight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '8+ characters with upper, lower and a number.',
                      style: context.ui(12.5, color: c.inkTertiary),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _changePassword(context, ref),
                            icon: const Icon(Icons.password_rounded, size: 18),
                            label: const Text('Update'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SectionHeader(title: 'Sign-in & device', padding: const EdgeInsets.fromLTRB(20, 26, 12, 4)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.hPad),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: c.hairline),
                ),
                child: Column(
                  children: [
                    Material(
                      type: MaterialType.transparency,
                      child: SwitchListTile(
                        value: settings.faceUnlock,
                        contentPadding: EdgeInsets.zero,
                        activeTrackColor: c.primary,
                        title: Text(
                          'Face ID / Touch ID',
                          style: context.ui(15.5, weight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Unlock PocketChef with biometrics',
                          style: context.ui(13, color: c.inkTertiary),
                        ),
                        onChanged: (value) {
                          Haptics.selection();
                          ref
                              .read(securitySettingsProvider.notifier)
                              .setFaceUnlock(value);
                          ref
                              .read(securityAuditProvider.notifier)
                              .record(
                                'Biometrics',
                                value
                                    ? 'Biometric unlock enabled'
                                    : 'Biometric unlock disabled',
                              );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    Material(
                      type: MaterialType.transparency,
                      child: SwitchListTile(
                        value: settings.mfaEnabled,
                        contentPadding: EdgeInsets.zero,
                        activeTrackColor: c.primary,
                        title: Text(
                          'Two-factor authentication',
                          style: context.ui(15.5, weight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'App code at sign-in',
                          style: context.ui(13, color: c.inkTertiary),
                        ),
                        onChanged: (value) {
                          Haptics.selection();
                          ref
                              .read(securitySettingsProvider.notifier)
                              .setMfaEnabled(value);
                          ref
                              .read(securityAuditProvider.notifier)
                              .record(
                                'MFA',
                                value
                                    ? 'Two-factor protection enabled'
                                    : 'Two-factor protection disabled',
                              );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.laptop_mac_rounded, size: 20, color: c.inkSecondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'This iPhone',
                                  style: context.ui(14.5, weight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  settings.lastRefresh == null
                                      ? 'Session started this time'
                                      : 'Refreshed at ${_timeOf(settings.lastRefresh!)}',
                                  style: context.ui(12.5, color: c.inkTertiary),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _refreshSession(context, ref),
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SectionHeader(title: 'Your data', padding: const EdgeInsets.fromLTRB(20, 26, 12, 4)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.hPad),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: c.hairline),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _DataAction(
                            icon: Icons.download_rounded,
                            label: 'Export my data',
                            caption: 'Copy everything as text',
                            onTap: () => _exportData(context, ref),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DataAction(
                            icon: Icons.delete_forever_rounded,
                            label: 'Delete my account',
                            caption: 'Erase account and data',
                            danger: true,
                            onTap: () => _deleteAccount(context, ref, profile.email),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _deleteAccount(context, ref, profile.email),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          'Under the UK GDPR and DPA, you can ask us to erase '
                          'your data at any time. Deleting is permanent and '
                          'cannot be undone.',
                          style: context.ui(12.5, color: c.inkTertiary, height: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SectionHeader(title: 'Activity log', padding: const EdgeInsets.fromLTRB(20, 26, 12, 4)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.hPad),
              child: audit.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: c.hairline),
                      ),
                      child: Text(
                        'Security events will appear here as they happen.',
                        style: context.ui(13.5, color: c.inkTertiary),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: c.hairline),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < audit.length; i++) ...[
                            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: c.oliveSoft,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.shield_outlined,
                                      size: 15,
                                      color: c.olive,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          audit[i].action,
                                          style: context.ui(14, weight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          audit[i].detail,
                                          style: context.ui(13, color: c.inkSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _timeOf(audit[i].at),
                                    style: context.ui(12, color: c.inkTertiary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyEmail(BuildContext context, WidgetRef ref, String email) async {
    final c = context.c;
    Haptics.light();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guest sessions have no email to verify.')),
      );
      return;
    }
    final code = await ref
        .read(authRepositoryProvider)
        .requestEmailVerification(email);
    if (!context.mounted) return;
    var entered = '';
    final codeField = TextEditingController();
    var verifying = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          title: Text('Verify your email', style: dialogContext.serif(22)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We sent a 6-digit code to $email. (Demo: your code is $code)',
                style: dialogContext.ui(13.5, color: c.inkSecondary),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: codeField,
                label: 'Verification code',
                hint: '6-digit code',
                keyboardType: TextInputType.number,
                onChanged: (value) => entered = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (verifying) return;
                verifying = true;
                final ok = await ref
                    .read(authRepositoryProvider)
                    .confirmEmailVerification(email, entered);
                if (!dialogContext.mounted || !context.mounted) return;
                if (!ok) {
                  verifying = false;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('That code does not match.')),
                  );
                  return;
                }
                await ref
                    .read(securitySettingsProvider.notifier)
                    .setEmailVerified(true);
                ref
                    .read(securityAuditProvider.notifier)
                    .record('Email verified', email);
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email verified.')),
                  );
                }
              },
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
    codeField.dispose();
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    Haptics.light();
    final current = TextEditingController();
    final next = TextEditingController();
    String? error;
    var saving = false;
    void Function(VoidCallback)? setDialogStateRef;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          title: Text('Change password', style: dialogContext.serif(22)),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              setDialogStateRef = setDialogState;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    controller: current,
                    label: 'Current password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: next,
                    label: 'New password',
                    obscureText: true,
                    errorText: error,
                    helperText: '8+ characters with upper, lower and a number',
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (saving) return;
                final issue = PasswordPolicy.firstIssueMessage(next.text);
                if (issue != null) {
                  setDialogStateRef!(() => error = issue);
                  return;
                }
                saving = true;
                try {
                  await ref
                      .read(authRepositoryProvider)
                      .changePassword(current.text, next.text);
                  ref
                      .read(securityAuditProvider.notifier)
                      .record('Password changed', 'Account password updated');
                  if (!dialogContext.mounted || !context.mounted) return;
                  Navigator.of(dialogContext).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password updated.')),
                    );
                  }
                } on AuthException catch (e) {
                  saving = false;
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.message)),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    current.dispose();
    next.dispose();
  }

  Future<void> _refreshSession(BuildContext context, WidgetRef ref) async {
    Haptics.light();
    final refreshed = await ref.read(authRepositoryProvider).refreshSession();
    await ref.read(securitySettingsProvider.notifier).recordRefresh(refreshed);
    ref
        .read(securityAuditProvider.notifier)
        .record('Session refreshed', 'Stale tokens rotated');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session refreshed.')),
      );
    }
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    Haptics.light();
    final app = ref.read(appStateProvider).value;
    final profile = app?.profile ?? UserProfile.guest;
    final settings = ref.read(securitySettingsProvider).value ??
        const SecuritySettings();
    final audit = ref.read(securityAuditProvider);
    final buffer = StringBuffer()
      ..writeln('PocketChef data export')
      ..writeln('Generated ${DateTime.now().toIso8601String()}')
      ..writeln()
      ..writeln('Profile: ${profile.name} (${profile.email.isEmpty ? 'guest' : profile.email})')
      ..writeln('Provider: ${profile.provider}')
      ..writeln('Family size: ${profile.familySize}')
      ..writeln('Email verified: ${settings.emailVerified}')
      ..writeln('Biometrics enabled: ${settings.faceUnlock}')
      ..writeln('MFA enabled: ${settings.mfaEnabled}')
      ..writeln()
      ..writeln('Security activity:');
    for (final entry in audit) {
      buffer.writeln('- ${entry.at.toIso8601String()}: ${entry.action} — ${entry.detail}');
    }
    final data = buffer.toString();
    ref
        .read(securityAuditProvider.notifier)
        .record('Data export', 'A copy of your data was generated');
    final c = context.c;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your data', style: sheetContext.serif(22)),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 220,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.surfaceAlt,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SelectableText(
                    data,
                    style: sheetContext.ui(12.5, height: 1.5),
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Copy to clipboard',
                  icon: Icons.copy_rounded,
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: data));
                    if (!sheetContext.mounted) return;
                    Haptics.light();
                    Navigator.of(sheetContext).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard.')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref, String email) async {
    Haptics.light();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final c = dialogContext.c;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          title: Text('Delete your account?', style: dialogContext.serif(22)),
          content: Text(
            'Your profile, saved recipes, plan and scanning history will be '
            'removed from PocketChef. This cannot be undone.',
            style: dialogContext.ui(14, color: c.inkSecondary, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep account'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: c.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    Haptics.medium();
    await ref.read(authRepositoryProvider).deleteAccount(email);
    ref
        .read(securityAuditProvider.notifier)
        .record('Account deleted', 'All personal data erased');
    await ref.read(appStateProvider.notifier).signOut();
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      children: [
        Text(label, style: context.ui(13.5, color: c.inkTertiary)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.ui(
              14.5,
              weight: FontWeight.w600,
              color: valueColor ?? c.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _DataAction extends StatelessWidget {
  const _DataAction({
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final accent = danger ? c.error : c.olive;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: danger
              ? c.error.withValues(alpha: 0.08)
              : c.oliveSoft.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: accent),
            const SizedBox(height: 10),
            Text(label, style: context.ui(14, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(caption, style: context.ui(12, color: c.inkTertiary)),
          ],
        ),
      ),
    );
  }
}