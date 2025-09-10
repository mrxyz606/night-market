import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_screen.dart'; // Ensure this path is correct

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance; // Instance of FirebaseAuth
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = "Email and password cannot be empty.";
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Attempting to login with email: ${_emailController.text.trim()}'); // DEBUG

      // THE CORE FIREBASE CALL
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      print('User logged in successfully: ${userCredential.user?.uid}'); // DEBUG
      // AuthWrapper will handle navigation

    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during login: ${e.code} - ${e.message}'); // DEBUG
      if (!mounted) return;
      setState(() {
        if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _errorMessage = 'Invalid email or password.';
        } else if (e.code == 'invalid-email') {
          _errorMessage = 'The email address is not valid.';
        } else {
          _errorMessage = e.message ?? "An error occurred during login.";
        }
      });
    } catch (e) {
      print('Generic error during login: $e'); // DEBUG
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
  // ... (rest of your build method for LoginScreen, ensure Login button calls _login) ...
  // The LoginScreen build method provided in the "Improved UI" step should be fine.
  // Just ensure the login button's onPressed calls the `_login` method above.
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
                  Icons.storefront,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Welcome Back!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Login to continue to your Night Market',
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
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _isLoading ? null : _login(),
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
                  onPressed: _login, // Ensure this calls _login
                  child: const Text('Login'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?", style: theme.textTheme.bodyMedium),
                    TextButton(
                      onPressed: () {
                        Navigator.push( // Or Navigator.pushReplacement
                          context,
                          MaterialPageRoute(builder: (context) => const SignUpScreen()),
                        );
                      },
                      child: Text(
                        'Sign Up',
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
    super.dispose();
  }
}
