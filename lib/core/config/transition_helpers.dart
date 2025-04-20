import 'package:flutter/material.dart';

class TransitionHelpers {
  // Duración consistente para animaciones
  static const Duration shortDuration = Duration(milliseconds: 150);
  static const Duration mediumDuration = Duration(milliseconds: 250);
  static const Duration longDuration = Duration(milliseconds: 350);
  
  // Curvas de animación consistentes
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve emphasizedCurve = Curves.easeOutBack;
  static const Curve snappyCurve = Curves.fastOutSlowIn;
  
  // Transición de página suave
  static PageRouteBuilder<T> smoothPageRoute<T>({
    required Widget page,
    Duration duration = mediumDuration,
    Curve curve = defaultCurve,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var tween = Tween(begin: const Offset(0.0, 0.05), end: Offset.zero)
            .chain(CurveTween(curve: curve));
        
        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: duration,
    );
  }
  
  // Transición para diálogos
  static PageRouteBuilder<T> dialogRoute<T>({
    required Widget dialog,
    Duration duration = shortDuration,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => dialog,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeInBack,
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: duration,
    );
  }
  
  // Transición para elementos que entran y salen de la vista
  static Widget fadeSlideInOut({
    required Widget child,
    required bool isVisible,
    Duration duration = shortDuration,
    Offset beginOffset = const Offset(0.0, 0.1),
  }) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: beginOffset,
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: isVisible ? child : const SizedBox.shrink(),
    );
  }
  
  // CrossFade con mejores transiciones
  static Widget improvedCrossFade({
    required Widget firstChild,
    required Widget secondChild,
    required bool showFirst,
    Duration duration = mediumDuration,
  }) {
    return AnimatedCrossFade(
      firstChild: firstChild,
      secondChild: secondChild,
      crossFadeState: showFirst ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      duration: duration,
      firstCurve: Curves.easeOutCubic,
      secondCurve: Curves.easeInCubic,
      sizeCurve: Curves.easeInOutCubic,
    );
  }
  
  // Animaciones para valores numéricos (saldos, montos)
  static Widget countAnimation({
    required double value,
    required TextStyle style,
    String prefix = '',
    String suffix = '',
    int decimalPlaces = 2,
    Duration duration = mediumDuration,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Text(
          '$prefix${value.toStringAsFixed(decimalPlaces)}$suffix',
          style: style,
        );
      },
    );
  }
}