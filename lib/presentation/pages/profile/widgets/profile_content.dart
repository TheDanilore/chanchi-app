import 'package:chanchi_app/presentation/pages/profile/widgets/profile_stats.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chanchi_app/config/theme.dart';
import 'package:chanchi_app/presentation/pages/about_screen.dart';
import 'package:chanchi_app/presentation/pages/faqs_screen.dart';

class ProfileContent extends StatelessWidget {
  final String bio;
  final int totalTransactions;
  final int incomeCount;
  final int expenseCount;
  final bool isLoading;
  final VoidCallback onEdit;
  final VoidCallback onDeleteAccount;
  final VoidCallback onShowMigrationDialog;
  final User user;

  const ProfileContent({
    Key? key,
    required this.bio,
    required this.totalTransactions,
    required this.incomeCount,
    required this.expenseCount,
    required this.isLoading,
    required this.onEdit,
    required this.onDeleteAccount,
    required this.onShowMigrationDialog,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Acerca de mí", 
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingM),
        
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(
              color: theme.primaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            bio, 
            style: theme.textTheme.bodyLarge,
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingXL),
        
        // Estadísticas del usuario
        ProfileStats(
          totalTransactions: totalTransactions,
          incomeCount: incomeCount,
          expenseCount: expenseCount,
          theme: theme,
        ),
        
        const SizedBox(height: AppTheme.spacingXL),
        
        // Botón de editar perfil
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : onEdit,
            icon: isLoading
                ? Container(
                    width: 24,
                    height: 24,
                    padding: const EdgeInsets.all(2.0),
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : const Icon(Icons.edit),
            label: Text(
              isLoading ? "Cargando..." : "Editar Perfil",
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingM),
        
        const Divider(),
        
        // Opciones de menú
        _buildOptionItem(
          context, 
          'Preguntas Frecuentes', 
          Icons.question_mark_rounded, 
          () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const FAQsScreen(),
              ),
            );
          }
        ),
        
        const Divider(),
        
        _buildOptionItem(
          context, 
          'Acerca de', 
          Icons.info, 
          () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AboutScreen(),
              ),
            );
          }
        ),
        
        const Divider(),
        
        _buildOptionItem(
          context, 
          'Actualizar base de datos', 
          Icons.system_update_alt, 
          onShowMigrationDialog,
        ),
        
        const SizedBox(height: AppTheme.spacingL),
        
        // Botón de eliminar cuenta
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : onDeleteAccount,
            icon: const Icon(Icons.delete_forever),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: AppTheme.cardColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
            ),
            label: Text(
              "Eliminar Cuenta",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.cardColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionItem(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).textTheme.bodySmall!.color,
            ),
          ],
        ),
      ),
    );
  }
}