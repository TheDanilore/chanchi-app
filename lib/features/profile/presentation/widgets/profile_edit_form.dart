// lib/features/profile/presentation/widgets/profile_edit_form.dart
import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/core/utils/error_handler.dart';
import 'package:chanchi_app/core/widgets/custom_text_field.dart';
import 'package:chanchi_app/features/profile/domain/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileEditForm extends StatelessWidget {
  const ProfileEditForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProfileProvider>(context);
    
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Editar Perfil',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Campo de nombre
          CustomTextField(
            controller: provider.nameController,
            label: 'Nombre',
            hint: 'Ingresa tu nombre',
            icon: Icons.person,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu nombre';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Campo de biografía
          CustomTextField(
            controller: provider.bioController,
            label: 'Descripción',
            hint: 'Cuenta algo sobre ti',
            icon: Icons.description,
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          
          // Sección de cambio de contraseña
          _buildPasswordSection(context, provider),
          
          const SizedBox(height: 32),
          
          // Botones de acción
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: provider.isLoading 
                    ? null 
                    : () => provider.setEditing(false),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: provider.isLoading 
                    ? null 
                    : () => _saveProfile(context, provider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Guardar Cambios'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Sección de cambio de contraseña
  Widget _buildPasswordSection(BuildContext context, ProfileProvider provider) {
    // Solo mostrar para usuarios con correo/contraseña
    final user = provider.user;
    final isPasswordUser = user.providerData.any((provider) => provider.providerId == 'password');
    
    if (!isPasswordUser) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        
        Text(
          'Cambiar Contraseña',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Contraseña actual
        PasswordField(
          controller: provider.oldPasswordController,
          label: 'Contraseña Actual',
        ),
        const SizedBox(height: 16),
        
        // Nueva contraseña
        PasswordField(
          controller: provider.newPasswordController,
          label: 'Nueva Contraseña',
        ),
        const SizedBox(height: 16),
        
        // Confirmar contraseña
        PasswordField(
          controller: provider.confirmPasswordController,
          label: 'Confirmar Nueva Contraseña',
          validator: (value) {
            if (value != provider.newPasswordController.text) {
              return 'Las contraseñas no coinciden';
            }
            return null;
          },
        ),
      ],
    );
  }
  
  // Guardar perfil
  void _saveProfile(BuildContext context, ProfileProvider provider) {
    // Validar contraseñas si se están cambiando
    if (provider.newPasswordController.text.isNotEmpty) {
      if (provider.newPasswordController.text != provider.confirmPasswordController.text) {
        ErrorHandler.showErrorSnackBar(context, 'Las contraseñas no coinciden');
        return;
      }
      
      if (provider.oldPasswordController.text.isEmpty) {
        ErrorHandler.showErrorSnackBar(context, 'Debes ingresar tu contraseña actual');
        return;
      }
    }
    
    // Guardar cambios
    ErrorHandler.handleFutureWithLoading(
      () => provider.saveProfile(),
      context,
      loadingMessage: 'Guardando cambios...',
      successMessage: 'Perfil actualizado correctamente',
    );
  }
}

// Campo de contraseña con visibilidad
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  const PasswordField({
    Key? key,
    required this.controller,
    required this.label,
    this.validator,
  }) : super(key: key);

  @override
  _PasswordFieldState createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      ),
      validator: widget.validator,
    );
  }
}