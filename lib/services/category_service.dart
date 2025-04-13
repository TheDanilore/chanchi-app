import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chanchi_app/models/category.dart';

class CategoryService {
  final FirebaseFirestore _firestore;

  CategoryService({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Obtiene todas las categorías disponibles en Firebase
  Future<List<Category>> getCategories() async {
    try {
      final categoriesSnapshot = await _firestore.collection('categories').get();
      
      return categoriesSnapshot.docs.map((doc) {
        final data = doc.data();
        return Category(
          id: doc.id,
          name: data['name'] ?? 'Sin nombre',
          iconName: data['iconName'] ?? 'category',
          color: data['color'] ?? '#4A6FFF',
          type: data['type'] ?? 'expense',
        );
      }).toList();
    } catch (e) {
      print('Error al cargar categorías: $e');
      return [];
    }
  }

  /// Obtiene las categorías filtradas por tipo (ingreso o gasto)
  Future<List<Category>> getCategoriesByType(String type) async {
    try {
      // Obtener todas las categorías primero, incluyendo 'general'
      final allCategoriesSnapshot = await _firestore.collection('categories').get();
      
      List<Category> allCategories = allCategoriesSnapshot.docs.map((doc) {
        final data = doc.data();
        return Category(
          id: doc.id,
          name: data['name'] ?? 'Sin nombre',
          iconName: data['iconName'] ?? 'category',
          color: data['color'] ?? '#4A6FFF',
          type: data['type'] ?? 'expense',
        );
      }).toList();
      
      // Comprobamos si ya existe la categoría general en Firestore
      bool generalExists = allCategories.any((cat) => cat.id == 'general');
      
      // Filtrar las categorías por tipo (incluyendo 'general' que podría tener cualquier tipo)
      List<Category> categories = allCategories.where((cat) {
        // Incluir categoría si coincide con el tipo o es 'general'
        return cat.type == type || (cat.id == 'general' && generalExists);
      }).toList();
      
      // Si no hay categoría 'general', crear una por defecto
      if (!generalExists) {
        categories.add(Category(
          id: 'general',
          name: 'General',
          iconName: 'category',
          color: '#4A6FFF',
          type: type,
        ));
      }
      
      // Ordenar: primero 'general', luego el resto alfabéticamente
      categories.sort((a, b) {
        if (a.id == 'general') return -1;
        if (b.id == 'general') return 1;
        return a.name.compareTo(b.name);
      });
      
      // Devolver categorías filtradas (incluyendo 'general')
      return categories;
    } catch (e) {
      print('Error al cargar categorías por tipo: $e');
      // Devolver al menos la categoría general en caso de error
      return [
        Category(
          id: 'general',
          name: 'General',
          iconName: 'category',
          color: '#4A6FFF',
          type: type,
        )
      ];
    }
  }

  /// Crea una nueva categoría personalizada
  Future<String?> createCategory(Category category) async {
    try {
      final docRef = await _firestore.collection('categories').add({
        'name': category.name,
        'iconName': category.iconName,
        'color': category.color,
        'type': category.type,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return docRef.id;
    } catch (e) {
      print('Error al crear categoría: $e');
      return null;
    }
  }

  /// Actualiza una categoría existente
  Future<bool> updateCategory(Category category) async {
    try {
      await _firestore.collection('categories').doc(category.id).update({
        'name': category.name,
        'iconName': category.iconName,
        'color': category.color,
        'type': category.type,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('Error al actualizar categoría: $e');
      return false;
    }
  }

  /// Elimina una categoría
  Future<bool> deleteCategory(String categoryId) async {
    try {
      await _firestore.collection('categories').doc(categoryId).delete();
      return true;
    } catch (e) {
      print('Error al eliminar categoría: $e');
      return false;
    }
  }
}