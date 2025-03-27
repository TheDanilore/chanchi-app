import 'dart:io';

import 'package:chanchi_app/config/theme.dart';
import 'package:chanchi_app/presentation/pages/about_screen.dart';
import 'package:chanchi_app/presentation/pages/faqs_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.cardColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.cardColor),
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(widget.user.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: CircularProgressIndicator(color: theme.primaryColor),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          String name = userData['name'] ?? 'Usuario';
          String email = userData['email'] ?? 'Sin correo';
          String avatarUrl = userData['avatarUrl'] ?? 'https://via.placeholder.com/150';
          String bio = userData['bio'] ?? 'Agrega una descripción sobre ti';

          _nameController.text = name;

          return _buildProfileUI(
            name,
            email,
            avatarUrl,
            bio,
            theme,
            isDarkMode,
          );
        },
      ),
    );
  }

  Widget _buildProfileUI(
    String name,
    String email,
    String avatarUrl,
    String bio,
    ThemeData theme,
    bool isDarkMode,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor,
            theme.colorScheme.secondary,
            AppTheme.accentColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: AppTheme.spacingL),
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
                    tag: 'profile-${widget.user.uid}',
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage(avatarUrl),
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(color: AppTheme.cardColor, width: 4),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickAndUploadImage,
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
              Text(
                name,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppTheme.cardColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.cardColor.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDarkMode ? AppTheme.darkCardColor : AppTheme.cardColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusXL),
                    topRight: Radius.circular(AppTheme.radiusXL),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Acerca de mí", style: theme.textTheme.titleLarge),
                      const SizedBox(height: AppTheme.spacingM),
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.black.withOpacity(0.2)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        child: Text(bio, style: theme.textTheme.bodyLarge),
                      ),
                      const SizedBox(height: AppTheme.spacingXL),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem("Publicaciones", "0", theme),
                          _buildStatItem("Seguidores", "0", theme),
                          _buildStatItem("Siguiendo", "0", theme),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingXL),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _editProfile,
                          icon: _isLoading
                              ? Container(
                                  width: 24,
                                  height: 24,
                                  padding: const EdgeInsets.all(2.0),
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Icon(Icons.edit),
                          label: Text(
                            _isLoading ? "Cargando..." : "Editar Perfil",
                          ),
                          style: AppTheme.buildElevatedButtonStyle(
                            AppTheme.primaryColor,
                            AppTheme.cardColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Compartir perfil próximamente"),
                              ),
                            );
                          },
                          icon: const Icon(Icons.share),
                          label: const Text("Compartir Perfil"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.primaryColor,
                            side: BorderSide(color: theme.primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                      Text("Logros", style: theme.textTheme.titleLarge),
                      const SizedBox(height: AppTheme.spacingM),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildAchievementBadge(
                              "Novato",
                              Icons.star,
                              AppTheme.successColor,
                              theme,
                            ),
                            _buildAchievementBadge(
                              "Popular",
                              Icons.favorite,
                              AppTheme.warningColor,
                              theme,
                              isLocked: true,
                            ),
                            _buildAchievementBadge(
                              "Experto",
                              Icons.workspace_premium,
                              AppTheme.errorColor,
                              theme,
                              isLocked: true,
                            ),
                            _buildAchievementBadge(
                              "Contribuidor",
                              Icons.history_edu,
                              AppTheme.accentColor,
                              theme,
                              isLocked: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                      _buildOptionItem(context, 'Preguntas Frecuentes', Icons.question_mark_rounded, () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FAQsScreen(),
                          ),
                        );
                      }),
                      const Divider(),
                      _buildOptionItem(context, 'Acerca de', Icons.info, () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AboutScreen(),
                          ),
                        );
                      }),
                      const SizedBox(height: AppTheme.spacingL),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _deleteAccount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.errorColor,
                            foregroundColor: AppTheme.cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            ),
                          ),
                          child: Text(
                            "Eliminar Cuenta",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.cardColor,
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
        ),
      ),
    );
  }

  Widget _buildOptionItem(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).textTheme.bodySmall!.color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        Text(label, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildAchievementBadge(
    String label,
    IconData icon,
    Color color,
    ThemeData theme, {
    bool isLocked = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: AppTheme.spacingM),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isLocked
                  ? Colors.grey.withOpacity(0.2)
                  : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              border: Border.all(
                color: isLocked ? Colors.grey : color,
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 30, color: isLocked ? Colors.grey : color),
                if (isLocked)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock,
                        size: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isLocked ? Colors.grey : theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _pickAndUploadImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (pickedFile == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      File imageFile = File(pickedFile.path);

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_avatars')
          .child('${widget.user.uid}_${path.basename(imageFile.path)}');

      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('users').doc(widget.user.uid).update({
        'avatarUrl': downloadUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Imagen de perfil actualizada correctamente"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al actualizar la imagen: ${e.toString()}"),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _editProfile() {
    setState(() {
      _isLoading = true;
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Editar Perfil"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nombre"),
              ),
              const SizedBox(height: AppTheme.spacingM),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Nueva Contraseña"),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isLoading = false;
                });
              },
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                String newName = _nameController.text;
                String newPassword = _passwordController.text;

                if (newName.isNotEmpty) {
                  await _firestore.collection('users').doc(widget.user.uid).update({
                    'name': newName,
                  });
                }

                if (newPassword.isNotEmpty) {
                  await widget.user.updatePassword(newPassword);
                }

                Navigator.of(context).pop();
                setState(() {
                  _isLoading = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Perfil actualizado correctamente"),
                  ),
                );
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  void _deleteAccount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.user.delete();
      await _firestore.collection('users').doc(widget.user.uid).delete();

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al eliminar la cuenta: ${e.toString()}"),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
