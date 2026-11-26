# Lab 11 Notes — `api_catalog` (Fetch, Parse, Emit: REST API Client with Cubit & Bloc)

---

## Part 1–4 Inline Questions

### 1. JSON Field Types & `bin/peek.dart` Output (Part 1)
Running `dart run bin/peek.dart` against `https://dummyjson.com/products/1` outputs:

```text
statusCode: 200
title: Essence Mascara Lash Princess
dimensions.runtimeType: _Map<String, dynamic>
```

When `jsonDecode(response.body)` parses the DummyJSON payload, Dart assigns the following runtime types:
- **`id`, `stock`, `weight`, `minimumOrderQuantity`:** `int`
- **`title`, `description`, `category`, `sku`, `thumbnail`:** `String`
- **`brand`:** `String?` (`String` when present, e.g. `"Essence"`, or `null`/absent on unbranded items such as groceries like `/products/16`)
- **`price`, `rating`, `discountPercentage`:** `double` when fractional (`9.99`, `2.56`), or `int` when whole (`10`, `4`) — both share Dart's `num` supertype
- **`tags`, `images`:** `List<dynamic>` (elements are `String`, must be mapped/cast to `List<String>`, and `tags` may be omitted)
- **`dimensions`:** `_Map<String, dynamic>` (Dart VM's internal `LinkedHashMap` implementation of `Map<String, dynamic>`), containing `width`, `height`, and `depth` numbers
- **`reviews`:** `List<dynamic>`, where each element is a `_Map<String, dynamic>` with `rating` (`int`), `comment` (`String`), `reviewerName` (`String`), and `date` (ISO-8601 `String`)

---

### 2. What Does `/products/0` Return, and Why Must Status Be Checked Before Decoding? (Part 1 & Part 3)
Requesting `https://dummyjson.com/products/0` returns **HTTP status `404 Not Found`** with the JSON body:

```json
{"message":"Product with id '0' not found"}
```

Notice that the payload is still valid JSON (`Map<String, dynamic>`), so `jsonDecode` alone would succeed, **but** none of the `Product` keys (`id`, `title`, `price`, etc.) exist. Checking `if (response.statusCode != 200)` inside `ProductApi._get` *before* decoding and model parsing converts the `404` immediately into a clean, user-readable `ApiException('The requested item was not found (404).')` instead of crashing inside `Product.fromJson` with a `TypeError`.

---

### 3. Why Does `json['price'] as double` Fail at Runtime When JSON Contains `10`? (Part 2)
JSON has only a single number primitive (`10` and `9.99` are both JSON numbers), whereas Dart's type system separates `int` and `double` into sibling subtypes of `num` (on the Dart VM, `int` is **not** a subtype of `double`).

When the API returns `"price": 10` without a decimal point, `jsonDecode` instantiates a Dart `int`. Executing `json['price'] as double` throws a runtime `TypeError`:

```text
type 'int' is not a subtype of type 'double' in type cast
```

Casting to `num` first — `(json['price'] as num).toDouble()` — accepts both `int` (`10 -> 10.0`) and `double` (`9.99 -> 9.99`) safely.

---

### 4. Why Are Fixture + `MockClient` Tests Better Than Live Network Requests? (Part 2 & Part 3)
1. **Determinism & zero data drift:** A live API's products, prices, ratings, or total item count can change or go down at any moment, causing flaky test failures unrelated to app code. `test/fixtures/product.json` guarantees identical inputs forever.
2. **Speed & offline reliability:** Unit and Bloc tests run in milliseconds without Wi-Fi, DNS lookups, TLS handshakes, corporate firewalls, or API rate limits (essential for CI/CD and sandboxed grading).
3. **Deterministic edge-case simulation:** With `MockClient`, tests can reliably reproduce HTTP `404`/`500` responses, malformed JSON (`FormatException`), offline `ClientException`s, and out-of-order network latencies (to verify `restartable()`), which cannot be triggered on demand against a live server.

---

### 5. What Happens Without `if (isClosed) return;` in `ProductsCubit` / `DetailsCubit`? (Part 4)
Async Cubit methods (`load()`, `loadMore()`) suspend execution at `await _api.getProducts()`. If the user navigates away (popping `DetailsScreen` or disposing `ProductsScreen`) while the HTTP request is still in flight, `BlocProvider` disposes the Cubit and calls `close()`.

When the HTTP future finishes moments later, calling `emit(...)` on an already-closed Cubit throws an unhandled `StateError`:

```text
Bad state: Cannot emit new states after calling close
```

Guarding `emit()` calls with `if (isClosed) return;` cleanly drops late responses after disposal.

---

### 6. Why Use `isA<ProductsLoaded>()` in `blocTest` Instead of Value Equality / `Equatable`? (Part 4)
In Dart, classes inherit `Object.==` (identity comparison) unless `operator ==` and `hashCode` are manually overridden or generated/mixed in via `Equatable`. Two separate `ProductsLoaded` instances containing newly parsed `List<Product>` objects are distinct references in memory, so `expect: () => [ProductsLoading(), ProductsLoaded(...)]` would fail equality comparison even when all field values match.

Using type matchers (`isA<ProductsLoaded>().having(...)`) lets `blocTest` verify the exact sealed state subtype and assert specific properties (`products.length`, `total`, `hasMore`) cleanly without adding `Equatable` boilerplate to every state and nested model (`Product`, `Dimensions`, `Review`).

---

## Final Checkpoint Questions

### 1. Trace a Single Product from HTTP Response to `ProductTile` UI
1. **Trigger:** `ProductsScreen` mounts and its `BlocProvider` creates `ProductsCubit(context.read<ProductApi>())..load()`.
2. **Loading state:** `ProductsCubit.load()` emits `const ProductsLoading()`, causing `ProductsScreen`'s `BlocBuilder` `switch` expression to render `CircularProgressIndicator`.
3. **HTTP transport:** `ProductsCubit` calls `ProductApi.getProducts(limit: 20, skip: 0)`, which builds `Uri.https('dummyjson.com', '/products', {'limit': '20', 'skip': '0'})` and calls `_client.get(uri).timeout(const Duration(seconds: 10))`.
4. **Validation & JSON decode:** `ProductApi._get` checks `response.statusCode == 200`, decodes `response.bodyBytes` as UTF-8, and runs `jsonDecode(...)` to produce a `Map<String, dynamic>`.
5. **Typed deserialization:** `ProductPage.fromJson` iterates over `json['products']` and calls `Product.fromJson` on each map (which in turn builds `Dimensions.fromJson` and `Review.fromJson`), returning a strongly typed `ProductPage` containing `List<Product>`.
6. **Loaded state emission:** `ProductsCubit` checks `if (isClosed) return;` and emits `ProductsLoaded(products: page.products, total: page.total)`.
7. **UI rendering:** `BlocBuilder<ProductsCubit, ProductsState>` rebuilds, exhaustively matches `ProductsLoaded`, and builds a `ListView.separated` that passes each typed `Product` into `ProductTile(product: products[index])`. `ProductTile` renders the left `Image.network` thumbnail (with `errorBuilder` icon fallback), `product.title`, `\$${product.price.toStringAsFixed(2)}`, and `★ ${product.rating.toStringAsFixed(1)}`.

---

### 2. Error-to-State Mapping in `getProducts()`
Every low-level failure in `ProductApi.getProducts()` is normalized into `ApiException` and mapped to `ProductsError(message)` in `ProductsCubit`:

| Failure Source | Exception Caught in `ProductApi` | `ApiException.message` | Cubit State & Screen UI |
| :--- | :--- | :--- | :--- |
| Non-200 HTTP (`404`) | Checked before `jsonDecode` | `"The requested item was not found (404)."` | `ProductsError(message)` + **Retry** button |
| Server failure (`500+`) | Checked before `jsonDecode` | `"Server error (500). Please try again later."` | `ProductsError(message)` + **Retry** button |
| Other non-200 HTTP | Checked before `jsonDecode` | `"Request failed with status code <code >."` | `ProductsError(message)` + **Retry** button |
| Slow network (>10s) | `TimeoutException` | `"The connection timed out. Please check your internet and try again."` | `ProductsError(message)` + **Retry** button |
| Offline / DNS / socket error | `http.ClientException` | `"Unable to connect to the server. Please check your internet connection."` | `ProductsError(message)` + **Retry** button |
| Corrupted / non-JSON body | `FormatException` | `"Received invalid data from the server. Please try again later."` | `ProductsError(message)` + **Retry** button |
| Unexpected field schema | `TypeError` | `"Received unexpected product list format."` | `ProductsError(message)` + **Retry** button |

Tapping **Retry** invokes `context.read<ProductsCubit>().load()`, transitioning back to `ProductsLoading` and re-attempting the request.

---

### 3. Cubit vs. Bloc: Comparing Catalog List (`ProductsCubit`) and Search (`SearchBloc`)
- **Cubit (`ProductsCubit` & `DetailsCubit`):** Exposes plain Dart methods (`load()`, `loadMore()`, `load(id)`). Because loading the catalog page or opening a product detail screen is a direct, discrete action without overlapping stream concurrency hazards, Cubit keeps the code concise — requiring only a sealed `State` hierarchy and no `Event` classes (`loadMore()` simply guards against duplicates with `if (current.isLoadingMore) return;`).
- **Bloc (`SearchBloc`):** Models user actions as explicit event objects (`SearchSubmitted(query)`, `SearchCleared()`) pushed into an input `Stream`. Because search input arrives rapidly as the user types, modeling inputs as a stream allows `SearchBloc` to attach `transformer: restartable()` to `on<SearchSubmitted>`, declaratively cancelling stale in-flight HTTP searches whenever a newer keystroke arrives. Achieving the same cancellation behavior in a Cubit would require manually managing stream subscriptions or cancellation tokens inside the Cubit.

---

### 4. `restartable()` vs. Default Event Transformer in `SearchBloc`
- **Default transformer (`concurrent()`):** Runs event handlers concurrently as events arrive. Suppose a user types `"ph"` (request A takes 600 ms) and immediately continues typing `"phone"` (request B takes 120 ms). Request B finishes first at 120 ms and displays `"phone"` results — then 480 ms later, stale Request A finishes and **overwrites** the UI with results for `"ph"`, leaving the screen out of sync with the text box.
- **`restartable()` (`package:bloc_concurrency`):** Uses `switchMap` semantics on the event stream. The instant `SearchSubmitted('phone')` is added, the active handler execution for `SearchSubmitted('ph')` is cancelled so any subsequent `emit(...)` from `"ph"` is ignored. Only the latest search query can emit final results to the UI.

---

### 5. Two Reasons Widgets Must Never Call `http.get` or Touch `Map<String, dynamic>`
1. **Separation of concerns & resilience to API changes:** If multiple screens (`ProductsScreen`, `DetailsScreen`, `SearchScreen`, `ProductTile`) read `map['price']` or `map['tags']` directly, every widget must duplicate null-safety defaults, numeric `(as num).toDouble()` casts, timeout logic, and HTTP status handling — and a single backend schema change breaks UI files across the entire app instead of one factory in `lib/models/` or one method in `ProductApi`.
2. **Offline testability & pure declarative UI (`UI = f(State)`):** Flutter's `build()` method must be synchronous, side-effect-free, and safe to invoke on any frame. Triggering `http.get` from widgets couples UI rendering to live network I/O, risks firing duplicate HTTP calls on rebuilds, and makes unit/widget testing impossible without global HTTP overrides. Restricting widgets to exhaustive `switch` expressions over sealed states keeps screens trivial to reason about and allows `Models`, `ProductApi`, `Cubits`, and `SearchBloc` to be tested completely offline.
