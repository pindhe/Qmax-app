import 'dart:convert';

import '../../domain/entities/entities.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.phone,
    super.email,
    super.avatar,
    super.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        name: json['name'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String?,
        avatar: json['avatar'] as String?,
        role: json['role'] as String? ?? 'customer',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'avatar': avatar,
        'role': role,
      };

  static UserModel? fromJsonString(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.slug,
    required super.icon,
    super.image,
    super.description,
    super.productCount,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as int,
        name: json['name'] as String,
        slug: json['slug'] as String,
        icon: json['icon'] as String? ?? 'hardware',
        image: json['image'] as String?,
        description: json['description'] as String?,
        productCount: json['product_count'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'icon': icon,
        'image': image,
        'description': description,
        'product_count': productCount,
      };
}

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.categoryId,
    required super.name,
    required super.slug,
    required super.sku,
    required super.description,
    required super.price,
    required super.stock,
    required super.brand,
    required super.images,
    super.discountPrice,
    super.rating,
    super.reviewCount,
    super.specifications,
    super.materials,
    super.dimensions,
    super.weight,
    super.warranty,
    super.isFeatured,
    super.isPopular,
    super.isNew,
    super.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final images = (json['images'] as List?)?.cast<String>() ??
        (json['image'] != null ? [json['image'] as String] : <String>[]);
    final specs = <String, String>{};
    if (json['specifications'] is Map) {
      (json['specifications'] as Map).forEach((k, v) {
        specs['$k'] = '$v';
      });
    }
    return ProductModel(
      id: json['id'] as int,
      categoryId: json['category_id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      sku: json['sku'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      discountPrice: (json['discount_price'] as num?)?.toDouble(),
      stock: json['stock'] as int,
      brand: json['brand'] as String,
      images: images,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] as int? ?? 0,
      specifications: specs,
      materials: json['materials'] as String?,
      dimensions: json['dimensions'] as String?,
      weight: json['weight'] as String?,
      warranty: json['warranty'] as String?,
      isFeatured: json['is_featured'] as bool? ?? false,
      isPopular: json['is_popular'] as bool? ?? false,
      isNew: json['is_new'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category_id': categoryId,
        'name': name,
        'slug': slug,
        'sku': sku,
        'description': description,
        'price': price,
        'discount_price': discountPrice,
        'stock': stock,
        'brand': brand,
        'images': images,
        'image': image,
        'rating': rating,
        'review_count': reviewCount,
        'specifications': specifications,
        'materials': materials,
        'dimensions': dimensions,
        'weight': weight,
        'warranty': warranty,
        'is_featured': isFeatured,
        'is_popular': isPopular,
        'is_new': isNew,
        'created_at': createdAt?.toIso8601String(),
      };
}

class AddressModel extends Address {
  const AddressModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.city,
    required super.area,
    required super.street,
    super.directions,
    super.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        id: json['id'] as int,
        name: json['name'] as String,
        phone: json['phone'] as String,
        city: json['city'] as String,
        area: json['area'] as String,
        street: json['street'] as String,
        directions: json['directions'] as String?,
        isDefault: json['is_default'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'city': city,
        'area': area,
        'street': street,
        'directions': directions,
        'is_default': isDefault,
      };
}

class CouponModel extends Coupon {
  const CouponModel({
    required super.id,
    required super.code,
    required super.type,
    required super.value,
    super.minimumOrder,
    super.expiresAt,
    super.status,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) => CouponModel(
        id: json['id'] as int,
        code: json['code'] as String,
        type: json['type'] == 'percent' ? CouponType.percent : CouponType.fixed,
        value: (json['value'] as num).toDouble(),
        minimumOrder: (json['minimum_order'] as num?)?.toDouble() ?? 0,
        expiresAt: json['expires_at'] != null
            ? DateTime.tryParse(json['expires_at'] as String)
            : null,
        status: json['status'] as String? ?? 'active',
      );
}

class ReviewModel extends Review {
  const ReviewModel({
    required super.id,
    required super.userName,
    required super.rating,
    required super.comment,
    required super.createdAt,
    super.images,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: json['id'] as int,
        userName: json['user_name'] as String? ?? json['user']?['name'] ?? 'Customer',
        rating: json['rating'] as int,
        comment: json['comment'] as String? ?? '',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        images: (json['images'] as List?)?.cast<String>() ??
            (json['image'] != null ? [json['image'] as String] : const []),
      );
}

class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.message,
    required super.type,
    required super.createdAt,
    super.isRead,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as int,
        title: json['title'] as String,
        message: json['message'] as String,
        type: json['type'] as String? ?? 'general',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        isRead: json['is_read'] as bool? ?? false,
      );
}

class OrderModel extends Order {
  OrderModel({
    required super.id,
    required super.orderNumber,
    required super.items,
    required super.subtotal,
    required super.deliveryFee,
    required super.discount,
    required super.total,
    required super.paymentMethod,
    required super.status,
    required super.createdAt,
    required super.address,
    super.deliveryMethod,
    super.paymentStatus,
    super.estimatedDelivery,
    super.driver,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as int,
      orderNumber: json['order_number'] as String,
      items: ((json['items'] ?? json['order_items']) as List? ?? [])
          .map((e) => OrderItem(
                productId: e['product_id'] as int,
                productName: e['product_name'] as String,
                quantity: e['quantity'] as int,
                price: (e['price'] as num).toDouble(),
                image: e['image'] as String?,
              ))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['delivery_fee'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num).toDouble(),
      paymentMethod: _payment(json['payment_method'] as String?),
      status: _status(json['order_status'] as String?),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      address: AddressModel.fromJson(json['address'] as Map<String, dynamic>),
      deliveryMethod: _delivery(json['delivery_method'] as String?),
      paymentStatus: json['payment_status'] as String? ?? 'paid',
      estimatedDelivery: json['estimated_delivery'] != null
          ? DateTime.tryParse(json['estimated_delivery'] as String)
          : null,
      driver: json['driver'] != null
          ? DriverInfo(
              name: json['driver']['name'] as String,
              phone: json['driver']['phone'] as String,
            )
          : null,
    );
  }

  static PaymentMethod _payment(String? value) => switch (value) {
        'zaad' => PaymentMethod.zaad,
        'edahab' => PaymentMethod.edahab,
        'card' => PaymentMethod.card,
        _ => PaymentMethod.cashOnDelivery,
      };

  static OrderStatus _status(String? value) => switch (value) {
        'confirmed' => OrderStatus.confirmed,
        'preparing' => OrderStatus.preparing,
        'out_for_delivery' => OrderStatus.outForDelivery,
        'delivered' => OrderStatus.delivered,
        'cancelled' => OrderStatus.cancelled,
        _ => OrderStatus.pending,
      };

  static DeliveryMethod _delivery(String? value) => switch (value) {
        'express' => DeliveryMethod.express,
        'pickup' => DeliveryMethod.pickup,
        _ => DeliveryMethod.standard,
      };
}
