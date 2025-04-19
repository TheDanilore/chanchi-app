import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/core/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';

/// Logo and header for authentication screens
class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final double iconSize;

  const AuthHeader({
    Key? key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.monetization_on_rounded,
    this.iconSize = 80,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: iconSize,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: AppTheme.spacingM),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.textPrimaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingS),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Email and password form fields for login/register
class EmailPasswordForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onForgotPassword;
  final bool showForgotPassword;
  final String? passwordLabel;
  final String? emailHint;
  final String? passwordHint;
  
  const EmailPasswordForm({
    Key? key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePasswordVisibility,
    this.onForgotPassword = _emptyCallback,
    this.showForgotPassword = true,
    this.passwordLabel = 'Contraseña',
    this.emailHint = 'ejemplo@correo.com',
    this.passwordHint = '••••••••',
  }) : super(key: key);

  static void _emptyCallback() {}

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            label: 'Correo electrónico',
            hint: emailHint!,
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          CustomTextField(
            label: passwordLabel!,
            hint: passwordHint!,
            controller: passwordController,
            obscureText: obscurePassword,
            validator: _validatePassword,
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: Theme.of(context).textTheme.bodySmall!.color,
              ),
              onPressed: onTogglePasswordVisibility,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          
          if (showForgotPassword)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onForgotPassword,
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Email validation
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, ingresa tu correo electrónico';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Ingresa un correo electrónico válido';
    }
    return null;
  }

  // Password validation
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, ingresa tu contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }
}

/// Error message display
class ErrorMessage extends StatelessWidget {
  final String message;
  final IconData icon;

  const ErrorMessage({
    Key? key,
    required this.message,
    this.icon = Icons.error_outline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Don't have an account? Register" prompt
class AuthNavigationLink extends StatelessWidget {
  final String leadText;
  final String linkText;
  final VoidCallback onTap;

  const AuthNavigationLink({
    Key? key,
    required this.leadText,
    required this.linkText,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          leadText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            linkText,
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Divider with text (e.g., "or")
class TextDivider extends StatelessWidget {
  final String text;

  const TextDivider({
    Key? key,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppTheme.textSecondaryColor.withOpacity(0.3),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
          child: Text(
            text,
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppTheme.textSecondaryColor.withOpacity(0.3),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

/// Authentication buttons container (login, register, google, etc.)
class AuthButtonsContainer extends StatelessWidget {
  final List<Widget> buttons;
  final double spacing;

  const AuthButtonsContainer({
    Key? key,
    required this.buttons,
    this.spacing = AppTheme.spacingM,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(buttons.length * 2 - 1, (index) {
        if (index.isEven) {
          return buttons[index ~/ 2];
        } else {
          return SizedBox(height: spacing);
        }
      }),
    );
  }
}