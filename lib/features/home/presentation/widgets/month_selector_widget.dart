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
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildArrowButton(Icons.chevron_left, onPreviousMonth, true),
          GestureDetector(
            onTap: () => _showMonthPicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('MMMM yyyy', 'es').format(selectedMonth),
                    style: style.selectedMonthStyle,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
          ),
          _buildArrowButton(Icons.chevron_right, onNextMonth, canGoNext),
        ],
      ),
    );
  }

  Widget _buildArrowButton(
    IconData icon,
    VoidCallback onPressed,
    bool isEnabled,
  ) {
    return InkWell(
      onTap: isEnabled ? onPressed : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          color: isEnabled ? style.arrowColor : Colors.grey.shade300,
          size: 22,
        ),
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
            dialogBackgroundColor: Colors.white,
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
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    this.arrowColor = Colors.black87,
  });
}
