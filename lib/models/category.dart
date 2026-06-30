class Category {
  final int id;
  final int businessId;
  final String name;
  final String type; // 'Service' | 'Inventory' | 'Expense'
  final int? parentId;
  final String? createdAt;

  Category({
    required this.id,
    required this.businessId,
    required this.name,
    required this.type,
    this.parentId,
    this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      businessId: json['businessId'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      parentId: json['parentId'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'name': name,
      'type': type,
      'parentId': parentId,
      'createdAt': createdAt,
    };
  }
}
