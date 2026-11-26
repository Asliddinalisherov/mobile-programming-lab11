import 'dart:convert';
import 'dart:io';

import 'package:api_catalog/cubit/products_cubit.dart';
import 'package:api_catalog/data/product_api.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final fixtureRaw = File('test/fixtures/product.json').readAsStringSync();
  final fixtureMap = jsonDecode(fixtureRaw) as Map<String, dynamic>;

  group('ProductsCubit', () {
    blocTest<ProductsCubit, ProductsState>(
      'emits [ProductsLoading, ProductsLoaded] when getProducts succeeds',
      build: () {
        final mockClient = MockClient((request) async {
          final body = jsonEncode({
            'products': [fixtureMap],
            'total': 194,
            'skip': 0,
            'limit': 20,
          });
          return http.Response(
            body,
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });
        return ProductsCubit(ProductApi(client: mockClient));
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<ProductsLoading>(),
        isA<ProductsLoaded>()
            .having((s) => s.products.length, 'products.length', 1)
            .having((s) => s.total, 'total', 194)
            .having((s) => s.hasMore, 'hasMore', isTrue),
      ],
    );

    blocTest<ProductsCubit, ProductsState>(
      'emits [ProductsLoading, ProductsError] when getProducts fails',
      build: () {
        final mockClient = MockClient((request) async {
          return http.Response('Internal Server Error', 500);
        });
        return ProductsCubit(ProductApi(client: mockClient));
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<ProductsLoading>(),
        isA<ProductsError>(),
      ],
    );

    blocTest<ProductsCubit, ProductsState>(
      'loadMore appends next page using skip = products.length',
      build: () {
        final mockClient = MockClient((request) async {
          final skip = int.parse(request.url.queryParameters['skip'] ?? '0');
          final secondItem = Map<String, dynamic>.from(fixtureMap)
            ..['id'] = 2
            ..['title'] = 'Eyeshadow Palette';
          final body = jsonEncode({
            'products': [skip == 0 ? fixtureMap : secondItem],
            'total': 2,
            'skip': skip,
            'limit': 1,
          });
          return http.Response(
            body,
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });
        return ProductsCubit(ProductApi(client: mockClient));
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.loadMore();
      },
      expect: () => [
        isA<ProductsLoading>(),
        isA<ProductsLoaded>()
            .having((s) => s.products.length, 'initial length', 1)
            .having((s) => s.hasMore, 'hasMore', isTrue),
        isA<ProductsLoaded>()
            .having((s) => s.isLoadingMore, 'isLoadingMore', isTrue),
        isA<ProductsLoaded>()
            .having((s) => s.products.length, 'appended length', 2)
            .having((s) => s.hasMore, 'hasMore', isFalse),
      ],
    );
  });
}
