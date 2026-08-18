import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/entities.dart';
import '../common/qmax_common.dart';

class QmaxProductCard extends StatelessWidget {
  const QmaxProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAdd,
    required this.onWishlist,
    required this.wishlisted,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onWishlist;
  final bool wishlisted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Hero(
                      tag: 'product-${product.id}',
                      child: CachedNetworkImage(
                        imageUrl: product.image,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const _ShimmerBox(),
                        errorWidget: (_, __, ___) => ColoredBox(
                          color: colors.surfaceContainer,
                          child: Icon(Icons.handyman_outlined, color: colors.outline),
                        ),
                      ),
                    ),
                  ),
                  if (product.hasDiscount)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.error,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          '${product.discountPercent}% OFF',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.onError),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: IconButton.filledTonal(
                      onPressed: onWishlist,
                      icon: Icon(
                        wishlisted ? Icons.favorite : Icons.favorite_border,
                        color: wishlisted ? colors.error : null,
                      ),
                    ).animate(target: wishlisted ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.12, 1.12)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.brand, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.primary)),
                  Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  QmaxRating(rating: product.rating, count: product.reviewCount, size: 14),
                  const SizedBox(height: 4),
                  QmaxPrice(price: product.effectivePrice, oldPrice: product.hasDiscount ? product.price : null),
                  const SizedBox(height: 4),
                  Text(
                    product.isOutOfStock
                        ? 'Out of Stock'
                        : product.isLowStock
                            ? 'Only ${product.stock} left'
                            : 'In Stock',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: product.isOutOfStock
                              ? colors.error
                              : product.isLowStock
                                  ? colors.tertiary
                                  : const Color(0xFF2D6A4F),
                        ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(36), padding: EdgeInsets.zero),
                      onPressed: product.isOutOfStock ? null : onAdd,
                      child: const Text('+ Add'),
                    ),
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

class QmaxCategoryCard extends StatelessWidget {
  const QmaxCategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    this.width,
  });

  final Category category;
  final VoidCallback onTap;
  final double? width;

  static IconData iconFor(String key) => switch (key) {
        'handyman' => Icons.handyman,
        'bolt' => Icons.bolt,
        'electrical_services' => Icons.electrical_services,
        'water_drop' => Icons.water_drop,
        'apartment' => Icons.apartment,
        'grid_view' => Icons.grid_view,
        'format_paint' => Icons.format_paint,
        'health_and_safety' => Icons.health_and_safety,
        'home_repair_service' => Icons.home_repair_service,
        _ => Icons.hardware,
      };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: width == null ? 28 : 22,
              backgroundColor: colors.primaryContainer,
              child: Icon(iconFor(category.icon), color: colors.primary, size: width == null ? 26 : 22),
            ),
            const SizedBox(height: 10),
            Text(
              category.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${category.productCount}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductSkeleton extends StatelessWidget {
  const ProductSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Column(
        children: [
          Expanded(child: _ShimmerBox()),
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              children: [
                _ShimmerBox(height: 12),
                SizedBox(height: 8),
                _ShimmerBox(height: 12, width: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _ShimmerBox(height: 28, width: 180),
        SizedBox(height: 12),
        _ShimmerBox(height: 48),
        SizedBox(height: 16),
        _ShimmerBox(height: 160),
        SizedBox(height: 16),
        _ShimmerBox(height: 96),
      ],
    );
  }
}

class OrderSkeleton extends StatelessWidget {
  const OrderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _ShimmerBox(height: 88),
          SizedBox(height: 12),
          _ShimmerBox(height: 88),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({this.height, this.width});
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: colors.surfaceContainer,
      highlightColor: colors.surfaceContainerLowest,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class ProductGrid extends StatelessWidget {
  const ProductGrid({
    super.key,
    required this.products,
    required this.onTap,
    required this.onAdd,
    required this.onWishlist,
    required this.isWishlisted,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.controller,
  });

  final List<Product> products;
  final ValueChanged<Product> onTap;
  final ValueChanged<Product> onAdd;
  final ValueChanged<Product> onWishlist;
  final bool Function(int id) isWishlisted;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final count = width >= 1200 ? 4 : width >= 840 ? 3 : 2;
    return GridView.builder(
      padding: padding ?? EdgeInsets.zero,
      physics: physics,
      shrinkWrap: shrinkWrap,
      controller: controller,
      itemCount: products.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: count,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.58,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        return QmaxProductCard(
          product: product,
          wishlisted: isWishlisted(product.id),
          onTap: () => onTap(product),
          onAdd: () => onAdd(product),
          onWishlist: () => onWishlist(product),
        );
      },
    );
  }
}
