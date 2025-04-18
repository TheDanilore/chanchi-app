import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

class FinancialTransaction {
  final String id;
  final String userId;
  final String accountId;
  final String categoryId;
  final String description;
  final double amount;
  final DateTime dateTime; // Fecha y hora completa
  final String type; // "expense" o "income"
  final String? notes;
  final String currencyCode;
  final bool isInTrash;


  FinancialTransaction({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.categoryId,
    required this.description,
    required this.amount,
    required this.dateTime,
    required this.type,
    this.notes,
    this.currencyCode = 'PEN', // Valor predeterminado
    this.isInTrash = false,
  });

  // Métodos para convertir de/a Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'accountId': accountId,
      'categoryId': categoryId,
      'description': description,
      'amount': amount,
      'dateTime': firestore.Timestamp.fromDate(dateTime),
      'type': type,
      'notes': notes,
      'currencyCode': currencyCode,
      'isInTrash': isInTrash,
    };
  }

  factory FinancialTransaction.fromMap(Map<String, dynamic> map, String docId) {
    return FinancialTransaction(
      id: docId,
      userId: map['userId'] ?? '',
      accountId: map['accountId'] ?? '',
      categoryId: map['categoryId'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      dateTime: map['dateTime'] is firestore.Timestamp 
          ? (map['dateTime'] as firestore.Timestamp).toDate()
          : DateTime.now(),
      type: map['type'] ?? 'expense',
      notes: map['notes'],
      currencyCode: map['currencyCode'] ?? 'PEN',
      isInTrash: map['isInTrash'] ?? 'false',
    );
  }
}