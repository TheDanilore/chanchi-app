import 'package:chanchi_app/core/utils/icon_utils.dart';
import 'package:flutter/material.dart';
import 'package:chanchi_app/core/config/theme.dart';
import 'package:chanchi_app/data/models/category.dart';
import 'package:chanchi_app/services/category_service.dart';

class CategorySelectorWidget extends StatefulWidget {
  final String? selectedCategoryId;
  final String transactionType;
  final Category? category;
  final Function(String?) onCategorySelected;

  const CategorySelectorWidget({
    super.key,
    required this.selectedCategoryId,
    required this.transactionType,
    required this.onCategorySelected,
    this.category,
  });

  @override
  _CategorySelectorWidgetState createState() => _CategorySelectorWidgetState();
}

class _CategorySelectorWidgetState extends State<CategorySelectorWidget> {
  final CategoryService _categoryService = CategoryService();
  bool _isLoading = true;
  List<Category> _categories = [];
  String? _selectedCategoryId;

  // Flag para controlar si ya notificamos la selección inicial
  bool _hasReportedInitialSelection = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.selectedCategoryId;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener categorías filtradas por tipo de transacción
      final categories = await _categoryService.getCategoriesByType(
        widget.transactionType,
      );

      // Asegurarnos de no tener duplicados (verificando por ID)
      final uniqueCategories = <String, Category>{};
      for (var category in categories) {
        uniqueCategories[category.id] = category;
      }

      final dedupedCategories = uniqueCategories.values.toList();

      print(
        'Categorías cargadas (sin duplicados): ${dedupedCategories.map((c) => "${c.id}: ${c.name}").join(", ")}',
      );

      // Ordenar las categorías: primero "General", luego el resto alfabéticamente
      dedupedCategories.sort((a, b) {
        // Si alguna es "general", ponerla primero
        if (a.id == 'general') return -1;
        if (b.id == 'general') return 1;
        // Para el resto, ordenar alfabéticamente
        return a.name.compareTo(b.name);
      });

      if (mounted) {
        setState(() {
          _categories = dedupedCategories;
          _isLoading = false;

          // Verificar si debemos seleccionar una categoría por defecto
          if (_selectedCategoryId == null ||
              !dedupedCategories.any((c) => c.id == _selectedCategoryId)) {
            // Intentar seleccionar 'general' primero
            if (dedupedCategories.any((c) => c.id == 'general')) {
              _selectedCategoryId = 'general';
            } else if (dedupedCategories.isNotEmpty) {
              _selectedCategoryId = dedupedCategories.first.id;
            }

            // Solo notificar al padre si no hemos notificado aún
            if (!_hasReportedInitialSelection) {
              widget.onCategorySelected(_selectedCategoryId);
              _hasReportedInitialSelection = true;
            }
          }
        });
      }
    } catch (e) {
      print('Error al cargar categorías: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(CategorySelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Solo si cambia el tipo de transacción, recargar las categorías
    if (oldWidget.transactionType != widget.transactionType) {
      print(
        'Tipo de transacción cambió: ${oldWidget.transactionType} -> ${widget.transactionType}',
      );
      _loadCategories();
      // Resetear el flag cuando cambia el tipo
      _hasReportedInitialSelection = false;
    }

    // Si cambia el ID de categoría seleccionada desde fuera, actualizar el estado interno
    if (widget.selectedCategoryId != oldWidget.selectedCategoryId) {
      print(
        'Categoría seleccionada cambió: ${oldWidget.selectedCategoryId} -> ${widget.selectedCategoryId}',
      );
      setState(() {
        _selectedCategoryId = widget.selectedCategoryId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_categories.isEmpty) {
      return const Center(child: Text('No hay categorías disponibles'));
    }

    // Imprimir estado de selección para depuración
    print('Renderizando categorías - Seleccionada: $_selectedCategoryId');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Categoría', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppTheme.spacingS),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                _categories.map((category) {
                  final isSelected = category.id == _selectedCategoryId;
                  final color = Color(
                    int.parse(category.color.substring(1, 7), radix: 16) +
                        0xFF000000,
                  );

                  return Padding(
                    padding: const EdgeInsets.only(right: AppTheme.spacingS),
                    child: ChoiceChip(
                      label: Text(category.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          print('Usuario seleccionó categoría: ${category.id}');
                          setState(() {
                            _selectedCategoryId = category.id;
                          });
                          widget.onCategorySelected(category.id);
                        }
                      },
                      avatar: Icon(
                        // Use IconUtils to get the icon
                        IconUtils.getIconByName(
                          category.iconName,
                          fallbackType: widget.transactionType == 'expense' 
                              ? 'expense' 
                              : 'income'
                        ),
                        size: 18,
                        color: isSelected ? Colors.white : color,
                      ),
                      labelStyle: TextStyle(
                        color:
                            isSelected
                                ? Colors.white
                                : AppTheme.textPrimaryColor,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: Colors.transparent,
                      selectedColor: color,
                      side: BorderSide(color: color),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}