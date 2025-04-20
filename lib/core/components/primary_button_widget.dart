// Ejemplo de un botón personalizado reutilizable
import 'package:chanchi_app/core/config/theme.dart';
import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;
  
  const PrimaryButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
      ),
      child: isLoading
        ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon),
                SizedBox(width: 8),
              ],
              Text(text),
            ],
          ),
    );
  }
}