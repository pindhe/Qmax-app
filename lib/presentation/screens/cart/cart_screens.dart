import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/network/api_result.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/app_providers.dart';
import '../../providers/state_providers.dart';
import '../../widgets/common/cart_actions.dart';
import '../../widgets/common/qmax_common.dart';
import '../../widgets/navigation/main_shell.dart';
import '../../widgets/product/product_widgets.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _coupon = TextEditingController();
  String? _couponMessage;
  bool _couponError = false;

  @override
  void dispose() {
    _coupon.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final cart = ref.read(cartProvider);
    final result = await ref.read(couponRepositoryProvider).validate(_coupon.text, cart.subtotal);
    if (!mounted) return;
    final l10n = context.l10n;
    switch (result) {
      case ApiSuccess(:final data):
        await ref.read(cartProvider.notifier).applyCoupon(data);
        setState(() {
          _couponError = false;
          _couponMessage = l10n.couponValid;
        });
      case ApiFailure(:final message):
        await ref.read(cartProvider.notifier).applyCoupon(null);
        setState(() {
          _couponError = true;
          _couponMessage = switch (message) {
            'expired' => l10n.couponExpired,
            'minimum' => l10n.couponMinimum(Formatters.money(50)),
            _ => l10n.couponInvalid,
          };
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.myCart)),
      body: cart.isEmpty
          ? QmaxEmptyState(
              icon: Icons.shopping_cart_outlined,
              title: l10n.emptyCart,
              subtitle: l10n.emptyCartHint,
              actionLabel: l10n.startShopping,
              onAction: () => context.go('/home'),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(context.pagePadding),
                    children: [
                      ...cart.items.map((item) => _CartTile(item: item)),
                      const SizedBox(height: 16),
                      Text(l10n.haveCoupon, style: context.texts.titleSmall),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: QmaxTextField(label: 'QMAX10', controller: _coupon),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(onPressed: _applyCoupon, child: Text(l10n.apply)),
                        ],
                      ),
                      if (_couponMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(_couponMessage!, style: TextStyle(color: _couponError ? context.colors.error : const Color(0xFF2D6A4F))),
                        ),
                      const SizedBox(height: 20),
                      _Totals(cart: cart),
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: QmaxButton(
                      label: l10n.checkout,
                      onPressed: () {
                        if (!RequireAuth.ensure(context, ref, message: l10n.loginToCheckout)) return;
                        context.push('/checkout');
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CartTile extends ConsumerWidget {
  const _CartTile({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(imageUrl: item.product.image, width: 72, height: 72, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                  QmaxPrice(price: item.product.effectivePrice),
                  Row(
                    children: [
                      QmaxQuantityStepper(
                        value: item.quantity,
                        max: item.product.stock,
                        onChanged: (v) => ref.read(cartProvider.notifier).setQuantity(item.product.id, v),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          if (!RequireAuth.ensure(context, ref, message: l10n.loginToSaveWishlist)) return;
                          await ref.read(wishlistProvider.notifier).toggle(item.product.id, authenticated: true);
                          await ref.read(cartProvider.notifier).remove(item.product.id);
                        },
                        child: Text(l10n.saveForLater),
                      ),
                      IconButton(
                        onPressed: () => ref.read(cartProvider.notifier).remove(item.product.id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.cart});
  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget row(String label, String value, {bool bold = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(label, style: bold ? Theme.of(context).textTheme.titleMedium : null),
            const Spacer(),
            Text(value, style: bold ? Theme.of(context).textTheme.titleMedium : null),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            row(l10n.subtotal, Formatters.money(cart.subtotal)),
            row(l10n.delivery, cart.deliveryFee == 0 ? l10n.free : Formatters.money(cart.deliveryFee)),
            row(l10n.discount, '-${Formatters.money(cart.discount)}'),
            const Divider(),
            row(l10n.total, Formatters.money(cart.total), bold: true),
          ],
        ),
      ),
    );
  }
}

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> with CartActions {
  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final ids = ref.watch(wishlistProvider);
    final l10n = context.l10n;
    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.wishlist)),
        body: QmaxEmptyState(
          icon: Icons.favorite_border,
          title: l10n.loginToSaveWishlist,
          actionLabel: l10n.login,
          onAction: () => context.push('/login'),
        ),
      );
    }
    final products = [
      for (final id in ids)
        if (ref.watch(productProvider(id)).valueOrNull != null) ref.watch(productProvider(id)).valueOrNull!,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.wishlist)),
      body: products.isEmpty
          ? QmaxEmptyState(icon: Icons.favorite_border, title: l10n.emptyWishlist, subtitle: l10n.emptyWishlistHint, actionLabel: l10n.startShopping, onAction: () => context.go('/home'))
          : ProductGrid(
              products: products,
              padding: EdgeInsets.all(context.pagePadding),
              isWishlisted: (_) => true,
              onTap: (p) => context.push('/products/${p.id}'),
              onAdd: addProduct,
              onWishlist: toggleWish,
            ),
    );
  }
}
