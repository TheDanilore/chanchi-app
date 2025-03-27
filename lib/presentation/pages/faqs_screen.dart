import 'package:chanchi_app/config/theme.dart';
import 'package:flutter/material.dart';

class FAQsScreen extends StatelessWidget {
  const FAQsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de Chanchi App')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFAQSection(theme),
            const SizedBox(height: 16),
            Text(
              'Chanchi App es una aplicación diseñada para ayudarte a gestionar tus ingresos y gastos.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text('Desarrollado por:', style: theme.textTheme.titleLarge),
            Text('TheDanilore', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            Text('Sitio web:', style: theme.textTheme.titleLarge),
            GestureDetector(
              onTap: () {}, // Aquí podrías abrir el enlace con url_launcher
              child: Text(
                'www.chanchiapp.com',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection(ThemeData theme) {
    final List<Map<String, String>> faqs = [
      {
        "question": "¿Cómo cambio mi nombre de usuario?",
        "answer": "Puedes cambiar tu nombre de usuario editando tu perfil.",
      },
      {
        "question": "¿Cómo cambio mi contraseña?",
        "answer":
            "Puedes cambiar tu contraseña en la sección de edición de perfil.",
      },
      {
        "question": "¿Cómo elimino mi cuenta?",
        "answer": "Puedes eliminar tu cuenta desde la sección de perfil.",
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          faqs.map((faq) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    faq["question"]!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkBackgroundColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    faq["answer"]!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkSurfaceColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}
