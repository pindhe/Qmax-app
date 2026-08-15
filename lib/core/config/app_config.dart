import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://api.qmaxtools.com/api';

  static bool get useMockData =>
      (dotenv.env['USE_MOCK_DATA'] ?? 'true').toLowerCase() == 'true';

  static String get storePhone =>
      dotenv.env['STORE_PHONE'] ?? '+252634142009';

  static String get storeWhatsapp =>
      dotenv.env['STORE_WHATSAPP'] ?? '252634142009';

  static double get storeLat =>
      double.tryParse(dotenv.env['STORE_LAT'] ?? '') ?? 9.5624;

  static double get storeLng =>
      double.tryParse(dotenv.env['STORE_LNG'] ?? '') ?? 44.0650;

  static Duration get connectTimeout => const Duration(seconds: 20);
  static Duration get receiveTimeout => const Duration(seconds: 20);
}
