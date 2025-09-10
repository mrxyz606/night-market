import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../models/product.dart'; // Your Product model
import '../data/mock_products.dart'; // Your mock products
import '../services/cart_service.dart'; // Your CartService
import 'cart_screen.dart'; // Your CartScreen

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Access the CartService. Using context.watch() will make this widget
    // rebuild when the cart changes (e.g., to update the badge count).
    final cart = context.watch<CartService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Night Market'),
            if (user != null)
              Text(
                'Welcome, ${user.displayName ?? user.email?.split('@')[0] ?? 'User'}!',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
          ],
        ),
        actions: [
          // Cart Icon with Badge
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  tooltip: 'Open Cart',
                  onPressed: () {
                    Navigator.pushNamed(context, '/cart');
                  },
                ),
                if (cart.totalQuantity > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error, // Or theme.colorScheme.secondary
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${cart.totalQuantity}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // AuthWrapper will handle navigation to LoginScreen
            },
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: mockProducts.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Number of columns
          childAspectRatio: 2 / 3, // Width to height ratio of items
          crossAxisSpacing: 10, // Horizontal space between items
          mainAxisSpacing: 10, // Vertical space between items
        ),
        itemBuilder: (ctx, i) {
          final product = mockProducts[i];
          return _buildProductItem(context, product, cart, theme);
        },
      ),
    );
  }

  Widget _buildProductItem(BuildContext context, Product product, CartService cart, ThemeData theme) {
    return Card(
      clipBehavior: Clip.antiAlias, // Ensures the InkWell splash is contained
      child: InkWell(
        onTap: () {
          // TODO: Navigate to Product Detail Screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tapped on ${product.name}. Details page TODO.'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              flex: 3, // Give more space to image
              child: Hero( // Optional: for hero animations to product detail page
                tag: product.id,
                child: product.imageUrl.isNotEmpty
                    ? Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
                    );
                  },
                )
                    : Container( // Placeholder if no image URL
                  color: Colors.grey[200],
                  child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey[400]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8,0,8,8),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  textStyle: theme.textTheme.labelMedium,
                  // Use a less prominent style if you have primary buttons elsewhere
                  // backgroundColor: theme.colorScheme.secondary.withOpacity(0.8),
                  // foregroundColor: theme.colorScheme.onSecondary,
                ),
                onPressed: () {
                  cart.addItem(product);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide previous snackbar if any
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
          ],
        ),
      ),
    );
  }
}
