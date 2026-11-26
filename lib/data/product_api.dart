import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';
import '../models/product_page.dart';

class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}

class ProductApi {
  static const String _host = 'dummyjson.com';
  static const Duration _timeout = Duration(seconds: 10);

  final http.Client _client;

  ProductApi({http.Client? client}) : _client = client ?? http.Client();

  Future<ProductPage> getProducts({int limit = 20, int skip = 0}) async {
    final uri = Uri.https(_host, '/products', {
      'limit': '$limit',
      'skip': '$skip',
    });
    final json = await _get(uri);
    try {
      return ProductPage.fromJson(json);
    } on TypeError {
      throw const ApiException('Received unexpected product list format.');
    }
  }

  Future<Product> getProduct(int id) async {
    final uri = Uri.https(_host, '/products/$id');
    final json = await _get(uri);
    try {
      return Product.fromJson(json);
    } on TypeError {
      throw const ApiException('Received unexpected product details format.');
    }
  }

  Future<ProductPage> search(String query) async {
    final uri = Uri.https(_host, '/products/search', {'q': query});
    final json = await _get(uri);
    try {
      return ProductPage.fromJson(json);
    } on TypeError {
      throw const ApiException('Received unexpected search results format.');
    }
  }

  Future<Map<String, dynamic>> _get(Uri uri) async {
    try {
      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode != 200) {
        if (response.statusCode == 404) {
          throw const ApiException('The requested item was not found (404).');
        }
        if (response.statusCode >= 500) {
          throw ApiException(
            'Server error (${response.statusCode}). Please try again later.',
          );
        }
        throw ApiException(
          'Request failed with status code ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object.');
      }
      return decoded;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'The connection timed out. Please check your internet and try again.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Unable to connect to the server. Please check your internet connection.',
      );
    } on FormatException {
      throw const ApiException(
        'Received invalid data from the server. Please try again later.',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
