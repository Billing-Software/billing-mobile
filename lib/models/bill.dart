class BillItem {
  final int? id;
  final int serviceId;
  final String serviceName;
  final double unitPrice;
  final int quantity;
  final double lineTotal;

  BillItem({
    this.id,
    required this.serviceId,
    required this.serviceName,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      id: json['id'],
      serviceId: json['serviceId'] ?? 0,
      serviceName: json['serviceName'] ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'lineTotal': lineTotal,
    };
  }
}

class Bill {
  final int id;
  final String billNumber;
  final double subtotal;
  final String? discountCode;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final String paymentMethod;
  final String status;
  final String createdAt;
  final String? customerName;
  final String? customerPhone;
  final String? staffName;
  final String? branchName;
  final List<BillItem> items;

  Bill({
    required this.id,
    required this.billNumber,
    required this.subtotal,
    this.discountCode,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.customerName,
    this.customerPhone,
    this.staffName,
    this.branchName,
    required this.items,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List?;
    List<BillItem> billItems = list != null
        ? list.map((i) => BillItem.fromJson(i)).toList()
        : [];

    return Bill(
      id: json['id'] ?? 0,
      billNumber: json['billNumber'] ?? '',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountCode: json['discountCode'],
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['createdAt'] ?? '',
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      staffName: json['staffName'],
      branchName: json['branchName'],
      items: billItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'billNumber': billNumber,
      'subtotal': subtotal,
      'discountCode': discountCode,
      'discountAmount': discountAmount,
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'status': status,
      'createdAt': createdAt,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'staffName': staffName,
      'branchName': branchName,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}
