import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  final String id;
  final String userId;
  final double amount;
  final String? categoryId;
  final String month; // Formato: 'YYYY-MM'
  final double? currentSpent;
  final bool isEnabled;
  final bool notifyWhenClose;
  final bool notifyWhenReached;
  final bool notifyWhenExceeded;
  final double notificationThreshold; // Porcentaje (0-1) para avisar cuando está cerca

  Budget({
    required this.id,
    required this.userId,
    required this.amount,
    this.categoryId,
    required this.month,
    this.currentSpent = 0.0,
    this.isEnabled = true,
    this.notifyWhenClose = true,
    this.notifyWhenReached = true,
    this.notifyWhenExceeded = true,
    this.notificationThreshold = 0.8, // Por defecto, avisar al 80%
  });

  /// Crea un objeto Budget desde un mapa de datos
  factory Budget.fromMap(Map<String, dynamic> data, String id) {
    return Budget(
      id: id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      categoryId: data['categoryId'],
      month: data['month'] ?? '',
      currentSpent: (data['currentSpent'] ?? 0.0).toDouble(),
      isEnabled: data['isEnabled'] ?? true,
      notifyWhenClose: data['notifyWhenClose'] ?? true,
      notifyWhenReached: data['notifyWhenReached'] ?? true,
      notifyWhenExceeded: data['notifyWhenExceeded'] ?? true,
      notificationThreshold: (data['notificationThreshold'] ?? 0.8).toDouble(),
    );
  }

  /// Convierte este objeto Budget a un mapa para almacenar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'categoryId': categoryId,
      'month': month,
      'currentSpent': currentSpent,
      'isEnabled': isEnabled,
      'notifyWhenClose': notifyWhenClose,
      'notifyWhenReached': notifyWhenReached,
      'notifyWhenExceeded': notifyWhenExceeded,
      'notificationThreshold': notificationThreshold,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Crea una copia de este Budget con los campos especificados reemplazados
  Budget copyWith({
    String? id,
    String? userId,
    double? amount,
    String? categoryId,
    String? month,
    double? currentSpent,
    bool? isEnabled,
    bool? notifyWhenClose,
    bool? notifyWhenReached,
    bool? notifyWhenExceeded,
    double? notificationThreshold,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      month: month ?? this.month,
      currentSpent: currentSpent ?? this.currentSpent,
      isEnabled: isEnabled ?? this.isEnabled,
      notifyWhenClose: notifyWhenClose ?? this.notifyWhenClose,
      notifyWhenReached: notifyWhenReached ?? this.notifyWhenReached,
      notifyWhenExceeded: notifyWhenExceeded ?? this.notifyWhenExceeded,
      notificationThreshold: notificationThreshold ?? this.notificationThreshold,
    );
  }

  /// Calcula el porcentaje de presupuesto utilizado (0-1)
  double get percentageUsed {
    if (amount <= 0) return 0;
    return (currentSpent ?? 0) / amount;
  }

  /// Determina si el presupuesto está próximo a alcanzarse
  bool get isCloseToLimit {
    return percentageUsed >= notificationThreshold && percentageUsed < 1.0;
  }

  /// Determina si el presupuesto se ha alcanzado exactamente
  bool get isLimitReached {
    return percentageUsed >= 1.0 && percentageUsed < 1.1;
  }

  /// Determina si el presupuesto se ha excedido
  bool get isLimitExceeded {
    return percentageUsed >= 1.1;
  }

  /// Obtiene el monto restante del presupuesto
  double get remainingAmount {
    return amount - (currentSpent ?? 0);
  }
}