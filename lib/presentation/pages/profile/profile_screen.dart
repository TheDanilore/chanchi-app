import 'package:chanchi_app/config/theme.dart';
import 'package:chanchi_app/presentation/pages/profile/services/profile_service.dart';
import 'package:chanchi_app/presentation/pages/profile/widgets/profile_content.dart';
import 'package:chanchi_app/presentation/pages/profile/widgets/profile_edit_form.dart';
import 'package:chanchi_app/presentation/pages/profile/widgets/profile_header.dart';
import 'package:chanchi_app/presentation/widgets/migration_dialog.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  bool _isEditing = false;
  
  // Controladores para los campos de texto
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Asegurar que el usuario esté inicializado en Firestore
    _profileService.initializeUser(widget.user);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  void _refreshProfile() {
    if (mounted) {
      setState(() {});
    }
  }

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
            icon: const Icon(Icons.update, color: AppTheme.cardColor),
            tooltip: 'Actualizar base de datos',
            onPressed: _showMigrationDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.cardColor),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _profileService.getUserData(widget.user.uid),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return Center(
              child: CircularProgressIndicator(color: theme.primaryColor),
            );
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          String name = userData['name'] ?? 'Usuario';
          String email = userData['email'] ?? widget.user.email ?? 'Sin correo';
          String avatarUrl = userData['avatarUrl'] ?? '';
          String bio = userData['bio'] ?? 'Agrega una descripción sobre ti';
          
          // Inicializar controladores con datos existentes
          if (!_isEditing) {
            _nameController.text = name;
            _bioController.text = bio;
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _getTransactionsStream(),
            builder: (context, transactionSnapshot) {
              // Calcular estadísticas
              int totalTransactions = 0;
              int incomeCount = 0;
              int expenseCount = 0;
              
              if (transactionSnapshot.hasData) {
                totalTransactions = transactionSnapshot.data!.docs.length;
                
                for (var doc in transactionSnapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['type'] == 'income') {
                    incomeCount++;
                  } else if (data['type'] == 'expense') {
                    expenseCount++;
                  }
                }
              }

              return _buildProfileScreen(
                name,
                email,
                avatarUrl,
                bio,
                totalTransactions,
                incomeCount,
                expenseCount,
                theme,
                isDarkMode,
              );
            },
          );
        },
      ),
    );
  }

  Stream<QuerySnapshot> _getTransactionsStream() {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: widget.user.uid)
        .where('isInTrash', isEqualTo: false)
        .snapshots();
  }

  Widget _buildProfileScreen(
    String name,
    String email,
    String avatarUrl,
    String bio,
    int totalTransactions,
    int incomeCount,
    int expenseCount,
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
              // Cabecera con foto, nombre y correo
              ProfileHeader(
                user: widget.user,
                name: name,
                email: email,
                avatarUrl: avatarUrl,
                setLoading: _setLoading,
                refreshProfile: _refreshProfile,
              ),
              
              // Contenido principal
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
                  child: _isEditing 
                    ? ProfileEditForm(
                        nameController: _nameController,
                        bioController: _bioController,
                        oldPasswordController: _oldPasswordController,
                        newPasswordController: _newPasswordController,
                        confirmPasswordController: _confirmPasswordController,
                        isLoading: _isLoading,
                        onSave: _saveProfile,
                        onCancel: () {
                          setState(() {
                            _isEditing = false;
                            _oldPasswordController.clear();
                            _newPasswordController.clear();
                            _confirmPasswordController.clear();
                          });
                        },
                        user: widget.user,
                      )
                    : ProfileContent(
                        bio: bio,
                        totalTransactions: totalTransactions,
                        incomeCount: incomeCount,
                        expenseCount: expenseCount,
                        isLoading: _isLoading,
                        onEdit: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                        onDeleteAccount: _confirmDeleteAccount,
                        onShowMigrationDialog: _showMigrationDialog,
                        user: widget.user,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMigrationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MigrationDialog(
        userId: widget.user.uid,
        onComplete: _refreshProfile,
      ),
    );
  }

  Future<void> _saveProfile() async {
    _setLoading(true);

    try {
      // Actualizar datos básicos
      await _profileService.updateUserProfile(widget.user.uid, {
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
      });

      // Cambiar contraseña si es necesario
      if (_newPasswordController.text.isNotEmpty) {
        if (_newPasswordController.text != _confirmPasswordController.text) {
          throw Exception("Las contraseñas no coinciden");
        }

        if (_oldPasswordController.text.isEmpty) {
          throw Exception("Debes ingresar tu contraseña actual");
        }

        await _profileService.changePassword(
          widget.user,
          _oldPasswordController.text,
          _newPasswordController.text,
        );
      }

      if (mounted) {
        setState(() {
          _isEditing = false;
          _oldPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Perfil actualizado correctamente"),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      _setLoading(false);
    }
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar Cuenta"),
        content: const Text(
          "¿Estás seguro de que deseas eliminar tu cuenta? Esta acción no se puede deshacer y perderás todos tus datos.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    _setLoading(true);

    try {
      // Para usuarios de Google, no se necesita reautenticación con contraseña
      if (widget.user.providerData.any((provider) => provider.providerId == 'password')) {
        // Solo mostrar diálogo de reautenticación para usuarios con contraseña
        final password = await _showReauthDialog();
        if (password == null) {
          _setLoading(false);
          return;
        }
        await _profileService.deleteAccount(widget.user, password);
      } else {
        // Para usuarios de Google, eliminar directamente
        await _profileService.deleteAccount(widget.user, '');
      }

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al eliminar la cuenta: ${e.toString()}"),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> _showReauthDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final passwordController = TextEditingController();
        bool obscurePassword = true;
        
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text("Confirmar identidad"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Para eliminar tu cuenta, necesitamos verificar tu identidad. Por favor, ingresa tu contraseña.",
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: "Contraseña",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: obscurePassword,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(passwordController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Confirmar"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _logout() async {
    try {
      await _profileService.signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al cerrar sesión: ${e.toString()}"),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}