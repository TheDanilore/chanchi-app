import 'package:flutter/material.dart';

class AppTheme {
  // Sistema de colores principales (con variantes)
  static const MaterialColor primarySwatch = MaterialColor(
    0xFF4A6FFF,
    <int, Color>{
      50: Color(0xFFE8EEFF),
      100: Color(0xFFC5D1FF),
      200: Color(0xFF9FB1FF),
      300: Color(0xFF7992FF),
      400: Color(0xFF5F7AFF),
      500: Color(0xFF4A6FFF), // Color primario base
      600: Color(0xFF4465F2),
      700: Color(0xFF3C58E0),
      800: Color(0xFF344CD0),
      900: Color(0xFF2635B0),
    },
  );

  static const Color primaryColor = Color(0xFF4A6FFF);
  static const Color secondaryColor = Color(0xFF6C63FF);
  static const Color accentColor = Color(0xFF00C6FF);

  // Paleta de colores extendida
  static const Color tertiaryColor = Color(
    0xFFFF7F50,
  ); // Color adicional para detalles

  // Colores de fondo
  static const Color lightBackgroundColor = Color(0xFFF8F9FE);
  static const Color darkBackgroundColor = Color(
    0xFF121212,
  ); // Más oscuro para mejor contraste
  static const Color cardColor = Colors.white;
  static const Color darkCardColor = Color(0xFF2C2C2C);
  static const Color surfaceColor = Color(0xFFF0F3FA);
  static const Color darkSurfaceColor = Color(0xFF252525);

  // Colores de texto
  static const Color textPrimaryColor = Color(0xFF2E384D);
  static const Color darkTextPrimaryColor = Colors.white;
  static const Color textSecondaryColor = Color(0xFF8798AD);
  static const Color darkTextSecondaryColor = Color(
    0xFFAAAAAA,
  ); // Mejorado para accesibilidad

  // Colores de estado
  static const Color successColor = Color(0xFF2ED573);
  static const Color warningColor = Color(0xFFFFBE21);
  static const Color errorColor = Color(0xFFFF4757);
  static const Color infoColor = Color(0xFF54A0FF);

  // Espaciado consistente
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Radios consistentes
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusXXL = 24.0;
  static const double radiusRound = 100.0;

  // Transiciones y animaciones
  static const Duration animationDurationShort = Duration(milliseconds: 150);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationLong = Duration(milliseconds: 500);

  // Profundidad - Elevaciones
  static const List<double> elevations = [0, 1, 2, 3, 4, 6, 8, 12, 16, 24];

