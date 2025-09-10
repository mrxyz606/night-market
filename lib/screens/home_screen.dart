import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:night_market/screens/product_detail_screen.dart';
import 'package:night_market/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';
import '../services/cart_service.dart';
// import 'cart_screen.dart'; // No longer explicitly needed here if using named routes only for FAB
import 'add_product_screen.dart';
import 'user_profile_screen.dart'; // Assuming you have this for the profile icon

class HomeScreen extends StatelessWidget {

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final cart = context.watch<CartService>(); // Watch for cart changes
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Night Market'),
            if (user != null)
              Text(
                'Welcome, ${ user.email?.split('@')[0] ?? 'User'}!',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
          ],
        ),
        actions: [
          // Admin Add Product Button (if you still want it here)
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add New Product',
            onPressed: () {
              Navigator.pushNamed(context, AddProductScreen.routeName);
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'My Profile',
            onPressed: () {
              Navigator.pushNamed(context, UserProfileScreen.routeName);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'App Settings',
            onPressed: ()  {
              Navigator.pushNamed(context, SettingsScreen.routeName);            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('products').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          // ... (your existing StreamBuilder logic for displaying products) ...
          // This part remains unchanged from the previous version
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Firestore error: ${snapshot.error}");
            return Center(child: Text('Error: ${snapshot.error?.toString() ?? "Something went wrong"}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storefront_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No products available yet.', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Try adding some products using the "+" button above.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final productDocs = snapshot.data!.docs;
          final products = productDocs.map((doc) => Product.fromFirestore(doc.data(), doc.id)).toList();

          return GridView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2 / 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (ctx, i) {
              final product = products[i];
              return _buildProductItem(context, product, cart, theme);
            },
          );
        },
      ),
      // Add the FloatingActionButton here
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/cart');
        },
        tooltip: 'View Cart',
        icon: Icon(
          Icons.shopping_cart_checkout_rounded,
          color: theme.colorScheme.onSecondaryContainer, // Example color
        ),
        label: Row(
          children: [
            Text(
              'View Cart',
              style: TextStyle(color: theme.colorScheme.onSecondaryContainer), // Example color
            ),
            if (cart.totalQuantity > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white, // Badge background color
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${cart.totalQuantity}',
                  style: TextStyle(
                    color: Colors.black, // Badge text color
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ]
          ],
        ),
        backgroundColor: theme.colorScheme.secondaryContainer, // Example FAB background color
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, // Or .endFloat, etc.
    );
  }

  // _buildProductItem method remains the same
  Widget _buildProductItem(BuildContext context, Product product, CartService cart, ThemeData theme) {
    // ... (This method is the same as in the previous HomeScreen version) ...
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Navigate to ProductDetailScreen and pass the product object
          Navigator.pushNamed(
            context,
            ProductDetailScreen.routeName,
            arguments: product, // Pass the product as an argument
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              flex: 3,
              child: Hero(
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
                    : Container(
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
                ),
                onPressed: () async{
                  await cart.addItem(product);
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
          ],
        ),
      ),
    );
  }
}

