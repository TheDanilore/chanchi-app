import 'package:chanchi_app/presentation/pages/home/home_screen.dart';
import 'package:chanchi_app/presentation/pages/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthCheck extends StatelessWidget {
  const AuthCheck({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Mostrar indicador de carga mientras se verifica
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Si hay un usuario autenticado, ir a la pantalla principal
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }
        
        // Si no hay usuario autenticado, ir a la pantalla de login
        return const LoginScreen();
      },
    );
  }
}