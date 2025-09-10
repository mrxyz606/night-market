// In lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

// Assuming LoginScreen is in the same directory or adjust path
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _auth = FirebaseAuth.instance; // Instance of FirebaseAuth

  String? _errorMessage;
  bool _isLoading = false;

  // ---- MOVED HELPER FUNCTION HERE ----
  // Helper function to create a default display name from email
  String _extractDisplayNameFromEmail(String email) {
    if (email.contains('@')) {
      String namePart = email.split('@')[0];
      // Capitalize first letter or apply other formatting as needed
      return namePart.isNotEmpty ? namePart[0].toUpperCase() + namePart.substring(1) : 'User';
    }
    return 'User'; // Fallback
  }
  // ---- END OF MOVED HELPER FUNCTION ----

  Future<void> _signUp() async {
    // Basic client-side validation first
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _confirmPasswordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = "All fields are required.";
      });
      return;
    }

    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      setState(() {
        _errorMessage = "Passwords do not match.";
      });
      return;
    }

    // Clear previous error and set loading state
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Attempting to create user with email: ${_emailController.text.trim()}');

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      print('User created in Auth successfully: ${userCredential.user?.uid}');

      // ---- START: Create user document in Firestore ----
      if (userCredential.user != null) {
        String userId = userCredential.user!.uid;
        String email = userCredential.user!.email ?? "";
        // Now this call is valid as the function is declared above
        String displayName = _extractDisplayNameFromEmail(email);

        CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');

        await usersCollection.doc(userId).set({
          'uid': userId,
          'email': email,
          'displayName': displayName,
          'photoUrl': '',
          'createdAt': FieldValue.serverTimestamp(),
          'userCart': [],
          'userWishlist': [],
        });
        print('User document created in Firestore for UID: $userId');
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
      // ---- END: Create user document in Firestore ----

    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during sign up: ${e.code} - ${e.message}');
      if (!mounted) return;
      setState(() {
        if (e.code == 'weak-password') {
          _errorMessage = 'The password provided is too weak.';
        } else if (e.code == 'email-already-in-use') {
          _errorMessage = 'An account already exists for that email.';
        } else if (e.code == 'invalid-email') {
          _errorMessage = 'The email address is not valid.';
        } else {
          _errorMessage = e.message ?? 'An error occurred during sign up.';
        }
      });
    } catch (e) {
      print('Generic error during sign up: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = "An unexpected error occurred. Please try again.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // The build method and dispose method remain the same
  // (Using the "Improved UI" version you already have)
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Join the Night Market community!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _isLoading ? null : _signUp(),
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: theme.colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    textStyle: theme.textTheme.titleMedium,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _signUp,
                  child: const Text('Sign Up'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account?", style: theme.textTheme.bodyMedium),
                    TextButton(
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      },
                      child: Text(
                        'Login',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
