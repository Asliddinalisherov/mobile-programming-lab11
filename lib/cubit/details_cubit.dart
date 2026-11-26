import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/product_api.dart';
import '../models/product.dart';

sealed class DetailsState {
  const DetailsState();
}

final class DetailsLoading extends DetailsState {
  const DetailsLoading();
}

final class DetailsLoaded extends DetailsState {
  final Product product;

  const DetailsLoaded(this.product);
}

final class DetailsError extends DetailsState {
  final String message;

  const DetailsError(this.message);
}

class DetailsCubit extends Cubit<DetailsState> {
  final ProductApi _api;

  DetailsCubit(this._api) : super(const DetailsLoading());

  Future<void> load(int id) async {
    if (isClosed) return;
    emit(const DetailsLoading());

    try {
      final product = await _api.getProduct(id);
      if (isClosed) return;
      emit(DetailsLoaded(product));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(DetailsError(e.message));
    } catch (_) {
      if (isClosed) return;
      emit(const DetailsError('Failed to load product details.'));
    }
  }
}
