import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cart_service.dart';
import '../models/address.dart'; // Import Address model
import '../models/product.dart';
import 'EditProfileScreen.dart'; // Import Product model
// Import your UserProfileScreen to navigate to edit address if needed


class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  static const routeName = '/checkout';

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Address? _shippingAddress;
  bool _isLoadingAddress = true;
  bool _isPlacingOrder = false;
  String _paymentMethod = 'cod'; // 'cod' for Cash on Delivery

  @override
  void initState() {
    super.initState();
    _loadUserShippingAddress();
  }

  Future<void> _loadUserShippingAddress() async {
    setState(() { _isLoadingAddress = true; });
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          if (userData['shippingAddress'] != null && userData['shippingAddress'] is Map) {
            _shippingAddress = Address.fromMap(userData['shippingAddress']);
          }
        }
      } catch (e) {
        print("Error loading shipping address: $e");
        // Handle error, maybe show a snackbar
      }
    }
    setState(() { _isLoadingAddress = false; });
  }

  Future<void> _placeOrder(CartService cart) async {
    if (_shippingAddress == null || !_shippingAddress!.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set a valid shipping address before placing an order.')),
      );
      return;
    }
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty.')),
      );
      return;
    }

    setState(() { _isPlacingOrder = true; });
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      // Should not happen
      setState(() { _isPlacingOrder = false; });
      return;
    }

    try {
      // Prepare order data
      List<Map<String, dynamic>> orderItems = cart.items.values.map((cartItem) {
        return {
          'productId': cartItem.product.id,
          'productName': cartItem.product.name, // Store some denormalized data
          'productImageUrl': cartItem.product.imageUrl, // For easier display in order history
          'quantity': cartItem.quantity,
          'price': cartItem.product.price, // Price at the time of order
        };
      }).toList();

      double orderTotal = cart.totalPrice;
      // You might add shipping fees, taxes etc. here
      // double shippingFee = 5.0;
      // orderTotal += shippingFee;

      // Create a new order document in a new 'orders' collection
      DocumentReference orderRef = await _firestore.collection('orders').add({
        'userId': currentUser.uid,
        'userEmail': currentUser.email, // For communication
        'userName': currentUser.displayName ?? _shippingAddress?.street.split(' ')[0] ?? 'Customer', // best effort name
        'shippingAddress': _shippingAddress!.toMap(),
        'items': orderItems,
        'totalAmount': orderTotal,
        'paymentMethod': _paymentMethod, // 'cod'
        'orderStatus': 'pending', // Initial status (e.g., pending, processing, shipped, delivered, cancelled)
        'orderDate': FieldValue.serverTimestamp(),
        // 'shippingFee': shippingFee,
      });

      // Clear the cart after successful order placement
      await cart.clearCart(); // This should also update Firestore for the cart

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order placed successfully! Order ID: ${orderRef.id}')),
        );
        // Navigate to an order success screen or back to home
        Navigator.of(context).popUntil((route) => route.isFirst); // Go to home
        // Or Navigator.of(context).pushReplacementNamed('/order-success', arguments: orderRef.id);
      }

    } catch (e) {
      print("Error placing order: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to place order: ${e.toString()}')),
        );
      }
    } finally {
      if(mounted) {
        setState(() { _isPlacingOrder = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: _isLoadingAddress
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shipping Address Section
            Text('Shipping Address', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            _shippingAddress != null && _shippingAddress!.isValid
                ? Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_shippingAddress!.street, style: theme.textTheme.bodyLarge),
                    Text('${_shippingAddress!.city}, ${_shippingAddress!.state} ${_shippingAddress!.postalCode}', style: theme.textTheme.bodyLarge),
                    Text(_shippingAddress!.country, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Change Address'),
                      onPressed: () async {
                        final bool? addressUpdated = await Navigator.pushNamed(context, EditProfileScreen.routeName) as bool?;
                        if (addressUpdated == true) {
                          _loadUserShippingAddress(); // Reload address after editing
                        }
                      },
                    )
                  ],
                ),
              ),
            )
                : Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    const Text('No shipping address found or address is incomplete.'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      child: const Text('Add/Edit Shipping Address'),
                      onPressed: () async {
                        final bool? addressUpdated = await Navigator.pushNamed(context, EditProfileScreen.routeName) as bool?;
                        if (addressUpdated == true) {
                          _loadUserShippingAddress(); // Reload address
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 32),

            // Order Summary Section
            Text('Order Summary', style: theme.textTheme.titleLarge),
            if (cart.items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text('Your cart is empty.'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cart.items.length,
                itemBuilder: (ctx, i) {
                  final cartItem = cart.items.values.toList()[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(cartItem.product.imageUrl),
                    ),
                    title: Text(cartItem.product.name),
                    subtitle: Text('Qty: ${cartItem.quantity}'),
                    trailing: Text('\$${(cartItem.product.price * cartItem.quantity).toStringAsFixed(2)}'),
                  );
                },
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal:', style: theme.textTheme.titleMedium),
                Text('\$${cart.totalPrice.toStringAsFixed(2)}', style: theme.textTheme.titleMedium),
              ],
            ),
            // You can add Shipping Fee, Taxes here if needed
            // Row( ... children: [Text('Shipping:'), Text('\$5.00')]),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text('\$${cart.totalPrice.toStringAsFixed(2)}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              ],
            ),

            const Divider(height: 32),

            // Payment Method Section
            Text('Payment Method', style: theme.textTheme.titleLarge),
            RadioListTile<String>(
              title: const Text('Cash on Delivery (COD)'),
              value: 'cod',
              groupValue: _paymentMethod,
              onChanged: (String? value) {
                if (value != null) setState(() => _paymentMethod = value);
              },
            ),
            // Add more payment methods here later if needed
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isPlacingOrder
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton.icon(
          icon: const Icon(Icons.payment_rounded),
          label: const Text('PLACE ORDER'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: cart.items.isEmpty || _shippingAddress == null || !_shippingAddress!.isValid
              ? null // Disable if cart is empty or no valid address
              : () => _placeOrder(cart),
        ),
      ),
    );
  }
}
