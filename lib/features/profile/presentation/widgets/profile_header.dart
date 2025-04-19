// profile_header.dart
import 'dart:io';
import 'package:chanchi_app/features/profile/domain/services/profile_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chanchi_app/core/config/theme.dart';

class ProfileHeader extends StatelessWidget {
  final User user;
  final String name;
  final String email;
  final String avatarUrl;
  final Function(bool) setLoading;
  final VoidCallback refreshProfile;

  final ProfileService _profileService = ProfileService();

  ProfileHeader({
    Key? key,
    required this.user,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.setLoading,
    required this.refreshProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: AppTheme.spacingL),
        
        // Avatar con botón de cambio
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 3,
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            Hero(
              tag: 'profile-${user.uid}',
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: _getProfileImage(user),
                  border: Border.all(color: AppTheme.cardColor, width: 4),
                  color: _shouldShowPlaceholder() ? theme.primaryColor.withOpacity(0.2) : null,
                ),
                child: _shouldShowPlaceholder() 
                  ? Icon(
                      Icons.person,
                      size: 60,
                      color: theme.primaryColor,
                    )
                  : null,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _pickAndUploadImage(context),
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingS),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.cardColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: AppTheme.cardColor,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppTheme.spacingL),
        
        // Nombre de usuario
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            name,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppTheme.cardColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingS),
        
        // Correo electrónico
        Text(
          email,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.cardColor.withOpacity(0.8),
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingXL),
      ],
    );
  }

  // Lógica para mostrar la imagen de perfil
  DecorationImage? _getProfileImage(User user) {
    // Comprobar primero la URL guardada en Firestore
    if (avatarUrl.isNotEmpty) {
      return DecorationImage(
        image: NetworkImage(avatarUrl),
        fit: BoxFit.cover,
      );
    }
    
    // Si no hay avatar en Firestore, intentar con photoURL de Auth
    if (user.photoURL != null && user.photoURL!.isNotEmpty) {
      return DecorationImage(
        image: NetworkImage(user.photoURL!),
        fit: BoxFit.cover,
      );
    }
    
    // Si no hay imagen, devolver null para mostrar placeholder
    return null;
  }

  bool _shouldShowPlaceholder() {
    return avatarUrl.isEmpty && (user.photoURL == null || user.photoURL!.isEmpty);
  }

  Future<void> _pickAndUploadImage(BuildContext context) async {
    setLoading(true);

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (pickedFile == null) {
        setLoading(false);
        return;
      }

      File imageFile = File(pickedFile.path);
      await _profileService.uploadProfileImage(user.uid, imageFile);
      
      refreshProfile(); // Actualizar UI

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Imagen de perfil actualizada correctamente"),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al actualizar la imagen: ${e.toString()}"),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setLoading(false);
    }
  }
}