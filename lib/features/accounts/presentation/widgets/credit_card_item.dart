import 'package:flutter/material.dart';
import 'package:chanchi_app/core/utils/currency_util.dart';
import 'package:chanchi_app/data/models/account.dart';
import 'package:chanchi_app/features/accounts/presentation/screens/credit_card_transactions_screen.dart';
import 'package:chanchi_app/features/accounts/presentation/widgets/credit_card_payment_dialog.dart';

class CreditCardItem extends StatelessWidget {
  final Account card;
  final String userId;
  final Function(String, bool) onUpdateIncludeInBalance;

  const CreditCardItem({
    super.key,
    required this.card,
    required this.userId,
    required this.onUpdateIncludeInBalance,
  });

  @override
  Widget build(BuildContext context) {
    // Calcular porcentaje de uso y días para fecha de pago
    final double? usagePercentage = card.creditUsagePercentage;
    final creditLimit = card.creditLimit ?? 0.0;
    final available = creditLimit - card.balance;

    // Calcular días hasta la fecha de cierre
    String dueDateText = "No establecida";
    int daysLeft = 0;
    if (card.billingCycleEndDate != null) {
      final now = DateTime.now();
      final dueDay = card.billingCycleEndDate!.day;

      // Crear fecha de cierre para el mes actual o el siguiente
      final dueDate =
          (now.day > dueDay)
              ? DateTime(now.year, now.month + 1, dueDay) // Próximo mes
              : DateTime(now.year, now.month, dueDay); // Este mes

      daysLeft = dueDate.difference(now).inDays;
      dueDateText =
          daysLeft == 0
              ? "¡Hoy es tu fecha de cierre!"
              : "$daysLeft días para el cierre";
    }

    // Determinar color según días restantes
    Color dateColor = Colors.blue;
    if (daysLeft <= 3) {
      dateColor = Colors.red;
    } else if (daysLeft <= 7) {
      dateColor = Colors.orange;
    }

    // Obtener color de la tarjeta
    Color cardColor =
        card.color != null
            ? Color(
              int.parse(card.color!.substring(1, 7), radix: 16) + 0xFF000000,
            )
            : Colors.deepPurple[800]!;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cardColor, cardColor.withOpacity(0.8)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(cardColor),
              const SizedBox(height: 22),
              _buildBalanceInfo(available),
              const SizedBox(height: 18),
              _buildProgressIndicator(usagePercentage),
              const SizedBox(height: 20),
              _buildDueDateIndicator(dateColor, dueDateText),
              const SizedBox(height: 16),
              _buildTotalBalanceSwitch(context),
              const SizedBox(height: 16),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(Color cardColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              card.institution,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
        const Icon(Icons.credit_card, color: Colors.white, size: 32),
      ],
    );
  }

  Widget _buildBalanceInfo(double available) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Saldo utilizado",
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
              ),
            ),
            Text(
              CurrencyUtil.format(
                amount: card.balance,
                currencyCode: card.currencyCode ?? 'PEN',
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "Disponible",
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
              ),
            ),
            Text(
              CurrencyUtil.format(
                amount: available,
                currencyCode: card.currencyCode ?? 'PEN',
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(double? usagePercentage) {
    if (card.creditLimit == null) return const SizedBox.shrink();
    
    return Column(
      children: [
        LinearProgressIndicator(
          value: card.creditLimit! > 0 ? card.balance / card.creditLimit! : 0,
          backgroundColor: Colors.white.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(
            usagePercentage! > 80
                ? Colors.red[300]!
                : usagePercentage > 60
                ? Colors.orange[300]!
                : Colors.green[300]!,
          ),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${usagePercentage.toStringAsFixed(1)}% utilizado",
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
            Text(
              "Límite: ${CurrencyUtil.format(amount: card.creditLimit!, currencyCode: card.currencyCode ?? 'PEN')}",
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDueDateIndicator(Color dateColor, String dueDateText) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: dateColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_today,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            dueDateText,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBalanceSwitch(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          card.includeInTotalBalance
              ? "Incluida en balance total"
              : "No incluida en balance total",
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
        Switch(
          value: card.includeInTotalBalance,
          onChanged: (value) {
            onUpdateIncludeInBalance(card.id, value);
          },
          activeColor: Colors.white,
          activeTrackColor: Colors.green.withOpacity(0.5),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreditCardTransactionsScreen(
                  userId: userId,
                  card: card,
                ),
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
          ),
          child: const Text("Ver historial"),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => CreditCardPaymentDialog(
                userId: userId,
                card: card,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Color(
              int.parse(card.color!.substring(1, 7), radix: 16) + 0xFF000000,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
          ),
          icon: const Icon(Icons.payments, size: 18),
          label: const Text("Registrar pago"),
        ),
      ],
    );
  }
}