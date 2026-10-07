import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme_extensions.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/artwork.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/text_fields.dart';
import '../../data/services/security_service.dart';
import '../../state/app_state_provider.dart';
import '../../state/domain_providers.dart';
import '../../state/security_providers.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _emailError;
  String? _passwordError;
  String? _submitError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _emailError = null;
      _passwordError = null;
      _submitError = null;
    });
    Haptics.light();
    try {
      await action();
    } on AuthException catch (e) {
      ref.read(securityAuditProvider.notifier).record('Sign-in failed', e.message);
      if (mounted) setState(() => _submitError = e.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitError =
              'Sign-in is unavailable right now. Try again or continue as guest.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInEmail() async {
    final email = _email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _emailError = 'Enter a valid email address');
      return;
    }
    final passwordIssue = PasswordPolicy.firstIssueMessage(
      _password.text,
      email: email,
    );
    if (passwordIssue != null) {
      setState(() => _passwordError = passwordIssue);
      return;
    }
    await _run(() async {
      try {
        final result = await ref
            .read(authRepositoryProvider)
            .signInWithEmail(email, _password.text);
        ref
            .read(securityAuditProvider.notifier)
            .record('Sign-in', '${result.provider} account authenticated');
        await ref.read(appStateProvider.notifier).signIn(result);
      } on AuthException catch (e) {
        ref
            .read(securityAuditProvider.notifier)
            .record('Sign-in failed', e.message);
        if (mounted) {
          setState(() => _submitError = e.message);
        }
      }
    });
  }

  Future<void> _signInSocial(Future<void> Function() provider) =>
      _run(() async {
        await provider();
      });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(context.hPad, 24, context.hPad, 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: 0,
              maxWidth: context.contentMax,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const LogoMark(size: 48),
                    const SizedBox(width: 12),
                    Text('PocketChef', style: context.serif(22)),
                  ],
                ),
                const SizedBox(height: 44),
                Text(
                  'Cook what you\nalready have.',
                  style: context.serif(36, height: 1.12),
                ),
                const SizedBox(height: 12),
                Text(
                  'Scan your kitchen, get recipes in seconds.',
                  style: context.ui(16, color: c.inkSecondary),
                ),
                const SizedBox(height: 36),
                AppTextField(
                  controller: _email,
                  label: 'Email',
                  hint: 'you@example.com',
                  errorText: _emailError,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.mail_outline_rounded,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _password,
                  label: 'Password',
                  hint: 'Your password',
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icons.lock_outline_rounded,
                  autofillHints: const [AutofillHints.password],
                  autocorrect: false,
                  errorText: _passwordError,
                  helperText:
                      '8+ characters, with upper, lower and a number',
                  onSubmitted: (_) => _signInEmail(),
                ),
                if (_submitError != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: c.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _submitError!,
                          style: context.ui(13.5, color: c.error),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Continue with email',
                  loading: _busy,
                  onTap: _busy ? null : _signInEmail,
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'or continue with',
                        style: context.ui(13, color: c.inkTertiary),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 26),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _signInSocial(() async {
                          final result = await ref
                              .read(authRepositoryProvider)
                              .signInWithGoogle();
                          await ref
                              .read(appStateProvider.notifier)
                              .signIn(result);
                        }),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: c.surface,
                    minimumSize: const Size.fromHeight(54),
                  ),
                  icon: Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    child: Text(
                      'G',
                      style: context.ui(
                        17,
                        weight: FontWeight.w800,
                        color: const Color(0xFF4285F4),
                        height: 1,
                      ),
                    ),
                  ),
                  label: const Text('Google'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _signInSocial(() async {
                          final result = await ref
                              .read(authRepositoryProvider)
                              .signInWithApple();
                          await ref
                              .read(appStateProvider.notifier)
                              .signIn(result);
                        }),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: c.surface,
                    minimumSize: const Size.fromHeight(54),
                  ),
                  icon: const Icon(Icons.apple_rounded, size: 22),
                  label: const Text('Apple'),
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: _busy
                        ? null
                        : () => _signInSocial(() async {
                            final result = await ref
                                .read(authRepositoryProvider)
                                .continueAsGuest();
                            await ref
                                .read(appStateProvider.notifier)
                                .signIn(result);
                          }),
                    child: Text(
                      'Browse without an account',
                      style: context.ui(
                        15,
                        weight: FontWeight.w600,
                        color: c.inkSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        Text(
                          'By continuing you agree to PocketChef’s ',
                          style: context.ui(
                            12.5,
                            color: c.inkTertiary,
                            height: 1.5,
                          ),
                        ),
                        _LegalLink(
                          label: 'Terms of Service',
                          onTap: () => context.push('/legal/terms'),
                        ),
                        Text(
                          ' and ',
                          style: context.ui(
                            12.5,
                            color: c.inkTertiary,
                            height: 1.5,
                          ),
                        ),
                        _LegalLink(
                          label: 'Privacy Policy',
                          onTap: () => context.push('/legal/privacy'),
                        ),
                        Text(
                          '.',
                          style: context.ui(
                            12.5,
                            color: c.inkTertiary,
                            height: 1.5,
                          ),
                        ),
                        _LegalLink(
                          label: 'Photo credits',
                          onTap: () => context.push('/legal/credits'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        button: true,
        link: true,
        child: Text(
          label,
          style: context.ui(
            12.5,
            color: context.c.primaryDeep,
            height: 1.5,
            weight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
