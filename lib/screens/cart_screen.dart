import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart'; // Adjust path as needed
import '../models/product.dart';
import 'checkout_screen.dart';      // Adjust path as needed

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      bottomNavigationBar: cart.items.isEmpty
          ? null
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(
                  '\$${cart.totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),

                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.shopping_cart_checkout_rounded),
              label: const Text('PROCEED TO CHECKOUT'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50), // Full width
              ),
              onPressed: () {
                Navigator.pushNamed(context, CheckoutScreen.routeName);
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          if (cart.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear Cart',
              onPressed: () {
                // Confirmation Dialog
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Cart?'),
                    content: const Text(
                        'Do you want to remove all items from your cart?'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('No'),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                        },
                      ),
                      TextButton(
                        child: Text('Yes', style: TextStyle(color: theme.colorScheme.error)),
                        onPressed: () {
                          cart.clearCart();
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: cart.items.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Your cart is empty!',
              style: theme.textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Looks like you haven\'t added anything to your cart yet.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),
            ElevatedButton(

              onPressed: () {
                Navigator.of(context).pop(); // Go back to the previous screen (likely HomeScreen)
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0,left: 8.0),
                child: const Text('Start Shopping'),
              ),
            )
          ],
        ),
      )
          : Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (ctx, i) {
                final cartItemEntry = cart.items.entries.toList()[i];
                final productId = cartItemEntry.key;
                final cartItem = cartItemEntry.value;
                return _buildCartItemTile(context, cart, cartItem, productId, theme);
              },
            ),
          ),
          _buildCartSummary(context, cart, theme),
        ],
      ),
    );
  }

  Widget _buildCartItemTile(BuildContext context, CartService cart, CartItem cartItem, String productId, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Product Image Placeholder (Optional)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(cartItem.product.imageUrl), // Assuming imageUrl is valid
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) => Icon(Icons.image_not_supported, size: 40, color: Colors.grey[300]),
                ),
                color: Colors.grey[200],
              ),
              child: cartItem.product.imageUrl.isEmpty ? Icon(Icons.shopping_bag, size: 40, color: Colors.grey[400]) : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    cartItem.product.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${cartItem.product.price.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline, color: theme.colorScheme.error, size: 28),
                        onPressed: () => cart.removeSingleItem(productId),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          cartItem.quantity.toString(),
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary, size: 28),
                        onPressed: () => cart.addItem(cartItem.product),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.delete_outline, color: theme.colorScheme.error.withOpacity(0.7), size: 24),
                  tooltip: 'Remove from cart',
                  onPressed: () => cart.removeItem(productId),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 20), // Spacer
                Text(
                  '\$${(cartItem.product.price * cartItem.quantity).toStringAsFixed(2)}',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(BuildContext context, CartService cart, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: theme.cardColor, // Or theme.scaffoldBackgroundColor for different effect
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -5), // changes position of shadow
          ),
        ],
        borderRadius: const BorderRadius.only( // Optional: if you want rounded top corners
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Subtotal:', style: theme.textTheme.titleMedium),
              Text(
                '\$${cart.totalPrice.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // You can add more details like Tax, Shipping if needed
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Shipping:', style: TextStyle(fontSize: 18)),
              Text('Free', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),


        ],
      ),
    );
  }
}
