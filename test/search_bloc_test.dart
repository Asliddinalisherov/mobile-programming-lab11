import 'dart:convert';
import 'dart:io';

import 'package:api_catalog/bloc/search_bloc.dart';
import 'package:api_catalog/bloc/search_event.dart';
import 'package:api_catalog/bloc/search_state.dart';
import 'package:api_catalog/data/product_api.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final fixtureRaw = File('test/fixtures/product.json').readAsStringSync();
  final fixtureMap = jsonDecode(fixtureRaw) as Map<String, dynamic>;

  group('SearchBloc', () {
    blocTest<SearchBloc, SearchState>(
      'SearchSubmitted("phone") emits [SearchLoading, SearchResults]',
      build: () {
        final mockClient = MockClient((request) async {
          expect(request.url.path, '/products/search');
          expect(request.url.queryParameters['q'], 'phone');
          final body = jsonEncode({
            'products': [fixtureMap],
            'total': 1,
            'skip': 0,
            'limit': 1,
          });
          return http.Response(
            body,
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });
        return SearchBloc(ProductApi(client: mockClient));
      },
      act: (bloc) => bloc.add(const SearchSubmitted('phone')),
      expect: () => [
        isA<SearchLoading>(),
        isA<SearchResults>().having(
          (s) => s.products.length,
          'products.length',
          1,
        ),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'SearchSubmitted("") emits only [SearchIdle] without network call',
      build: () {
        final mockClient = MockClient((request) async {
          fail('Network should not be called for an empty search query');
        });
        return SearchBloc(ProductApi(client: mockClient));
      },
      act: (bloc) => bloc.add(const SearchSubmitted('   ')),
      expect: () => [
        isA<SearchIdle>(),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'restartable() cancels slow in-flight search when newer query arrives',
      build: () {
        final mockClient = MockClient((request) async {
          final query = request.url.queryParameters['q'];
          if (query == 'ph') {
            await Future<void>.delayed(const Duration(milliseconds: 120));
            return http.Response(
              jsonEncode({
                'products': <dynamic>[],
                'total': 0,
                'skip': 0,
                'limit': 0,
              }),
              200,
            );
          }
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return http.Response(
            jsonEncode({
              'products': [fixtureMap],
              'total': 1,
              'skip': 0,
              'limit': 1,
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });
        return SearchBloc(ProductApi(client: mockClient));
      },
      act: (bloc) async {
        bloc.add(const SearchSubmitted('ph'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const SearchSubmitted('phone'));
      },
      wait: const Duration(milliseconds: 200),
      expect: () => [
        isA<SearchLoading>(),
        isA<SearchResults>(),
      ],
    );
  });
}
