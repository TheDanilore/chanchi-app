import 'package:chanchi_app/presentation/widgets/line_chart_painter.dart';
import 'package:flutter/material.dart';
import 'package:chanchi_app/config/theme.dart';
import 'package:intl/intl.dart';

class IncomeExpenseChart extends StatelessWidget {
  final Map<String, double> monthlyIncome;
  final Map<String, double> monthlyExpenses;

  const IncomeExpenseChart({
    Key? key,
    required this.monthlyIncome,
    required this.monthlyExpenses,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool hasData = monthlyIncome.isNotEmpty && monthlyExpenses.isNotEmpty;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Evolución de Ingresos y Gastos",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            // Añadir texto explicativo
            Text(
              "Este gráfico muestra la tendencia de tus ingresos y gastos durante los últimos 4 meses.",
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            if (!hasData)
              _buildEmptyState(context)
            else
              _buildChartContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.show_chart_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              "No hay suficientes datos de transacciones",
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartContent(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      decimalDigits: 0,
      symbol: 'S/',
      locale: 'es_PE',
    );
    
    // Calcular balance para cada mes
    Map<String, double> monthlyBalance = {};
    List<String> months = [];
    
    // Asegurar que procesamos los meses en orden cronológico
    if (monthlyIncome.isNotEmpty) {
      months = monthlyIncome.keys.toList();
      months.sort(); // Esto funcionará porque los meses están en formato "MMM" y en orden alfabético
      
      for (var month in months) {
        final income = monthlyIncome[month] ?? 0;
        final expense = monthlyExpenses[month] ?? 0;
        monthlyBalance[month] = income - expense;
      }
    }
    
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: CustomPaint(
            size: Size(MediaQuery.of(context).size.width - 80, 220),
            painter: LineChartPainter(
              incomeData: monthlyIncome,
              expenseData: monthlyExpenses,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        
        // Leyenda del gráfico
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildChartLegend("Ingresos", Colors.green),
            const SizedBox(width: 30),
            _buildChartLegend("Gastos", Colors.redAccent),
          ],
        ),
        
        const SizedBox(height: AppTheme.spacingM),
        
        // Tabla de datos mensuales (últimos 4 meses)
        months.isNotEmpty 
          ? Column(
              children: [
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(child: Text('Mes', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(child: Text('Ingresos', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(child: Text('Gastos', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(child: Text('Balance', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                const Divider(),
                ...months.map((month) {
                  final income = monthlyIncome[month] ?? 0;
                  final expense = monthlyExpenses[month] ?? 0;
                  final balance = monthlyBalance[month] ?? 0;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Expanded(child: Text(month)),
                        Expanded(child: Text(currencyFormat.format(income))),
                        Expanded(child: Text(currencyFormat.format(expense))),
                        Expanded(
                          child: Text(
                            currencyFormat.format(balance),
                            style: TextStyle(
                              color: balance >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold
                            ),
                          )
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const Divider(),
                
                // Conclusión basada en los datos
                const SizedBox(height: AppTheme.spacingS),
                _buildChartAnalysis(months, monthlyIncome, monthlyExpenses, monthlyBalance),
              ],
            )
          : const SizedBox(),
      ],
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }
  
  // Nuevo widget para mostrar un análisis de la tendencia
  Widget _buildChartAnalysis(
    List<String> months, 
    Map<String, double> incomes, 
    Map<String, double> expenses, 
    Map<String, double> balances
  ) {
    if (months.isEmpty || months.length < 2) return const SizedBox();
    
    // Analizar la tendencia de los últimos meses
    final currencyFormat = NumberFormat.currency(
      decimalDigits: 0,
      symbol: 'S/',
      locale: 'es_PE',
    );
    
    // Tomar los dos últimos meses para analizar la tendencia
    final lastMonth = months.last;
    final previousMonth = months[months.length - 2];
    
    final lastIncome = incomes[lastMonth] ?? 0;
    final previousIncome = incomes[previousMonth] ?? 0;
    final incomeDiff = lastIncome - previousIncome;
    final incomePercent = previousIncome > 0 ? (incomeDiff / previousIncome) * 100 : 0;
    
    final lastExpense = expenses[lastMonth] ?? 0;
    final previousExpense = expenses[previousMonth] ?? 0;
    final expenseDiff = lastExpense - previousExpense;
    final expensePercent = previousExpense > 0 ? (expenseDiff / previousExpense) * 100 : 0;
    
    final lastBalance = balances[lastMonth] ?? 0;
    final previousBalance = balances[previousMonth] ?? 0;
    
    // Textos de análisis
    TextStyle infoStyle = TextStyle(fontSize: 13, color: AppTheme.textPrimaryColor);
    
    String incomeText = "";
    Color incomeColor = Colors.black;
    
    if (incomeDiff > 0) {
      incomeText = "Tus ingresos aumentaron un ${incomePercent.toStringAsFixed(1)}% respecto al mes anterior.";
      incomeColor = Colors.green;
    } else if (incomeDiff < 0) {
      incomeText = "Tus ingresos disminuyeron un ${incomePercent.abs().toStringAsFixed(1)}% respecto al mes anterior.";
      incomeColor = Colors.orange;
    } else {
      incomeText = "Tus ingresos se mantuvieron igual que el mes anterior.";
      incomeColor = Colors.blue;
    }
    
    String expenseText = "";
    Color expenseColor = Colors.black;
    
    if (expenseDiff > 0) {
      expenseText = "Tus gastos aumentaron un ${expensePercent.toStringAsFixed(1)}% respecto al mes anterior.";
      expenseColor = Colors.red;
    } else if (expenseDiff < 0) {
      expenseText = "Tus gastos disminuyeron un ${expensePercent.abs().toStringAsFixed(1)}% respecto al mes anterior.";
      expenseColor = Colors.green;
    } else {
      expenseText = "Tus gastos se mantuvieron igual que el mes anterior.";
      expenseColor = Colors.blue;
    }
    
    String balanceText = "";
    if (lastBalance > previousBalance) {
      balanceText = "Tu balance ha mejorado respecto al mes anterior.";
    } else if (lastBalance < previousBalance) {
      balanceText = "Tu balance ha empeorado respecto al mes anterior.";
    } else {
      balanceText = "Tu balance se mantiene similar al mes anterior.";
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Análisis de tendencia:",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(incomeText, style: infoStyle.copyWith(color: incomeColor)),
        const SizedBox(height: 4),
        Text(expenseText, style: infoStyle.copyWith(color: expenseColor)),
        const SizedBox(height: 4),
        Text(balanceText, style: infoStyle),
      ],
    );
  }
}