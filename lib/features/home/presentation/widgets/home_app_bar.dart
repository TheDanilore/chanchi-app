// lib/features/home/presentation/widgets/home_app_bar.dart
import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:chanchi_app/features/pages/trash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController tabController;
  final int selectedIndex;
  final bool isOffline;
  final bool isSyncing;
  final int pendingOperationsCount;
  final VoidCallback onSyncPressed;

  const HomeAppBar({
    Key? key,
    required this.tabController,
    required this.selectedIndex,
    required this.isOffline,
    required this.isSyncing,
    required this.pendingOperationsCount,
    required this.onSyncPressed,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(selectedIndex == 0 ? 102 : 56);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    String appBarTitle;
    switch (selectedIndex) {
      case 0:
        appBarTitle = 'Chanchi App';
        break;
      case 1:
        appBarTitle = 'Agregar Transacción';
        break;
      case 2:
        appBarTitle = 'Mis Cuentas';
        break;
      default:
        appBarTitle = 'Chanchi App';
    }

    return AppBar(
      elevation: 0,
      title: Text(
        appBarTitle,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: AppTheme.lightBackgroundColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: AppTheme.primaryColor,
      actions: [
        // Indicador de modo sin conexión
        if (isOffline)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Tooltip(
                  message: 'Modo sin conexión',
                  child: Icon(
                    Icons.cloud_off,
                    color: Colors.white.withOpacity(0.8),
                    size: 20,
                  ),
                ),
                if (pendingOperationsCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        pendingOperationsCount > 9
                            ? '9+'
                            : pendingOperationsCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
        // Botón de sincronización
        if (isOffline)
          IconButton(
            icon: isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.sync),
            tooltip: 'Intentar sincronizar',
            onPressed: isSyncing ? null : onSyncPressed,
          ),
          
        // Botón de papelera
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () {
            if (user != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TrashScreen(userId: user.uid),
                ),
              );
            }
          },
          tooltip: 'Papelera de transacciones',
        ),
        
        // Avatar de perfil
        IconButton(
          icon: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withOpacity(0.3),
            backgroundImage: user?.photoURL != null
                ? NetworkImage(user!.photoURL!)
                : null,
            child: user?.photoURL == null
                ? const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  )
                : null,
          ),
          onPressed: () {
            if (user != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(user: user),
                ),
              );
            }
          },
        ),
        
        const SizedBox(width: 8),
      ],
      bottom: selectedIndex == 0
          ? PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: AppTheme.primaryColor,
                child: TabBar(
                  controller: tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.7),
                  tabs: const [
                    Tab(text: "General"),
                    Tab(text: "Análisis"),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}