class StaffMember {
  final int id;
  final String name;
  final String empCode;
  final String contact;
  final String role; // 'Manager' | 'Staff' | 'Cashier'
  final int totalBills;
  final double revenueGen;
  final String status; // 'Active' | 'Inactive'

  StaffMember({
    required this.id,
    required this.name,
    required this.empCode,
    required this.contact,
    required this.role,
    required this.totalBills,
    required this.revenueGen,
    required this.status,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      empCode: json['empCode'] ?? '',
      contact: json['contact'] ?? '',
      role: json['role'] ?? 'Staff',
      totalBills: json['totalBills'] ?? 0,
      revenueGen: (json['revenueGenerated'] as num?)?.toDouble() ?? (json['revenueGen'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'empCode': empCode,
      'contact': contact,
      'role': role,
      'totalBills': totalBills,
      'revenueGen': revenueGen,
      'status': status,
    };
  }
}
