import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:night_market/screens/settings_screen.dart';
import '../../models/address.dart';
import 'EditProfileScreen.dart'; // Import your Address model

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  static const routeName = '/user-profile';

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // This future will be re-fetched when setState is called
  Future<DocumentSnapshot<Map<String, dynamic>>?> _getUserProfileData() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot<Map<String, dynamic>> userDoc =
        await _firestore.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          return userDoc;
        } else {
          print('User document does not exist in Firestore for UID: ${currentUser.uid}');
          return null;
        }
      } catch (e) {
        print('Error fetching user profile data: $e');
        // Optionally show a snackbar or error message to the user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not load profile: ${e.toString()}')),
          );
        }
        return null;
      }
    }
    return null;
  }

  // Helper to extract a display name if only email is available (less likely now)
  String _extractDisplayNameFromEmail(String email) {
    if (email.contains('@')) {
      return email.split('@')[0];
    }
    return 'User';
  }

  @override
  Widget build(BuildContext context) {
    final User? firebaseUser = _auth.currentUser; // Get the Firebase Auth user
    final theme = Theme.of(context);

    if (firebaseUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(
          child: Text('Not logged in. Please log in to view your profile.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
        future: _getUserProfileData(), // FutureBuilder will re-call this when its key changes or parent rebuilds
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // Error already handled in _getUserProfileData by showing a SnackBar
            return Center(child: Text('Error loading profile. Please try again.', style: TextStyle(color: theme.colorScheme.error)));
          }
          if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
            // Data from Firestore 'users' collection not found
            // Fallback to Firebase Auth data
            return _buildProfileContent(
              context: context,
              theme: theme,
              displayName: firebaseUser.displayName ?? _extractDisplayNameFromEmail(firebaseUser.email ?? ''),
              email: firebaseUser.email ?? 'No email address',
              photoUrl: firebaseUser.photoURL,
              phoneNumber: null, // No phone from Auth directly
              shippingAddress: null, // No address from Auth
              uid: firebaseUser.uid,
              firestoreDataAvailable: false,
            );
          }

          // Data from Firestore 'users' collection is available
          Map<String, dynamic> userData = snapshot.data!.data()!;
          Address? shippingAddress;
          if (userData['shippingAddress'] != null && userData['shippingAddress'] is Map) {
            shippingAddress = Address.fromMap(userData['shippingAddress']);
          }

          return _buildProfileContent(
            context: context,
            theme: theme,
            displayName: userData['displayName'] ?? firebaseUser.displayName ?? 'N/A',
            email: userData['email'] ?? firebaseUser.email ?? 'N/A',
            photoUrl: userData['photoUrl']?.isNotEmpty == true ? userData['photoUrl'] : firebaseUser.photoURL,
            phoneNumber: userData['phoneNumber'],
            shippingAddress: shippingAddress,
            uid: firebaseUser.uid,
            firestoreDataAvailable: true,
          );
        },
      ),
    );
  }

  Widget _buildProfileContent({
    required BuildContext context,
    required ThemeData theme,
    required String displayName,
    required String email,
    String? photoUrl,
    String? phoneNumber,
    Address? shippingAddress,
    required String uid,
    bool firestoreDataAvailable = true,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: theme.colorScheme.secondaryContainer,
              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                  ? NetworkImage(photoUrl)
                  : null,
              child: (photoUrl == null || photoUrl.isEmpty)
                  ? Icon(
                Icons.person_outline,
                size: 60,
                color: theme.colorScheme.onSecondaryContainer,
              )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              displayName,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Center(
            child: Text(
              email,
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
          if (phoneNumber != null && phoneNumber.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  phoneNumber,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          const SizedBox(height: 24),

          if (!firestoreDataAvailable)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                "Complete your profile information for a better experience.",
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),

          const Divider(),

          // Display Shipping Address if available
          if (shippingAddress != null && shippingAddress.isValid)
            _buildProfileSection(
                context,
                title: 'Shipping Address',
                icon: Icons.local_shipping_outlined,
                contentWidget: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shippingAddress.street, style: theme.textTheme.bodyLarge),
                    Text('${shippingAddress.city}, ${shippingAddress.state} ${shippingAddress.postalCode}', style: theme.textTheme.bodyLarge),
                    Text(shippingAddress.country, style: theme.textTheme.bodyLarge),
                  ],
                )
            )
          else if (firestoreDataAvailable) // Show this only if we tried to load from Firestore
            _buildProfileSection(
              context,
              title: 'Shipping Address',
              icon: Icons.local_shipping_outlined,
              contentWidget: Text('No shipping address set.', style: theme.textTheme.bodyMedium),
            ),


          _buildProfileOption(
            context,
            icon: Icons.shopping_bag_outlined,
            title: 'My Orders',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('My Orders page - TODO')),
              );
              // TODO: Navigate to Order History Screen
            },
          ),
          _buildProfileOption(
            context,
            icon: Icons.edit_note_outlined, // Changed icon
            title: 'Edit Profile & Address',
            onTap: () async {
              final result = await Navigator.pushNamed(context, EditProfileScreen.routeName);
              if (result == true && mounted) {
                // Trigger a re-fetch of data by rebuilding the FutureBuilder
                setState(() {});
              }
            },
          ),
          _buildProfileOption(
            context,
            icon: Icons.settings_outlined,
            title: 'App Settings',
            onTap: () {
              Navigator.pushNamed(context, SettingsScreen.routeName);
            },
          ),
          const Divider(),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout_outlined),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.errorContainer,
              foregroundColor: theme.colorScheme.onErrorContainer,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'UID: $uid',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          )
        ],
      ),
    );
  }

  // Helper for profile list options
  Widget _buildProfileOption(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title, style: theme.textTheme.titleMedium),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
    );
  }

  // Helper for profile sections (like shipping address)
  Widget _buildProfileSection(BuildContext context, {required String title, required IconData icon, required Widget contentWidget}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 28.0), // Indent content
            child: contentWidget,
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }
}

