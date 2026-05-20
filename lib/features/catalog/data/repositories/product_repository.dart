import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

abstract interface class IProductRepository {
  Future<List<ProductModel>> getProducts({int? limit});

  Future<ProductModel> getProductById(int id);

  Future<List<String>> getCategories();

  Future<List<ProductModel>> getProductsByCategory(
      String category, {
        int? limit,
      });
}

class ProductRepository implements IProductRepository {
  const ProductRepository(this._service);

  final ProductService _service;

  @override
  Future<List<ProductModel>> getProducts({int? limit}) async {
    final response = await _guardedCall(
          () => _service.getProducts(limit: limit),
    );
    return _parseProductList(response.body);
  }

  @override
  Future<ProductModel> getProductById(int id) async {
    final response = await _guardedCall(
          () => _service.getProductById(id),
    );
    return _parseProduct(response.body);
  }

  @override
  Future<List<String>> getCategories() async {
    final response = await _guardedCall(
          () => _service.getCategories(),
    );
    final body = response.body;
    if (body is! List) {
      throw const ParseException('Expected a JSON array for categories');
    }
    return body.map((e) => e.toString()).toList();
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(
      String category, {
        int? limit,
      }) async {
    final response = await _guardedCall(
          () => _service.getProductsByCategory(category, limit: limit),
    );
    return _parseProductList(response.body);
  }

  Future<Response<T>> _guardedCall<T>(
      Future<Response<T>> Function() call,
      ) async {
    try {
      final response = await call();
      if (!response.isSuccessful) {
        throw NetworkException(
          statusCode: response.statusCode,
          message: response.error?.toString() ??
              'Request failed with status ${response.statusCode}',
        );
      }
      return response;
    } on NetworkException {
      rethrow;
    } on SocketException {
      throw const NoConnectionException();
    } on HttpException catch (e) {
      throw NoConnectionException();
    } catch (e) {
      throw ParseException(e.toString());
    }
  }

  ProductModel _parseProduct(dynamic json) {
    try {
      return ProductModel.fromJson(json as Map<String, dynamic>);
    } catch (e) {
      throw ParseException('product: $e');
    }
  }

  List<ProductModel> _parseProductList(dynamic json) {
    try {
      final list = json as List<dynamic>;
      return list
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ParseException('product list: $e');
    }
  }
}

final productRepositoryProvider = Provider<IProductRepository>((ref) {
  final service = ref.watch(productServiceProvider);
  return ProductRepository(service);
});