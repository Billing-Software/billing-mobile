import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/bill.dart';
import '../models/customer.dart';
import '../models/staff.dart';
import '../services/bill_service.dart';
import '../services/customer_service.dart';
import '../services/staff_service.dart';
import '../providers/auth_provider.dart';
import '../providers/bluetooth_printer_provider.dart';
import '../services/bluetooth_printer_service.dart';

class InvoicesHistoryScreen extends StatefulWidget {
  const InvoicesHistoryScreen({Key? key}) : super(key: key);

  @override
  State<InvoicesHistoryScreen> createState() => _InvoicesHistoryScreenState();
}

class _InvoicesHistoryScreenState extends State<InvoicesHistoryScreen> {
  final BillService _billService = BillService();
  final CustomerService _customerService = CustomerService();
  final StaffService _staffService = StaffService();

  List<Bill> _bills = [];
  List<Customer> _customers = [];
  List<StaffMember> _staffList = [];
  bool _isLoading = true;

  // Filter States
  Customer? _selectedCustomer;
  StaffMember? _selectedStaff;
  DateTimeRange? _selectedDateRange;
  String? _selectedStatus;
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  List<Bill> _filteredBills = [];

  void _updateFilteredData() {
    _filteredBills = _bills.where((b) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return b.billNumber.toLowerCase().contains(q) ||
          (b.customerName ?? '').toLowerCase().contains(q) ||
          (b.customerPhone ?? '').contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadFiltersAndData();
  }

  Future<void> _loadFiltersAndData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isOwner = authProvider.currentUser?.role == 'Owner';

      final custs = await _customerService.getAll();
      setState(() {
        _customers = custs;
      });

      if (isOwner) {
        final staff = await _staffService.getAll();
        setState(() {
          _staffList = staff;
        });
      }
      await _fetchBills();
    } catch (e) {
      _showSnackBar('Error loading filters: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchBills() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isOwner = authProvider.currentUser?.role == 'Owner';

      final Map<String, dynamic> filters = {};

      if (_selectedCustomer != null) {
        filters['customerId'] = _selectedCustomer!.id;
      }

      if (!isOwner && authProvider.currentUser?.staffId != null) {
        filters['staffId'] = authProvider.currentUser!.staffId;
      } else if (_selectedStaff != null) {
        filters['staffId'] = _selectedStaff!.id;
      }

      if (_selectedDateRange != null) {
        filters['startDate'] = _selectedDateRange!.start.toUtc().toIso8601String();
        filters['endDate'] = _selectedDateRange!.end.add(const Duration(hours: 23, minutes: 59, seconds: 59)).toUtc().toIso8601String();
      }

      if (_selectedStatus != null) {
        filters['status'] = _selectedStatus;
      }

      if (_minAmountController.text.isNotEmpty) {
        filters['minAmount'] = double.tryParse(_minAmountController.text);
      }

      if (_maxAmountController.text.isNotEmpty) {
        filters['maxAmount'] = double.tryParse(_maxAmountController.text);
      }

      final data = await _billService.getAll(filters: filters);
      setState(() {
        _bills = data;
        _updateFilteredData();
      });
    } catch (e) {
      _showSnackBar('Error loading invoices: $e', isError: true);
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCustomer = null;
      _selectedStaff = null;
      _selectedDateRange = null;
      _selectedStatus = null;
      _minAmountController.clear();
      _maxAmountController.clear();
      _searchController.clear();
      _searchQuery = '';
    });
    _fetchBills();
    _showSnackBar('Filters reset successfully');
  }

  Future<void> _deleteBill(Bill bill) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Invoice', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to permanently delete invoice ${bill.billNumber}? This action is irreversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBA1A1A)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _billService.delete(bill.id);
        _showSnackBar('Invoice ${bill.billNumber} deleted successfully');
        await _fetchBills();
      } catch (e) {
        _showSnackBar('Delete failed: $e', isError: true);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
        backgroundColor: isError ? const Color(0xFFBA1A1A) : const Color(0xFF006A61),
      ),
    );
  }

  void _openFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final isOwner = authProvider.currentUser?.role == 'Owner';

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Advanced Search Filters',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0B1C30)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Customer drop-down
                    Text('Customer CRM', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF7C839B))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<Customer>(
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Color(0xFFF3F4F6),
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      value: _selectedCustomer,
                      hint: const Text('Select Customer'),
                      items: _customers.map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.name, style: GoogleFonts.inter(fontSize: 13)),
                      )).toList(),
                      onChanged: (val) {
                        setModalState(() => _selectedCustomer = val);
                        setState(() => _selectedCustomer = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Staff selector (Owner only)
                    if (isOwner) ...[
                      Text('Billed By Staff', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF7C839B))),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<StaffMember>(
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Color(0xFFF3F4F6),
                          border: OutlineInputBorder(borderSide: BorderSide.none),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        value: _selectedStaff,
                        hint: const Text('Select Staff'),
                        items: _staffList.map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.name, style: GoogleFonts.inter(fontSize: 13)),
                        )).toList(),
                        onChanged: (val) {
                          setModalState(() => _selectedStaff = val);
                          setState(() => _selectedStaff = val);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Date range picker
                    Text('Date Range Filter', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF7C839B))),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.centerLeft,
                      ),
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2030),
                          initialDateRange: _selectedDateRange,
                        );
                        if (picked != null) {
                          setModalState(() => _selectedDateRange = picked);
                          setState(() => _selectedDateRange = picked);
                        }
                      },
                      icon: const Icon(Icons.date_range, size: 16, color: Color(0xFF006A61)),
                      label: Text(
                        _selectedDateRange == null
                            ? 'All Dates'
                            : '${DateFormat.yMMMd().format(_selectedDateRange!.start)} - ${DateFormat.yMMMd().format(_selectedDateRange!.end)}',
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0B1C30)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status Segment
                    Text('Payment Status', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF7C839B))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatusChip(setModalState, 'Paid'),
                        const SizedBox(width: 8),
                        _buildStatusChip(setModalState, 'Unpaid'),
                        const SizedBox(width: 8),
                        _buildStatusChip(setModalState, null), // All
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Amount ranges
                    Text('Grand Total Range (₹)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF7C839B))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minAmountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Min Amount',
                              filled: true,
                              fillColor: Color(0xFFF3F4F6),
                              border: OutlineInputBorder(borderSide: BorderSide.none),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _maxAmountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Max Amount',
                              filled: true,
                              fillColor: Color(0xFFF3F4F6),
                              border: OutlineInputBorder(borderSide: BorderSide.none),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _clearFilters();
                              Navigator.of(context).pop();
                            },
                            child: const Text('Reset All'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF006A61),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              _fetchBills();
                              Navigator.of(context).pop();
                            },
                            child: const Text('Apply Filters'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(StateSetter setModalState, String? val) {
    final isSelected = _selectedStatus == val;
    return ChoiceChip(
      label: Text(val ?? 'ALL STATUSES', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
      selected: isSelected,
      selectedColor: const Color(0xFF86F2E4).withValues(alpha: 0.3),
      onSelected: (selected) {
        if (selected) {
          setModalState(() => _selectedStatus = val);
          setState(() => _selectedStatus = val);
        }
      },
    );
  }

  void _showReceiptDialog(Bill bill) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 340),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Receipt Preview', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),

                // Receipt Scroll Body
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          bill.branchName ?? 'BillCom',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF006A61)),
                        ),
                        Text(
                          'POS TRANSACTION INVOICE',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFF7C839B)),
                        ),
                        const SizedBox(height: 12),

                        // Invoicing Context
                        _buildReceiptRow('Invoice #', bill.billNumber, bold: true),
                        _buildReceiptRow('Billed Date', DateFormat.yMMMd().add_jm().format(DateTime.tryParse(bill.createdAt) ?? DateTime.now())),
                        _buildReceiptRow('Billed By', bill.staffName ?? 'Owner'),
                        _buildReceiptRow('Customer', bill.customerName ?? 'Walk-In Customer'),
                        _buildReceiptRow('Phone', bill.customerPhone ?? 'N/A'),
                        const SizedBox(height: 8),
                        const Divider(height: 1, color: Colors.grey),
                        const SizedBox(height: 8),

                        // Items list
                        Text('SERVICES / PRODUCTS', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF7C839B))),
                        const SizedBox(height: 4),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: bill.items.length,
                          itemBuilder: (c, idx) {
                            final it = bill.items[idx];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${it.serviceName} x${it.quantity}',
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Text(
                                    '₹${NumberFormat('#,##,###').format(it.lineTotal)}',
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1, color: Colors.grey),
                        const SizedBox(height: 8),

                        // Subtotal
                        _buildReceiptRow('Subtotal', '₹${NumberFormat('#,##,###').format(bill.subtotal)}'),
                        if (bill.discountAmount > 0)
                          _buildReceiptRow('Promo Discount (${bill.discountCode})', '-₹${NumberFormat('#,##,###').format(bill.discountAmount)}', color: const Color(0xFF006A61)),
                        _buildReceiptRow('Taxes (5% Flat)', '₹${NumberFormat('#,##,###').format(bill.taxAmount)}'),
                        const Divider(height: 8),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Grand Total', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF006A61))),
                            Text('₹${NumberFormat('#,##,###').format(bill.totalAmount)}', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF006A61))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Payment Method: ${bill.paymentMethod}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0B1C30)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Footer print actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006A61),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          final printerProvider = Provider.of<BluetoothPrinterProvider>(context, listen: false);
                          if (printerProvider.connectionState == PrinterConnectionState.connected) {
                            await printerProvider.printBill(bill, businessName: bill.branchName ?? 'BillCom');
                          } else {
                            final success = await printerProvider.autoDetectAndConnect();
                            if (success) {
                              await printerProvider.printBill(bill, businessName: bill.branchName ?? 'BillCom');
                            } else {
                              _showSnackBar('No paired Bluetooth thermal billing printer found.', isError: true);
                            }
                          }
                          Navigator.of(ctx).pop();
                        },
                        icon: const Icon(Icons.print, size: 14),
                        label: const Text('Print'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF7C839B), fontWeight: FontWeight.w500)),
          Text(value, style: GoogleFonts.inter(fontSize: 11, color: color ?? const Color(0xFF0B1C30), fontWeight: bold ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isOwner = authProvider.currentUser?.role == 'Owner';

    final filtered = _filteredBills;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text(
          'Invoice History',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilterDialog,
          ),
          if (_selectedCustomer != null || _selectedStaff != null || _selectedDateRange != null || _selectedStatus != null || _minAmountController.text.isNotEmpty || _maxAmountController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.filter_list_off, color: Color(0xFFBA1A1A)),
              onPressed: _clearFilters,
            ),
        ],
      ),
      body: Column(
        children: [
          // Search input panel
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                  _updateFilteredData();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by Invoice No, Name, or Phone...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF006A61)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          // Total counts summary
          if (filtered.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${filtered.length} invoices',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF7C839B), fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Total Amount: ₹${NumberFormat('#,##,###').format(filtered.fold(0.0, (sum, b) => sum + b.totalAmount))}',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF006A61), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

          // List body
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF006A61)))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text('No invoices recorded.', style: GoogleFonts.inter(color: Colors.grey)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchBills,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final bill = filtered[index];
                            final time = DateTime.tryParse(bill.createdAt) ?? DateTime.now();

                            return Card(
                              color: Colors.white,
                              margin: const EdgeInsets.symmetric(vertical: 6.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              elevation: 0,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      bill.billNumber,
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF006A61), fontSize: 14),
                                    ),
                                    Text(
                                      '₹${NumberFormat('#,##,###').format(bill.totalAmount)}',
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF0B1C30), fontSize: 14),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      '${bill.customerName ?? 'Walk-In Customer'} • ${DateFormat.yMMMd().format(time)}',
                                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF45464D), fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Billed By: ${bill.staffName ?? 'Owner'}',
                                          style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF7C839B), fontWeight: FontWeight.bold),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: bill.status == 'Paid' ? const Color(0xFFE8F5F3) : const Color(0xFFFFF7ED),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            bill.status.toUpperCase(),
                                            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: bill.status == 'Paid' ? const Color(0xFF006A61) : const Color(0xFFC2410C)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () => _showReceiptDialog(bill),
                                trailing: isOwner
                                    ? IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Color(0xFFBA1A1A), size: 20),
                                        onPressed: () => _deleteBill(bill),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
