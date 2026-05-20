// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'product_service.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$ProductService extends ProductService {
  _$ProductService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = ProductService;

  @override
  Future<Response<List<dynamic>>> getProducts({int? limit}) {
    final Uri $url = Uri.parse('/products');
    final Map<String, dynamic> $params = <String, dynamic>{'limit': limit};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<List<dynamic>, List<dynamic>>($request);
  }

  @override
  Future<Response<dynamic>> getProductById(int id) {
    final Uri $url = Uri.parse('/products/${id}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<List<dynamic>>> getCategories() {
    final Uri $url = Uri.parse('/products/categories');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<List<dynamic>, List<dynamic>>($request);
  }

  @override
  Future<Response<List<dynamic>>> getProductsByCategory(
    String category, {
    int? limit,
  }) {
    final Uri $url = Uri.parse('/products/category/${category}');
    final Map<String, dynamic> $params = <String, dynamic>{'limit': limit};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<List<dynamic>, List<dynamic>>($request);
  }
}
