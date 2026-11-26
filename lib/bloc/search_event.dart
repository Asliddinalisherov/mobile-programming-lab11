sealed class SearchEvent {
  const SearchEvent();
}

final class SearchSubmitted extends SearchEvent {
  final String query;

  const SearchSubmitted(this.query);
}

final class SearchCleared extends SearchEvent {
  const SearchCleared();
}
