class Customer {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final bool isWalkIn;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.isWalkIn,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      isWalkIn: json['isWalkIn'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'isWalkIn': isWalkIn,
    };
  }
}
