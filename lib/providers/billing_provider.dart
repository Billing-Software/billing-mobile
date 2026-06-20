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
  String _paymentMethod = 'Cash';

  List<BillItem> get cart => _cart;
  int? get selectedBranchId => _selectedBranchId;
  int? get selectedCustomerId => _selectedCustomerId;
  String get discountCode => _discountCode;
  String get activeDiscountCode => _activeDiscountCode;
  double get activeDiscountPercent => _activeDiscountPercent;
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
    _activeDiscountCode = 'VIP10';
    _activeDiscountPercent = 10.0;
    _paymentMethod = 'Cash';
    notifyListeners();
  }

  // Calculations
  double get subtotal => _cart.fold(0.0, (sum, item) => sum + item.lineTotal);
  double get discountAmount => subtotal * (_activeDiscountPercent / 100.0);
  double get taxAmount => (subtotal - discountAmount) * 0.05; // 5% Flat CGST/SGST proxy
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
  }) async {
    if (_cart.isEmpty) {
      throw Exception("Please add services to the current bill first!");
    }

    final billNumber = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    
    final payload = {
      'branchId': branchId,
      'customerId': customerId,
      'createdByStaffId': null,
      'billNumber': billNumber,
      'subtotal': subtotal,
      'discountCode': _activeDiscountPercent > 0 ? _activeDiscountCode : null,
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
}
