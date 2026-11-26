import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/product_api.dart';
import '../models/product.dart';

sealed class ProductsState {
  const ProductsState();
}

final class ProductsLoading extends ProductsState {
  const ProductsLoading();
}

final class ProductsError extends ProductsState {
  final String message;

  const ProductsError(this.message);
}

final class ProductsLoaded extends ProductsState {
  final List<Product> products;
  final int total;
  final bool isLoadingMore;

  const ProductsLoaded({
    required this.products,
    required this.total,
    this.isLoadingMore = false,
  });

  bool get hasMore => products.length < total;
}

class ProductsCubit extends Cubit<ProductsState> {
  final ProductApi _api;

  ProductsCubit(this._api) : super(const ProductsLoading());

  Future<void> load() async {
    if (isClosed) return;
    emit(const ProductsLoading());

    try {
      final page = await _api.getProducts();
      if (isClosed) return;
      emit(ProductsLoaded(products: page.products, total: page.total));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(ProductsError(e.message));
    } catch (_) {
      if (isClosed) return;
      emit(const ProductsError('Something went wrong. Please try again.'));
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! ProductsLoaded) return;
    if (current.isLoadingMore || !current.hasMore) return;

    if (isClosed) return;
    emit(
      ProductsLoaded(
        products: current.products,
        total: current.total,
        isLoadingMore: true,
      ),
    );

    try {
      final page = await _api.getProducts(skip: current.products.length);
      if (isClosed) return;
      emit(
        ProductsLoaded(
          products: [...current.products, ...page.products],
          total: page.total,
          isLoadingMore: false,
        ),
      );
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(ProductsError(e.message));
    } catch (_) {
      if (isClosed) return;
      emit(const ProductsError('Failed to load more products.'));
    }
  }
}
