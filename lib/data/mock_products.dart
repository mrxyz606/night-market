// lib/data/mock_products.dart
import '../models/product.dart';

final List<Product> mockProducts = [
  Product(
    id: 'p1',
    name: 'Comfy T-Shirt',
    description: 'A very comfortable cotton t-shirt, available in various colors.',
    price: 19.99,
    imageUrl: 'https://via.placeholder.com/150/FFC107/000000?Text=T-Shirt', // Placeholder
  ),
  Product(
    id: 'p2',
    name: 'Stylish Jeans',
    description: 'Modern slim-fit jeans for everyday wear.',
    price: 49.99,
    imageUrl: 'https://via.placeholder.com/150/03A9F4/FFFFFF?Text=Jeans', // Placeholder
  ),
  Product(
    id: 'p3',
    name: 'Running Shoes',
    description: 'Lightweight and durable running shoes for optimal performance.',
    price: 79.50,
    imageUrl: 'https://via.placeholder.com/150/4CAF50/FFFFFF?Text=Shoes', // Placeholder
  ),
  Product(
    id: 'p4',
    name: 'Wireless Headphones',
    description: 'High-quality sound with noise cancellation.',
    price: 129.99,
    imageUrl: 'https://via.placeholder.com/150/E91E63/FFFFFF?Text=Headphones', // Placeholder
  ),
  Product(
    id: 'p5',
    name: 'Smart Watch',
    description: 'Track your fitness and stay connected.',
    price: 199.00,
    imageUrl: 'https://via.placeholder.com/150/9C27B0/FFFFFF?Text=Watch', // Placeholder
  ),
];
