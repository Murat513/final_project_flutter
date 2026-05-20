import 'package:chopper/chopper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chopper_client.dart';

/// Global [ChopperClient] provider.
///
/// Consume this in feature-level service providers so they all share
/// one underlying HTTP client:
///
/// ```dart
/// final productServiceProvider = Provider<ProductService>((ref) {
///   final client = ref.watch(chopperClientProvider);
///   return client.getService<ProductService>();
/// });
/// ```
///
/// To register a new Chopper service, add it to the [services] list here.
/// The client is created lazily — it is only built when first watched.
final chopperClientProvider = Provider<ChopperClient>((ref) {
  // Register all Chopper services here as the project grows:
  //   import '../../features/catalog/data/services/product_service.dart';
  //   services: [ProductService.create()],
  final client = buildChopperClient(
    services: [
      // ProductService.create(),   ← uncomment when the service is ready
    ],
  );

  // Dispose the client when the provider is destroyed.
  ref.onDispose(client.dispose);

  return client;
});

/// Convenience typedef so feature layers can name the type clearly.
typedef NetworkClient = ChopperClient;
