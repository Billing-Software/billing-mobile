import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../models/bill.dart';
import '../services/customer_service.dart';
import '../services/bill_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/confirm_sheet.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({Key? key}) : super(key: key);

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final CustomerService _customerService = CustomerService();
  final BillService _billService = BillService();
  List<Customer> _customers = [];
  List<Bill> _bills = [];
  bool _isLoading = true;
  String _searchQuery = '';

  List<Customer> _filteredCustomers = [];

  void _updateFilteredData() {
    _filteredCustomers = _customers.where((c) {
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.phone.contains(_searchQuery) ||
          (c.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final results = await Future.wait([
        _customerService.getAll(),
        _billService.getAll(),
      ]);
      if (!mounted) return;
      setState(() {
        _customers = results[0] as List<Customer>;
        _bills = results[1] as List<Bill>;
        _isLoading = false;
        _updateFilteredData();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load customers/ledger: $e')),
      );
    }
  }

  void _showAddEditCustomerBottomSheet({Customer? customer}) {
    final isEdit = customer != null;
    final nameController = TextEditingController(text: customer?.name ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    final emailController = TextEditingController(text: customer?.email ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setBottomSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC6C6CD),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEdit ? 'Modify CRM Record' : 'Enroll New Client',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: const Color(0xFF0B1C30),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomTextField(
                          controller: nameController,
                          label: 'Customer Name *',
                          placeholder: 'e.g. John Doe',
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: phoneController,
                          label: 'Contact Phone',
                          placeholder: 'e.g. 9876543210',
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: emailController,
                          label: 'Email (Optional)',
                          placeholder: 'e.g. john@business.com',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006A61),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            final name = nameController.text.trim();
                            final phone = phoneController.text.trim();
                            final email = emailController.text.trim();
                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter customer name')),
                              );
                              return;
                            }

                            final payload = {
                              'name': name,
                              'phone': phone.isNotEmpty ? phone : 'N/A',
                              'email': email.isNotEmpty ? email : null,
                              'isWalkIn': customer?.isWalkIn ?? false,
                            };

                            try {
                              if (isEdit) {
                                await _customerService.update(customer.id, payload);
                              } else {
                                await _customerService.create(payload);
                              }
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                              _fetchCustomers();
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Operation failed: $e')),
                                );
                              }
                            }
                          },
                          child: Text(
                            isEdit ? 'Save Changes' : 'Establish Profile',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteCustomer(int id) async {
    final confirm = await ConfirmSheet.show(
      context: context,
      title: 'Delete Client Profile?',
      message: 'This action will permanently wipe this customer profile and cannot be undone.',
      confirmText: 'Remove',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirm == true) {
      try {
        await _customerService.delete(id);
        _fetchCustomers();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  void _showLedgerBottomSheet(Customer customer) {
    final customerBills = _bills.where((b) => b.customerId == customer.id).toList();
    final double outstandingDues = customerBills
        .where((b) => b.status.toLowerCase() != 'paid')
        .fold(0.0, (sum, b) => sum + b.totalAmount);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Grab handle
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC6C6CD),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer Ledger',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0B1C30),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Account history for ${customer.name}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF7C839B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Info and Dues Banner
                        Row(
                          children: [
                            // Contact info box
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FF),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CONTACT INFO',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF7C839B),
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      customer.phone,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0B1C30),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      customer.email ?? 'No email registered',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: const Color(0xFF45464D),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Dues box
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: outstandingDues > 0
                                      ? const Color(0xFFFFDAD6).withOpacity(0.4)
                                      : const Color(0xFFE8F5E9).withOpacity(0.4),
                                  border: Border.all(
                                    color: outstandingDues > 0
                                        ? const Color(0xFFFFDAD6)
                                        : const Color(0xFFE8F5E9),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'OUTSTANDING DUES',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: outstandingDues > 0
                                            ? const Color(0xFFBA1A1A)
                                            : const Color(0xFF2E7D32),
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${outstandingDues.toStringAsFixed(0)}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: outstandingDues > 0
                                            ? const Color(0xFFBA1A1A)
                                            : const Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'INVOICES & PAYMENTS HISTORY',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0B1C30),
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (customerBills.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'No invoices recorded for this customer yet.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF7C839B),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: customerBills.length,
                            separatorBuilder: (c, idx) => const SizedBox(height: 8),
                            itemBuilder: (ctx, idx) {
                              final bill = customerBills[idx];
                              final isPaid = bill.status.toLowerCase() == 'paid';
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                bill.billNumber,
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF0B1C30),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isPaid
                                                      ? const Color(0xFFE8F5E9)
                                                      : const Color(0xFFFFDAD6),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  bill.status.toUpperCase(),
                                                  style: GoogleFonts.inter(
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.bold,
                                                    color: isPaid
                                                        ? const Color(0xFF2E7D32)
                                                        : const Color(0xFFBA1A1A),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Date: ${bill.createdAt.replaceAll('T', ' ').substring(0, 10)}  •  Mode: ${bill.paymentMethod.toUpperCase()}',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: const Color(0xFF7C839B),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '₹${bill.totalAmount.toStringAsFixed(0)}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF0B1C30),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCustomers;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text('Customer CRM', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'customer_fab',
        backgroundColor: const Color(0xFF006A61),
        foregroundColor: Colors.white,
        onPressed: () => _showAddEditCustomerBottomSheet(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF006A61)))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        child: TextField(
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                              _updateFilteredData();
                            });
                          },
                          textInputAction: TextInputAction.search,
                          autocorrect: false,
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search customers by name, phone or email...',
                            hintStyle: GoogleFonts.inter(color: const Color(0x997C839B), fontSize: 13),
                            prefixIcon: const Icon(Icons.search, size: 20),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFC6C6CD)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF006A61), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'No customer profiles found.',
                                  style: GoogleFonts.inter(color: const Color(0xFF7C839B), fontWeight: FontWeight.bold),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                itemCount: filtered.length,
                                separatorBuilder: (c, i) => const SizedBox(height: 8),
                                itemBuilder: (ctx, idx) {
                                  final customer = filtered[idx];
                                  return Card(
                                    color: Colors.white,
                                    elevation: 1,
                                    margin: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                      visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
                                      leading: CircleAvatar(
                                        backgroundColor: const Color(0xFFEFF4FF),
                                        child: Text(
                                          customer.name.substring(0, 1).toUpperCase(),
                                          style: GoogleFonts.outfit(color: const Color(0xFF006A61), fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      title: Text(
                                        customer.name,
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF0B1C30), fontSize: 13),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 2),
                                          Text('Contact: ${customer.phone}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF45464D))),
                                          if (customer.email != null && customer.email!.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text('Email: ${customer.email}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF7C839B))),
                                          ],
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            icon: const Icon(Icons.receipt_long_outlined, color: Color(0xFF006A61), size: 18),
                                            tooltip: 'View Ledger',
                                            onPressed: () => _showLedgerBottomSheet(customer),
                                          ),
                                          if (!customer.isWalkIn) ...[
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                              icon: const Icon(Icons.edit_outlined, color: Color(0xFF006A61), size: 18),
                                              onPressed: () => _showAddEditCustomerBottomSheet(customer: customer),
                                            ),
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                              icon: const Icon(Icons.delete_outline, color: Color(0xFFBA1A1A), size: 18),
                                              onPressed: () => _deleteCustomer(customer.id),
                                            ),
                                          ] else ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEFF4FF),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'System Walk-in',
                                                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF006A61)),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                  ],
                ),
              ),
            ),
        ),
    );
  }
}
