import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chanchi_app/core/config/theme.dart';

class MonthSelectorWidget extends StatelessWidget {
  final DateTime selectedMonth;
  final Function(DateTime) onMonthChanged;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final bool canGoNext;
  final MonthSelectorStyle style;

  const MonthSelectorWidget({
    Key? key,
    required this.selectedMonth,
    required this.onMonthChanged,
    required this.onPreviousMonth,
    required this.onNextMonth,
    this.canGoNext = true,
    this.style = const MonthSelectorStyle(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: style.arrowColor),
            onPressed: onPreviousMonth,
          ),
          GestureDetector(
            onTap: () => _showMonthPicker(context),
            child: Text(
              DateFormat('MMMM yyyy', 'es').format(selectedMonth),
              style: style.selectedMonthStyle,
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, 
              color: canGoNext ? style.arrowColor : Colors.grey),
            onPressed: canGoNext ? onNextMonth : null,
          ),
        ],
      ),
    );
  }

  void _showMonthPicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onMonthChanged(DateTime(picked.year, picked.month, 1));
    }
  }
}

class MonthSelectorStyle {
  final TextStyle selectedMonthStyle;
  final Color arrowColor;

  const MonthSelectorStyle({
    this.selectedMonthStyle = const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    this.arrowColor = Colors.black87,
  });
}