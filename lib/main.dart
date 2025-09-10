// In main.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:night_market/screens/checkout_screen.dart';
import 'package:provider/provider.dart';
// ... other imports ...
import 'firebase_options.dart';
import 'screens/EditProfileScreen.dart';
import 'screens/add_product_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/user_profile_screen.dart';
import 'services/cart_service.dart';
import 'services/theme_service.dart'; // Import ThemeService
import 'screens/settings_screen.dart';
import 'services/wishlist_service.dart'; // We'll create this

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // It's good practice to initialize ThemeService once and then provide it.
    // However, if ThemeService itself loads preferences, it's fine this way.
    return ChangeNotifierProvider(
      create: (_) => ThemeService(), // Create ThemeService here
      child: Consumer<ThemeService>( // Consume it to rebuild MyApp when theme changes
        builder: (context, themeService, child) {
          return MultiProvider(
            providers: [
              // Keep other providers if ThemeService is the outermost for theme changes
              // Or, if ThemeService is simple enough, can be part of this MultiProvider
              ChangeNotifierProvider.value(value: themeService), // Provide the same instance
              ChangeNotifierProvider(create: (context) => CartService()),
              ChangeNotifierProvider(create: (context) => WishlistService()),
            ],
            child: MaterialApp(
              title: 'Night Market',
              theme: themeService.lightTheme, // Use light theme from service
              darkTheme: themeService.darkTheme, // Use dark theme from service
              themeMode: themeService.themeMode, // Use theme mode from service
              home: const AuthWrapper(),
              routes: {
                CheckoutScreen.routeName: (context) => const CheckoutScreen(), // Add this
                EditProfileScreen.routeName: (context) => const EditProfileScreen(), // Add this
                '/login': (context) => const LoginScreen(),
                '/signup': (context) => const SignUpScreen(),
                '/home': (context) => const HomeScreen(),
                '/cart': (context) => const CartScreen(),
                ProductDetailScreen.routeName: (context) => const ProductDetailScreen(),
                UserProfileScreen.routeName: (context) => const UserProfileScreen(),
                AddProductScreen.routeName: (context) => const AddProductScreen(),
                // Ensure this line is present and correct:
                SettingsScreen.routeName: (context) => const SettingsScreen(),
              },
              debugShowCheckedModeBanner: false,
            ),
          );
        },
      ),
    );
  }
}

// AuthWrapper and other parts remain the same

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
