import 'package:flutter/foundation.dart';

/// Prepared for Firebase Cloud Messaging. The current build uses local
/// notification records from the API/mock layer. Wire FCM tokens here when
/// the Laravel backend is connected.
class NotificationService {
  Future<void> initialize() async {
    debugPrint('NotificationService ready (FCM integration pending).');
  }

  Future<String?> getDeviceToken() async => null;
}
