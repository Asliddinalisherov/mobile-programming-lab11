import 'dart:convert';
import 'dart:io';

import 'package:api_catalog/data/product_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ProductApi', () {
    test('getProducts parses ProductPage from MockClient response', () async {
      final fixtureRaw = File('test/fixtures/product.json').readAsStringSync();
      final fixtureMap = jsonDecode(fixtureRaw) as Map<String, dynamic>;

      final mockClient = MockClient((request) async {
        expect(request.url.host, 'dummyjson.com');
        expect(request.url.path, '/products');
        expect(request.url.queryParameters['limit'], '20');
        expect(request.url.queryParameters['skip'], '0');

        final pageJson = jsonEncode({
          'products': [fixtureMap],
          'total': 194,
          'skip': 0,
          'limit': 20,
        });
        return http.Response(
          pageJson,
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final api = ProductApi(client: mockClient);
      final page = await api.getProducts();

      expect(page.total, 194);
      expect(page.skip, 0);
      expect(page.limit, 20);
      expect(page.products, hasLength(1));
      expect(page.products.first.title, 'Essence Mascara Lash Princess');
    });

    test('getProduct throws ApiException on 404 response', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/products/0');
        return http.Response(
          jsonEncode({'message': "Product with id '0' not found"}),
          404,
        );
      });

      final api = ProductApi(client: mockClient);

      await expectLater(
        api.getProduct(0),
        throwsA(isA<ApiException>()),
      );
    });

    test('getProducts converts ClientException and FormatException to ApiException', () async {
      final offlineApi = ProductApi(
        client: MockClient((_) async => throw http.ClientException('Offline')),
      );
      await expectLater(
        offlineApi.getProducts(),
        throwsA(isA<ApiException>()),
      );

      final malformedApi = ProductApi(
        client: MockClient((_) async => http.Response('<<<not json>>>', 200)),
      );
      await expectLater(
        malformedApi.getProducts(),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
