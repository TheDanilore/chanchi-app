import 'package:flutter/material.dart';
import 'package:chanchi_app/config/theme.dart';

class OfflineIndicatorWidget extends StatelessWidget {
  final bool isOffline;
  final bool isSyncing;
  final int pendingOperationsCount;
  final VoidCallback onSyncPressed;

  const OfflineIndicatorWidget({
    Key? key,
    required this.isOffline,
    required this.isSyncing,
    required this.pendingOperationsCount,
    required this.onSyncPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isOffline || pendingOperationsCount == 0) return SizedBox.shrink();
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
      padding: EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade50, Colors.orange.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.shade200.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: Colors.amber.shade300.withOpacity(0.7),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.shade300.withOpacity(0.3),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.sync_problem,
              color: Colors.amber.shade700,
              size: 24,
            ),
          ),
          SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modo sin conexión',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tienes $pendingOperationsCount ${pendingOperationsCount == 1 ? 'transacción pendiente' : 'transacciones pendientes'} de sincronizar',
                  style: TextStyle(
                    color: Colors.amber.shade800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            child: isSyncing 
                ? Container(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade800),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: onSyncPressed,
                    icon: Icon(Icons.sync, size: 16),
                    label: Text('Sincronizar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}