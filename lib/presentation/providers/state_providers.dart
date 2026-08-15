import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_result.dart';
import '../../domain/entities/entities.dart';
import 'app_providers.dart';

class AuthState {
  const AuthState({this.user, this.isLoading = false, this.error});
  final User? user;
  final bool isLoading;
  final String? error;
  bool get isAuthenticated => user != null;

  AuthState copyWith({User? user, bool? isLoading, String? error, bool clearUser = false}) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> restore() async {
    final user = await ref.read(authRepositoryProvider).currentUser();
    if (user != null) state = AuthState(user: user);
  }

  Future<bool> login(String identifier, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await ref.read(authRepositoryProvider).login(identifier, password);
    return switch (result) {
      ApiSuccess(:final data) => () {
          state = AuthState(user: data);
          return true;
        }(),
      ApiFailure(:final message) => () {
          state = state.copyWith(isLoading: false, error: message);
          return false;
        }(),
    };
  }

  Future<bool> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await ref.read(authRepositoryProvider).register(
          name: name,
          phone: phone,
          email: email,
          password: password,
        );
    return switch (result) {
      ApiSuccess(:final data) => () {
          state = AuthState(user: data);
          return true;
        }(),
      ApiFailure(:final message) => () {
          state = state.copyWith(isLoading: false, error: message);
          return false;
        }(),
    };
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState();
  }

  Future<bool> sendOtp(String identifier) async {
    final result = await ref.read(authRepositoryProvider).sendOtp(identifier);
    return result is ApiSuccess;
  }

  Future<bool> verifyOtp(String identifier, String otp) async {
    final result = await ref.read(authRepositoryProvider).verifyOtp(identifier, otp);
    return result is ApiSuccess;
  }

  Future<bool> resetPassword(String identifier, String password) async {
    final result =
        await ref.read(authRepositoryProvider).resetPassword(identifier, password);
    return result is ApiSuccess;
  }

  Future<bool> changePassword(String current, String next) async {
    final result =
        await ref.read(authRepositoryProvider).changePassword(current, next);
    return result is ApiSuccess;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('en'),
    this.notificationsEnabled = true,
    this.onboardingComplete = false,
  });

  final ThemeMode themeMode;
  final Locale locale;
  final bool notificationsEnabled;
  final bool onboardingComplete;

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? notificationsEnabled,
    bool? onboardingComplete,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final storage = ref.read(storageServiceProvider);
    final theme = switch (storage.themeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final localeCode = storage.locale ?? 'en';
    return SettingsState(
      themeMode: theme,
      locale: Locale(localeCode),
      notificationsEnabled: storage.notificationsEnabled,
      onboardingComplete: storage.onboardingComplete,
    );
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await ref.read(storageServiceProvider).setThemeMode(mode.name);
  }

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    await ref.read(storageServiceProvider).setLocale(locale.languageCode);
  }

  Future<void> setNotifications(bool value) async {
    state = state.copyWith(notificationsEnabled: value);
    await ref.read(storageServiceProvider).setNotificationsEnabled(value);
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(onboardingComplete: true);
    await ref.read(storageServiceProvider).setOnboardingComplete();
  }

  Future<void> clearCache() => ref.read(storageServiceProvider).clearCache();
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);

class CartNotifier extends Notifier<Cart> {
  @override
  Cart build() {
    Future.microtask(restore);
    return const Cart();
  }

  Future<void> restore() async {
    state = await ref.read(cartRepositoryProvider).load();
  }

  Future<String?> add(Product product, {int quantity = 1}) async {
    if (product.isOutOfStock) return 'out';
    final existing = state.items.where((i) => i.product.id == product.id).firstOrNull;
    final nextQty = (existing?.quantity ?? 0) + quantity;
    if (nextQty > product.stock) return 'stock';
    final items = [...state.items];
    if (existing == null) {
      items.add(CartItem(product: product, quantity: quantity));
    } else {
      final index = items.indexWhere((i) => i.product.id == product.id);
      items[index] = existing.copyWith(quantity: nextQty);
    }
    await _persist(state: Cart(items: items, coupon: state.coupon, deliveryFee: state.deliveryFee));
    return null;
  }

  Future<void> setQuantity(int productId, int quantity) async {
    final items = [...state.items];
    final index = items.indexWhere((i) => i.product.id == productId);
    if (index < 0) return;
    final product = items[index].product;
    if (quantity <= 0) {
      items.removeAt(index);
    } else {
      items[index] = items[index].copyWith(quantity: quantity.clamp(1, product.stock));
    }
    await _persist(state: Cart(items: items, coupon: state.coupon, deliveryFee: state.deliveryFee));
  }

