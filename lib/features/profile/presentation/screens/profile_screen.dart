// lib/features/profile/presentation/screens/profile_screen.dart
import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/core/utils/error_handler.dart';
import 'package:chanchi_app/features/profile/domain/providers/profile_provider.dart';
import 'package:chanchi_app/features/profile/presentation/widgets/profile_content.dart';
import 'package:chanchi_app/features/profile/presentation/widgets/profile_edit_form.dart';
import 'package:chanchi_app/features/profile/presentation/widgets/profile_header.dart';
import 'package:chanchi_app/core/widgets/migration_dialog.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  final User user;

  const ProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileProvider(user),
      child: ProfileScreenContent(user: user),
    );
  }
}

class ProfileScreenContent extends StatelessWidget {
  final User user;

  const ProfileScreenContent({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final provider = Provider.of<ProfileProvider>(context);
    
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
            onPressed: () => _showMigrationDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.cardColor),
            onPressed: () => _logout(context, provider),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: provider.isLoading && !provider.isEditing
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : Container(
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
                        user: user,
                        name: provider.name,
                        email: provider.email,
                        avatarUrl: provider.avatarUrl,
                        setLoading: provider.setLoading,
                        refreshProfile: provider.refreshProfile,
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
                          child: provider.isEditing 
                            ? ProfileEditForm()
                            : ProfileContent(
                                bio: provider.bio,
                                totalTransactions: provider.totalTransactions,
                                incomeCount: provider.incomeCount,
                                expenseCount: provider.expenseCount,
                                isLoading: provider.isLoading,
                                onEdit: provider.setEditing,
                                onDeleteAccount: () => _confirmDeleteAccount(context, provider),
                                onShowMigrationDialog: () => _showMigrationDialog(context),
                                user: user,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
  
  // Mostrar diálogo de migración
  void _showMigrationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MigrationDialog(
        userId: user.uid,
        onComplete: () {
          final provider = Provider.of<ProfileProvider>(context, listen: false);
          provider.refreshProfile();
        },
      ),
    );
  }
  
  // Confirmar eliminación de cuenta
  void _confirmDeleteAccount(BuildContext context, ProfileProvider provider) {
    ErrorHandler.showConfirmationDialog(
      context,
      title: "Eliminar Cuenta",
      message: "¿Estás seguro de que deseas eliminar tu cuenta? Esta acción no se puede deshacer y perderás todos tus datos.",
      confirmText: "Eliminar",
      cancelText: "Cancelar",
      confirmColor: AppTheme.errorColor,
    ).then((confirmed) {
      if (confirmed) {
        _deleteAccount(context, provider);
      }
    });
  }
  
  // Eliminar cuenta
  Future<void> _deleteAccount(BuildContext context, ProfileProvider provider) async {
    // Para usuarios de Google, no se necesita reautenticación con contraseña
    if (user.providerData.any((provider) => provider.providerId == 'password')) {
      // Solo mostrar diálogo de reautenticación para usuarios con contraseña
      final password = await _showReauthDialog(context);
      if (password == null) {
        return;
      }
      
      ErrorHandler.handleFutureWithLoading(
        () => provider.deleteAccount(password),
        context,
        loadingMessage: 'Eliminando cuenta...',
        successMessage: 'Cuenta eliminada correctamente',
        onSuccess: (_) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      );
    } else {
      // Para usuarios de Google, eliminar directamente
      ErrorHandler.handleFutureWithLoading(
        () => provider.deleteAccount(''),
        context,
        loadingMessage: 'Eliminando cuenta...',
        successMessage: 'Cuenta eliminada correctamente',
        onSuccess: (_) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      );
    }
  }
  
  // Mostrar diálogo de reautenticación
  Future<String?> _showReauthDialog(BuildContext context) async {
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
  
  // Cerrar sesión
  Future<void> _logout(BuildContext context, ProfileProvider provider) async {
    ErrorHandler.handleFutureWithLoading(
      () => provider.signOut(),
      context,
      loadingMessage: 'Cerrando sesión...',
      onSuccess: (_) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );
  }
}