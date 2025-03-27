import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de Chanchi App')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  // Image.asset('assets/avatar.png', height: 100),
                  const SizedBox(height: 16),
                  Text(
                    'Chanchi App',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    'Versión 1.0.0',
                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chanchi App es una aplicación diseñada para ayudarte a gestionar tus ingresos y gastos.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Desarrollado por:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'TheDanilore',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Sitio web:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'www.chanchiapp.com',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
