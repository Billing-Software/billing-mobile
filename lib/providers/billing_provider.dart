import 'package:flutter/material.dart';
import '../models/bill.dart';
import '../models/service.dart';
import '../services/bill_service.dart';

class BillingProvider extends ChangeNotifier {
  final BillService _billService = BillService();

  final List<BillItem> _cart = [];
  int? _selectedBranchId;
  int? _selectedCustomerId;
  
  String _discountCode = '';
  String _activeDiscountCode = 'VIP10';
  double _activeDiscountPercent = 10.0;

  String _discountType = 'percentage'; // 'percentage' | 'flat'
  double _discountValue = 0.0;

  String _paymentMethod = 'Cash';

  List<BillItem> get cart => _cart;
  int? get selectedBranchId => _selectedBranchId;
  int? get selectedCustomerId => _selectedCustomerId;
  String get discountCode => _discountCode;
  String get activeDiscountCode => _activeDiscountCode;
  double get activeDiscountPercent => _activeDiscountPercent;
  String get discountType => _discountType;
  double get discountValue => _discountValue;
  String get paymentMethod => _paymentMethod;

  void selectBranch(int? id) {
    _selectedBranchId = id;
    notifyListeners();
  }

  void selectCustomer(int? id) {
    _selectedCustomerId = id;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void setDiscountCodeText(String code) {
    _discountCode = code;
    notifyListeners();
  }

  void setDiscount(String type, double value) {
    _discountType = type;
    _discountValue = value;
    if (_discountType == 'percentage') {
      _activeDiscountPercent = _discountValue;
      _activeDiscountCode = _discountValue > 0 ? 'CUSTOM-${_discountValue.toStringAsFixed(0)}%' : 'NONE';
    } else {
      _activeDiscountPercent = 0.0;
      _activeDiscountCode = _discountValue > 0 ? 'FLAT ₹${_discountValue.toStringAsFixed(0)}' : 'NONE';
    }
    notifyListeners();
  }

  void updateUnitPrice(int serviceId, double newPrice) {
    int index = _cart.indexWhere((item) => item.serviceId == serviceId);
    if (index != -1) {
      final old = _cart[index];
      _cart[index] = BillItem(
        serviceId: old.serviceId,
        serviceName: old.serviceName,
        unitPrice: newPrice,
        quantity: old.quantity,
        lineTotal: old.quantity * newPrice,
      );
      notifyListeners();
    }
  }

  void addService(Service service) {
    int index = _cart.indexWhere((item) => item.serviceId == service.id);
    if (index != -1) {
      final old = _cart[index];
      final newQty = old.quantity + 1;
      _cart[index] = BillItem(
        serviceId: old.serviceId,
        serviceName: old.serviceName,
        unitPrice: old.unitPrice,
        quantity: newQty,
        lineTotal: newQty * old.unitPrice,
      );
    } else {
      _cart.add(BillItem(
        serviceId: service.id,
        serviceName: service.name,
        unitPrice: service.basePrice,
        quantity: 1,
        lineTotal: service.basePrice,
      ));
    }
    notifyListeners();
  }

  void updateQuantity(int serviceId, int delta) {
    int index = _cart.indexWhere((item) => item.serviceId == serviceId);
    if (index != -1) {
      final old = _cart[index];
      final newQty = old.quantity + delta;
      if (newQty > 0) {
        _cart[index] = BillItem(
          serviceId: old.serviceId,
          serviceName: old.serviceName,
          unitPrice: old.unitPrice,
          quantity: newQty,
          lineTotal: newQty * old.unitPrice,
        );
      } else {
        _cart.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeItem(int serviceId) {
    _cart.removeWhere((item) => item.serviceId == serviceId);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _discountCode = '';
    _activeDiscountCode = 'NONE';
    _activeDiscountPercent = 0.0;
    _discountType = 'percentage';
    _discountValue = 0.0;
    _paymentMethod = 'Cash';
    notifyListeners();
  }

  // Calculations
  double get subtotal => _cart.fold(0.0, (sum, item) => sum + item.lineTotal);
  double get discountAmount {
    if (_discountType == 'percentage') {
      return subtotal * (_discountValue / 100.0);
    } else {
      return _discountValue;
    }
  }
  double get taxAmount => 0.0;
  double get totalAmount => subtotal - discountAmount + taxAmount < 0.0 ? 0.0 : subtotal - discountAmount + taxAmount;

  String applyPromo(String code) {
    String message = '';
    final codeUpper = code.trim().toUpperCase();
    if (codeUpper == 'VIP10') {
      _activeDiscountCode = 'VIP10';
      _activeDiscountPercent = 10.0;
      message = "Promo 'VIP10' applied! 10% Discount included.";
    } else if (codeUpper.endsWith('%')) {
      final percentStr = codeUpper.replaceAll('%', '');
      final percentVal = double.tryParse(percentStr);
      if (percentVal != null && percentVal >= 0 && percentVal <= 100) {
        _activeDiscountCode = 'CUSTOM-$percentStr%';
        _activeDiscountPercent = percentVal;
        message = "Custom $percentStr% promo rate injected!";
      } else {
        _activeDiscountCode = 'CUSTOM';
        _activeDiscountPercent = 5.0;
        message = "Custom coupon registered: 5% flat discount activated!";
      }
    } else {
      _activeDiscountCode = 'CUSTOM';
      _activeDiscountPercent = 5.0;
      message = "Custom coupon registered: 5% flat discount activated!";
    }
    _discountCode = '';
    notifyListeners();
    return message;
  }

  Future<Bill> checkout({
    required int branchId,
    required int customerId,
    required String customerName,
    required String customerPhone,
    int? createdByStaffId,
  }) async {
    if (_cart.isEmpty) {
      throw Exception("Please add services to the current bill first!");
    }

    final billNumber = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    
    final payload = {
      'branchId': branchId,
      'customerId': customerId,
      'createdByStaffId': createdByStaffId,
      'billNumber': billNumber,
      'subtotal': subtotal,
      'discountCode': _discountValue > 0 ? _activeDiscountCode : null,
      'discountAmount': discountAmount,
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
      'paymentMethod': _paymentMethod,
      'status': 'Paid',
      'items': _cart.map((item) => {
        'serviceId': item.serviceId,
        'serviceName': item.serviceName,
        'unitPrice': item.unitPrice,
        'quantity': item.quantity,
        'lineTotal': item.lineTotal,
      }).toList()
    };

    final createdBill = await _billService.create(payload);
    
    // Construct local Bill with correct Names for HUD/popup rendering
    final mappedBill = Bill(
      id: createdBill.id,
      customerId: customerId,
      billNumber: createdBill.billNumber,
      subtotal: createdBill.subtotal,
      discountCode: createdBill.discountCode,
      discountAmount: createdBill.discountAmount,
      taxAmount: createdBill.taxAmount,
      totalAmount: createdBill.totalAmount,
      paymentMethod: createdBill.paymentMethod,
      status: createdBill.status,
      createdAt: createdBill.createdAt,
      customerName: customerName,
      customerPhone: customerPhone,
      items: createdBill.items,
    );

    clearCart();
    return mappedBill;
  }

  int _refreshTrigger = 0;
  int get refreshTrigger => _refreshTrigger;
  void triggerRefresh() {
    _refreshTrigger++;
    notifyListeners();
  }
}
