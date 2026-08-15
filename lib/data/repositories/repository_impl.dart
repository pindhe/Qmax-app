import 'dart:convert';
import 'dart:math';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../services/storage_service.dart';
import '../datasources/mock/mock_data.dart';
import '../models/models.dart';

Future<void> _delay([int ms = 350]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._storage);
  final StorageService _storage;

  @override
  Future<ApiResult<User>> login(String identifier, String password) async {
    await _delay();
    final matchEmail = identifier.trim().toLowerCase() ==
        MockData.demoUser.email?.toLowerCase();
    final matchPhone = identifier.replaceAll(RegExp(r'\D'), '').endsWith(
          MockData.demoUser.phone.replaceAll(RegExp(r'\D'), '').substring(4),
        );
    if ((matchEmail || matchPhone || identifier.contains('63')) &&
        password.length >= 8) {
      await _storage.saveToken('mock-jwt-${DateTime.now().millisecondsSinceEpoch}');
      await _storage.write(
        StorageKeys.currentUser,
        jsonEncode(MockData.demoUser.toJson()),
      );
      return ApiSuccess(MockData.demoUser);
    }
    return const ApiFailure('Incorrect phone/email or password');
  }

  @override
  Future<ApiResult<User>> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    await _delay();
    final user = UserModel(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      name: name,
      phone: phone,
      email: email,
    );
    await _storage.saveToken('mock-jwt-${user.id}');
    await _storage.write(StorageKeys.currentUser, jsonEncode(user.toJson()));
    return ApiSuccess(user);
  }

  @override
  Future<ApiResult<void>> logout() async {
    await _storage.clearTokens();
    await _storage.delete(StorageKeys.currentUser);
    return const ApiSuccess(null);
  }

  @override
  Future<ApiResult<void>> sendOtp(String identifier) async {
    await _delay();
    return const ApiSuccess(null);
  }

  @override
  Future<ApiResult<void>> verifyOtp(String identifier, String otp) async {
    await _delay();
    if (otp == AppConstants.demoOtp) return const ApiSuccess(null);
    return const ApiFailure('Invalid OTP');
  }

  @override
  Future<ApiResult<void>> resetPassword(String identifier, String password) async {
    await _delay();
    return const ApiSuccess(null);
  }

  @override
  Future<User?> currentUser() async {
    return UserModel.fromJsonString(_storage.read(StorageKeys.currentUser));
  }

  @override
  Future<ApiResult<void>> changePassword(String current, String next) async {
    await _delay();
    if (current.length < 8) return const ApiFailure('Current password is incorrect');
    return const ApiSuccess(null);
  }
}

