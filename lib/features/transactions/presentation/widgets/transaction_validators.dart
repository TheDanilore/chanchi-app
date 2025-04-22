import 'package:chanchi_app/features/transactions/domain/services/transaction_service.dart';

class TransactionValidators {
  static Future<String?> validateTransactionAmount(
    TransactionService transactionService,
    String userId,
    String accountId,
    double amount,
    String transactionType,
    String currencyCode,
  ) async {
    if (transactionType == 'expense') {
      try {
        final validationError = await transactionService.getTransactionValidationError(
          userId,
          accountId,
          amount,
          transactionType,
          currencyCode,
        );

        return validationError;
      } catch (validationError) {
        print('Error en validación: $validationError');
        return null;
      }
    }
    return null;
  }

  static bool validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return false;
    }
    final amount = double.tryParse(value);
    return amount != null && amount > 0 && amount <= 1000000;
  }
}