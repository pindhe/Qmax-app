import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/validators.dart';
import '../../providers/app_providers.dart';
import '../../providers/state_providers.dart';
import '../../widgets/common/cart_actions.dart';
import '../../widgets/common/qmax_common.dart';
import '../../widgets/navigation/main_shell.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  const ProductDetailsScreen({super.key, required this.productId});
  final int productId;

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> with CartActions {
  int _qty = 1;
  int _imageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(productProvider(widget.productId));
    final l10n = context.l10n;
    return async.when(
      loading: () => const Scaffold(body: QmaxLoading()),
      error: (_, __) => Scaffold(body: QmaxError(message: l10n.somethingWentWrong, onRetry: () => ref.invalidate(productProvider(widget.productId)))),
      data: (product) {
        if (product == null) {
          return Scaffold(body: QmaxEmptyState(icon: Icons.inventory_2_outlined, title: l10n.noProductsFound));
        }
        final wishlisted = ref.watch(wishlistProvider).contains(product.id);
        return Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                onPressed: () => toggleWish(product),
                icon: Icon(wishlisted ? Icons.favorite : Icons.favorite_border, color: wishlisted ? context.colors.error : null),
              ),
              IconButton(
                onPressed: () => Share.share('${product.name} — ${Formatters.money(product.effectivePrice)} at QMAX Tools'),
                icon: const Icon(Icons.share_outlined),
              ),
            ],
          ),
          body: ListView(
            children: [
              SizedBox(
                height: 320,
                child: Stack(
                  children: [
                    PageView.builder(
                      itemCount: product.images.length,
                      onPageChanged: (i) => setState(() => _imageIndex = i),
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => _openGallery(product.images, i),
                        child: Hero(
                          tag: i == 0 ? 'product-${product.id}' : 'product-${product.id}-$i',
                          child: CachedNetworkImage(imageUrl: product.images[i], fit: BoxFit.cover, width: double.infinity),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          product.images.length,
                          (i) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == _imageIndex ? context.colors.primary : Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(context.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.brand, style: context.texts.labelLarge?.copyWith(color: context.colors.primary)),
                    Text(product.name, style: context.texts.headlineSmall),
                    const SizedBox(height: 6),
                    Text('${l10n.sku}: ${product.sku}', style: context.texts.bodySmall),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => context.push('/products/${product.id}/reviews'),
                      child: QmaxRating(rating: product.rating, count: product.reviewCount),
                    ),
                    const SizedBox(height: 12),
                    QmaxPrice(price: product.effectivePrice, oldPrice: product.hasDiscount ? product.price : null, large: true),
                    if (product.hasDiscount)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(l10n.offPercent(product.discountPercent), style: TextStyle(color: context.colors.error, fontWeight: FontWeight.w700)),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      product.isOutOfStock
                          ? l10n.outOfStock
                          : product.isLowStock
                              ? l10n.onlyLeft(product.stock)
                              : l10n.inStock,
                      style: TextStyle(
                        color: product.isOutOfStock ? context.colors.error : const Color(0xFF2D6A4F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(l10n.quantity, style: context.texts.titleSmall),
                        const Spacer(),
                        QmaxQuantityStepper(
                          value: _qty,
                          max: product.stock == 0 ? 1 : product.stock,
                          onChanged: (v) => setState(() => _qty = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _Expandable(title: l10n.description, body: product.description, initiallyOpen: true),
                    _Expandable(
                      title: l10n.specifications,
                      body: product.specifications.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
                    ),
                    if (product.materials != null) _Expandable(title: l10n.materials, body: product.materials!),
                    if (product.dimensions != null) _Expandable(title: l10n.dimensions, body: product.dimensions!),
                    if (product.weight != null) _Expandable(title: l10n.weight, body: product.weight!),
                    if (product.warranty != null) _Expandable(title: l10n.warranty, body: product.warranty!),
                    _Expandable(title: l10n.availability, body: product.isOutOfStock ? l10n.outOfStock : l10n.inStock),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.reviews),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/products/${product.id}/reviews'),
                    ),
                    const SizedBox(height: 88),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: QmaxButton(
                      label: l10n.addToCart,
                      outlined: true,
                      onPressed: product.isOutOfStock ? null : () => addProduct(product, qty: _qty),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: QmaxButton(
                      label: l10n.buyNow,
                      onPressed: product.isOutOfStock
                          ? null
                          : () async {
                              await addProduct(product, qty: _qty);
                              if (!context.mounted) return;
                              if (!RequireAuth.ensure(context, ref, message: context.l10n.loginToCheckout)) return;
                              context.push('/checkout');
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openGallery(List<String> images, int index) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullscreenGallery(images: images, initial: index),
      ),
    );
  }
}

class _Expandable extends StatelessWidget {
  const _Expandable({required this.title, required this.body, this.initiallyOpen = false});
  final String title;
  final String body;
  final bool initiallyOpen;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: initiallyOpen,
      tilePadding: EdgeInsets.zero,
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      children: [
        Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(body))),
      ],
    );
  }
}

class _FullscreenGallery extends StatelessWidget {
  const _FullscreenGallery({required this.images, required this.initial});
  final List<String> images;
  final int initial;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: PhotoViewGallery.builder(
        itemCount: images.length,
        pageController: PageController(initialPage: initial),
        builder: (_, i) => PhotoViewGalleryPageOptions(
          imageProvider: CachedNetworkImageProvider(images[i]),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
        ),
      ),
    );
  }
}

class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key, required this.productId});
  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(reviewsProvider(productId)).valueOrNull ?? [];
    final product = ref.watch(productProvider(productId)).valueOrNull;
    final l10n = context.l10n;
    final counts = List<int>.generate(5, (i) => reviews.where((r) => r.rating == 5 - i).length);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reviews),
        actions: [
          TextButton(
            onPressed: () {
              if (!RequireAuth.ensure(context, ref, message: l10n.loginToReview)) return;
              context.push('/products/$productId/review');
            },
            child: Text(l10n.writeReview),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(context.pagePadding),
        children: [
          if (product != null) ...[
            Row(
              children: [
                Text(product.rating.toStringAsFixed(1), style: context.texts.displaySmall),
                const SizedBox(width: 12),
                const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 32),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < 5; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Text('${5 - i} ★'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: reviews.isEmpty ? 0 : counts[i] / reviews.length,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
          ],
          if (reviews.isEmpty) QmaxEmptyState(icon: Icons.reviews_outlined, title: l10n.noReviews),
          ...reviews.map(
            (r) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(r.userName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    QmaxRating(rating: r.rating.toDouble()),
                    const SizedBox(height: 4),
                    Text(r.comment),
                  ],
                ),
                isThreeLine: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WriteReviewScreen extends ConsumerStatefulWidget {
  const WriteReviewScreen({super.key, required this.productId});
  final int productId;

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  int _rating = 5;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.writeReview)),
      body: Padding(
        padding: EdgeInsets.all(context.pagePadding),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => IconButton(
                  onPressed: () => setState(() => _rating = i + 1),
                  icon: Icon(i < _rating ? Icons.star : Icons.star_border, color: const Color(0xFFF59E0B), size: 36),
                ),
              ),
            ),
            QmaxTextField(label: l10n.comment, controller: _comment, maxLines: 5),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.showSnack(l10n.uploadImages),
              icon: const Icon(Icons.photo_outlined),
              label: Text(l10n.uploadImages),
            ),
            const Spacer(),
            QmaxButton(
              label: l10n.submitReview,
              onPressed: () async {
                await ref.read(catalogRepositoryProvider).addReview(
                      productId: widget.productId,
                      rating: _rating,
                      comment: _comment.text,
                      images: const [],
                    );
                if (!context.mounted) return;
                context.showSnack(l10n.reviewSubmitted);
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
