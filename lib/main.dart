import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'data/product_api.dart';
import 'screens/products_screen.dart';

void main() {
  runApp(const ApiCatalogApp());
}

class ApiCatalogApp extends StatelessWidget {
  const ApiCatalogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<ProductApi>(
      create: (_) => ProductApi(),
      child: MaterialApp(
        title: 'API Catalog',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
        ),
        home: const ProductsScreen(),
      ),
    );
  }
}
