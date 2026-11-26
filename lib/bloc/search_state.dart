import '../models/product.dart';

sealed class SearchState {
  const SearchState();
}

final class SearchIdle extends SearchState {
  const SearchIdle();
}

final class SearchLoading extends SearchState {
  const SearchLoading();
}

final class SearchResults extends SearchState {
  final List<Product> products;

  const SearchResults(this.products);
}

final class SearchEmpty extends SearchState {
  final String query;

  const SearchEmpty(this.query);
}

final class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);
}
