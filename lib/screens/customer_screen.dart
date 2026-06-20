import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../widgets/sidebar_drawer.dart';
import '../widgets/custom_text_field.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({Key? key}) : super(key: key);

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final CustomerService _customerService = CustomerService();
  List<Customer> _customers = [];
  bool _isLoading = true;
  String _searchQuery = '';

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
      final list = await _customerService.getAll();
      if (!mounted) return;
      setState(() {
        _customers = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load customers: $e')),
      );
    }
  }

  void _showAddEditDialog({Customer? customer}) {
    final isEdit = customer != null;
    final nameController = TextEditingController(text: customer?.name ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    final emailController = TextEditingController(text: customer?.email ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isEdit ? 'Modify CRM Record' : 'Enroll New Client',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: nameController,
              label: 'Name',
              placeholder: 'e.g. John Doe',
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: phoneController,
              label: 'Contact Phone',
              placeholder: 'e.g. 9876543210',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: emailController,
              label: 'Email (Optional)',
              placeholder: 'e.g. john@business.com',
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF7C839B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006A61), foregroundColor: Colors.white),
            onPressed: () async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              final email = emailController.text.trim();
              if (name.isEmpty || phone.isEmpty) return;

              final payload = {
                'name': name,
                'phone': phone,
                'email': email.isNotEmpty ? email : null,
                'isWalkIn': customer?.isWalkIn ?? false,
              };

              try {
                if (isEdit) {
                  await _customerService.update(customer.id, payload);
                } else {
                  await _customerService.create(payload);
                }
                Navigator.pop(ctx);
                _fetchCustomers();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Operation failed: $e')),
                );
              }
            },
            child: Text(isEdit ? 'Save Changes' : 'Establish Profile'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCustomer(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Client Profile?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('This action will permanently wipe this customer profile and cannot be undone.', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.inter())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBA1A1A), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove', style: GoogleFonts.inter()),
          ),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    final filtered = _customers.where((c) {
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.phone.contains(_searchQuery) ||
          (c.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text('Customer CRM', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchCustomers),
        ],
      ),
      drawer: const SidebarDrawer(activeRoute: '/customers'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF006A61),
        foregroundColor: Colors.white,
        onPressed: () => _showAddEditDialog(),
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
                          });
                        },
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
                                        if (!customer.isWalkIn) ...[
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            icon: const Icon(Icons.edit_outlined, color: Color(0xFF006A61), size: 18),
                                            onPressed: () => _showAddEditDialog(customer: customer),
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
    );
  }
}
