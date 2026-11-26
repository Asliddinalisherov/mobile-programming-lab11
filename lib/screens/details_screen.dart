import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/details_cubit.dart';
import '../data/product_api.dart';
import '../models/product.dart';
import '../models/review.dart';

class DetailsScreen extends StatelessWidget {
  final int productId;

  const DetailsScreen({
    super.key,
    required this.productId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DetailsCubit>(
      create: (context) =>
          DetailsCubit(context.read<ProductApi>())..load(productId),
      child: _DetailsView(productId: productId),
    );
  }
}

class _DetailsView extends StatelessWidget {
  final int productId;

  const _DetailsView({required this.productId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
      ),
      body: BlocBuilder<DetailsCubit, DetailsState>(
        builder: (context, state) {
          return switch (state) {
            DetailsLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            DetailsError(:final message) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () =>
                            context.read<DetailsCubit>().load(productId),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            DetailsLoaded(:final product) => _ProductDetailsContent(
                product: product,
              ),
          };
        },
      ),
    );
  }
}

class _ProductDetailsContent extends StatelessWidget {
  final Product product;

  const _ProductDetailsContent({required this.product});

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _renderStars(int rating) {
    final clamped = rating.clamp(0, 5);
    return '${'★' * clamped}${'☆' * (5 - clamped)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final imageUrls = product.images.isNotEmpty
        ? product.images
        : (product.thumbnail.isNotEmpty ? [product.thumbnail] : <String>[]);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (imageUrls.isNotEmpty)
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: imageUrls.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: imageUrls.length == 1
                        ? MediaQuery.sizeOf(context).width - 32
                        : 260,
                    color: colorScheme.surfaceContainerHighest,
                    child: Image.network(
                      imageUrls[index],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          )
        else
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                size: 48,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          product.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (product.brand != null && product.brand!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Brand: ${product.brand}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            Chip(
              label: Text('★ ${product.rating.toStringAsFixed(1)}'),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        if (product.tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in product.tags)
                Chip(
                  label: Text('#$tag'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Text(
          'Description',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          product.description,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dimensions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Width: ${product.dimensions.width.toStringAsFixed(2)} cm  •  '
                  'Height: ${product.dimensions.height.toStringAsFixed(2)} cm  •  '
                  'Depth: ${product.dimensions.depth.toStringAsFixed(2)} cm',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Reviews (${product.reviews.length})',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (product.reviews.isEmpty)
          Text(
            'No customer reviews yet.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          )
        else
          for (final Review review in product.reviews)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            review.reviewerName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          _formatDate(review.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _renderStars(review.rating),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      review.comment,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