  Future<void> remove(int productId) => setQuantity(productId, 0);

  Future<void> applyCoupon(Coupon? coupon) async {
    await _persist(state: Cart(items: state.items, coupon: coupon, deliveryFee: state.deliveryFee));
  }

  Future<void> setDeliveryFee(double fee) async {
    await _persist(state: Cart(items: state.items, coupon: state.coupon, deliveryFee: fee));
  }

  Future<void> clear() async {
    await _persist(state: const Cart());
  }

  Future<void> _persist({required Cart state}) async {
    this.state = await ref.read(cartRepositoryProvider).save(state);
  }
}

final cartProvider = NotifierProvider<CartNotifier, Cart>(CartNotifier.new);

class WishlistNotifier extends Notifier<List<int>> {
  @override
  List<int> build() {
    Future.microtask(restore);
    return const [];
  }

  Future<void> restore() async {
    state = await ref.read(wishlistRepositoryProvider).loadIds();
  }

  bool contains(int id) => state.contains(id);

  Future<bool> toggle(int id, {required bool authenticated}) async {
    if (!authenticated) return false;
    final next = [...state];
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = next;
    await ref.read(wishlistRepositoryProvider).saveIds(next);
    return true;
  }

  Future<void> remove(int id) async {
    final next = [...state]..remove(id);
    state = next;
    await ref.read(wishlistRepositoryProvider).saveIds(next);
  }
}

final wishlistProvider =
    NotifierProvider<WishlistNotifier, List<int>>(WishlistNotifier.new);

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final result = await ref.watch(catalogRepositoryProvider).getCategories();
  return switch (result) {
    ApiSuccess(:final data) => data,
    ApiFailure() => [],
  };
});

final bannersProvider = FutureProvider<List<PromoBanner>>((ref) async {
  final result = await ref.watch(catalogRepositoryProvider).getBanners();
  return switch (result) {
    ApiSuccess(:final data) => data,
    ApiFailure() => [],
  };
});

final productProvider = FutureProvider.family<Product?, int>((ref, id) async {
  final result = await ref.watch(catalogRepositoryProvider).getProduct(id);
  return switch (result) {
    ApiSuccess(:final data) => data,
    ApiFailure() => null,
  };
});

final reviewsProvider = FutureProvider.family<List<Review>, int>((ref, id) async {
  final result = await ref.watch(catalogRepositoryProvider).getReviews(id);
  return switch (result) {
    ApiSuccess(:final data) => data,
    ApiFailure() => [],
  };
});

class ProductListState {
  const ProductListState({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.filter = const ProductFilter(),
    this.total = 0,
  });

  final List<Product> items;
  final int page;
  final bool hasMore;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final ProductFilter filter;
  final int total;

  ProductListState copyWith({
    List<Product>? items,
    int? page,
    bool? hasMore,
    bool? loading,
    bool? loadingMore,
    String? error,
    ProductFilter? filter,
    int? total,
  }) {
    return ProductListState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
      filter: filter ?? this.filter,
      total: total ?? this.total,
    );
  }
}

class ProductListNotifier extends Notifier<ProductListState> {
  @override
  ProductListState build() => const ProductListState();

  Future<void> load({ProductFilter? filter, bool refresh = false}) async {
    final nextFilter = filter ?? state.filter;
    state = state.copyWith(
      loading: true,
      filter: nextFilter,
      items: refresh || filter != null ? [] : state.items,
      page: 1,
    );
    final result = await ref.read(catalogRepositoryProvider).getProducts(
          page: 1,
          filter: nextFilter,
        );
    state = switch (result) {
      ApiSuccess(:final data) => ProductListState(
          items: data.items,
          page: data.page,
          hasMore: data.hasMore,
          total: data.total,
          filter: nextFilter,
        ),
      ApiFailure(:final message) => state.copyWith(loading: false, error: message),
    };
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore || state.loading) return;
    state = state.copyWith(loadingMore: true);
    final nextPage = state.page + 1;
    final result = await ref.read(catalogRepositoryProvider).getProducts(
          page: nextPage,
          filter: state.filter,
        );
    state = switch (result) {
      ApiSuccess(:final data) => state.copyWith(
          items: [...state.items, ...data.items],
          page: data.page,
          hasMore: data.hasMore,
          loadingMore: false,
          total: data.total,
        ),
      ApiFailure(:final message) => state.copyWith(loadingMore: false, error: message),
    };
  }
}

final featuredProductsProvider = FutureProvider<List<Product>>((ref) async {
  final result = await ref.watch(catalogRepositoryProvider).getSection('featured');
  return result is ApiSuccess<List<Product>> ? result.data : [];
});

