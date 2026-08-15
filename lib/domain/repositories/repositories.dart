import '../entities/entities.dart';
import '../../core/network/api_result.dart';

abstract class AuthRepository {
  Future<ApiResult<User>> login(String identifier, String password);
  Future<ApiResult<User>> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  });
  Future<ApiResult<void>> logout();
  Future<ApiResult<void>> sendOtp(String identifier);
  Future<ApiResult<void>> verifyOtp(String identifier, String otp);
  Future<ApiResult<void>> resetPassword(String identifier, String password);
  Future<User?> currentUser();
  Future<ApiResult<void>> changePassword(String current, String next);
}

abstract class CatalogRepository {
  Future<ApiResult<List<Category>>> getCategories();
  Future<ApiResult<List<PromoBanner>>> getBanners();
  Future<ApiResult<PaginatedData<Product>>> getProducts({
    int page = 1,
    ProductFilter? filter,
  });
  Future<ApiResult<Product>> getProduct(int id);
  Future<ApiResult<List<Product>>> getSection(String section);
  Future<ApiResult<List<Review>>> getReviews(int productId);
  Future<ApiResult<Review>> addReview({
    required int productId,
    required int rating,
    required String comment,
    List<String> images,
  });
}

abstract class CartRepository {
  Future<Cart> load();
  Future<Cart> save(Cart cart);
}

abstract class WishlistRepository {
  Future<List<int>> loadIds();
  Future<void> saveIds(List<int> ids);
}

abstract class OrderRepository {
  Future<ApiResult<List<Order>>> getOrders();
  Future<ApiResult<Order>> getOrder(int id);
  Future<ApiResult<Order>> placeOrder({
    required Cart cart,
    required Address address,
    required DeliveryMethod delivery,
    required PaymentMethod payment,
  });
  Future<ApiResult<Order>> cancelOrder(int id);
}

abstract class AddressRepository {
  Future<ApiResult<List<Address>>> getAddresses();
  Future<ApiResult<Address>> saveAddress(Address address);
  Future<ApiResult<void>> deleteAddress(int id);
}

abstract class NotificationRepository {
  Future<ApiResult<List<AppNotification>>> getNotifications();
  Future<void> markRead(int id);
  Future<void> markAllRead();
}

abstract class CouponRepository {
  Future<ApiResult<Coupon>> validate(String code, double subtotal);
}
