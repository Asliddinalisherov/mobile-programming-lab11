import 'dart:convert';
import 'dart:io';

import 'package:api_catalog/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Product & nested models', () {
    test('parses test/fixtures/product.json accurately', () {
      final raw = File('test/fixtures/product.json').readAsStringSync();
      final json = jsonDecode(raw) as Map<String, dynamic>;

      final product = Product.fromJson(json);

      expect(product.id, 1);
      expect(product.title, 'Essence Mascara Lash Princess');
      expect(product.price, isA<double>());
      expect(product.price, 9.99);
      expect(product.rating, 2.56);
      expect(product.brand, 'Essence');
      expect(product.tags, ['beauty', 'mascara']);
      expect(product.dimensions.width, 15.14);
      expect(product.dimensions.height, 13.08);
      expect(product.dimensions.depth, 22.99);
      expect(product.reviews, hasLength(3));
      expect(product.reviews.first.rating, 3);
      expect(product.reviews.first.reviewerName, 'Eleanor Collins');
      expect(product.reviews.first.comment, 'Would not recommend!');
      expect(
        product.reviews.first.date,
        DateTime.parse('2025-04-30T09:41:02.053Z'),
      );
    });

    test('handles missing brand, missing tags, and integer numbers safely', () {
      final map = <String, dynamic>{
        'id': 16,
        'title': 'Fresh Apple',
        'description': 'Crisp red apple.',
        'price': 10,
        'rating': 4,
        'thumbnail': 'https://cdn.dummyjson.com/apple.webp',
        'dimensions': <String, dynamic>{
          'width': 8,
          'height': 8,
          'depth': 8,
        },
        'reviews': <dynamic>[],
      };

      final product = Product.fromJson(map);

      expect(product.brand, isNull);
      expect(product.tags, isEmpty);
      expect(product.price, isA<double>());
      expect(product.price, 10.0);
      expect(product.rating, 4.0);
      expect(product.dimensions.width, 8.0);
    });
  });
}
