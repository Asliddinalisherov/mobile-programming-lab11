import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/product_api.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final ProductApi _api;

  SearchBloc(this._api) : super(const SearchIdle()) {
    on<SearchSubmitted>(_onSearchSubmitted, transformer: restartable());
    on<SearchCleared>(_onSearchCleared);
  }

  Future<void> _onSearchSubmitted(
    SearchSubmitted event,
    Emitter<SearchState> emit,
  ) async {
    final trimmed = event.query.trim();
    if (trimmed.isEmpty) {
      emit(const SearchIdle());
      return;
    }

    emit(const SearchLoading());

    try {
      final page = await _api.search(trimmed);
      if (page.products.isEmpty) {
        emit(SearchEmpty(trimmed));
      } else {
        emit(SearchResults(page.products));
      }
    } on ApiException catch (e) {
      emit(SearchError(e.message));
    } catch (_) {
      emit(const SearchError('Something went wrong while searching.'));
    }
  }

  void _onSearchCleared(SearchCleared event, Emitter<SearchState> emit) {
    emit(const SearchIdle());
  }
}
