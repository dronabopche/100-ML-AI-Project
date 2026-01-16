import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final User? currentUser;

  const ProfilePage({super.key, required this.onToggleTheme, this.currentUser});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isUploading = false;
  Map<String, dynamic> _userStats = {
    'courses_completed': 0,
    'books_generated': 0,
    'queries_made': 0,
    'reading_hours': 0,
    'current_streak': 0,
  };
  String? _bannerImageUrl;
  String? _profileImageUrl;
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    _initializeUserProfile();
  }

  // Initialize user profile from Firestore
  Future<void> _initializeUserProfile() async {
    try {
      final user = widget.currentUser;
      if (user == null) return;

      _displayName = user.displayName ?? user.email?.split('@').first ?? 'User';
      _profileImageUrl = user.photoURL;

      // Check if user profile exists in Firestore
      final docRef = _firestore.collection('user_profiles').doc(user.uid);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        // Create new profile for social login users
        await _createOrUpdateUserProfile(user);
      } else {
        // Load existing profile
        _loadProfileData(docSnapshot.data()!);
      }
    } catch (e) {
      print('Error initializing profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Create or update user profile in Firestore
  Future<void> _createOrUpdateUserProfile(User user) async {
    try {
      final profileData = {
        'user_id': user.uid,
        'email': user.email,
        'display_name':
            user.displayName ?? user.email?.split('@').first ?? 'User',
        'profile_image_url': user.photoURL,
        'banner_url': _bannerImageUrl,
        'courses_completed': 0,
        'books_generated': 0,
        'queries_made': 0,
        'reading_hours': 0,
        'current_streak': 0,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'last_active': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('user_profiles')
          .doc(user.uid)
          .set(profileData, SetOptions(merge: true));

      // Load the created/updated profile
      final docSnapshot = await _firestore
          .collection('user_profiles')
          .doc(user.uid)
          .get();

      if (docSnapshot.exists) {
        _loadProfileData(docSnapshot.data()!);
      }
    } catch (e) {
      print('Error creating/updating profile: $e');
      // Fallback to basic user data
      setState(() {
        _displayName =
            user.displayName ?? user.email?.split('@').first ?? 'User';
        _profileImageUrl = user.photoURL;
      });
    }
  }

  void _loadProfileData(Map<String, dynamic> data) {
    setState(() {
      _userStats = {
        'courses_completed': data['courses_completed'] ?? 0,
        'books_generated': data['books_generated'] ?? 0,
        'queries_made': data['queries_made'] ?? 0,
        'reading_hours': data['reading_hours'] ?? 0,
        'current_streak': data['current_streak'] ?? 0,
      };
      _bannerImageUrl = data['banner_url'];
      _profileImageUrl =
          data['profile_image_url'] ?? widget.currentUser?.photoURL;
      _displayName =
          data['display_name'] ?? widget.currentUser?.displayName ?? 'User';
    });
  }

  // Upload image to Firebase Storage
  Future<String?> _uploadImageToFirebase(File image, String folder) async {
    try {
      final user = widget.currentUser;
      if (user == null) return null;

      final fileName =
          '${user.uid}_${folder}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('$folder/$fileName');

      // Upload file
      final uploadTask = await storageRef.putFile(image);

      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _pickAndUploadBanner() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final file = File(image.path);
      final downloadUrl = await _uploadImageToFirebase(file, 'user_banners');

      if (downloadUrl != null) {
        // Update Firestore
        await _firestore
            .collection('user_profiles')
            .doc(widget.currentUser!.uid)
            .update({
              'banner_url': downloadUrl,
              'updated_at': FieldValue.serverTimestamp(),
            });

        setState(() {
          _bannerImageUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Banner updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading banner: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _pickAndUploadProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final file = File(image.path);
      final downloadUrl = await _uploadImageToFirebase(file, 'profile_images');

      if (downloadUrl != null) {
        // Update Firestore
        await _firestore
            .collection('user_profiles')
            .doc(widget.currentUser!.uid)
            .update({
              'profile_image_url': downloadUrl,
              'updated_at': FieldValue.serverTimestamp(),
            });

        // Update Firebase Auth profile
        await widget.currentUser!.updatePhotoURL(downloadUrl);

        setState(() {
          _profileImageUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile picture updated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading profile image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // Update user stats in Firestore
  Future<void> _updateUserStats(String field, int incrementBy) async {
    try {
      await _firestore
          .collection('user_profiles')
          .doc(widget.currentUser!.uid)
          .update({
            field: FieldValue.increment(incrementBy),
            'updated_at': FieldValue.serverTimestamp(),
          });

      setState(() {
        _userStats[field] = (_userStats[field] ?? 0) + incrementBy;
      });
    } catch (e) {
      print('Error updating stats: $e');
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = widget.currentUser;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading your profile...'),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Banner Image with Edit Button
                  Stack(
                    children: [
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: _bannerImageUrl == null
                              ? LinearGradient(
                                  colors: [
                                    Colors.orange.shade700,
                                    Colors.orange.shade400,
                                  ],
                                )
                              : null,
                        ),
                        child: _bannerImageUrl != null
                            ? Image.network(
                                _bannerImageUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                              )
                            : null,
                      ),
                      if (!_isUploading)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              onPressed: _pickAndUploadBanner,
                              icon: const Icon(Icons.edit, color: Colors.white),
                            ),
                          ),
                        ),
                      // Profile Image Positioned Over Banner
                      Positioned(
                        bottom: -40,
                        left: 20,
                        child: GestureDetector(
                          onTap: _pickAndUploadProfileImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.grey.shade900
                                        : Colors.white,
                                    width: 4,
                                  ),
                                  gradient: _profileImageUrl == null
                                      ? LinearGradient(
                                          colors: [
                                            Colors.blue.shade700,
                                            Colors.blue.shade400,
                                          ],
                                        )
                                      : null,
                                ),
                                child: _profileImageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(50),
                                        child: Image.network(
                                          _profileImageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Center(
                                                  child: Text(
                                                    _displayName.isNotEmpty
                                                        ? _displayName[0]
                                                              .toUpperCase()
                                                        : 'U',
                                                    style: const TextStyle(
                                                      fontSize: 36,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                );
                                              },
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          _displayName.isNotEmpty
                                              ? _displayName[0].toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                              ),
                              if (_isUploading)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),

                  // User Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _displayName,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.email,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      user?.email ?? 'No email',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                // Social login indicator
                                if (user?.providerData.isNotEmpty == true)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getProviderIcon(
                                            user
                                                ?.providerData
                                                .first
                                                ?.providerId,
                                          ),
                                          size: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _getProviderName(
                                            user
                                                ?.providerData
                                                .first
                                                ?.providerId,
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            OutlinedButton.icon(
                              onPressed: _isUploading
                                  ? null
                                  : () {
                                      _showEditProfileDialog();
                                    },
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // User Bio
                        Text(
                          'Book enthusiast • ${_userStats['books_generated']} books created',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Stats Grid
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey.shade900
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStatItem(
                                    value: _userStats['books_generated']
                                        .toString(),
                                    label: 'Books Created',
                                    icon: Icons.auto_stories,
                                  ),
                                  _buildStatItem(
                                    value: _userStats['queries_made']
                                        .toString(),
                                    label: 'AI Queries',
                                    icon: Icons.question_answer,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStatItem(
                                    value: '${_userStats['reading_hours']}h',
                                    label: 'Reading Time',
                                    icon: Icons.timer,
                                  ),
                                  _buildStatItem(
                                    value: _userStats['current_streak']
                                        .toString(),
                                    label: 'Day Streak',
                                    icon: Icons.local_fire_department,
                                    color: Colors.orange.shade700,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Firebase Storage Usage Info
                        if (_bannerImageUrl != null || _profileImageUrl != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.cloud_upload,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Images stored securely',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Your profile and banner images are stored in Firebase Cloud Storage',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 32),

                        // Menu Items
                        Column(
                          children: [
                            _buildMenuItem(
                              icon: Icons.history,
                              title: 'Generation History',
                              subtitle: 'View all created books',
                              onTap: () {},
                            ),
                            _buildMenuItem(
                              icon: Icons.download,
                              title: 'Downloaded Books',
                              subtitle:
                                  '${_userStats['books_generated']} items',
                              onTap: () {},
                            ),
                            _buildMenuItem(
                              icon: Icons.leaderboard,
                              title: 'Achievements',
                              subtitle:
                                  '${(_userStats['books_generated'] / 5).floor()} unlocked',
                              onTap: () {},
                            ),
                            _buildMenuItem(
                              icon: Icons.settings,
                              title: 'Settings',
                              subtitle: 'App preferences',
                              onTap: () {},
                            ),
                            _buildMenuItem(
                              icon: Icons.help,
                              title: 'Help & Support',
                              subtitle: 'FAQs and contact',
                              onTap: () {},
                            ),
                            const SizedBox(height: 8),
                            _buildMenuItem(
                              icon: Icons.logout,
                              title: 'Sign Out',
                              subtitle: 'Secure logout',
                              onTap: _signOut,
                              isSignOut: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // Helper methods for provider info
  IconData _getProviderIcon(String? providerId) {
    switch (providerId) {
      case 'google.com':
        return Icons.g_mobiledata;
      case 'apple.com':
        return Icons.apple;
      case 'facebook.com':
        return Icons.facebook;
      default:
        return Icons.email;
    }
  }

  String _getProviderName(String? providerId) {
    switch (providerId) {
      case 'google.com':
        return 'Google';
      case 'apple.com':
        return 'Apple';
      case 'facebook.com':
        return 'Facebook';
      default:
        return 'Email';
    }
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
    Color? color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color ?? Colors.orange.shade700, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isSignOut = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? Colors.grey.shade900 : Colors.white,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSignOut
                ? Colors.red.shade50
                : isDark
                ? Colors.grey.shade800
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isSignOut ? Colors.red : Colors.orange.shade700,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSignOut
                ? Colors.red
                : (isDark ? Colors.white : Colors.black),
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _displayName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: _isUploading ? null : _pickAndUploadProfileImage,
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Photo'),
                ),
                TextButton.icon(
                  onPressed: _isUploading ? null : _pickAndUploadBanner,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Banner'),
                ),
              ],
            ),
            if (_isUploading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(),
                    ),
                    SizedBox(width: 8),
                    Text('Uploading...'),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isUploading
                ? null
                : () async {
                    if (nameController.text.isNotEmpty) {
                      final user = widget.currentUser;
                      if (user != null) {
                        // Update Firebase Auth
                        await user.updateDisplayName(nameController.text);

                        // Update Firestore
                        await _firestore
                            .collection('user_profiles')
                            .doc(user.uid)
                            .update({
                              'display_name': nameController.text,
                              'updated_at': FieldValue.serverTimestamp(),
                            });

                        setState(() {
                          _displayName = nameController.text;
                        });
                      }
                    }
                    Navigator.pop(context);
                  },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
