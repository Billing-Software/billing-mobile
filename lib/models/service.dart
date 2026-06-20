class Service {
  final int id;
  final String name;
  final String sku;
  final String category;
  final double basePrice;
  final double taxRate;
  final String status; // 'Active' | 'Inactive'
  final String iconName;

  Service({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.basePrice,
    required this.taxRate,
    required this.status,
    required this.iconName,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      sku: json['sku'] ?? '',
      category: json['category'] ?? '',
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0.0,
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Active',
      iconName: json['iconName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'category': category,
      'basePrice': basePrice,
      'taxRate': taxRate,
      'status': status,
      'iconName': iconName,
    };
  }
}