class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl(this._storage);
  final StorageService _storage;

  List<Product> get _all => MockData.products;

  @override
  Future<ApiResult<List<Category>>> getCategories() async {
    await _delay(200);
    await _storage.write(
      StorageKeys.cachedCategories,
      jsonEncode(MockData.categories.map((c) => c.toJson()).toList()),
    );
    return const ApiSuccess(MockData.categories);
  }

  @override
  Future<ApiResult<List<PromoBanner>>> getBanners() async {
    await _delay(200);
    return const ApiSuccess(MockData.banners);
  }

  @override
  Future<ApiResult<PaginatedData<Product>>> getProducts({
    int page = 1,
    ProductFilter? filter,
  }) async {
    await _delay(280);
    var list = List<Product>.from(_all);
    if (filter != null) {
      if (filter.categoryId != null) {
        list = list.where((p) => p.categoryId == filter.categoryId).toList();
      }
      if (filter.brand != null && filter.brand!.isNotEmpty) {
        list = list
            .where((p) => p.brand.toLowerCase() == filter.brand!.toLowerCase())
            .toList();
      }
      if (filter.minPrice != null) {
        list = list.where((p) => p.effectivePrice >= filter.minPrice!).toList();
      }
      if (filter.maxPrice != null) {
        list = list.where((p) => p.effectivePrice <= filter.maxPrice!).toList();
      }
      if (filter.minRating != null) {
        list = list.where((p) => p.rating >= filter.minRating!).toList();
      }
      if (filter.inStockOnly) {
        list = list.where((p) => !p.isOutOfStock).toList();
      }
      final q = filter.query?.trim().toLowerCase();
      if (q != null && q.isNotEmpty) {
        list = list.where((p) {
          return p.name.toLowerCase().contains(q) ||
              p.sku.toLowerCase().contains(q) ||
              p.brand.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q) ||
              MockData.categories
                  .firstWhere(
                    (c) => c.id == p.categoryId,
                    orElse: () => MockData.categories.first,
                  )
                  .name
                  .toLowerCase()
                  .contains(q);
        }).toList();
      }
      list = switch (filter.sort) {
        ProductSort.newest => [...list]
          ..sort((a, b) => (b.id).compareTo(a.id)),
        ProductSort.priceLowHigh => [...list]
          ..sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice)),
        ProductSort.priceHighLow => [...list]
          ..sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice)),
        ProductSort.popular => [...list]
          ..sort((a, b) => b.reviewCount.compareTo(a.reviewCount)),
      };
    }
    await _storage.write(
      StorageKeys.cachedProducts,
      jsonEncode(MockData.products.map((p) => p.toJson()).toList()),
    );
    const size = AppConstants.pageSize;
    final lastPage = max(1, (list.length / size).ceil());
    final start = (page - 1) * size;
    final slice = start >= list.length
        ? <Product>[]
        : list.sublist(start, min(start + size, list.length));
    return ApiSuccess(
      PaginatedData(
        items: slice,
        page: page,
        lastPage: lastPage,
        total: list.length,
      ),
    );
  }

  @override
  Future<ApiResult<List<Product>>> getSection(String section) async {
    await _delay(220);
    final list = switch (section) {
      'featured' => _all.where((p) => p.isFeatured).toList(),
      'popular' => _all.where((p) => p.isPopular).toList(),
      'new' => _all.where((p) => p.isNew).toList(),
      'offers' => _all.where((p) => p.hasDiscount).toList(),
      _ => _all,
    };
    return ApiSuccess(list);
  }

  @override
  Future<ApiResult<Product>> getProduct(int id) async {
    await _delay(200);
    try {
      return ApiSuccess(_all.firstWhere((p) => p.id == id));
    } catch (_) {
      return const ApiFailure('Product not found');
    }
  }

  @override
  Future<ApiResult<List<Review>>> getReviews(int productId) async {
    await _delay(200);
    return ApiSuccess(MockData.reviewsFor(productId));
  }

  @override
  Future<ApiResult<Review>> addReview({
    required int productId,
    required int rating,
    required String comment,
    List<String> images = const [],
  }) async {
    await _delay();
    return ApiSuccess(
      ReviewModel(
        id: DateTime.now().millisecondsSinceEpoch,
        userName: 'You',
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
        images: images,
      ),
    );
  }
}

class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl(this._storage);
  final StorageService _storage;

  @override
  Future<Cart> load() async {
    final raw = _storage.read(StorageKeys.cart);
    if (raw == null) return const Cart();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final items = <CartItem>[];
    for (final item in (json['items'] as List? ?? [])) {
      final product = MockData.products
          .where((p) => p.id == item['product_id'])
          .firstOrNull;
      if (product != null) {
        items.add(CartItem(product: product, quantity: item['quantity'] as int));
      }
    }
    Coupon? coupon;
    if (json['coupon_code'] != null) {
      coupon = MockData.coupons
          .where((c) => c.code == json['coupon_code'])
          .firstOrNull;
    }
    return Cart(
      items: items,
      coupon: coupon,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  Future<Cart> save(Cart cart) async {
    await _storage.write(
      StorageKeys.cart,
      jsonEncode({
        'items': cart.items
            .map((e) => {'product_id': e.product.id, 'quantity': e.quantity})
            .toList(),
        'coupon_code': cart.coupon?.code,
        'delivery_fee': cart.deliveryFee,
      }),
    );
    return cart;
  }
}

class WishlistRepositoryImpl implements WishlistRepository {
  WishlistRepositoryImpl(this._storage);
  final StorageService _storage;

  @override
  Future<List<int>> loadIds() async {
    final raw = _storage.read(StorageKeys.guestWishlist);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<int>();
  }

  @override
  Future<void> saveIds(List<int> ids) {
    return _storage.write(StorageKeys.guestWishlist, jsonEncode(ids));
  }
}

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(StorageService _);
  final List<Order> _orders = List<Order>.from(MockData.orders);

  @override
  Future<ApiResult<List<Order>>> getOrders() async {
    await _delay();
    return ApiSuccess(List<Order>.from(_orders));
  }

  @override
  Future<ApiResult<Order>> getOrder(int id) async {
    await _delay();
    try {
      return ApiSuccess(_orders.firstWhere((o) => o.id == id));
    } catch (_) {
      return const ApiFailure('Order not found');
    }
  }

  @override
  Future<ApiResult<Order>> placeOrder({
    required Cart cart,
    required Address address,
    required DeliveryMethod delivery,
    required PaymentMethod payment,
  }) async {
    await _delay(600);
    final id = 10000 + Random().nextInt(90000);
    final order = Order(
      id: id,
      orderNumber: 'QMAX-$id',
      items: cart.items
          .map(
            (e) => OrderItem(
              productId: e.product.id,
              productName: e.product.name,
              quantity: e.quantity,
              price: e.product.effectivePrice,
              image: e.product.image,
            ),
          )
          .toList(),
      subtotal: cart.subtotal,
      deliveryFee: cart.deliveryFee,
      discount: cart.discount,
      total: cart.total,
      paymentMethod: payment,
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
      address: address,
      deliveryMethod: delivery,
      estimatedDelivery: DateTime.now().add(
        Duration(days: delivery == DeliveryMethod.express ? 0 : 2),
      ),
    );
    _orders.insert(0, order);
    return ApiSuccess(order);
  }

  @override
  Future<ApiResult<Order>> cancelOrder(int id) async {
    await _delay();
    final index = _orders.indexWhere((o) => o.id == id);
    if (index < 0) return const ApiFailure('Order not found');
    final current = _orders[index];
    if (current.status == OrderStatus.outForDelivery ||
        current.status == OrderStatus.delivered) {
      return const ApiFailure('This order can no longer be cancelled');
    }
    final updated = Order(
      id: current.id,
      orderNumber: current.orderNumber,
      items: current.items,
      subtotal: current.subtotal,
      deliveryFee: current.deliveryFee,
      discount: current.discount,
      total: current.total,
      paymentMethod: current.paymentMethod,
      status: OrderStatus.cancelled,
      createdAt: current.createdAt,
      address: current.address,
      deliveryMethod: current.deliveryMethod,
      paymentStatus: current.paymentStatus,
      estimatedDelivery: current.estimatedDelivery,
    );
    _orders[index] = updated;
    return ApiSuccess(updated);
  }
}

