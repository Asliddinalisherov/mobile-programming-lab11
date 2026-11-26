import 'package:material_ui/material_ui.dart';

import '../models/product.dart';
import '../screens/details_screen.dart';

class ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductTile({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 56,
          height: 56,
          color: colorScheme.surfaceContainerHighest,
          child: product.thumbnail.isEmpty
              ? Icon(
                  Icons.image_not_supported_outlined,
                  color: colorScheme.onSurfaceVariant,
                )
              : Image.network(
                  product.thumbnail,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.broken_image_outlined,
                      color: colorScheme.onSurfaceVariant,
                    );
                  },
                ),
        ),
      ),
      title: Text(
        product.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '★ ${product.rating.toStringAsFixed(1)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap ??
          () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => DetailsScreen(productId: product.id),
              ),
            );
          },
    );
  }
}
