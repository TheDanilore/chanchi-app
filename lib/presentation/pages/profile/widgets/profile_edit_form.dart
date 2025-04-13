import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chanchi_app/config/theme.dart';

class ProfileEditForm extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController bioController;
  final TextEditingController oldPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool isLoading;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final User user;

  const ProfileEditForm({
    Key? key,
    required this.nameController,
    required this.bioController,
    required this.oldPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.isLoading,
    required this.onSave,
    required this.onCancel,
    required this.user,
  }) : super(key: key);

  @override
  State<ProfileEditForm> createState() => _ProfileEditFormState();
}

class _ProfileEditFormState extends State<ProfileEditForm> {
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _showPasswordFields = false;

  @override
  void initState() {
    super.initState();
    // Determinar si mostrar campos de contraseña basado en el proveedor de inicio de sesión
    _showPasswordFields = widget.user.providerData.any(
      (provider) => provider.providerId == 'password'
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Editar Perfil", 
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.isLoading ? null : widget.onCancel,
            ),
          ],
        ),
        
        const SizedBox(height: AppTheme.spacingM),
        
        // Formulario de edición
        TextFormField(
          controller: widget.nameController,
          decoration: InputDecoration(
            labelText: "Nombre",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            prefixIcon: const Icon(Icons.person),
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingM),
        
        TextFormField(
          controller: widget.bioController,
          decoration: InputDecoration(
            labelText: "Acerca de mí",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            prefixIcon: const Icon(Icons.description),
          ),
          maxLines: 3,
        ),
        
        if (_showPasswordFields) ...[
          const SizedBox(height: AppTheme.spacingL),
          
          // Sección de cambio de contraseña
          Text(
            "Cambiar Contraseña (opcional)", 
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          TextFormField(
            controller: widget.oldPasswordController,
            decoration: InputDecoration(
              labelText: "Contraseña actual",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureOldPassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscureOldPassword = !_obscureOldPassword;
                  });
                },
              ),
            ),
            obscureText: _obscureOldPassword,
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          TextFormField(
            controller: widget.newPasswordController,
            decoration: InputDecoration(
              labelText: "Nueva contraseña",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              prefixIcon: const Icon(Icons.lock_reset),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscureNewPassword = !_obscureNewPassword;
                  });
                },
              ),
            ),
            obscureText: _obscureNewPassword,
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          TextFormField(
            controller: widget.confirmPasswordController,
            decoration: InputDecoration(
              labelText: "Confirmar nueva contraseña",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
            obscureText: _obscureConfirmPassword,
          ),
        ],
        
        const SizedBox(height: AppTheme.spacingXL),
        
        // Botones de acción
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.isLoading ? null : widget.onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.primaryColor,
                  side: BorderSide(color: theme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                ),
                child: const Text("Cancelar"),
              ),
            ),
            
            const SizedBox(width: AppTheme.spacingM),
            
            Expanded(
              child: ElevatedButton(
                onPressed: widget.isLoading ? null : widget.onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                ),
                child: widget.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text("Guardar Cambios"),
              ),
            ),
          ],
        ),
      ],
    );
  }
}