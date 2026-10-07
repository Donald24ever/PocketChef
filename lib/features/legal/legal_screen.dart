import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme_extensions.dart';

enum LegalDoc { privacy, terms }

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.doc});

  final LegalDoc doc;

  static const _lastUpdated = 'Last updated: October 2026';

  List<(String, String)> get _sections => switch (doc) {
    LegalDoc.privacy => const [
      (
        'About this policy',
        'PocketChef ("we") provides recipe suggestions based on the ingredients '
            'you scan. This policy explains what we collect, why we collect it, how '
            'long we keep it, and the control you have. It applies to the PocketChef '
            'mobile application.',
      ),
      (
        'Information we collect',
        'We may collect the following information:\n'
            '• Name\n'
            '• Email address\n'
            '• Authentication information\n'
            '• Uploaded food images\n'
            '• Favourite recipes\n'
            '• Crash diagnostics\n'
            '• Anonymous usage analytics',
      ),
      (
        'How we use your information',
        'Collected information is used solely to provide app functionality, improve '
            'performance, personalize recommendations, secure user accounts, and '
            'maintain service quality. We do not sell your personal information.',
      ),
      (
        'Uploaded images',
        'Food images you upload are used to detect ingredients and suggest recipes. '
            'They are processed only for that purpose and are not used to train '
            'third-party models.',
      ),
      (
        'Account deletion',
        'You may permanently delete your account at any time from Account '
            'Settings (Profile → Privacy & security) in the app. When an account is '
            'deleted:\n'
            '• Profile information is removed.\n'
            '• Saved recipes are deleted.\n'
            '• Uploaded content is removed.\n'
            '• Authentication records are deleted.\n'
            'Deletion requests are processed immediately where technically possible '
            'and no later than 30 days after submission.',
      ),
      (
        'Security',
        'Data is encrypted in transit, and access is restricted to authorized '
            'systems only.',
      ),
      (
        'Data retention',
        'We retain personal information only for as long as needed to provide the '
            'app and meet legal obligations. On account deletion, profile '
            'information, saved recipes, uploaded content and authentication records '
            'are removed as described above.',
      ),
      (
        'Your rights',
        'Depending on where you live (for example under the GDPR or UK DPA), you may '
            'have the right to access, correct, export or delete your personal '
            'information, and to object to or restrict certain processing. Use the '
            'Account Settings page or contact us to exercise these rights.',
      ),
      (
        'Children',
        'PocketChef is not directed at children, and we do not knowingly collect '
            'personal information from children.',
      ),
      (
        'Contact',
        'Questions or requests: privacy@pocketchef.app. We aim to respond within 30 '
            'days.',
      ),
    ],
    LegalDoc.terms => const [
      (
        'Acceptance',
        'By creating an account or using PocketChef you agree to these terms. If you do not agree, please do not use the app.',
      ),
      (
        'Your account',
        'You are responsible for your account and for keeping your credentials secure. Provide accurate information and let us know about any unauthorised use.',
      ),
      (
        'Acceptable use',
        'Do not misuse the app, attempt to break or overload it, scrape it, or use it to infringe others rights. Do not upload content you do not have the right to use.',
      ),
      (
        'Recipe and nutrition information',
        'Recipe suggestions, ingredient detection, calories and nutrition are provided for general information only and may be inaccurate. Always check labels and allergens yourself. PocketChef is not a substitute for professional dietary or medical advice.',
      ),
      (
        'Allergens',
        'Never rely on the app to confirm a dish is safe for an allergy. Verify every ingredient and preparation method.',
      ),
      (
        'Subscriptions',
        'Paid features, if offered, are billed through the Apple App Store or Google Play and renew until cancelled. Manage or cancel in your store account. Refunds follow the store policy.',
      ),
      (
        'Content and intellectual property',
        'The app, brand and content are owned by us or our licensors. Recipe photos remain the property of their respective owners and are used under their licences.',
      ),
      (
        'Disclaimer and liability',
        'The app is provided as is without warranties. To the extent permitted by law, we are not liable for indirect or consequential loss arising from your use of the app.',
      ),
      (
        'Changes and contact',
        'We may update these terms; material changes will be notified in the app. Questions: legal@pocketchef.app.',
      ),
    ],
  };

  String get _title => doc == LegalDoc.privacy ? 'Privacy Policy' : 'Terms of Service';

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
        title: Text(_title, style: context.serif(20)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(context.hPad, 8, context.hPad, 40),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.contentMax),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_title, style: context.serif(30)),
                const SizedBox(height: 6),
                Text(
                  _lastUpdated,
                  style: context.ui(13, color: c.inkTertiary),
                ),
                const SizedBox(height: 24),
                for (final (heading, body) in _sections) ...[
                  Text(heading, style: context.ui(16, weight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: context.ui(14.5, height: 1.55, color: c.inkSecondary),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}