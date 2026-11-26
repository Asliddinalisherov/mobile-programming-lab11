# `api_catalog` — Mobile Programming Lab 11

A 3-screen Flutter 3.x / Dart 3.x catalog client for the [DummyJSON Products REST API](https://dummyjson.com/docs/products), built with strict layered architecture, hand-written JSON models, **Cubit** (paginated product list & product details), and **Bloc** + `bloc_concurrency` (`restartable()` live search).

## Project Structure

- `bin/peek.dart` — CLI script inspecting `/products/1` (`statusCode`, `title`, `dimensions.runtimeType`)
- `lib/models/` — Hand-written `Product`, `Dimensions`, `Review`, and `ProductPage` models
- `lib/data/product_api.dart` — `ProductApi` & `ApiException` (10s timeout, HTTP status checks, error normalization)
- `lib/cubit/` — `ProductsCubit` (pagination + `isClosed` guards) & `DetailsCubit` with sealed states
- `lib/bloc/` — `SearchBloc`, `SearchEvent`, and 5 sealed `SearchState` classes using `restartable()`
- `lib/screens/` — `ProductsScreen`, `DetailsScreen`, and `SearchScreen` rendering exhaustive `switch` expressions
- `lib/widgets/product_tile.dart` — Reusable `ProductTile` with `Image.network` error fallback
- `test/` — Offline unit & `blocTest` suites powered by `test/fixtures/product.json` and `MockClient`
- `NOTES.md` — Answers to all Parts 1–4 inline questions and the 5 final checkpoint questions

## Commands

```bash
flutter pub get
dart run bin/peek.dart
flutter analyze
flutter test
flutter run
```
