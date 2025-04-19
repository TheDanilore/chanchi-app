import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chanchi_app/core/config/theme.dart';

class ReauthDialog extends StatefulWidget {
  final User user;
  final Function(String) onReauthComplete;
  final VoidCallback onCancel;

  const ReauthDialog({
    Key? key,
    required this.user,
    required this.onReauthComplete,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<ReauthDialog> createState() => _ReauthDialogState();
}

class _ReauthDialogState extends State<ReauthDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Confirmar identidad"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Para continuar, necesitamos verificar tu identidad. Por favor, ingresa tu contraseña.",
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: "Contraseña",
              border: const OutlineInputBorder(),
              errorText: _errorMessage,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            obscureText: _obscurePassword,
            onChanged: (_) => setState(() => _errorMessage = null),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : widget.onCancel,
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _authenticate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text("Confirmar"),
        ),
      ],
    );
  }

  Future<void> _authenticate() async {
    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = "Por favor ingresa tu contraseña";
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Reautenticar usuario
      AuthCredential credential = EmailAuthProvider.credential(
        email: widget.user.email!,
        password: _passwordController.text,
      );
      
      await widget.user.reauthenticateWithCredential(credential);
      
      if (mounted) {
        widget.onReauthComplete(_passwordController.text);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = "Contraseña incorrecta";
        });
      }
    }
  }
}