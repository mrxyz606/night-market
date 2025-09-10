import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
// You'll need a way to get full Product details from an ID for loading the cart
// This might involve fetching from your products collection or having a product repository.
// For simplicity, we'll assume products are available or can be fetched.

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get totalPrice => product.price * quantity;

  // For Firestore persistence
  Map<String, dynamic> toFirestoreMap() {
    return {
      'productId': product.id,
      'quantity': quantity,
    };
  }
}

class CartService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, CartItem> _items = {};
  List<Product> _availableProducts = []; // To resolve product details from IDs

  // Temporary product lookup - replace with a robust solution (e.g., ProductService)
  // This is a simplification. In a real app, you'd fetch these from Firestore as needed
  // or have them readily available via another service.
  Future<Product?> _getProductById(String productId) async {
    // This is a naive lookup. Ideally, you fetch from your 'products' collection in Firestore.
    // For this example, let's assume _availableProducts is populated somehow (e.g., from HomeScreen)
    // or you fetch directly:
    try {
      DocumentSnapshot productDoc = await _firestore.collection('products').doc(productId).get();
      if (productDoc.exists) {
        return Product.fromFirestore(productDoc.data() as Map<String, dynamic>, productDoc.id);
      }
    } catch (e) {
      print("Error fetching product $productId: $e");
    }
    return null; // Product not found
  }


  CartService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
    _loadCartOnStartup(); // Attempt to load cart for current user if any
  }

  Future<void> _loadCartOnStartup() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _loadCartFromFirestore(user.uid);
    }
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      _items.clear(); // Clear local cart on logout
      print("User logged out, cart cleared.");
      notifyListeners();
    } else {
      // User logged in or already logged in
      print("User ${user.uid} detected, loading cart...");
      await _loadCartFromFirestore(user.uid);
    }
  }

  Map<String, CartItem> get items => {..._items};
  int get itemCount => _items.length;
  int get totalQuantity {
    int total = 0;
    _items.forEach((key, cartItem) {
      total += cartItem.quantity;
    });
    return total; // <<<--- ADDED RETURN STATEMENT
  }

  double get totalPrice {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.product.price * cartItem.quantity;
    });
    return total; // <<<--- ADDED RETURN STATEMENT
  }
  Future<void> _loadCartFromFirestore(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        List<dynamic> cartData = userData['userCart'] as List<dynamic>? ?? [];

        Map<String, CartItem> loadedItems = {};
        for (var itemMap in cartData) {
          String productId = itemMap['productId'];
          int quantity = itemMap['quantity'];
          Product? product = await _getProductById(productId); // You need a way to get Product objects
          if (product != null) {
            loadedItems[productId] = CartItem(product: product, quantity: quantity);
          } else {
            print("Warning: Product with ID $productId not found while loading cart.");
          }
        }
        _items = loadedItems;
        print("Cart loaded from Firestore: ${_items.length} unique items.");
      } else {
        _items.clear(); // User document might not have a cart yet, or doesn't exist
        print("No cart data found in Firestore for user $userId, or user doc doesn't exist.");
      }
    } catch (e) {
      print('Error loading cart from Firestore: $e');
      _items.clear(); // Clear cart on error to avoid inconsistent state
    }
    notifyListeners();
  }

  Future<void> _saveCartToFirestore() async {
    User? user = _auth.currentUser;
    if (user == null) return; // Not logged in

    List<Map<String, dynamic>> cartToSave = _items.values
        .map((cartItem) => cartItem.toFirestoreMap())
        .toList();

    try {
      await _firestore.collection('users').doc(user.uid).set(
        {'userCart': cartToSave},
        SetOptions(merge: true), // Use merge to avoid overwriting other user fields
      );
      print("Cart saved to Firestore for user ${user.uid}");
    } catch (e) {
      print('Error saving cart to Firestore: $e');
      // Optionally, implement retry logic or notify user of save failure
    }
  }

  Future<void> addItem(Product product) async {
    if (_items.containsKey(product.id)) {
      _items.update(
        product.id,
            (existingCartItem) => CartItem(
          product: existingCartItem.product,
          quantity: existingCartItem.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        product.id,
            () => CartItem(product: product, quantity: 1),
      );
    }
    notifyListeners();
    await _saveCartToFirestore(); // Save after modification
  }

  Future<void> removeItem(String productId) async {
    _items.remove(productId);
    notifyListeners();
    await _saveCartToFirestore();
  }

  Future<void> removeSingleItem(String productId) async {
    if (!_items.containsKey(productId)) return;

    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
            (existingCartItem) => CartItem(
          product: existingCartItem.product,
          quantity: existingCartItem.quantity - 1,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
    await _saveCartToFirestore();
  }

  Future<void> clearCart() async {
    _items.clear();
    notifyListeners();
    await _saveCartToFirestore(); // Save empty cart
  }
}