  // Sombras personalizadas
  static List<BoxShadow> getShadow(int level) {
    final shadowLevel = level.clamp(0, 4);
    final List<List<BoxShadow>> shadows = [
      [], // 0 - Sin sombra
      [
        // 1 - Sombra sutil
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
      [
        // 2 - Sombra estándar
        BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
      [
        // 3 - Sombra media
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
      [
        // 4 - Sombra prominente
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ];

    return shadows[shadowLevel];
  }

  // Estados de botones mejorados
  static ButtonStyle buildElevatedButtonStyle(
    Color backgroundColor,
    Color textColor,
  ) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: textColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusL),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: spacingM,
        horizontal: spacingL,
      ),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      shadowColor: backgroundColor.withOpacity(0.4),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.pressed)) {
          return textColor.withOpacity(0.1);
        }
        if (states.contains(WidgetState.hovered)) {
          return textColor.withOpacity(0.05);
        }
        return Colors.transparent;
      }),
    );
  }

  // Tema claro
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primaryColor,
    primarySwatch: primarySwatch,
    scaffoldBackgroundColor: lightBackgroundColor,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: tertiaryColor,
      surface: surfaceColor,
      background: lightBackgroundColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimaryColor,
      onBackground: textPrimaryColor,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardTheme(
      color: cardColor,
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXL),
      ),
      margin: const EdgeInsets.symmetric(
        vertical: spacingS,
        horizontal: spacingS,
      ),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(
        horizontal: spacingM,
        vertical: spacingS,
      ),
      minLeadingWidth: 24,
      minVerticalPadding: spacingS,
    ),
    dividerTheme: const DividerThemeData(
      space: 1,
      thickness: 1,
      color: Color(0xFFEEEEEE),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: textSecondaryColor,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Colors.white,
      selectedIconTheme: IconThemeData(color: primaryColor, size: 24),
      unselectedIconTheme: IconThemeData(color: textSecondaryColor, size: 24),
      selectedLabelTextStyle: TextStyle(
        color: primaryColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: textSecondaryColor,
        fontSize: 14,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: textPrimaryColor,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        color: textPrimaryColor,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.3,
      ),
      displaySmall: TextStyle(
        color: textPrimaryColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: TextStyle(
        color: textPrimaryColor,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.2,
      ),
      headlineMedium: TextStyle(
        color: textPrimaryColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: TextStyle(
        color: textPrimaryColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        color: textPrimaryColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: textPrimaryColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: textPrimaryColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: textPrimaryColor, fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(
        color: textSecondaryColor,
        fontSize: 14,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        color: textSecondaryColor,
        fontSize: 12,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        color: textPrimaryColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: TextStyle(
        color: textSecondaryColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: TextStyle(
        color: textSecondaryColor,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    ),
    buttonTheme: ButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusL),
      ),
      buttonColor: primaryColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: buildElevatedButtonStyle(primaryColor, Colors.white),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: spacingM,
          horizontal: spacingL,
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.pressed)) {
            return primaryColor.withOpacity(0.1);
          }
          if (states.contains(WidgetState.hovered)) {
            return primaryColor.withOpacity(0.05);
          }
          return Colors.transparent;
        }),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        padding: const EdgeInsets.symmetric(
          vertical: spacingS,
          horizontal: spacingM,
        ),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.pressed)) {
            return primaryColor.withOpacity(0.1);
          }
          if (states.contains(WidgetState.hovered)) {
            return primaryColor.withOpacity(0.05);
          }
          return Colors.transparent;
        }),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingM,
        vertical: spacingM,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusL),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusL),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusL),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusL),
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusL),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      errorStyle: const TextStyle(color: errorColor, fontSize: 12),
      hintStyle: TextStyle(color: textSecondaryColor.withOpacity(0.7)),
      labelStyle: const TextStyle(color: textSecondaryColor),
      prefixIconColor: textSecondaryColor,
      suffixIconColor: textSecondaryColor,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return Colors.white;
      }),
      side: BorderSide(color: Colors.grey.shade400),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusS),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return Colors.grey.shade400;
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor.withOpacity(0.4);
        }
        return Colors.grey.shade300;
      }),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryColor,
      inactiveTrackColor: primaryColor.withOpacity(0.2),
      thumbColor: primaryColor,
      overlayColor: primaryColor.withOpacity(0.12),
      valueIndicatorColor: primaryColor,
      valueIndicatorTextStyle: const TextStyle(color: Colors.white),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceColor,
      disabledColor: Colors.grey.shade200,
      selectedColor: primaryColor.withOpacity(0.1),
      secondarySelectedColor: primaryColor,
      padding: const EdgeInsets.symmetric(
        horizontal: spacingS,
        vertical: spacingXS,
      ),
      labelStyle: const TextStyle(color: textPrimaryColor),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusRound),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryColor,
      circularTrackColor: Color(0xFFE5E9F2),
      linearTrackColor: Color(0xFFE5E9F2),
    ),
    tabBarTheme: const TabBarTheme(
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      labelColor: primaryColor,
      unselectedLabelColor: textSecondaryColor,
      labelStyle: TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(radiusM),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXL)),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXL),
      ),
      titleTextStyle: const TextStyle(
        color: textPrimaryColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: const TextStyle(color: textPrimaryColor, fontSize: 16),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.grey.shade900,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusM),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      extendedTextStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
    ),
  );

  // Tema oscuro
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primaryColor,
    primarySwatch: primarySwatch,
    scaffoldBackgroundColor: darkBackgroundColor,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: tertiaryColor,
      surface: darkSurfaceColor,
      background: darkBackgroundColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkTextPrimaryColor,
      onBackground: darkTextPrimaryColor,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1A1A),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardTheme(
      color: darkCardColor,
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXL),
      ),
      margin: const EdgeInsets.symmetric(
        vertical: spacingS,
        horizontal: spacingS,
      ),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(
        horizontal: spacingM,
        vertical: spacingS,
      ),
      minLeadingWidth: 24,
      minVerticalPadding: spacingS,
    ),
    dividerTheme: const DividerThemeData(
      space: 1,
      thickness: 1,
      color: Color(0xFF3A3A3A),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1A1A1A),
      selectedItemColor: primaryColor,
      unselectedItemColor: darkTextSecondaryColor,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Color(0xFF1A1A1A),
      selectedIconTheme: IconThemeData(color: primaryColor, size: 24),
      unselectedIconTheme: IconThemeData(
        color: darkTextSecondaryColor,
        size: 24,
      ),
      selectedLabelTextStyle: TextStyle(
        color: primaryColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: darkTextSecondaryColor,
        fontSize: 14,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: darkTextPrimaryColor,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        color: darkTextPrimaryColor,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.3,
      ),
      displaySmall: TextStyle(
        color: darkTextPrimaryColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: TextStyle(
        color: darkTextPrimaryColor,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.2,
      ),
      headlineMedium: TextStyle(
        color: darkTextPrimaryColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: TextStyle(
        color: darkTextPrimaryColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        color: darkTextPrimaryColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: darkTextPrimaryColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: darkTextPrimaryColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: darkTextPrimaryColor,
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: darkTextSecondaryColor,
        fontSize: 14,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        color: darkTextSecondaryColor,
        fontSize: 12,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        color: darkTextPrimaryColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: TextStyle(
        color: darkTextSecondaryColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: TextStyle(
        color: darkTextSecondaryColor,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    ),
    buttonTheme: ButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusL),
      ),
      buttonColor: primaryColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: buildElevatedButtonStyle(primaryColor, Colors.white),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: spacingM,
          horizontal: spacingL,
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.pressed)) {
            return primaryColor.withOpacity(0.2);
          }
          if (states.contains(WidgetState.hovered)) {
            return primaryColor.withOpacity(0.1);
          }
          return Colors.transparent;
        }),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        padding: const EdgeInsets.symmetric(
          vertical: spacingS,
          horizontal: spacingM,
        ),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.pressed)) {
            return primaryColor.withOpacity(0.2);
          }
          if (states.contains(WidgetState.hovered)) {
            return primaryColor.withOpacity(0.1);
          }
          return Colors.transparent;
        }),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCardColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingM,
        vertical: spacingM,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusL),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusL),
        borderSide: BorderSide(color: Colors.grey.shade800),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusL),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusL),
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusL),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      errorStyle: const TextStyle(color: errorColor, fontSize: 12),
      hintStyle: TextStyle(color: darkTextSecondaryColor.withOpacity(0.7)),
      labelStyle: const TextStyle(color: darkTextSecondaryColor),
      prefixIconColor: darkTextSecondaryColor,
      suffixIconColor: darkTextSecondaryColor,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return darkCardColor;
      }),
      side: const BorderSide(color: Color(0xFF6C6C6C)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusS),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return Colors.grey.shade600;
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return Colors.grey.shade400;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor.withOpacity(0.4);
        }
        return Colors.grey.shade700;
      }),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryColor,
      inactiveTrackColor: primaryColor.withOpacity(0.2),
      thumbColor: primaryColor,
      overlayColor: primaryColor.withOpacity(0.12),
      valueIndicatorColor: darkCardColor,
      valueIndicatorTextStyle: const TextStyle(color: Colors.white),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: darkSurfaceColor,
      disabledColor: Colors.grey.shade800,
      selectedColor: primaryColor.withOpacity(0.2),
      secondarySelectedColor: primaryColor,
      padding: const EdgeInsets.symmetric(
        horizontal: spacingS,
        vertical: spacingXS,
      ),
      labelStyle: const TextStyle(color: darkTextPrimaryColor),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusRound),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryColor,
      circularTrackColor: Color(0xFF3A3A3A),
      linearTrackColor: Color(0xFF3A3A3A),
    ),
    tabBarTheme: const TabBarTheme(
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      labelColor: primaryColor,
      unselectedLabelColor: darkTextSecondaryColor,
      labelStyle: TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(radiusM),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: darkCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXL)),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: darkCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXL),
      ),
      titleTextStyle: const TextStyle(
        color: darkTextPrimaryColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: const TextStyle(
        color: darkTextPrimaryColor,
        fontSize: 16,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.grey.shade900,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusM),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      extendedTextStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
    ),
  );

  // Función de utilidad para obtener el tema apropiado según el brillo
  static ThemeData getThemeByBrightness(Brightness brightness) {
    return brightness == Brightness.light ? lightTheme : darkTheme;
  }

  // Utilidades para crear variaciones de colores
  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return hslLight.toColor();
  }
}