final popularProductsProvider = FutureProvider<List<Product>>((ref) async {
  final result = await ref.watch(catalogRepositoryProvider).getSection('popular');
  return result is ApiSuccess<List<Product>> ? result.data : [];
});

final newProductsProvider = FutureProvider<List<Product>>((ref) async {
  final result = await ref.watch(catalogRepositoryProvider).getSection('new');
  return result is ApiSuccess<List<Product>> ? result.data : [];
});

final offerProductsProvider = FutureProvider<List<Product>>((ref) async {
  final result = await ref.watch(catalogRepositoryProvider).getSection('offers');
  return result is ApiSuccess<List<Product>> ? result.data : [];
});

class ExploreNotifier extends ProductListNotifier {}

final exploreProvider =
    NotifierProvider<ExploreNotifier, ProductListState>(ExploreNotifier.new);

class SearchNotifier extends ProductListNotifier {}

final searchProvider =
    NotifierProvider<SearchNotifier, ProductListState>(SearchNotifier.new);

final recentSearchesProvider =
    NotifierProvider<RecentSearchesNotifier, List<String>>(RecentSearchesNotifier.new);

class RecentSearchesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    final raw = ref.read(storageServiceProvider).read('recent_searches');
    if (raw == null || raw.isEmpty) return const [];
    return raw.split('|').where((e) => e.isNotEmpty).toList();
  }

  Future<void> add(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final next = [q, ...state.where((e) => e.toLowerCase() != q.toLowerCase())]
        .take(8)
        .toList();
    state = next;
    await ref.read(storageServiceProvider).write('recent_searches', next.join('|'));
  }

  Future<void> clear() async {
    state = const [];
    await ref.read(storageServiceProvider).delete('recent_searches');
  }
}

class OrdersNotifier extends Notifier<List<Order>> {
  @override
  List<Order> build() {
    Future.microtask(refresh);
    return const [];
  }

  Future<void> refresh() async {
    final result = await ref.read(orderRepositoryProvider).getOrders();
    if (result is ApiSuccess<List<Order>>) state = result.data;
  }

  Future<Order?> place({
    required Cart cart,
    required Address address,
    required DeliveryMethod delivery,
    required PaymentMethod payment,
  }) async {
    final result = await ref.read(orderRepositoryProvider).placeOrder(
          cart: cart,
          address: address,
          delivery: delivery,
          payment: payment,
        );
    return switch (result) {
      ApiSuccess(:final data) => () {
          state = [data, ...state];
          return data;
        }(),
      ApiFailure() => null,
    };
  }

  Future<bool> cancel(int id) async {
    final result = await ref.read(orderRepositoryProvider).cancelOrder(id);
    if (result is ApiSuccess<Order>) {
      state = [
        for (final o in state)
          if (o.id == id) result.data else o,
      ];
      return true;
    }
    return false;
  }

  Order? byId(int id) => state.where((o) => o.id == id).firstOrNull;
}

final ordersProvider =
    NotifierProvider<OrdersNotifier, List<Order>>(OrdersNotifier.new);

class AddressNotifier extends Notifier<List<Address>> {
  @override
  List<Address> build() {
    Future.microtask(refresh);
    return const [];
  }

  Future<void> refresh() async {
    final result = await ref.read(addressRepositoryProvider).getAddresses();
    if (result is ApiSuccess<List<Address>>) state = result.data;
  }

  Future<void> save(Address address) async {
    final result = await ref.read(addressRepositoryProvider).saveAddress(address);
    if (result is ApiSuccess<Address>) await refresh();
  }

  Future<void> remove(int id) async {
    await ref.read(addressRepositoryProvider).deleteAddress(id);
    await refresh();
  }

  Address? get defaultAddress =>
      state.where((a) => a.isDefault).firstOrNull ?? state.firstOrNull;
}

final addressProvider =
    NotifierProvider<AddressNotifier, List<Address>>(AddressNotifier.new);

class NotificationsNotifier extends Notifier<List<AppNotification>> {
  @override
  List<AppNotification> build() {
    Future.microtask(refresh);
    return const [];
  }

  Future<void> refresh() async {
    final result = await ref.read(notificationRepositoryProvider).getNotifications();
    if (result is ApiSuccess<List<AppNotification>>) state = result.data;
  }

  Future<void> markAll() async {
    await ref.read(notificationRepositoryProvider).markAllRead();
    await refresh();
  }
}

final notificationsListProvider =
    NotifierProvider<NotificationsNotifier, List<AppNotification>>(
  NotificationsNotifier.new,
);
