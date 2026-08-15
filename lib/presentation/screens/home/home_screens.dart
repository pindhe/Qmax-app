import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/entities.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/connectivity_service.dart';
import '../../providers/state_providers.dart';
import '../../widgets/common/cart_actions.dart';
import '../../widgets/common/qmax_common.dart';
import '../../widgets/product/product_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with CartActions {
  final _bannerController = PageController();

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categories = ref.watch(categoriesProvider);
    final banners = ref.watch(bannersProvider);
    final featured = ref.watch(featuredProductsProvider);
    final popular = ref.watch(popularProductsProvider);
    final newest = ref.watch(newProductsProvider);
    final offers = ref.watch(offerProductsProvider);
    final online = ref.watch(isOnlineProvider);
    final loading = categories.isLoading || banners.isLoading;

    return Scaffold(
      body: SafeArea(
        child: loading
            ? const HomeSkeleton()
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(categoriesProvider);
                  ref.invalidate(bannersProvider);
                  ref.invalidate(featuredProductsProvider);
                  ref.invalidate(popularProductsProvider);
                  ref.invalidate(newProductsProvider);
                  ref.invalidate(offerProductsProvider);
                },
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(context.pagePadding, 8, context.pagePadding, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!online)
                              _OfflineBanner(label: l10n.offlineCached),
                            Text('QMAX TOOLS', style: context.texts.labelLarge?.copyWith(letterSpacing: 1.4, color: context.colors.primary)),
                            Text(Formatters.greeting(TimeOfDay.now(), l10n), style: context.texts.headlineSmall),
                            Text(l10n.shopAtQmax, style: context.texts.bodyMedium),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.location_on, color: context.colors.primary, size: 18),
                                const SizedBox(width: 4),
                                Text(l10n.hargeisa, style: context.texts.titleSmall),
                                const SizedBox(width: 8),
                                Text(l10n.deliverTo, style: context.texts.bodySmall),
                              ],
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () => context.push('/search'),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.search),
                                  hintText: l10n.searchProducts,
                                ),
                                child: Text(l10n.searchProducts, style: TextStyle(color: context.colors.onSurfaceVariant)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            banners.when(
                              data: (items) => _BannerCarousel(items: items, controller: _bannerController),
                              loading: () => const _ShimmerBanner(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 20),
                            _SectionHeader(title: l10n.categories, onViewAll: () => context.push('/categories')),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 128,
                        child: categories.when(
                          data: (items) => ListView.separated(
                            padding: EdgeInsets.symmetric(horizontal: context.pagePadding),
                            scrollDirection: Axis.horizontal,
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (_, i) => QmaxCategoryCard(
                              category: items[i],
                              onTap: () => context.push('/categories/${items[i].id}'),
                            ),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    ..._productSection(l10n.featuredProducts, featured, '/explore?sort=popular'),
                    ..._productSection(l10n.popularProducts, popular, '/explore'),
                    ..._productSection(l10n.newArrivals, newest, '/explore?sort=newest'),
                    ..._productSection(l10n.specialOffers, offers, '/explore'),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
      ),
    );
  }

  List<Widget> _productSection(String title, AsyncValue<List<Product>> value, String more) {
    final products = value.valueOrNull ?? [];
    if (products.isEmpty && !value.isLoading) return [];
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(context.pagePadding, 20, context.pagePadding, 12),
          child: _SectionHeader(title: title, onViewAll: () => context.go('/explore')),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: context.pagePadding),
        sliver: SliverToBoxAdapter(
          child: SizedBox(
            height: 320,
            child: value.isLoading
                ? const ProductSkeleton()
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final p = products[i];
                      return SizedBox(
                        width: 180,
                        child: QmaxProductCard(
                          product: p,
                          wishlisted: ref.watch(wishlistProvider).contains(p.id),
                          onTap: () => context.push('/products/${p.id}'),
                          onAdd: () => addProduct(p),
                          onWishlist: () => toggleWish(p),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    ];
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onViewAll});
  final String title;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        TextButton(onPressed: onViewAll, child: Text(context.l10n.viewAll)),
      ],
    );
  }
}

class _BannerCarousel extends StatelessWidget {
  const _BannerCarousel({required this.items, required this.controller});
  final List<PromoBanner> items;
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: controller,
            itemCount: items.length,
            itemBuilder: (_, i) {
              final banner = items[i];
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(imageUrl: banner.imageUrl, fit: BoxFit.cover),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xCC0D1B2A), Color(0x330D1B2A)],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(banner.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                            Text(banner.subtitle, style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 8),
                            FilledButton(
                              onPressed: () {
                                if (banner.categoryId != null) {
                                  context.push('/categories/${banner.categoryId}');
                                } else {
                                  context.go('/explore');
                                }
                              },
                              child: Text(context.l10n.shopNow),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        SmoothPageIndicator(
          controller: controller,
          count: items.length,
          effect: ExpandingDotsEffect(
            activeDotColor: Theme.of(context).colorScheme.primary,
            dotHeight: 7,
            dotWidth: 7,
          ),
        ),
      ],
    );
  }
}

