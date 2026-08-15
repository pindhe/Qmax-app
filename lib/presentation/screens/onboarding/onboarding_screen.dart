import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../providers/state_providers.dart';
import '../../widgets/brand/qmax_logo.dart';
import '../../widgets/common/qmax_common.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(settingsProvider.notifier).completeOnboarding();
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = [
      (Icons.storefront, l10n.onboardingTitle1, l10n.onboardingDesc1),
      (Icons.verified, l10n.onboardingTitle2, l10n.onboardingDesc2),
      (Icons.local_shipping, l10n.onboardingTitle3, l10n.onboardingDesc3),
    ];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.pagePadding, vertical: AppSpacing.lg),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _finish, child: Text(l10n.skip)),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) {
                    final page = pages[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const QmaxLogo(size: 96),
                        const SizedBox(height: 32),
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: context.colors.primaryContainer,
                          child: Icon(page.$1, size: 40, color: context.colors.primary),
                        ),
                        const SizedBox(height: 28),
                        Text(page.$2, textAlign: TextAlign.center, style: context.texts.headlineSmall),
                        const SizedBox(height: 12),
                        Text(page.$3, textAlign: TextAlign.center, style: context.texts.bodyLarge),
                      ],
                    );
                  },
                ),
              ),
              SmoothPageIndicator(
                controller: _controller,
                count: pages.length,
                effect: ExpandingDotsEffect(
                  activeDotColor: context.colors.primary,
                  dotColor: context.colors.outlineVariant,
                  dotHeight: 8,
                  dotWidth: 8,
                ),
              ),
              const SizedBox(height: 24),
              QmaxButton(
                label: _index == pages.length - 1 ? l10n.getStarted : l10n.next,
                onPressed: () {
                  if (_index == pages.length - 1) {
                    _finish();
                  } else {
                    _controller.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
