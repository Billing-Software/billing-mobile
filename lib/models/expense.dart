class Expense {
  final int id;
  final int businessId;
  final String description;
  final double amount;
  final String category;
  final String expenseDate;
  final String? createdAt;

  Expense({
    required this.id,
    required this.businessId,
    required this.description,
    required this.amount,
    required this.category,
    required this.expenseDate,
    this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] ?? 0,
      businessId: json['businessId'] ?? 0,
      description: json['description'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] ?? '',
      expenseDate: json['expenseDate'] ?? '',
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'description': description,
      'amount': amount,
      'category': category,
      'expenseDate': expenseDate,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
}