class _ShimmerBanner extends StatelessWidget {
  const _ShimmerBanner();
  @override
  Widget build(BuildContext context) => const SizedBox(height: 170, child: ProductSkeleton());
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label),
    );
  }
}

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> with CartActions {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    Future.microtask(() => ref.read(exploreProvider.notifier).load(refresh: true));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) {
      ref.read(exploreProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exploreProvider);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.exploreCatalog),
        actions: [
          IconButton(onPressed: () => context.push('/search'), icon: const Icon(Icons.search)),
          IconButton(
            onPressed: () => openProductFilters(context, l10n, state.filter, (f) => ref.read(exploreProvider.notifier).load(filter: f, refresh: true)),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: state.loading && state.items.isEmpty
          ? GridView.builder(
              padding: EdgeInsets.all(context.pagePadding),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.58, mainAxisSpacing: 12, crossAxisSpacing: 12),
              itemCount: 6,
              itemBuilder: (_, __) => const ProductSkeleton(),
            )
          : state.items.isEmpty
              ? QmaxEmptyState(icon: Icons.inventory_2_outlined, title: l10n.noProductsFound)
              : Column(
                  children: [
                    Expanded(
                      child: ProductGrid(
                        products: state.items,
                        padding: EdgeInsets.all(context.pagePadding),
                        controller: _scroll,
                        isWishlisted: (id) => ref.watch(wishlistProvider).contains(id),
                        onTap: (p) => context.push('/products/${p.id}'),
                        onAdd: addProduct,
                        onWishlist: toggleWish,
                      ),
                    ),
                    if (state.loadingMore)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(l10n.loadingMore),
                      ),
                  ],
                ),
    );
  }
}

Future<void> openProductFilters(
  BuildContext context,
  AppLocalizations l10n,
  ProductFilter current,
  ValueChanged<ProductFilter> onApply,
) async {
  var filter = current;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModal) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.paddingOf(ctx).bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.filters, style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: ProductSort.values.map((s) {
                    final label = switch (s) {
                      ProductSort.newest => l10n.newest,
                      ProductSort.popular => l10n.popular,
                      ProductSort.priceLowHigh => l10n.priceLowHigh,
                      ProductSort.priceHighLow => l10n.priceHighLow,
                    };
                    return ChoiceChip(
                      label: Text(label),
                      selected: filter.sort == s,
                      onSelected: (_) => setModal(() => filter = filter.copyWith(sort: s)),
                    );
                  }).toList(),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.inStock),
                  value: filter.inStockOnly,
                  onChanged: (v) => setModal(() => filter = filter.copyWith(inStockOnly: v)),
                ),
                Wrap(
                  spacing: 8,
                  children: [4, 3, 2].map((r) {
                    return ChoiceChip(
                      label: Text(l10n.ratingAndUp(r)),
                      selected: filter.minRating == r,
                      onSelected: (_) => setModal(() => filter = filter.copyWith(minRating: r)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () => onApply(const ProductFilter()), child: Text(l10n.reset))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          onApply(filter);
                          Navigator.pop(ctx);
                        },
                        child: Text(l10n.showResults),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.allCategories)),
      body: GridView.builder(
        padding: EdgeInsets.all(context.pagePadding),
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.3, mainAxisSpacing: 12, crossAxisSpacing: 12),
        itemBuilder: (_, i) => QmaxCategoryCard(
          category: categories[i],
          onTap: () => context.push('/categories/${categories[i].id}'),
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
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(exploreProvider.notifier).load(
            filter: ProductFilter(categoryId: widget.categoryId),
            refresh: true,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final cat = cats.where((c) => c.id == widget.categoryId).firstOrNull;
    final state = ref.watch(exploreProvider);
    return Scaffold(
      appBar: AppBar(title: Text(cat?.name ?? context.l10n.categories)),
      body: ProductGrid(
        products: state.items,
        padding: EdgeInsets.all(context.pagePadding),
        isWishlisted: (id) => ref.watch(wishlistProvider).contains(id),
        onTap: (p) => context.push('/products/${p.id}'),
        onAdd: addProduct,
        onWishlist: toggleWish,
      ),
    );
  }
}
