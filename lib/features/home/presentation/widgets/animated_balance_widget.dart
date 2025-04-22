import 'package:flutter/material.dart';
import 'package:chanchi_app/core/config/theme.dart';
import 'package:intl/intl.dart';

class AnimatedBalanceWidget extends StatelessWidget {
  final double balance;
  final TextStyle? style;
  final String currencySymbol;
  final bool isHidden;
  final Color? positiveColor;
  final Color? negativeColor;

  const AnimatedBalanceWidget({
    Key? key, 
    required this.balance, 
    this.style,
    this.currencySymbol = 'S/',
    this.isHidden = false,
    this.positiveColor,
    this.negativeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Defensive checks to prevent crashes
    final safeBalance = _ensureSafeBalance(balance);

    // Determinar el color basado en el balance
    Color balanceColor = safeBalance >= 0
        ? (positiveColor ?? AppTheme.successColor)
        : (negativeColor ?? AppTheme.errorColor);

    // Estilo por defecto si no se proporciona
    TextStyle defaultStyle = TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: balanceColor,
      letterSpacing: 0.5,
      shadows: [
        BoxShadow(
          color: balanceColor.withOpacity(0.2),
          blurRadius: 4,
          offset: const Offset(0, 2),
        )
      ],
    );

    return Text(
      isHidden 
        ? '$currencySymbol •••.••' 
        : '$currencySymbol ${_formatCurrency(safeBalance)}',
      style: style ?? defaultStyle,
      overflow: TextOverflow.ellipsis,
    );
  }
  
  // Método más robusto para manejar valores del balance
  double _ensureSafeBalance(double value) {
    // Manejar valores nulos, NaN o infinitos de manera más segura
    if (value.isNaN) return 0.0;
    if (value.isInfinite) return 0.0;

    // Limitar a un rango razonable
    const maxSafeValue = 1e12; // 1 billón
    const minSafeValue = -1e12; // -1 billón

    // Truncar valores fuera del rango
    if (value > maxSafeValue) return maxSafeValue;
    if (value < minSafeValue) return minSafeValue;

    // Redondear a 2 decimales para evitar problemas de precisión
    return double.parse(value.toStringAsFixed(2));
  }
  
  String _formatCurrency(double value) {
    try {
      // Manejar valores muy grandes
      if (value.abs() > 1e12) {
        return value.toStringAsExponential(2);
      }

      // Formatear con separador de miles
      final formatter = NumberFormat.currency(
        symbol: '',  // No necesitamos símbolo aquí
        decimalDigits: 2,
        locale: 'es_PE',  // Configuración específica para Perú
      );
      
      return formatter.format(value).trim();
    } catch (e) {
      // Fallback seguro
      return '0.00';
    }
  }
}