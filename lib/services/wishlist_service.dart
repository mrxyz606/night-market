import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart'; // Ensure Product model is available

class WishlistService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> _wishlistedProductIds = []; // Store only IDs
  // To display wishlisted items, you'll need to fetch Product details using these IDs
  // This might involve a method similar to _getProductById in CartService or a Product repository

  WishlistService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
    _loadWishlistOnStartup();
  }

  Future<void> _loadWishlistOnStartup() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _loadWishlistFromFirestore(user.uid);
    }
  }


  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      _wishlistedProductIds.clear();
      print("User logged out, wishlist cleared.");
      notifyListeners();
    } else {
      print("User ${user.uid} detected, loading wishlist...");
      await _loadWishlistFromFirestore(user.uid);
    }
  }

  // This getter is just for the IDs. To get full Product objects for display,
  // you'll need another method that fetches Products based on these IDs.
  List<String> get wishlistedProductIds => [..._wishlistedProductIds];

  Future<void> _loadWishlistFromFirestore(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        // Ensure the field name matches what you use in Firestore (e.g., 'userWishlist')
        _wishlistedProductIds = List<String>.from(userData['userWishlist'] as List<dynamic>? ?? []);
        print("Wishlist loaded from Firestore: ${_wishlistedProductIds.length} items.");
      } else {
        _wishlistedProductIds.clear();
        print("No wishlist data found in Firestore for user $userId, or user doc doesn't exist.");
      }
    } catch (e) {
      print('Error loading wishlist from Firestore: $e');
      _wishlistedProductIds.clear();
    }
    notifyListeners();
  }

  Future<void> _saveWishlistToFirestore() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set(
        {'userWishlist': _wishlistedProductIds}, // Store the list of IDs
        SetOptions(merge: true),
      );
      print("Wishlist saved to Firestore for user ${user.uid}");
    } catch (e) {
      print('Error saving wishlist to Firestore: $e');
    }
  }

  bool isFavorite(String productId) {
    return _wishlistedProductIds.contains(productId);
  }

  Future<void> toggleFavorite(Product product) async {
    final productId = product.id; // We only need the ID for persistence logic
    final isCurrentlyFavorite = isFavorite(productId);

    if (isCurrentlyFavorite) {
      _wishlistedProductIds.remove(productId);
    } else {
      _wishlistedProductIds.add(productId);
    }
    notifyListeners();
    await _saveWishlistToFirestore(); // Save after modification
  }

  Future<void> clearWishlist() async {
    _wishlistedProductIds.clear();
    notifyListeners();
    await _saveWishlistToFirestore();
  }

  // IMPORTANT: To display actual wishlisted products, you'll need a method like this:
  Future<List<Product>> getFullWishlistItems() async {
    List<Product> wishlistProducts = [];
    // Similar to _getProductById in CartService, you need a robust way to fetch products
    for (String productId in _wishlistedProductIds) {
      try {
        DocumentSnapshot productDoc = await _firestore.collection('products').doc(productId).get();
        if (productDoc.exists) {
          wishlistProducts.add(Product.fromFirestore(productDoc.data() as Map<String,dynamic>, productDoc.id));
        }
      } catch (e) {
        print("Error fetching product $productId for wishlist display: $e");
      }
    }
    return wishlistProducts;
  }
}
