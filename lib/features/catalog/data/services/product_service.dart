import 'package:chopper/chopper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/app_constants.dart';

part 'product_service.chopper.dart';

@ChopperApi(baseUrl: '/products')
abstract class ProductService extends ChopperService {

  static ProductService create([ChopperClient? client]) =>
      _$ProductService(client);

  @Get()
  Future<Response<List<dynamic>>> getProducts({
    @Query('limit') int? limit,
  });

  @Get(path: '/{id}')
  Future<Response<dynamic>> getProductById(@Path('id') int id);

  @Get(path: '/categories')
  Future<Response<List<dynamic>>> getCategories();

  @Get(path: '/category/{category}')
  Future<Response<List<dynamic>>> getProductsByCategory(
      @Path('category') String category, {
        @Query('limit') int? limit,
      });
}

final chopperClientProvider = Provider<ChopperClient>((ref) {
  return ChopperClient(
    baseUrl: Uri.parse(AppConstants.baseUrl),
    services: [ProductService.create()],
    converter: const CustomJsonConverter(),
    interceptors: [
      HttpLoggingInterceptor(),
    ],
  );
});

final productServiceProvider = Provider<ProductService>((ref) {
  final client = ref.watch(chopperClientProvider);
  return client.getService<ProductService>();
});

class CustomJsonConverter implements Converter {
  const CustomJsonConverter();

  @override
  Request convertRequest(Request request) => request.copyWith(
    headers: {
      ...request.headers,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );

  @override
  Future<Response<BodyType>> convertResponse<BodyType, InnerType>(
      Response response,
      ) async {
    return response.copyWith<BodyType>(body: response.body as BodyType);
  }
}