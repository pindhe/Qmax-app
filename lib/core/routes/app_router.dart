import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/auth/auth_screens.dart';
import '../../presentation/screens/cart/cart_screens.dart';
import '../../presentation/screens/category/category_screens.dart';
import '../../presentation/screens/checkout/checkout_screens.dart';
import '../../presentation/screens/home/home_screens.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/orders/order_screens.dart';
import '../../presentation/screens/product/product_screens.dart';
import '../../presentation/screens/profile/profile_screens.dart';
import '../../presentation/screens/search/search_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/widgets/navigation/main_shell.dart';
import '../../l10n/app_localizations.dart';

final _rootKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', pageBuilder: (c, s) => const NoTransitionPage(child: HomeScreen())),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/cart', pageBuilder: (c, s) => const NoTransitionPage(child: CartScreen())),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', pageBuilder: (c, s) => const NoTransitionPage(child: ProfileScreen())),
          ]),
        ],
      ),
      GoRoute(path: '/explore', builder: (_, __) => const ExploreScreen()),
      GoRoute(path: '/wishlist', builder: (_, __) => const WishlistScreen()),
      GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
      GoRoute(path: '/categories', builder: (_, __) => const CategoriesScreen()),
      GoRoute(
        path: '/categories/:id',
        builder: (_, state) => CategoryProductsScreen(categoryId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/products/:id',
        builder: (_, state) => ProductDetailsScreen(productId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/products/:id/reviews',
        builder: (_, state) => ReviewsScreen(productId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/products/:id/review',
        builder: (_, state) => WriteReviewScreen(productId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
      GoRoute(
        path: '/order-confirmation',
        builder: (_, state) => OrderConfirmationScreen(orderId: int.tryParse(state.uri.queryParameters['id'] ?? '') ?? 0),
      ),
      GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen()),
      GoRoute(
        path: '/orders/:id',
        builder: (_, state) => OrderDetailsScreen(orderId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/orders/:id/track',
        builder: (_, state) => OrderTrackingScreen(orderId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/addresses', builder: (_, __) => const AddressesScreen()),
      GoRoute(
        path: '/addresses/form',
        builder: (_, state) => AddressFormScreen(addressId: int.tryParse(state.uri.queryParameters['id'] ?? '')),
      ),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/help', builder: (_, __) => const HelpCenterScreen()),
      GoRoute(path: '/about', builder: (_, __) => const AboutScreen()),
      GoRoute(
        path: '/terms',
        builder: (context, _) => LegalScreen(title: AppLocalizations.of(context).terms, body: AppLocalizations.of(context).termsBody),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, _) => LegalScreen(title: AppLocalizations.of(context).privacy, body: AppLocalizations.of(context).privacyBody),
      ),
      GoRoute(path: '/change-password', builder: (_, __) => const ChangePasswordScreen()),
      GoRoute(path: '/payment-methods', builder: (_, __) => const PaymentMethodsScreen()),
    ],
  );
});
