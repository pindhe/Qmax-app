import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/network/dio_client.dart';
import '../../data/repositories/repository_impl.dart';
import '../../domain/repositories/repositories.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../services/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('storageServiceProvider must be overridden');
});

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  ),
);

final dioClientProvider = Provider<DioClient>(
  (ref) => DioClient(secureStorage: ref.watch(secureStorageProvider)),
);

final apiServiceProvider = Provider<ApiService>(
  (ref) => ApiService(ref.watch(dioClientProvider)),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(storageServiceProvider)),
);

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepositoryImpl(ref.watch(storageServiceProvider)),
);

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => CartRepositoryImpl(ref.watch(storageServiceProvider)),
);

final wishlistRepositoryProvider = Provider<WishlistRepository>(
  (ref) => WishlistRepositoryImpl(ref.watch(storageServiceProvider)),
);

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => OrderRepositoryImpl(ref.watch(storageServiceProvider)),
);

final addressRepositoryProvider = Provider<AddressRepository>(
  (ref) => AddressRepositoryImpl(),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepositoryImpl(),
);

final couponRepositoryProvider = Provider<CouponRepository>(
  (ref) => CouponRepositoryImpl(),
);
