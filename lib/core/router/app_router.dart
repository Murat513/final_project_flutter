import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/catalog/presentation/pages/catalog_page.dart';
import '../../features/catalog/presentation/pages/product_detail_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/orders/presentation/pages/order_detail_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../shell/main_shell.dart';

// Route name constants
class AppRoutes {
  static const home = '/';
  static const catalog = '/catalog';
  static const productDetail = '/catalog/:id';
  static const cart = '/cart';
  static const favorites = '/favorites';
  static const orders = '/orders';
  static const orderDetail = '/orders/:orderId';
  static const profile = '/profile';
  static const login = '/login';
  static const register = '/register';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    routes: [
      // Auth routes (no shell)
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: LoginPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: RegisterPage(),
        ),
      ),

      // Main app with bottom nav shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.catalog,
                builder: (context, state) => const CatalogPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return ProductDetailPage(productId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.cart,
                builder: (context, state) => const CartPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.favorites,
                builder: (context, state) => const FavoritesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.orders,
                builder: (context, state) => const OrdersPage(),
                routes: [
                  GoRoute(
                    path: ':orderId',
                    builder: (context, state) {
                      final orderId = state.pathParameters['orderId']!;
                      return OrderDetailPage(orderId: orderId);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
