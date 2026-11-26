import 'review.dart';

class Dimensions {
  final double width;
  final double height;
  final double depth;

  const Dimensions({
    required this.width,
    required this.height,
    required this.depth,
  });

  factory Dimensions.fromJson(Map<String, dynamic> json) {
    return Dimensions(
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      depth: (json['depth'] as num).toDouble(),
    );
  }
}

class Product {
  final int id;
  final String title;
  final String description;
  final double price;
  final double rating;
  final String? brand;
  final List<String> tags;
  final String thumbnail;
  final List<String> images;
  final Dimensions dimensions;
  final List<Review> reviews;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rating,
    required this.brand,
    required this.tags,
    required this.thumbnail,
    required this.images,
    required this.dimensions,
    required this.reviews,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'] as List<dynamic>?;
    final rawImages = json['images'] as List<dynamic>?;
    final rawReviews = json['reviews'] as List<dynamic>?;
    final rawDimensions = json['dimensions'] as Map<String, dynamic>?;

    return Product(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      price: (json['price'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      brand: json['brand'] as String?,
      tags: rawTags?.map((tag) => tag as String).toList() ?? const <String>[],
      thumbnail: (json['thumbnail'] as String?) ?? '',
      images:
          rawImages?.map((img) => img as String).toList() ?? const <String>[],
      dimensions: rawDimensions != null
          ? Dimensions.fromJson(rawDimensions)
          : const Dimensions(width: 0, height: 0, depth: 0),
      reviews: rawReviews
              ?.map((rev) => Review.fromJson(rev as Map<String, dynamic>))
              .toList() ??
          const <Review>[],
    );
  }
}
