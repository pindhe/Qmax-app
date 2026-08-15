import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/datasources/mock/mock_data.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/state_providers.dart';
import '../../widgets/common/cart_actions.dart';
import '../../widgets/common/qmax_common.dart';
import '../../widgets/product/product_widgets.dart';
import '../home/home_screens.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> with CartActions {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: AppConstants.searchDebounceMs), () {
      setState(() => _query = value.trim());
      if (_query.isNotEmpty) {
        ref.read(recentSearchesProvider.notifier).add(_query);
        ref.read(searchProvider.notifier).load(
              filter: ProductFilter(query: _query),
              refresh: true,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final recent = ref.watch(recentSearchesProvider);
    final results = ref.watch(searchProvider);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.searchQmax,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
        ),
        actions: [
          IconButton(
            onPressed: () => openProductFilters(
              context,
              l10n,
              results.filter.copyWith(query: _query),
              (f) => ref.read(searchProvider.notifier).load(filter: f.copyWith(query: _query), refresh: true),
            ),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: _query.isEmpty
          ? ListView(
              padding: EdgeInsets.all(context.pagePadding),
              children: [
                Row(
                  children: [
                    Expanded(child: Text(l10n.recentSearches, style: context.texts.titleMedium)),
                    if (recent.isNotEmpty)
                      TextButton(onPressed: () => ref.read(recentSearchesProvider.notifier).clear(), child: Text(l10n.clearHistory)),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: recent
                      .map((e) => ActionChip(
                            label: Text(e),
                            onPressed: () {
                              _controller.text = e;
                              _onChanged(e);
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 20),
                Text(l10n.popularSearches, style: context.texts.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: MockData.popularSearches
                      .map((e) => ActionChip(
                            label: Text(e),
                            onPressed: () {
                              _controller.text = e;
                              _onChanged(e);
                            },
                          ))
                      .toList(),
                ),
              ],
            )
          : results.items.isEmpty && !results.loading
              ? QmaxEmptyState(icon: Icons.search_off, title: l10n.noProductsFound)
              : ProductGrid(
                  products: results.items,
                  padding: EdgeInsets.all(context.pagePadding),
                  isWishlisted: (id) => ref.watch(wishlistProvider).contains(id),
                  onTap: (p) => context.push('/products/${p.id}'),
                  onAdd: addProduct,
                  onWishlist: toggleWish,
                ),
    );
  }
}
