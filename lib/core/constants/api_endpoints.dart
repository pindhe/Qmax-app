class ApiEndpoints {
  static const String login = '/login';
  static const String register = '/register';
  static const String logout = '/logout';
  static const String forgotPassword = '/forgot-password';
  static const String verifyOtp = '/verify-otp';
  static const String resetPassword = '/reset-password';
  static const String profile = '/profile';
  static const String changePassword = '/change-password';

  static const String categories = '/categories';
  static const String products = '/products';
  static String product(int id) => '/products/$id';
  static const String search = '/search';
  static const String banners = '/banners';

  static const String cart = '/cart';
  static String cartItem(int id) => '/cart/$id';

  static const String wishlist = '/wishlist';
  static String wishlistItem(int id) => '/wishlist/$id';

  static const String addresses = '/addresses';
  static String address(int id) => '/addresses/$id';

  static const String orders = '/orders';
  static String order(int id) => '/orders/$id';
  static String cancelOrder(int id) => '/orders/$id/cancel';

  static const String reviews = '/reviews';
  static const String notifications = '/notifications';
  static const String coupons = '/coupons';
  static const String contact = '/contact';
}
