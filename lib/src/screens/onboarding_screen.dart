import 'package:flutter/material.dart';

import '../i18n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  final Future<void> Function() onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    (Icons.route_outlined, 'onboarding_ride_title', 'onboarding_ride_body'),
    (
      Icons.build_outlined,
      'onboarding_service_title',
      'onboarding_service_body',
    ),
    (
      Icons.cloud_off_outlined,
      'onboarding_privacy_title',
      'onboarding_privacy_body',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _advance() async {
    if (_page == _pages.length - 1) {
      await widget.onComplete();
    } else {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final isLastPage = _page == _pages.length - 1;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: PageView(
                      key: const Key('onboarding-pages'),
                      controller: _controller,
                      onPageChanged: (page) => setState(() => _page = page),
                      children: [
                        for (final page in _pages)
                          _OnboardingPage(
                            icon: page.$1,
                            title: l10n.t(page.$2),
                            body: l10n.t(page.$3),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var index = 0; index < _pages.length; index++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: index == _page ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: index == _page
                                ? colors.primary
                                : colors.outlineVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        key: const Key('onboarding-skip'),
                        onPressed: widget.onComplete,
                        child: Text(l10n.t('onboarding_skip')),
                      ),
                      FilledButton(
                        key: Key(
                          isLastPage ? 'onboarding-start' : 'onboarding-next',
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                        onPressed: _advance,
                        child: Text(
                          l10n.t(
                            isLastPage ? 'onboarding_start' : 'onboarding_next',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 52, color: colors.onPrimaryContainer),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
