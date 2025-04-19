import 'package:flutter/material.dart';
import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/data/models/category.dart';
import 'package:chanchi_app/data/models/account.dart';
import 'package:chanchi_app/features/home/domain/services/transaction_list_service.dart';
import 'package:intl/intl.dart';

class FilterSection extends StatefulWidget {
  final String userId;
  final DateTime selectedMonth;
  final void Function(String? categoryId) onCategorySelected;
  final void Function(String? accountId) onAccountSelected;
  final void Function(DateTime? startDate, DateTime? endDate) onDateRangeSelected;
  final void Function() onClearFilters;

  const FilterSection({
    Key? key,
    required this.userId,
    required this.selectedMonth,
    required this.onCategorySelected,
    required this.onAccountSelected,
    required this.onDateRangeSelected,
    required this.onClearFilters,
  }) : super(key: key);

  @override
  _FilterSectionState createState() => _FilterSectionState();
}

class _FilterSectionState extends State<FilterSection> {
  String? _selectedCategoryId;
  String? _selectedAccountId;
  DateTime? _startDate;
  DateTime? _endDate;

  late TransactionListService _service;
  List<Category> _categories = [];
  List<Account> _accounts = [];

  @override
  void initState() {
    super.initState();
    _service = TransactionListService(userId: widget.userId);
    _loadData();
  }

  Future<void> _loadData() async {
    final categories = await _service.loadCategories();
    final accounts = await _service.loadAccounts();

    setState(() {
      _categories = categories.values.toList();
      _accounts = accounts.values.toList();
    });
  }

  void _applyFilters() {
    widget.onCategorySelected(_selectedCategoryId);
    widget.onAccountSelected(_selectedAccountId);
    widget.onDateRangeSelected(_startDate, _endDate);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Filtros",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        DropdownButtonFormField<String?>(
          decoration: InputDecoration(
            labelText: "Categoría",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
          ),
          value: _selectedCategoryId,
          items: [
            DropdownMenuItem(
              value: null,
              child: Text("Todas"),
            ),
            ..._categories.map((category) => DropdownMenuItem(
              value: category.id,
              child: Text(category.name),
            )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedCategoryId = value;
            });
            _applyFilters();
          },
        ),
        const SizedBox(height: AppTheme.spacingM),
        DropdownButtonFormField<String?>(
          decoration: InputDecoration(
            labelText: "Cuenta",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
          ),
          value: _selectedAccountId,
          items: [
            DropdownMenuItem(
              value: null,
              child: Text("Todas"),
            ),
            ..._accounts.map((account) => DropdownMenuItem(
              value: account.id,
              child: Text(account.name),
            )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedAccountId = value;
            });
            _applyFilters();
          },
        ),
        const SizedBox(height: AppTheme.spacingM),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () async {
                  final DateTimeRange? picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) {
                    setState(() {
                      _startDate = picked.start;
                      _endDate = picked.end;
                    });
                    _applyFilters();
                  }
                },
                child: Text("Seleccionar Rango de Fechas"),
              ),
            ),
            if (_startDate != null && _endDate != null)
              Text(
                " ${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}",
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        TextButton(
          onPressed: () {
            setState(() {
              _selectedCategoryId = null;
              _selectedAccountId = null;
              _startDate = null;
              _endDate = null;
            });
            _applyFilters();
            widget.onClearFilters();
          },
          child: Text("Limpiar Filtros"),
        ),
      ],
    );
  }
}
