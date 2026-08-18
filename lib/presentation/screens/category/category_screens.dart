import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/state_providers.dart';
import '../../widgets/common/cart_actions.dart';
import '../../widgets/common/qmax_common.dart';
import '../../widgets/product/product_widgets.dart';
import '../home/home_screens.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.allCategories)),
      body: categories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => QmaxError(
          message: context.l10n.somethingWentWrong,
          onRetry: () => ref.invalidate(categoriesProvider),
        ),
        data: (items) => GridView.builder(
          padding: EdgeInsets.all(context.pagePadding),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.12,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (_, i) => QmaxCategoryCard(
            category: items[i],
            onTap: () => context.push('/categories/${items[i].id}'),
          ),
        ),
      ),
    );
  }
}

class CategoryProductsScreen extends ConsumerStatefulWidget {
  const CategoryProductsScreen({super.key, required this.categoryId});
  final int categoryId;

  @override
  ConsumerState<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends ConsumerState<CategoryProductsScreen> with CartActions {
  ProductSort _sort = ProductSort.popular;

  List<Product> _sorted(List<Product> items) {
    final list = [...items];
    switch (_sort) {
      case ProductSort.newest:
        list.sort((a, b) => b.id.compareTo(a.id));
      case ProductSort.popular:
        list.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
      case ProductSort.priceLowHigh:
        list.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
      case ProductSort.priceHighLow:
        list.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final cat = cats.where((c) => c.id == widget.categoryId).firstOrNull;
    final async = ref.watch(categoryProductsProvider(widget.categoryId));

    return Scaffold(
      appBar: AppBar(
        title: Text(cat?.name ?? l10n.categories),
        actions: [
          IconButton(onPressed: () => context.push('/search'), icon: const Icon(Icons.search)),
          IconButton(
            onPressed: () => openProductFilters(
              context,
              l10n,
              ProductFilter(categoryId: widget.categoryId, sort: _sort),
              (f) => setState(() => _sort = f.sort),
            ),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: async.when(
        loading: () => GridView.builder(
          padding: EdgeInsets.all(context.pagePadding),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.58,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: 4,
          itemBuilder: (_, __) => const ProductSkeleton(),
        ),
        error: (_, __) => QmaxError(
          message: l10n.somethingWentWrong,
          onRetry: () => ref.invalidate(categoryProductsProvider(widget.categoryId)),
        ),
        data: (products) {
          final items = _sorted(products);
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(context.pagePadding, 8, context.pagePadding, 12),
                  child: _CategoryHero(category: cat, count: products.length),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: context.pagePadding),
                    children: [
                      _SortChip(
                        label: l10n.popular,
                        selected: _sort == ProductSort.popular,
                        onTap: () => setState(() => _sort = ProductSort.popular),
                      ),
                      _SortChip(
                        label: l10n.newest,
                        selected: _sort == ProductSort.newest,
                        onTap: () => setState(() => _sort = ProductSort.newest),
                      ),
                      _SortChip(
                        label: l10n.priceLowHigh,
                        selected: _sort == ProductSort.priceLowHigh,
                        onTap: () => setState(() => _sort = ProductSort.priceLowHigh),
                      ),
                      _SortChip(
                        label: l10n.priceHighLow,
                        selected: _sort == ProductSort.priceHighLow,
                        onTap: () => setState(() => _sort = ProductSort.priceHighLow),
                      ),
                    ],
                  ),
                ),
              ),
              if (items.isEmpty)
                SliverFillRemaining(
                  child: QmaxEmptyState(icon: Icons.inventory_2_outlined, title: l10n.noProductsFound),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(context.pagePadding, 12, context.pagePadding, 24),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: Helpers.crossAxisCount(context),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.58,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = items[index];
                        return QmaxProductCard(
                          product: product,
                          wishlisted: ref.watch(wishlistProvider).contains(product.id),
                          onTap: () => context.push('/products/${product.id}'),
                          onAdd: () => addProduct(product),
                          onWishlist: () => toggleWish(product),
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryHero extends StatelessWidget {
  const _CategoryHero({required this.category, required this.count});
  final Category? category;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: colors.primaryContainer,
            child: Icon(
              QmaxCategoryCard.iconFor(category?.icon ?? 'hardware'),
              color: colors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category?.name ?? context.l10n.categories, style: Theme.of(context).textTheme.titleLarge),
                if (category?.description != null)
                  Text(category!.description!, style: Theme.of(context).textTheme.bodySmall),
                Text(
                  context.l10n.productsCount(count),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