class AddressRepositoryImpl implements AddressRepository {
  AddressRepositoryImpl();
  final List<Address> _items = List<Address>.from(MockData.addresses);

  @override
  Future<ApiResult<List<Address>>> getAddresses() async {
    await _delay(200);
    return ApiSuccess(List<Address>.from(_items));
  }

  @override
  Future<ApiResult<Address>> saveAddress(Address address) async {
    await _delay();
    if (address.id == 0) {
      final created = address.copyWith(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
      );
      if (created.isDefault) {
        for (var i = 0; i < _items.length; i++) {
          _items[i] = _items[i].copyWith(isDefault: false);
        }
      }
      _items.add(created);
      return ApiSuccess(created);
    }
    final index = _items.indexWhere((a) => a.id == address.id);
    if (index >= 0) {
      if (address.isDefault) {
        for (var i = 0; i < _items.length; i++) {
          _items[i] = _items[i].copyWith(isDefault: false);
        }
      }
      _items[index] = address;
    }
    return ApiSuccess(address);
  }

  @override
  Future<ApiResult<void>> deleteAddress(int id) async {
    _items.removeWhere((a) => a.id == id);
    return const ApiSuccess(null);
  }
}

class NotificationRepositoryImpl implements NotificationRepository {
  final List<AppNotification> _items = List.from(MockData.notifications);

  @override
  Future<ApiResult<List<AppNotification>>> getNotifications() async {
    await _delay(200);
    return ApiSuccess(List.from(_items));
  }

  @override
  Future<void> markRead(int id) async {
    final i = _items.indexWhere((n) => n.id == id);
    if (i >= 0) {
      final n = _items[i];
      _items[i] = AppNotification(
        id: n.id,
        title: n.title,
        message: n.message,
        type: n.type,
        createdAt: n.createdAt,
        isRead: true,
      );
    }
  }

  @override
  Future<void> markAllRead() async {
    for (var i = 0; i < _items.length; i++) {
      final n = _items[i];
      _items[i] = AppNotification(
        id: n.id,
        title: n.title,
        message: n.message,
        type: n.type,
        createdAt: n.createdAt,
        isRead: true,
      );
    }
  }
}

class CouponRepositoryImpl implements CouponRepository {
  @override
  Future<ApiResult<Coupon>> validate(String code, double subtotal) async {
    await _delay(250);
    final coupon = MockData.coupons
        .where((c) => c.code.toUpperCase() == code.trim().toUpperCase())
        .firstOrNull;
    if (coupon == null) return const ApiFailure('invalid');
    if (coupon.isExpired || coupon.status != 'active') {
      return const ApiFailure('expired');
    }
    if (subtotal < coupon.minimumOrder) return const ApiFailure('minimum');
    return ApiSuccess(coupon);
  }
}
