import 'package:cloud_firestore/cloud_firestore.dart';

class Account {
  final String id;
  final String name;
  final String type; // checking, savings, credit_card, etc.
  final String institution;
  final double balance;
  final String? iconName;
  final String? color;
  final String? currencyCode;

  // Nuevas propiedades para tarjetas de crédito
  final bool isCreditCard;
  final double? creditLimit;
  final bool includeInTotalBalance; // Controla si se suma al balance total
  final DateTime? billingCycleEndDate; // Fecha de cierre del ciclo

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.institution,
    required this.balance,
    this.iconName,
    this.color,
    this.currencyCode = 'PEN',
    this.isCreditCard = false,
    this.creditLimit,
    this.includeInTotalBalance = true,
    this.billingCycleEndDate,
  });

  // Método para obtener el balance disponible según el tipo de cuenta
  double get availableBalance {
    if (isCreditCard && creditLimit != null) {
      return creditLimit! - balance; // Para tarjetas, el balance es lo gastado
    }
    return balance;
  }

  // Método para calcular el porcentaje de crédito utilizado
  double? get creditUsagePercentage {
    if (isCreditCard && creditLimit != null && creditLimit! > 0) {
      return (balance / creditLimit!) * 100;
    }
    return null;
  }

  // Añade este método a la clase Account
  static String normalizeType(String type) {
    Map<String, String> typeMapping = {
      'Efectivo': 'cash',
      'Cuenta Corriente': 'checking',
      'Cuenta de Ahorros': 'savings',
      'Tarjeta de Crédito': 'credit_card',
      'Inversión': 'investment',
    };

    return typeMapping[type] ?? type;
  }

  factory Account.fromMap(Map<String, dynamic> map, String docId) {
    final type = normalizeType(map['type'] ?? '');

    // Verificar si ya existe un userId en el mapa
    final id = map.containsKey('userId') ? '${map['userId']}/$docId' : docId;

    return Account(
      id: id, // Usar el ID generado
      name: map['name'] ?? '',
      type: type,
      institution: map['institution'] ?? '',
      balance: (map['balance'] ?? 0.0).toDouble(),
      iconName: map['iconName'],
      color: map['color'],
      currencyCode: map['currencyCode'] ?? 'PEN',
      isCreditCard: map['isCreditCard'] ?? type == 'credit_card',
      creditLimit: map['creditLimit']?.toDouble(),
      includeInTotalBalance: map['includeInTotalBalance'] ?? true,
      billingCycleEndDate:
          map['billingCycleEndDate'] != null
              ? (map['billingCycleEndDate'] as Timestamp).toDate()
              : null,
    );
  }

  // Convertir a mapa
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'institution': institution,
      'balance': balance,
      'iconName': iconName,
      'color': color,
      'currencyCode': currencyCode,
      'isCreditCard': isCreditCard,
      'creditLimit': creditLimit,
      'includeInTotalBalance': includeInTotalBalance,
      'billingCycleEndDate':
          billingCycleEndDate != null
              ? Timestamp.fromDate(billingCycleEndDate!)
              : null,
    };
  }

  // Crear una copia con valores modificados
  Account copyWith({
    String? id,
    String? name,
    String? type,
    String? institution,
    double? balance,
    String? iconName,
    String? color,
    String? currencyCode,
    bool? isCreditCard,
    double? creditLimit,
    bool? includeInTotalBalance,
    DateTime? billingCycleEndDate,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      institution: institution ?? this.institution,
      balance: balance ?? this.balance,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      currencyCode: currencyCode ?? this.currencyCode,
      isCreditCard: isCreditCard ?? this.isCreditCard,
      creditLimit: creditLimit ?? this.creditLimit,
      includeInTotalBalance:
          includeInTotalBalance ?? this.includeInTotalBalance,
      billingCycleEndDate: billingCycleEndDate ?? this.billingCycleEndDate,
    );
  }
}
