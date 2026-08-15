import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/state_providers.dart';
import '../../widgets/brand/qmax_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: AppConstants.splashDurationMs), _go);
  }

  void _go() {
    if (!mounted) return;
    final onboarded = ref.read(settingsProvider).onboardingComplete;
    context.go(onboarded ? '/home' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const QmaxLogo(size: 108)
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.82, 0.82), curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text(
              'QMAX TOOLS',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    letterSpacing: 2.4,
                    fontWeight: FontWeight.w900,
                  ),
            ).animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 8),
            Text(
              AppConstants.tagline,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFFFB923C)),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 36),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFFFB923C)),
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}
