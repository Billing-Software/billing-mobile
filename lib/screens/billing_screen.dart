import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/billing_provider.dart';
import '../models/service.dart';
import '../models/customer.dart';
import '../services/service_catalog_service.dart';
import '../services/customer_service.dart';
import '../services/branch_service.dart';
import '../widgets/sidebar_drawer.dart';
import '../widgets/custom_text_field.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({Key? key}) : super(key: key);

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final ServiceCatalogService _serviceService = ServiceCatalogService();
  final CustomerService _customerService = CustomerService();
  final BranchService _branchService = BranchService();

  List<Service> _services = [];
  List<Customer> _customers = [];
  List<Map<String, dynamic>> _branches = [];
  bool _isLoading = true;

  String _selectedCategory = 'All';
  String _serviceQuery = '';
  String _customerQuery = '';

  // Form state to add customer
  bool _isAddingCustomer = false;
  final _newCustNameController = TextEditingController();
  final _newCustPhoneController = TextEditingController();

  final _promoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final billingProvider = Provider.of<BillingProvider>(context, listen: false);

      final List<dynamic> results = await Future.wait([
        _serviceService.getAll(),
        _customerService.getAll(),
        _branchService.getAll(),
      ]);

      if (!mounted) return;
      setState(() {
        _services = results[0] as List<Service>;
        _customers = results[1] as List<Customer>;
        _branches = results[2] as List<Map<String, dynamic>>;
      });

      // Find default customer (Walk-In)
      Customer? walkIn;
      try {
        walkIn = _customers.firstWhere((c) => c.isWalkIn);
      } catch (_) {
        if (_customers.isNotEmpty) {
          walkIn = _customers.first;
        } else {
          walkIn = Customer(id: 0, name: 'Walk-In Customer', phone: 'N/A', isWalkIn: true);
        }
      }
      
      billingProvider.selectCustomer(walkIn.id);

      // Find matching branch
      if (_branches.isNotEmpty) {
        final currentBranchName = authProvider.currentBranch;
        Map<String, dynamic>? matched;
        try {
          matched = _branches.firstWhere(
            (b) => b['name'].toString().toLowerCase().contains(currentBranchName.toLowerCase()),
          );
        } catch (_) {
          matched = _branches.first;
        }
        billingProvider.selectBranch(matched['id']);
      }
    } catch (e) {
      debugPrint('Error fetching POS data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _newCustNameController.dispose();
    _newCustPhoneController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _createNewCustomer() async {
    final name = _newCustNameController.text.trim();
    final phone = _newCustPhoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) return;

    try {
      final cust = await _customerService.create({
        'name': name,
        'phone': phone,
        'isWalkIn': false,
      });

      setState(() {
        _customers.add(cust);
        _isAddingCustomer = false;
        _newCustNameController.clear();
        _newCustPhoneController.clear();
      });

      if (mounted) {
        Provider.of<BillingProvider>(context, listen: false).selectCustomer(cust.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Customer ${cust.name} selected.')),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Error'),
            content: Text('Could not create customer: $e'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      }
    }
  }

  Widget _buildCategoryIcon(String iconName) {
    switch (iconName) {
      case 'content_cut':
        return const Text('✂️', style: TextStyle(fontSize: 20));
      case 'face':
        return const Text('👤', style: TextStyle(fontSize: 20));
      case 'spa':
        return const Text('🌸', style: TextStyle(fontSize: 20));
      case 'brush':
        return const Text('🎨', style: TextStyle(fontSize: 20));
      case 'water_drop':
        return const Text('💧', style: TextStyle(fontSize: 20));
      default:
        return const Text('📦', style: TextStyle(fontSize: 20));
    }
  }

  @override
  Widget build(BuildContext context) {
    final billingProvider = Provider.of<BillingProvider>(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Billing POS')),
        drawer: const SidebarDrawer(activeRoute: '/billing'),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF006A61)),
              SizedBox(height: 12),
              Text(
                'Synchronizing POS Terminals...',
                style: TextStyle(
                  color: Color(0xFF7C839B),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final categories = ['All', ..._services.where((s) => s.status == 'Active').map((s) => s.category).toSet().toList()];

    final filteredServices = _services.where((s) {
      if (s.status != 'Active') return false;
      final matchesCategory = _selectedCategory == 'All' || s.category == _selectedCategory;
      final matchesQuery = s.name.toLowerCase().contains(_serviceQuery.toLowerCase()) ||
          s.sku.toLowerCase().contains(_serviceQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();

    final filteredCustomers = _customers.where((c) {
      return c.name.toLowerCase().contains(_customerQuery.toLowerCase()) ||
          c.phone.contains(_customerQuery);
    }).toList();

    Customer currentSelectedCustomer;
    try {
      currentSelectedCustomer = _customers.firstWhere(
        (c) => c.id == billingProvider.selectedCustomerId,
      );
    } catch (_) {
      if (_customers.isNotEmpty) {
        currentSelectedCustomer = _customers.first;
      } else {
        currentSelectedCustomer = Customer(id: 0, name: 'Walk-In Customer', phone: 'N/A', isWalkIn: true);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text(
          'Billing POS',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
        ),
        bottom: MediaQuery.of(context).size.width > 900
            ? null
            : TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF006A61),
                unselectedLabelColor: const Color(0xFF7C839B),
                indicatorColor: const Color(0xFF006A61),
                tabs: [
                  const Tab(icon: Icon(Icons.grid_view), text: 'Services'),
                  Tab(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.shopping_cart),
                        if (billingProvider.cart.isNotEmpty)
                          Positioned(
                            right: -10,
                            top: -10,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFBA1A1A),
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              child: Text(
                                '${billingProvider.cart.fold(0, (sum, item) => sum + item.quantity)}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                    text: 'Checkout (₹${NumberFormat('#,##,###').format(billingProvider.totalAmount)})',
                  ),
                ],
              ),
      ),
      drawer: const SidebarDrawer(activeRoute: '/billing'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          if (width > 900) {
            // Desktop side-by-side split layout
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Panel: Catalog
                Expanded(
                  flex: 8,
                  child: Column(
                    children: [
                      // Customer Selection Header Panel
                      _buildCustomerSelectPanel(billingProvider, filteredCustomers, currentSelectedCustomer),

                      // Service search filter bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0), // Shrank from 8.0
                        child: TextField(
                          onChanged: (val) {
                            setState(() {
                              _serviceQuery = val;
                            });
                          },
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Filter services by name or SKU...',
                            hintStyle: GoogleFonts.inter(color: const Color(0x997C839B), fontSize: 13),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF7C839B)),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Color(0xFFC6C6CD), width: 1.0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Color(0xFF006A61), width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),

                      // Category chips list
                      Container(
                        height: 40, // Shrank from 48
                        padding: const EdgeInsets.symmetric(vertical: 4.0), // Shrank from 6.0
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            final isSelected = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: ChoiceChip(
                                label: Text(
                                  cat,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : const Color(0xFF45464D),
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: const Color(0xFF006A61),
                                backgroundColor: const Color(0xFFEFF4FF),
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategory = cat;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const Divider(height: 1),

                      // Services Grid View
                      Expanded(
                        child: filteredServices.isEmpty
                            ? const Center(
                                child: Text(
                                  'No services found.',
                                  style: TextStyle(color: Color(0xFF7C839B), fontWeight: FontWeight.bold),
                                ),
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.all(12),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 1.25,
                                ),
                                itemCount: filteredServices.length,
                                itemBuilder: (context, index) {
                                  final service = filteredServices[index];
                                  return Card(
                                    color: Colors.white,
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        billingProvider.addService(service);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${service.name} added to cart.'),
                                            duration: const Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFEFF4FF),
                                                shape: BoxShape.circle,
                                              ),
                                              child: _buildCategoryIcon(service.iconName),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              service.name,
                                              maxLines: 2,
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.outfit(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF0B1C30),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '₹${NumberFormat('#,##,###').format(service.basePrice)}',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w900,
                                                color: const Color(0xFF006A61),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
                // Right Panel: Checkout details
                Expanded(
                  flex: 4,
                  child: Container(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _buildCheckoutPanelItems(billingProvider, currentSelectedCustomer),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Mobile Tab-based layout
            return TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Catalog
                Column(
                  children: [
                    // Customer Selection Header Panel
                    _buildCustomerSelectPanel(billingProvider, filteredCustomers, currentSelectedCustomer),

                    // Service Search Filter Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: TextField(
                        onChanged: (val) {
                          setState(() {
                            _serviceQuery = val;
                          });
                        },
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Filter services by name or SKU...',
                          hintStyle: GoogleFonts.inter(color: const Color(0x997C839B), fontSize: 13),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF7C839B)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Color(0xFFC6C6CD), width: 1.0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Color(0xFF006A61), width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    // Category chips list
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final isSelected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ChoiceChip(
                              label: Text(
                                cat,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : const Color(0xFF45464D),
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: const Color(0xFF006A61),
                              backgroundColor: const Color(0xFFEFF4FF),
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = cat;
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),

                    // Services Grid View
                    Expanded(
                      child: filteredServices.isEmpty
                          ? const Center(
                              child: Text(
                                'No services found.',
                                style: TextStyle(color: Color(0xFF7C839B), fontWeight: FontWeight.bold),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 1.25,
                              ),
                              itemCount: filteredServices.length,
                              itemBuilder: (context, index) {
                                final service = filteredServices[index];
                                return Card(
                                  color: Colors.white,
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      billingProvider.addService(service);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${service.name} added to cart.'),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFEFF4FF),
                                              shape: BoxShape.circle,
                                            ),
                                            child: _buildCategoryIcon(service.iconName),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            service.name,
                                            maxLines: 2,
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.outfit(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF0B1C30),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '₹${NumberFormat('#,##,###').format(service.basePrice)}',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              color: const Color(0xFF006A61),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
                // Tab 2: Checkout details
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _buildCheckoutPanelItems(billingProvider, currentSelectedCustomer),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  List<Widget> _buildCheckoutPanelItems(
    BillingProvider billingProvider,
    Customer currentSelectedCustomer,
  ) {
    return [
        Row(
        children: [
          const Icon(Icons.receipt_outlined, color: Color(0xFF006A61)),
          const SizedBox(width: 8),
          Text(
            'Current Invoice Items',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0B1C30)),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '#INV-LIVE',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF45464D)),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
 
      // Selected client HUD
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF4FF).withValues(alpha: 0.6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.person, color: Color(0xFF7C839B), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Billing Client: ${currentSelectedCustomer.name} (${currentSelectedCustomer.phone})',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0B1C30)),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Items list
      if (billingProvider.cart.isEmpty)
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Column(
            children: [
              Icon(Icons.shopping_cart_outlined, size: 48, color: Color(0xFFC6C6CD)),
              SizedBox(height: 12),
              Text(
                'Your cart is currently empty.',
                style: TextStyle(fontSize: 13, color: Color(0xFF7C839B), fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Go back to Catalog to add items.',
                style: TextStyle(fontSize: 11, color: Color(0xFF7C839B)),
              ),
            ],
          ),
        )
      else
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: billingProvider.cart.length,
          separatorBuilder: (c, idx) => const SizedBox(height: 10),
          itemBuilder: (ctx, idx) {
            final item = billingProvider.cart[idx];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  // Quantity Controls
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF4FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          icon: const Icon(Icons.remove, size: 14, color: Color(0xFF006A61)),
                          onPressed: () => billingProvider.updateQuantity(item.serviceId, -1),
                        ),
                        Text(
                          '${item.quantity}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0B1C30),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          icon: const Icon(Icons.add, size: 14, color: Color(0xFF006A61)),
                          onPressed: () => billingProvider.updateQuantity(item.serviceId, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Service Name & Unit Price
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.serviceName,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0B1C30),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${NumberFormat('#,##,###').format(item.unitPrice)} each',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF7C839B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Total price
                  Text(
                    '₹${NumberFormat('#,##,###').format(item.lineTotal)}',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0B1C30),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete button
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFBA1A1A), size: 18),
                    onPressed: () => billingProvider.removeItem(item.serviceId),
                  ),
                ],
              ),
            );
          },
        ),
      const SizedBox(height: 12), // Shrank from 20

      // Calculations Panel
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            // Promo entry
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Enter Promo Code (e.g. VIP10)',
                      hintStyle: GoogleFonts.inter(color: const Color(0x997C839B), fontSize: 13),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFC6C6CD), width: 1.0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF006A61), width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEFF4FF),
                    foregroundColor: const Color(0xFF006A61),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onPressed: () {
                    final msg = billingProvider.applyPromo(_promoController.text);
                    _promoController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                  },
                  child: Text('Apply', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10), // Shrank from 16
            // Math stats
            _buildSummaryRow('Subtotal', '₹${NumberFormat('#,##,###').format(billingProvider.subtotal)}'),
            _buildSummaryRow(
              'Discount (${billingProvider.activeDiscountCode})',
              '-₹${NumberFormat('#,##,###').format(billingProvider.discountAmount)}',
              textColor: const Color(0xFF006A61),
            ),
            _buildSummaryRow('Tax (5% Flat Local)', '₹${NumberFormat('#,##,###').format(billingProvider.taxAmount)}'),
            const Divider(height: 12),
            // Grand Total
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF0B1C30)),
                  ),
                  Text(
                    '₹${NumberFormat('#,##,###').format(billingProvider.totalAmount)}',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: const Color(0xFF006A61)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12), // Shrank from 20
 
      // Payment Method
      Text(
        'PAYMENT METHOD',
        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF7C839B), letterSpacing: 1.0),
      ),
      const SizedBox(height: 6), // Shrank from 8
      Row(
        children: [
          _buildPaymentBtn(billingProvider, 'Cash', '💵'),
          const SizedBox(width: 8),
          _buildPaymentBtn(billingProvider, 'UPI', '📲'),
          const SizedBox(width: 8),
          _buildPaymentBtn(billingProvider, 'Card', '💳'),
        ],
      ),
      const SizedBox(height: 16), // Shrank from 24
 
      // Checkout Submit Button
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF006A61),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 14), // Shrank from 16
        ),
        onPressed: billingProvider.cart.isEmpty ? null : () => _performCheckout(billingProvider, currentSelectedCustomer),
        icon: const Icon(Icons.send),
        label: Text(
          'Generate & WhatsApp Invoice',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    ];
  }

  Widget _buildCustomerSelectPanel(
    BillingProvider billingProvider,
    List<Customer> filteredCustomers,
    Customer currentSelectedCustomer,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Customer Details',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF0B1C30)),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isAddingCustomer = !_isAddingCustomer;
                  });
                },
                icon: Icon(_isAddingCustomer ? Icons.close : Icons.add, size: 14),
                label: Text(
                  _isAddingCustomer ? 'Cancel' : 'New Client',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF006A61)),
                ),
              ),
            ],
          ),
 
          // Add Customer Form inline
          if (_isAddingCustomer) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4FF).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _newCustNameController,
                          label: 'Customer Name',
                          placeholder: 'e.g. John Doe',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomTextField(
                          controller: _newCustPhoneController,
                          label: 'Customer Phone',
                          placeholder: 'e.g. 9876543210',
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006A61),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: _createNewCustomer,
                    child: Text('Save & Select Customer', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
 
          // Search client input
          TextField(
            onChanged: (val) {
              setState(() {
                _customerQuery = val;
              });
            },
            style: GoogleFonts.inter(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search walk-in or phone (e.g. John/987)...',
              hintStyle: GoogleFonts.inter(color: const Color(0x997C839B), fontSize: 13),
              prefixIcon: const Icon(Icons.person_search_outlined, color: Color(0xFF7C839B)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFFC6C6CD), width: 1.0),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFF006A61), width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 6), // Shrank from 8
 
          // Horizontal selection chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filteredCustomers.take(5).map((cust) {
                final isSelected = billingProvider.selectedCustomerId == cust.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: InputChip(
                    label: Text('${cust.name} ${cust.phone != 'N/A' ? '(${cust.phone})' : ''}'),
                    selected: isSelected,
                    selectedColor: const Color(0xFF86F2E4).withValues(alpha: 0.3),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF006A61) : const Color(0xFF45464D),
                    ),
                    onPressed: () {
                      billingProvider.selectCustomer(cust.id);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF45464D), fontWeight: FontWeight.bold)),
          Text(value, style: GoogleFonts.inter(fontSize: 12, color: textColor ?? const Color(0xFF0B1C30), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
 
  Widget _buildPaymentBtn(BillingProvider bp, String method, String emoji) {
    final isSelected = bp.paymentMethod == method;
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF006A61).withValues(alpha: 0.05) : Colors.white,
          side: BorderSide(
            color: isSelected ? const Color(0xFF006A61) : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 10), // Shrank from 12
        ),
        onPressed: () => bp.setPaymentMethod(method),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              method.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF006A61) : const Color(0xFF7C839B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performCheckout(BillingProvider billingProvider, Customer currentCustomer) async {
    if (billingProvider.selectedBranchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No branch configuration matched. Please sync branches first.')),
      );
      return;
    }

    try {
      final bill = await billingProvider.checkout(
        branchId: billingProvider.selectedBranchId!,
        customerId: currentCustomer.id,
        customerName: currentCustomer.name,
        customerPhone: currentCustomer.phone,
      );

      // Show success modal dialog
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(color: Color(0xFFE6F4EA), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, color: Color(0xFF1E8E3E), size: 28),
              ),
              const SizedBox(height: 12),
              Text('Bill Compiled!', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Invoice ${bill.billNumber} has been generated successfully and queued for secure WhatsApp deliverability.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: const Color(0xFF7C839B), fontSize: 11),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildPopupRow('Client Name', bill.customerName ?? ''),
                    _buildPopupRow('Payment Gateway', '${bill.paymentMethod} Payment'),
                    _buildPopupRow('Discount Code', bill.discountCode ?? 'None'),
                    const SizedBox(height: 8),
                    const DashedDivider(height: 1, color: Color(0xFFCBD5E1)),
                    const SizedBox(height: 8),
                    _buildPopupRow('Total Amount', '₹${NumberFormat('#,##,###').format(bill.totalAmount)}', isTotal: true),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Receipt successfully sent to print pipeline.')),
                );
              },
              child: Text('Print Receipt', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006A61),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: Text('Done', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      // Return to services tab
      _tabController.animateTo(0);
    } catch (e) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('POS Error'),
          content: Text('$e'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  Widget _buildPopupRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF45464D),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: isTotal
                ? GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF006A61),
                  )
                : GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0B1C30),
                  ),
          ),
        ],
      ),
    );
  }
}

class DashedDivider extends StatelessWidget {
  final double height;
  final Color color;
  final double dashWidth;
  final double dashSpace;

  const DashedDivider({
    Key? key,
    this.height = 1,
    this.color = const Color(0xFFE2E8F0),
    this.dashWidth = 5,
    this.dashSpace = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Flex(
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
        );
      },
    );
  }
}
