import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/state_providers.dart';

mixin CartActions<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  Future<void> addProduct(Product product, {int qty = 1}) async {
    final result = await ref.read(cartProvider.notifier).add(product, quantity: qty);
    if (!mounted) return;
    if (result == 'out') {
      context.showSnack(context.l10n.outOfStock, error: true);
    } else if (result == 'stock') {
      context.showSnack(context.l10n.stockExceeded(product.stock), error: true);
    } else {
      context.showSnack(context.l10n.addedToCart);
    }
  }

  Future<void> toggleWish(Product product) async {
    final ok = await ref.read(wishlistProvider.notifier).toggle(
          product.id,
          authenticated: ref.read(authProvider).isAuthenticated,
        );
    if (!ok && mounted) {
      context.showSnack(context.l10n.loginToSaveWishlist);
      context.push('/login');
    }
  }
}
