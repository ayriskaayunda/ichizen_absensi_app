import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ichizen/constants/app_colors.dart';
import 'package:ichizen/models/app_models.dart';
import 'package:ichizen/services/api_services.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final User currentUser;

  const EditProfileScreen({super.key, required this.currentUser});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ApiService _apiService = ApiService(); // Use ApiService
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;

  File? _pickedImage;
  String? _profilePhotoBase64;
  String? _initialProfilePhotoUrl;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUser.name);
    _initialProfilePhotoUrl = widget.currentUser.profile_photo;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
      List<int> imageBytes = await _pickedImage!.readAsBytes();
      _profilePhotoBase64 = base64Encode(imageBytes);
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      final String newName = _nameController.text.trim();

      bool profileDetailsChanged = false;
      bool profilePhotoChanged = false;

      final bool nameChanged = newName != widget.currentUser.name;

      if (nameChanged) {
        try {
          final ApiResponse<User> response = await _apiService.updateProfile(
            name: newName,
          );

          if (response.statusCode == 200 && response.data != null) {
            profileDetailsChanged = true;
          } else {
            String errorMessage = response.message;
            if (response.errors != null) {
              response.errors!.forEach((key, value) {
                errorMessage += '\n$key: ${(value as List).join(', ')}';
              });
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to update profile details: $errorMessage',
                  ),
                ),
              );
            }
            setState(() {
              _isLoading = false;
            });
            return;
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('An error occurred updating details: $e')),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (_pickedImage != null && _profilePhotoBase64 != null) {
        try {
          final ApiResponse<User> photoResponse = await _apiService
              .updateProfilePhoto(profilePhoto: _profilePhotoBase64!);

          if (photoResponse.statusCode == 200 && photoResponse.data != null) {
            profilePhotoChanged = true;
            if (photoResponse.data!.profile_photo != null) {
              _initialProfilePhotoUrl = photoResponse.data!.profile_photo;
            }
            _pickedImage = null;
            _profilePhotoBase64 = null;
          } else {
            String errorMessage = photoResponse.message;
            if (photoResponse.errors != null) {
              photoResponse.errors!.forEach((key, value) {
                errorMessage += '\n$key: ${(value as List).join(', ')}';
              });
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to update profile photo: $errorMessage',
                  ),
                ),
              );
            }
            setState(() {
              _isLoading = false;
            });
            return;
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('An error occurred updating photo: $e')),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (!mounted) return;

      if (profileDetailsChanged || profilePhotoChanged) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No changes to save.")));
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? currentImageProvider;
    if (_pickedImage != null) {
      currentImageProvider = FileImage(_pickedImage!);
    } else if (_initialProfilePhotoUrl != null &&
        _initialProfilePhotoUrl!.isNotEmpty) {
      final String fullImageUrl = _initialProfilePhotoUrl!.startsWith('http')
          ? _initialProfilePhotoUrl!
          : 'https://appabsensi.mobileprojp.com/public/${_initialProfilePhotoUrl!}';
      currentImageProvider = NetworkImage(fullImageUrl);
    }

    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFD8B4E2), Color(0xFFBFEFFF)],
              ),
            ),
          ),
        ),

        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            centerTitle: true,
            title: const Text(
              'Edit Profil',
              style: TextStyle(
                color: Color(0xFF624F82),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
          ),

          body: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      kToolbarHeight -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: AppColors.primary
                                      .withOpacity(0.2),
                                  backgroundImage: currentImageProvider,
                                  child: currentImageProvider == null
                                      ? const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: AppColors.textLight,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: _pickImage,
                                child: Text(
                                  _pickedImage != null ||
                                          (_initialProfilePhotoUrl != null &&
                                              _initialProfilePhotoUrl!
                                                  .isNotEmpty)
                                      ? 'Ganti Foto'
                                      : 'Unggah Foto',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Nama Lengkap',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 81, 67, 95),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            hintText: 'Masukkan nama lengkap Anda',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nama tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              )
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF624F82),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Simpan Perubahan',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
