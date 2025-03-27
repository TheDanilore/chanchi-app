import 'package:chanchi_app/config/theme.dart';
import 'package:chanchi_app/presentation/pages/auth_check.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    // Navegar a la siguiente pantalla después de 2 segundos
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthCheck()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo de la app
                    Icon(
                      Icons.monetization_on_rounded,
                      size: 120,
                      color: AppTheme.lightBackgroundColor,
                    ),
                    const SizedBox(height: 24),
                    // Nombre de la app
                    Text(
                      'Chanchi App',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppTheme.lightBackgroundColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Eslogan
                    Text(
                      'Gestiona tus Finanzas Personales',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.lightBackgroundColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Indicador de carga
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.lightBackgroundColor),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
