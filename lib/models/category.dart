class Category {
  final String id;
  final String name;
  final String iconName;
  final String color;
  final String type; // "expense" o "income"

  Category({
    required this.id,
    required this.name,
    required this.iconName,
    required this.color,
    required this.type,
  });

  // Métodos para convertir de/a Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'iconName': iconName,
      'color': color,
      'type': type,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map, String docId) {
    return Category(
      id: docId,
      name: map['name'] ?? '',
      iconName: map['iconName'] ?? 'category',
      color: map['color'] ?? '#4A6FFF',
      type: map['type'] ?? 'expense',
    );
  }
}