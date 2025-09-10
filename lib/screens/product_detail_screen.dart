import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/wishlist_service.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

  static const routeName = '/product-detail';

  @override
  Widget build(BuildContext context) {
    // Retrieve the product passed via arguments
    // Ensure you pass the Product object when navigating to this screen
    final product = ModalRoute.of(context)?.settings.arguments as Product?;

    if (product == null) {
      // Fallback if product is not passed correctly (should not happen with proper navigation)
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Product not found! Please go back.')),
      );
    }

    final cart = Provider.of<CartService>(context, listen: false); // listen:false if only using methods
    final wishlist = context.watch<WishlistService>(); // watch:true to rebuild on favorite change
    final theme = Theme.of(context);

    final isFavorite = wishlist.isFavorite(product.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? theme.colorScheme.error : null,
            ),
            tooltip: isFavorite ? 'Remove from Wishlist' : 'Add to Wishlist',
            onPressed: () async{
              await wishlist.toggleFavorite(product); // await the call
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(isFavorite
                    ? '${product.name} removed from wishlist.'
                    : '${product.name} added to wishlist!'),
                duration: const Duration(seconds: 2),
              ));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(0), // No padding for full-width image at top
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Hero(
              tag: product.id, // Same tag as in HomeScreen
              child: product.imageUrl.isNotEmpty
                  ? Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                height: MediaQuery.of(context).size.height * 0.4, // 40% of screen height
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: MediaQuery.of(context).size.height * 0.4,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  height: MediaQuery.of(context).size.height * 0.4,
                  color: Colors.grey[200],
                  child: Icon(Icons.broken_image, size: 60, color: Colors.grey[400]),
                ),
              )
                  : Container(
                height: MediaQuery.of(context).size.height * 0.4,
                color: Colors.grey[200],
                child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey[400]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Description',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5), // Improved line spacing
                  ),
                  const SizedBox(height: 24),
                  // You can add more details like reviews, specifications etc.
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.add_shopping_cart_rounded),
          label: const Text('ADD TO CART'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            // backgroundColor: theme.colorScheme.secondary,
            // foregroundColor: theme.colorScheme.onSecondary,
          ),
          onPressed: () {
            cart.addItem(product);
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${product.name} added to cart!'),
                duration: const Duration(seconds: 2),
                action: SnackBarAction(
                  label: 'VIEW CART',
                  onPressed: () {
                    Navigator.pushNamed(context, '/cart');
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


