// lib/features/home/domain/models/transaction.dart
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'transaction.g.dart'; // Generado por hive_generator

@HiveType(typeId: 0)
class Transaction {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String userId;
  
  @HiveField(2)
  final String accountId;
  
  @HiveField(3)
  final String categoryId;
  
  @HiveField(4)
  final String description;
  
  @HiveField(5)
  final double amount;
  
  @HiveField(6)
  final DateTime dateTime;
  
  @HiveField(7)
  final String type; // 'income' o 'expense'
  
  @HiveField(8)
  final String? notes;
  
  @HiveField(9)
  final String currencyCode;
  
  @HiveField(10)
  final bool isInTrash;
  
  @HiveField(11)
  final DateTime? createdAt;
  
  @HiveField(12)
  final DateTime? updatedAt;
  
  @HiveField(13)
  final String? fromAccountId; // Para transferencias
  
  Transaction({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.categoryId,
    required this.description,
    required this.amount,
    required this.dateTime,
    required this.type,
    this.notes,
    required this.currencyCode,
    required this.isInTrash,
    this.createdAt,
    this.updatedAt,
    this.fromAccountId,
  });
  
  // Constructor desde mapa (para Firestore)
  factory Transaction.fromMap(Map<String, dynamic> map, String documentId) {
    return Transaction(
      id: documentId,
      userId: map['userId'] ?? '',
      accountId: map['accountId'] ?? '',
      categoryId: map['categoryId'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      dateTime: map['dateTime'] != null
          ? (map['dateTime'] as Timestamp).toDate()
          : DateTime.now(),
      type: map['type'] ?? 'expense',
      notes: map['notes'],
      currencyCode: map['currencyCode'] ?? 'PEN',
      isInTrash: map['isInTrash'] ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      fromAccountId: map['fromAccountId'],
    );
  }
  
  // Convertir a mapa (para Firestore)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'accountId': accountId,
      'categoryId': categoryId,
      'description': description,
      'amount': amount,
      'dateTime': Timestamp.fromDate(dateTime),
      'type': type,
      'notes': notes,
      'currencyCode': currencyCode,
      'isInTrash': isInTrash,
      'fromAccountId': fromAccountId,
    };
  }
  
  // Copiar con nuevos campos
  Transaction copyWith({
    String? id,
    String? userId,
    String? accountId,
    String? categoryId,
    String? description,
    double? amount,
    DateTime? dateTime,
    String? type,
    String? notes,
    String? currencyCode,
    bool? isInTrash,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fromAccountId,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      dateTime: dateTime ?? this.dateTime,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      currencyCode: currencyCode ?? this.currencyCode,
      isInTrash: isInTrash ?? this.isInTrash,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fromAccountId: fromAccountId ?? this.fromAccountId,
    );
  }
}

// Evita usar FinancialTransaction para mantener consistencia 
// Para compatibilidad, creamos un typedef
typedef FinancialTransaction = Transaction;