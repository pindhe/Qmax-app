class User {
  const User({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.avatar,
    this.role = 'customer',
  });

  final int id;
  final String name;
  final String phone;
  final String? email;
  final String? avatar;
  final String role;

  User copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? avatar,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
    );
  }
}

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.icon,
    this.image,
    this.description,
    this.productCount = 0,
  });

  final int id;
  final String name;
  final String slug;
  final String icon;
  final String? image;
  final String? description;
  final int productCount;
}

class PromoBanner {
  const PromoBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.actionLabel = 'Shop Now',
    this.categoryId,
  });

  final int id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String actionLabel;
  final int? categoryId;
}

class Product {
  const Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.slug,
    required this.sku,
    required this.description,
    required this.price,
    required this.stock,
    required this.brand,
    required this.images,
    this.discountPrice,
    this.rating = 0,
    this.reviewCount = 0,
    this.specifications = const {},
    this.materials,
    this.dimensions,
    this.weight,
    this.warranty,
    this.isFeatured = false,
    this.isPopular = false,
    this.isNew = false,
    this.createdAt,
  });

  final int id;
  final int categoryId;
  final String name;
  final String slug;
  final String sku;
  final String description;
  final double price;
  final double? discountPrice;
  final int stock;
  final String brand;
  final List<String> images;
  final double rating;
  final int reviewCount;
  final Map<String, String> specifications;
  final String? materials;
  final String? dimensions;
  final String? weight;
  final String? warranty;
  final bool isFeatured;
  final bool isPopular;
  final bool isNew;
  final DateTime? createdAt;

  String get image => images.isNotEmpty ? images.first : '';
  double get effectivePrice => discountPrice ?? price;
  bool get hasDiscount => discountPrice != null && discountPrice! < price;
  int get discountPercent => hasDiscount
      ? (((price - discountPrice!) / price) * 100).round()
      : 0;
  bool get isOutOfStock => stock <= 0;
  bool get isLowStock => stock > 0 && stock <= 5;
}

class CartItem {
  const CartItem({
    required this.product,
    required this.quantity,
  });

  final Product product;
  final int quantity;

  double get lineTotal => product.effectivePrice * quantity;

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class Cart {
  const Cart({
    this.items = const [],
    this.coupon,
    this.deliveryFee = 0,
  });

  final List<CartItem> items;
  final Coupon? coupon;
  final double deliveryFee;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => items.fold(0, (sum, item) => sum + item.lineTotal);
  double get discount {
    if (coupon == null) return 0;
    if (coupon!.type == CouponType.percent) {
      return subtotal * (coupon!.value / 100);
    }
    return coupon!.value;
  }

  double get total {
    final value = subtotal + deliveryFee - discount;
    return value < 0 ? 0 : value;
  }

  bool get isEmpty => items.isEmpty;
}

enum CouponType { percent, fixed }

class Coupon {
  const Coupon({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    this.minimumOrder = 0,
    this.expiresAt,
    this.status = 'active',
  });

  final int id;
  final String code;
  final CouponType type;
  final double value;
  final double minimumOrder;
  final DateTime? expiresAt;
  final String status;

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isActive => status == 'active' && !isExpired;
}

class Address {
  const Address({
    required this.id,
    required this.name,
    required this.phone,
    required this.city,
    required this.area,
    required this.street,
    this.directions,
    this.isDefault = false,
  });

  final int id;
  final String name;
  final String phone;
  final String city;
  final String area;
  final String street;
  final String? directions;
  final bool isDefault;

  String get fullLine =>
      [city, area, street, if (directions != null && directions!.isNotEmpty) directions]
          .join(', ');

  Address copyWith({
    int? id,
    String? name,
    String? phone,
    String? city,
    String? area,
    String? street,
    String? directions,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      area: area ?? this.area,
      street: street ?? this.street,
      directions: directions ?? this.directions,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

enum DeliveryMethod { standard, express, pickup }

enum PaymentMethod { zaad, edahab, card, cashOnDelivery }

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  cancelled,
}

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    this.image,
  });

  final int productId;
  final String productName;
  final int quantity;
  final double price;
  final String? image;

  double get subtotal => price * quantity;
}

class DriverInfo {
  const DriverInfo({required this.name, required this.phone});
  final String name;
  final String phone;
}

class Order {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    required this.address,
    this.deliveryMethod = DeliveryMethod.standard,
    this.paymentStatus = 'paid',
    this.estimatedDelivery,
    this.driver,
  });

  final int id;
  final String orderNumber;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final PaymentMethod paymentMethod;
  final OrderStatus status;
  final DateTime createdAt;
  final Address address;
  final DeliveryMethod deliveryMethod;
  final String paymentStatus;
  final DateTime? estimatedDelivery;
  final DriverInfo? driver;

  int get productCount => items.fold(0, (s, i) => s + i.quantity);
}

class Review {
  const Review({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.images = const [],
  });

  final int id;
  final String userName;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final List<String> images;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  final int id;
  final String title;
  final String message;
  final String type;
  final DateTime createdAt;
  final bool isRead;
}

class ProductFilter {
  const ProductFilter({
    this.categoryId,
    this.brand,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.inStockOnly = false,
    this.sort = ProductSort.popular,
    this.query,
  });

  final int? categoryId;
  final String? brand;
  final double? minPrice;
  final double? maxPrice;
  final int? minRating;
  final bool inStockOnly;
  final ProductSort sort;
  final String? query;

  ProductFilter copyWith({
    int? categoryId,
    String? brand,
    double? minPrice,
    double? maxPrice,
    int? minRating,
    bool? inStockOnly,
    ProductSort? sort,
    String? query,
    bool clearCategory = false,
    bool clearBrand = false,
  }) {
    return ProductFilter(
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      brand: clearBrand ? null : brand ?? this.brand,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      inStockOnly: inStockOnly ?? this.inStockOnly,
      sort: sort ?? this.sort,
      query: query ?? this.query,
    );
  }
}

enum ProductSort { newest, popular, priceLowHigh, priceHighLow }
