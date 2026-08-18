import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../providers/state_providers.dart';
import 'qmax_liquid_footer.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartProvider).itemCount;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: navigationShell,
      bottomNavigationBar: QmaxLiquidFooter(
        currentIndex: navigationShell.currentIndex,
        cartCount: cartCount,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class RequireAuth {
  static bool ensure(BuildContext context, WidgetRef ref, {String? message}) {
    if (ref.read(authProvider).isAuthenticated) return true;
    context.showSnack(message ?? context.l10n.loginRequired);
    context.push('/login');
    return false;
  }
}
