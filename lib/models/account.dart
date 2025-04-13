class Account {
  final String id;
  final String name;
  final String type; // "Débito", "Crédito", "Efectivo", etc.
  final String institution; // "BCP", "Interbank", etc.
  final double balance;
  final String? iconName;
  final String? color;
  final String currencyCode; // New field

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.institution,
    required this.balance,
    this.iconName,
    this.color,
    this.currencyCode = 'PEN', // Valor predeterminado
  });

  // Métodos para convertir de/a Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'institution': institution,
      'balance': balance,
      'iconName': iconName,
      'color': color,
      'currencyCode': currencyCode,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map, String docId) {
    return Account(
      id: docId,
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      institution: map['institution'] ?? '',
      balance: (map['balance'] ?? 0.0).toDouble(),
      iconName: map['iconName'],
      color: map['color'],
      currencyCode: map['currencyCode'] ?? 'PEN',
    );
  }
}