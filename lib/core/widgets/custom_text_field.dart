// lib/core/widgets/custom_text_field.dart
import 'package:chanchi_app/core/config/theme.dart';
import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int? maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? helperText;
  final Widget? suffixIcon;
  final String? prefixText;
  final bool obscureText;
  final bool autofocus;
  final Function(String)? onChanged;
  final bool enabled;
  final int? maxLength;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.helperText,
    this.suffixIcon,
    this.prefixText,
    this.obscureText = false,
    this.autofocus = false,
    this.onChanged,
    this.enabled = true,
    this.maxLength,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        prefixIcon: icon != null ? Icon(icon) : null,
        prefixText: prefixText,
        suffixIcon: suffixIcon,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppTheme.primaryColor),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppTheme.errorColor),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        filled: true,
        fillColor:
            enabled
                ? Theme.of(context).inputDecorationTheme.fillColor
                : Colors.grey[200],
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines! > 1 ? 16 : 12,
        ),
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      obscureText: obscureText,
      autofocus: autofocus,
      onChanged: onChanged,
      enabled: enabled,
      maxLength: maxLength,
      style: TextStyle(
        color:
            enabled ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor,
      ),
    );
  }
}

// Actualizar las clases derivadas para que utilicen el nuevo parámetro hint
class CurrencyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final String? helperText;
  final String currencySymbol;
  final bool readOnly;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final Widget? suffixIcon;
  final bool enabled;

  const CurrencyTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.helperText,
    this.currencySymbol = '£',
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.suffixIcon,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: label,
      hint: hint,
      validator: validator,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      helperText: helperText,
      prefixText: currencySymbol,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      suffixIcon: suffixIcon,
      enabled: enabled,
    );
  }
}

class DescriptionTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final int maxLines;
  final int? maxLength;
  final bool enabled;

  const DescriptionTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.maxLines = 3,
    this.maxLength,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: label,
      hint: hint,
      validator: validator,
      maxLines: maxLines,
      maxLength: maxLength,
      icon: Icons.description,
      enabled: enabled,
    );
  }
}

class DateTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final Function(DateTime)? onDateSelected;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DateTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.onDateSelected,
    this.initialDate,
    this.firstDate,
    this.lastDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: label,
      hint: hint,
      validator: validator,
      readOnly: true,
      icon: Icons.calendar_today,
      onTap: () => _selectDate(context),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = this.initialDate ?? now;
    final DateTime firstDate = this.firstDate ?? DateTime(now.year - 5);
    final DateTime lastDate = this.lastDate ?? DateTime(now.year + 5);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text = _formatDate(picked);
      if (onDateSelected != null) {
        onDateSelected!(picked);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}