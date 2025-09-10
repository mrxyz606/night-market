class Product {
  final String id; // This will be the document ID from Firestore
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  // final Timestamp? createdAt; // Optional: if you want to store creation time

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    // this.createdAt,
  });

  // Factory constructor to create a Product from a Firestore DocumentSnapshot
  factory Product.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Product(
      id: documentId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      // createdAt: data['createdAt'] as Timestamp?, // Example for Timestamp
    );
  }

  // Method to convert a Product instance to a Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      // 'createdAt': createdAt ?? FieldValue.serverTimestamp(), // Example for Timestamp
    };
  }
}
    