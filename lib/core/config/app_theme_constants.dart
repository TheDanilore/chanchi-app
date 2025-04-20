import 'package:chanchi_app/core/config/theme.dart';
import 'package:flutter/material.dart';

// Mejores constantes de tema para toda la aplicación
class AppThemeConstants {
  // Espaciado consistente
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 24.0;
  
  // Radios de bordes consistentes
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusCircular = 24.0;
  
  // Sombras consistentes
  static List<BoxShadow> lightShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];
  
  static List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];
  
  // Tamaños de texto optimizados
  static const double fontSizeSmall = 12.0;
  static const double fontSizeNormal = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeXL = 20.0;
  static const double fontSizeXXL = 24.0;
  
  // Grosor de borde consistente
  static const double borderWidth = 1.0;
  static const double borderWidthFocus = 1.5;
  
  // Opacidad consistente
  static const double opacityDisabled = 0.38;
  static const double opacityLight = 0.08;
  static const double opacityMedium = 0.20;
  static const double opacityHigh = 0.87;
}

// Estilos de tarjeta consistentes
class CardStyles {
  static BoxDecoration mainCardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(AppThemeConstants.radiusL),
    boxShadow: AppThemeConstants.lightShadow,
  );
  
  static BoxDecoration accountCardDecoration = BoxDecoration(
    color: Colors.grey.shade50,
    borderRadius: BorderRadius.circular(AppThemeConstants.radiusM),
    border: Border.all(
      color: Colors.grey.shade200,
      width: AppThemeConstants.borderWidth,
    ),
  );
  
  static BoxDecoration budgetCardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(AppThemeConstants.radiusL),
    boxShadow: AppThemeConstants.lightShadow,
    border: Border.all(
      color: Colors.grey.shade100,
      width: AppThemeConstants.borderWidth,
    ),
  );
  
  static BoxDecoration transactionItemDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(AppThemeConstants.radiusM),
    boxShadow: AppThemeConstants.lightShadow,
  );
}

// Estilos de botón consistentes
class ButtonStyles {
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(
      horizontal: AppThemeConstants.spacingL, 
      vertical: AppThemeConstants.spacingM
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppThemeConstants.radiusM),
    ),
  );
  
  static ButtonStyle secondaryButton = OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(
      horizontal: AppThemeConstants.spacingL, 
      vertical: AppThemeConstants.spacingM
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppThemeConstants.radiusM),
    ),
  );
  
  static ButtonStyle compactButton = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(
      horizontal: AppThemeConstants.spacingM, 
      vertical: AppThemeConstants.spacingS
    ),
    minimumSize: Size.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

// Estilos de campos de entrada consistentes
class InputStyles {
  static InputDecoration textFieldDecoration = InputDecoration(
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppThemeConstants.spacingM,
      vertical: AppThemeConstants.spacingM,
    ),
    isDense: true,
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppThemeConstants.radiusM),
      borderSide: BorderSide(
        color: Colors.grey.shade300,
        width: AppThemeConstants.borderWidth,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppThemeConstants.radiusM),
      borderSide: BorderSide(
        color: Colors.grey.shade300,
        width: AppThemeConstants.borderWidth,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppThemeConstants.radiusM),
      borderSide: BorderSide(
        color: AppTheme.primaryColor,
        width: AppThemeConstants.borderWidthFocus,
      ),
    ),
  );
}