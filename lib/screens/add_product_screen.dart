import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  static const routeName = '/add-product'; // For navigation

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();

  bool _isLoading = false;

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return; // Invalid input
    }
    _formKey.currentState!.save(); // Triggers onSaved for FormFields if used

    setState(() {
      _isLoading = true;
    });

    try {
      // Get a reference to the 'products' collection
      CollectionReference products = FirebaseFirestore.instance.collection('products');

      // Add a new document with a generated ID
      await products.add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'imageUrl': _imageUrlController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(), // Optional: adds a server timestamp
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully!')),
      );
      Navigator.of(context).pop(); // Go back after saving
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add product: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a product name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  textInputAction: TextInputAction.next,
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price', prefixText: '\$ '),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a price.';
                    }
                    if (double.tryParse(value) == null || double.parse(value) <= 0) {
                      return 'Please enter a valid positive price.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    hintText: 'https://via.placeholder.com/150...',
                  ),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an image URL.';
                    }
                    // Basic URL validation (can be more sophisticated)
                    if (!value.startsWith('http://') && !value.startsWith('https://')) {
                      return 'Please enter a valid URL.';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _isLoading ? null : _saveProduct(),
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Add Product'),
                    onPressed: _saveProduct,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
