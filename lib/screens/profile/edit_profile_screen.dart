import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jongerenpunt_app/constants/app_theme.dart';
import 'package:jongerenpunt_app/services/auth_service.dart';
import 'package:jongerenpunt_app/services/storage_service.dart';
import 'package:jongerenpunt_app/widgets/custom_widgets.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  File? _imageFile;
  String? _profileImageUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;
  
  // User interests/preferences
  final List<String> _availableInterests = [
    'Financiën', 'Gezondheid', 'Studie & Stage', 
    'Vrije Tijd', 'Wonen', 'Juridisch', 
    'Ondernemen', 'Veiligheid', 'Discriminatie'
  ];
  
  List<String> _selectedInterests = [];
  
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }
  
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid;
      
      if (userId == null) {
        throw Exception('Geen gebruiker ingelogd');
      }
      
      // Get user profile data
      final userData = await authService.getUserProfile();
      
      if (!mounted) return;
      
      setState(() {
        _nameController.text = userData['username'] ?? '';
        _bioController.text = userData['bio'] ?? '';
        _profileImageUrl = userData['profileImage'];
        _selectedInterests = List<String>.from(userData['interests'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user profile: $e');
      }
      
      if (mounted) {
        setState(() {
          _errorMessage = 'Fout bij het laden van je profiel: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _showImageSourceActionSheet() async {
    // Show a modal bottom sheet with camera and gallery options
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_camera, color: AppColors.primaryStart),
                title: const Text('Foto maken'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.primaryStart),
                title: const Text('Kies uit galerij'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _errorMessage = null; // Clear any previous error
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking image: $e');
      }
      
      setState(() {
        _errorMessage = 'Er is een fout opgetreden bij het selecteren van een afbeelding';
      });
    }
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storageService = Provider.of<StorageService>(context, listen: false);
      final userId = authService.currentUser?.uid;
      
      if (userId == null) {
        throw Exception('Geen gebruiker ingelogd');
      }
      
      // Upload profile image if a new one was selected
      String? imageUrl = _profileImageUrl;
      if (_imageFile != null) {
        imageUrl = await storageService.uploadProfileImage(userId, _imageFile!);
      }
      
      // Save profile data
      await authService.updateUserProfile({
        'username': _nameController.text,
        'bio': _bioController.text,
        'profileImage': imageUrl,
        'interests': _selectedInterests,
      });
      
      if (!mounted) return;
      
      setState(() {
        _isSaving = false;
        _successMessage = 'Profiel succesvol bijgewerkt';
        _profileImageUrl = imageUrl;
        _imageFile = null;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error saving profile: $e');
      }
      
      if (mounted) {
        setState(() {
          _errorMessage = 'Fout bij het opslaan van je profiel: ${e.toString()}';
          _isSaving = false;
        });
      }
    }
  }
  
  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiel bewerken', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryStart,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center, // Center all content
                  children: [
                    // Profile image - centered
                    Center(
                      child: Stack(
                        children: [
                          // Profile image
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!) as ImageProvider
                                : _profileImageUrl != null
                                    ? NetworkImage(_profileImageUrl!) as ImageProvider
                                    : null,
                            child: _imageFile == null && _profileImageUrl == null
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                          
                          // Edit image button (camera icon)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primaryStart,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, color: Colors.white),
                                iconSize: 20,
                                onPressed: _showImageSourceActionSheet,
                                constraints: const BoxConstraints(
                                  minHeight: 40,
                                  minWidth: 40,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Error message
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(Icons.error_outline, color: Colors.red, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _errorMessage = null;
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    
                    // Success message
                    if (_successMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _successMessage!,
                                style: const TextStyle(color: Colors.green),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16, color: Colors.green),
                              onPressed: () {
                                setState(() {
                                  _successMessage = null;
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    
                    // Name field
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Naam',
                          hintText: 'Jouw naam',
                          prefixIcon: Icon(Icons.person),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Voer een naam in';
                          }
                          return null;
                        },
                      ),
                    ),
                    
                    // Bio field
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _bioController,
                        decoration: const InputDecoration(
                          labelText: 'Bio',
                          hintText: 'Vertel iets over jezelf',
                          prefixIcon: Icon(Icons.description),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        maxLines: 3,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Interests section
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Interesses',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.start,
                      children: _availableInterests.map((interest) {
                        final isSelected = _selectedInterests.contains(interest);
                        return FilterChip(
                          label: Text(interest),
                          selected: isSelected,
                          onSelected: (_) => _toggleInterest(interest),
                          backgroundColor: Colors.grey[200],
                          selectedColor: AppColors.primaryStart.withOpacity(0.2),
                          checkmarkColor: AppColors.primaryStart,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primaryStart : Colors.black,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryStart,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.primaryStart.withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Opslaan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}