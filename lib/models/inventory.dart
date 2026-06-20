class InventoryItem {
  final int id;
  final String name;
  final String sku;
  final String category;
  final int currentStock;
  final String unit;
  final int reorderLevel;
  final String? imageUrl;
  final String? placeholderType;

  InventoryItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.currentStock,
    required this.unit,
    required this.reorderLevel,
    this.imageUrl,
    this.placeholderType,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      sku: json['sku'] ?? '',
      category: json['category'] ?? '',
      currentStock: json['currentStock'] ?? 0,
      unit: json['unit'] ?? '',
      reorderLevel: json['reorderLevel'] ?? 0,
      imageUrl: json['imageUrl'],
      placeholderType: json['placeholderType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'category': category,
      'currentStock': currentStock,
      'unit': unit,
      'reorderLevel': reorderLevel,
      'imageUrl': imageUrl,
      'placeholderType': placeholderType,
    };
  }
}
