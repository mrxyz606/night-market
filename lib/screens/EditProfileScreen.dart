import 'dart:io'; // For File object
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'package:firebase_storage/firebase_storage.dart';

import '../models/address.dart'; // Import firebase_storage
// import 'package:permission_handler/permission_handler.dart'; // If you need explicit permission handling

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  static const routeName = '/edit-profile';

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance; // Storage instance

  late TextEditingController _displayNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneNumberController; // New controller
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postalCodeController;
  late TextEditingController _countryController;
  File? _pickedImageFile; // To store the selected image file
  String? _currentPhotoUrl; // To display current or newly uploaded photo

  bool _isLoading = false;
  String? _userId;


  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneNumberController = TextEditingController(); // Initialize
    _streetController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _postalCodeController = TextEditingController();
    _countryController = TextEditingController();
    _loadCurrentUserData();
  }

  Future<void> _loadCurrentUserData() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    _userId = currentUser.uid;

    setState(() { _isLoading = true; });
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
      await _firestore.collection('users').doc(_userId).get();

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data()!;
        _displayNameController.text = userData['displayName'] ?? '';
        _emailController.text = userData['email'] ?? currentUser.email ?? '';
        _phoneNumberController.text = userData['phoneNumber'] ?? ''; // Load phone
        _currentPhotoUrl = userData['photoUrl']; // Load current photo URL
        if (userData['shippingAddress'] != null && userData['shippingAddress'] is Map) {
          Address shippingAddress = Address.fromMap(userData['shippingAddress']);
          _streetController.text = shippingAddress.street;
          _cityController.text = shippingAddress.city;
          _stateController.text = shippingAddress.state;
          _postalCodeController.text = shippingAddress.postalCode;
          _countryController.text = shippingAddress.country;
        }
      } else {
        _emailController.text = currentUser.email ?? '';
        _currentPhotoUrl = currentUser.photoURL; // Fallback to auth photoURL
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load full profile. Some fields may be empty or from auth.')),
        );
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading profile: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    // --- Optional: Permission Handling (especially if using camera directly without system picker) ---
    // if (source == ImageSource.camera) {
    //   var cameraStatus = await Permission.camera.request();
    //   if (!cameraStatus.isGranted) {
    //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Camera permission denied.')));
    //     return;
    //   }
    // } else {
    //   // For gallery, on newer Android versions, explicit permission might not be needed if using system picker.
    //   // On iOS, Info.plist entries are key.
    //   // var photoStatus = await Permission.photos.request(); // Or Permission.storage for older Android
    //   // if (!photoStatus.isGranted) {
    //   //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo library permission denied.')));
    //   //   return;
    //   // }
    // }
    // --- End Optional Permission Handling ---


    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedImage = await picker.pickImage(
        source: source,
        imageQuality: 70, // Adjust quality to manage file size
        maxWidth: 800,     // Resize image
      );

      if (pickedImage == null) {
        return; // User cancelled picker
      }
      setState(() {
        _pickedImageFile = File(pickedImage.path);
        _currentPhotoUrl = null; // Clear existing URL preview if a new image is picked
      });
    } catch (e) {
      print("Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: ${e.toString()}')));
      }
    }
  }


  Future<String?> _uploadProfilePicture(String userId, File imageFile) async {
    if (_userId == null) return null;
    try {
      final ref = _storage.ref().child('user_profile_images').child('$userId.jpg');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading image: ${e.toString()}')));
      }
      return null;
    }
  }

  Future<void> _saveProfile() async {
    Address shippingAddress = Address(
      street: _streetController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      country: _countryController.text.trim(),
    );
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: User not identified.')));
      return;
    }

    setState(() { _isLoading = true; });

    String? newPhotoUrl = _currentPhotoUrl; // Start with existing or previously uploaded URL

    // Upload new image if one was picked
    if (_pickedImageFile != null) {
      newPhotoUrl = await _uploadProfilePicture(_userId!, _pickedImageFile!);
      if (newPhotoUrl == null && _pickedImageFile != null) { // Upload failed but an image was picked
        setState(() { _isLoading = false; });
        // Optionally, ask user if they want to save other changes without the new image
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image upload failed. Other changes not saved.')));
        return; // Stop if image upload failed and a new image was expected
      }
    }

    Map<String, dynamic> updatedData = {
      'displayName': _displayNameController.text.trim(),
      'phoneNumber': _phoneNumberController.text.trim(),
      'photoUrl': newPhotoUrl ?? '', // Use the new URL, or empty if null (or keep old if no change)
      'shippingAddress': shippingAddress.street.isNotEmpty ? shippingAddress.toMap() : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore.collection('users').doc(_userId!).set( // Use set with merge:true or update
        updatedData,
        SetOptions(merge: true), // Use merge to avoid overwriting fields not included here
      );

      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Update Firebase Auth profile (displayName and photoURL)
        await currentUser.updateDisplayName(_displayNameController.text.trim());
        if (newPhotoUrl != null && newPhotoUrl.isNotEmpty) { // Only update if newPhotoUrl is valid
          await currentUser.updatePhotoURL(newPhotoUrl);
        } else if (newPhotoUrl == '' && currentUser.photoURL != null) {
          // If user cleared photo and auth had one, clear it in auth too
          await currentUser.updatePhotoURL(null);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
        Navigator.of(context).pop(true); // Pop with true to indicate success
      }
    } catch (e) {
      print('Error saving profile: $e');
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving profile: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose(); // Dispose
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Photo Library'),
                  onTap: () {
                    _pickImage(ImageSource.gallery);
                    Navigator.of(context).pop();
                  }),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
              if (_currentPhotoUrl != null || _pickedImageFile != null) // Show remove option if there's an image
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    setState(() {
                      _pickedImageFile = null;
                      _currentPhotoUrl = ''; // Indicate photo should be removed
                    });
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save_outlined),
              tooltip: 'Save Changes',
              onPressed: _saveProfile,
            ),
        ],
      ),
      body: _isLoading && _userId == null // Adjust loading condition
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      backgroundImage: _pickedImageFile != null
                          ? FileImage(_pickedImageFile!)
                          : (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty)
                          ? NetworkImage(_currentPhotoUrl!)
                          : null // No image
                      as ImageProvider?,
                      child: (_pickedImageFile == null && (_currentPhotoUrl == null || _currentPhotoUrl!.isEmpty))
                          ? Icon(Icons.person_outline, size: 70, color: theme.colorScheme.onSecondaryContainer)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: () => _showImagePickerOptions(context),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: theme.colorScheme.primary,
                          child: Icon(Icons.camera_alt_outlined, color: theme.colorScheme.onPrimary, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
        TextFormField(
          controller: _displayNameController,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your display name.';
            }
            if (value.trim().length < 3) {
              return 'Display name must be at least 3 characters.';
            }
            return null;
          },
          textInputAction: TextInputAction.next,
        ),
              const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email (Cannot be changed here)',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
          readOnly: true, // Make email read-only
          style: TextStyle(color: theme.disabledColor),
        ),
              const SizedBox(height: 16),
              TextFormField( // New Phone Number Field
                controller: _phoneNumberController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number ',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.length < 10|| value.length > 14|| value.characters.contains("()0123456789+")) { // Basic validation
                    return 'Please enter a valid phone number.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),const SizedBox(height: 16),
              Text('Shipping Address', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(labelText: 'Street Address', border: OutlineInputBorder()),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter street address.' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter city.' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(labelText: 'State/Province', border: OutlineInputBorder()),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter state/province.' : null,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _postalCodeController,
                      decoration: const InputDecoration(labelText: 'Postal Code', border: OutlineInputBorder()),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter postal code.' : null,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(labelText: 'Country', border: OutlineInputBorder()),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter country.' : null,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_isLoading || _userId == null) ? null : (_) => _saveProfile(),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: CircularProgressIndicator()))
              else
    ElevatedButton.icon(
    icon: const Icon(Icons.save_alt_outlined),
    label: const Text('Save Changes'),
    style: ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 16),
    ),
    onPressed: _saveProfile,
    ),
            ],
          ),
        ),
      ),
    );
  }
}

