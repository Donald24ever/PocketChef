import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme_extensions.dart';
import '../../data/seed/photo_credits.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final groups = <String, List<PhotoCredit>>{};
    for (final credit in photoCredits) {
      groups.putIfAbsent(credit.source, () => []).add(credit);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
        title: Text('Photo credits', style: context.serif(20)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(context.hPad, 8, context.hPad, 40),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.contentMax),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Photo credits', style: context.serif(30)),
                const SizedBox(height: 8),
                Text(
                  'Recipe photography is sourced from the providers below and '
                  'reproduced under the stated licences. Thanks to the photographers '
                  'who make their work freely available.',
                  style: context.ui(14.5, height: 1.55, color: c.inkSecondary),
                ),
                const SizedBox(height: 24),
                for (final entry in groups.entries) ...[
                  Text(
                    entry.key,
                    style: context.ui(16, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${entry.value.length} photos',
                    style: context.ui(12.5, color: c.inkTertiary),
                  ),
                  const SizedBox(height: 12),
                  for (final credit in entry.value) ...[
                    _CreditTile(credit: credit),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreditTile extends StatelessWidget {
  const _CreditTile({required this.credit});

  final PhotoCredit credit;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            credit.dish,
            style: context.ui(15, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            credit.author,
            style: context.ui(13.5, color: c.inkSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            credit.license,
            style: context.ui(12.5, color: c.inkTertiary),
          ),
          if (credit.sourceUrl.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(
              credit.sourceUrl,
              style: context.ui(11.5, color: c.primaryDeep),
            ),
          ],
          if (credit.licenseUrl.isNotEmpty &&
              credit.licenseUrl != credit.sourceUrl) ...[
            const SizedBox(height: 2),
            SelectableText(
              credit.licenseUrl,
              style: context.ui(11.5, color: c.primaryDeep),
            ),
          ],
        ],
      ),
    );
  }
}