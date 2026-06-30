import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/billing_provider.dart';
import '../providers/bluetooth_printer_provider.dart';
import '../models/service.dart';
import '../models/bill.dart';
import '../models/customer.dart';
import '../models/business.dart';
import '../models/category.dart';
import '../services/service_catalog_service.dart';
import '../services/customer_service.dart';
import '../services/branch_service.dart';
import '../services/business_service.dart';
import '../services/category_service.dart';
import '../services/bluetooth_printer_service.dart';
import '../widgets/custom_text_field.dart';
import '../services/api_client.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({Key? key}) : super(key: key);

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {

  final ServiceCatalogService _serviceService = ServiceCatalogService();
  final CustomerService _customerService = CustomerService();
  final BranchService _branchService = BranchService();
  final BusinessService _businessService = BusinessService();
  final CategoryService _categoryService = CategoryService();

  List<Service> _services = [];
  List<Customer> _customers = [];
  List<Map<String, dynamic>> _branches = [];
  List<Category> _dbCategories = [];
  Business? _businessProfile;
  bool _isLoading = true;

  final Set<int> _selectedCategoryIds = {};
  final Set<int> _collapsedCategoryIds = {};
  bool _hasInitializedCollapsedCategories = false;
  String _serviceQuery = '';
  String _customerQuery = '';

  List<Service> _filteredServices = [];
  List<Customer> _filteredCustomers = [];
  Set<String> _selectedCategoryNames = {};

  void _updateFilteredData() {
    _selectedCategoryNames = _getSelectedCategoryNamesAndDescendants();

    _filteredServices = _services.where((s) {
      if (s.status != 'Active') return false;
      final matchesCategory = _selectedCategoryIds.isEmpty ||
          _selectedCategoryNames.contains(s.category.toLowerCase());
      final matchesQuery = s.name.toLowerCase().contains(_serviceQuery.toLowerCase()) ||
          s.sku.toLowerCase().contains(_serviceQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();

    _filteredCustomers = _customers.where((c) {
      return c.name.toLowerCase().contains(_customerQuery.toLowerCase()) ||
          c.phone.contains(_customerQuery);
    }).toList();
  }

  // Form state to add customer
  bool _isAddingCustomer = false;
  final _newCustNameController = TextEditingController();
  final _newCustPhoneController = TextEditingController();

  final _promoController = TextEditingController();

  bool _sendWhatsApp = false;
  bool _printReceipt = false;

  int? _lastRefreshTrigger;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final billingProvider = Provider.of<BillingProvider>(context);
    if (_lastRefreshTrigger != billingProvider.refreshTrigger) {
      _lastRefreshTrigger = billingProvider.refreshTrigger;
      _fetchInitialData();
    }
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
        _businessService.getProfile(),
        _categoryService.getAll(),
      ]);

      if (!mounted) return;
      setState(() {
        _services = results[0] as List<Service>;
        _customers = results[1] as List<Customer>;
        _branches = results[2] as List<Map<String, dynamic>>;
        _businessProfile = results[3] as Business;
        _dbCategories = (results[4] as List<Category>).where((c) => c.type == 'Service').toList();
        _updateFilteredData();
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
        _updateFilteredData();
      });

      if (mounted) {
        Provider.of<BillingProvider>(context, listen: false).selectCustomer(cust.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Customer ${cust.name} selected.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not create customer: $e'),
            backgroundColor: const Color(0xFFBA1A1A),
          ),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final billingProvider = Provider.of<BillingProvider>(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Billing POS')),
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
    final filteredServices = _filteredServices;
    final filteredCustomers = _filteredCustomers;

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

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text(
          'Billing POS',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final gridWidth = (width > 900) ? (width * 8 / 12) : width;
          int columns = (gridWidth / 150).floor();
          if (columns < 2) columns = 2;

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
                              _updateFilteredData();
                            });
                          },
                          textInputAction: TextInputAction.search,
                          autocorrect: false,
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
                      _buildFilterChipsRow(),
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
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 0.85,
                                ),
                                itemCount: filteredServices.length,
                                itemBuilder: (context, index) {
                                  final service = filteredServices[index];
                                  return _buildModernServiceCard(context, service, billingProvider);
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
            // Mobile Unified layout (Catalog only on main screen)
            return Column(
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
                        _updateFilteredData();
                      });
                    },
                    textInputAction: TextInputAction.search,
                    autocorrect: false,
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
                _buildFilterChipsRow(),
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
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: filteredServices.length,
                          itemBuilder: (context, index) {
                            final service = filteredServices[index];
                            return _buildModernServiceCard(context, service, billingProvider);
                          },
                        ),
                ),
              ],
            );
          }
        },
      ),
      bottomNavigationBar: (MediaQuery.of(context).size.width > 900 || billingProvider.cart.isEmpty)
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 10,
                  ),
                ],
                border: const Border(
                  top: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${billingProvider.cart.fold(0, (sum, item) => sum + item.quantity)} Services Selected',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF7C839B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${NumberFormat('#,##,###').format(billingProvider.totalAmount)}',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF006A61),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006A61),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: () {
                        _showCheckoutBottomSheet(context, billingProvider, currentSelectedCustomer);
                      },
                      icon: const Icon(Icons.shopping_cart_checkout),
                      label: Text(
                        'Review & Pay',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  void _showCheckoutBottomSheet(
    BuildContext context,
    BillingProvider billingProvider,
    Customer currentSelectedCustomer,
  ) {
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
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Consumer<BillingProvider>(
                builder: (context, bp, child) {
                  Customer activeCust;
                  try {
                    activeCust = _customers.firstWhere((c) => c.id == bp.selectedCustomerId);
                  } catch (_) {
                    activeCust = currentSelectedCustomer;
                  }

                  return DraggableScrollableSheet(
                    initialChildSize: 0.85,
                    minChildSize: 0.5,
                    maxChildSize: 0.95,
                    expand: false,
                    builder: (context, scrollController) {
                      return Column(
                        children: [
                          // Grab handle decoration
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFC6C6CD),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          // Header with close button
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Checkout Review',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0B1C30),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          // Scrollable content containing all checkout details
                          Expanded(
                            child: SingleChildScrollView(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: _buildCheckoutPanelItems(bp, activeCust, setModalState: setBottomSheetState),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildCheckoutPanelItems(
    BillingProvider billingProvider,
    Customer currentSelectedCustomer, {
    void Function(void Function())? setModalState,
  }) {
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
                        Row(
                          children: [
                            Text(
                              '₹${NumberFormat('#,##,###').format(item.unitPrice)} each',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF7C839B),
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => _showEditPriceDialog(context, item, billingProvider),
                              child: const Icon(
                                Icons.edit_outlined,
                                size: 12,
                                color: Color(0xFF006A61),
                              ),
                            ),
                          ],
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
            // Modern Discount Type Selector
            Row(
              children: [
                Text(
                  'DISCOUNT TYPE',
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF7C839B), letterSpacing: 0.5),
                ),
                const Spacer(),
                ChoiceChip(
                  label: const Text('% Percent'),
                  selected: billingProvider.discountType == 'percentage',
                  onSelected: (val) {
                    if (val) {
                      billingProvider.setDiscount('percentage', 0);
                    }
                  },
                  selectedColor: const Color(0xFF006A61),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: billingProvider.discountType == 'percentage' ? Colors.white : const Color(0xFF7C839B),
                  ),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('₹ Flat'),
                  selected: billingProvider.discountType == 'flat',
                  onSelected: (val) {
                    if (val) {
                      billingProvider.setDiscount('flat', 0);
                    }
                  },
                  selectedColor: const Color(0xFF006A61),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: billingProvider.discountType == 'flat' ? Colors.white : const Color(0xFF7C839B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Custom discount value input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: billingProvider.discountType == 'percentage' ? 'Enter discount percent...' : 'Enter discount amount...',
                      hintStyle: GoogleFonts.inter(color: const Color(0x997C839B), fontSize: 12),
                      prefixText: billingProvider.discountType == 'percentage' ? null : '₹ ',
                      suffixText: billingProvider.discountType == 'percentage' ? ' %' : null,
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF006A61), width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val) ?? 0.0;
                      billingProvider.setDiscount(billingProvider.discountType, parsed);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Quick Action Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: billingProvider.discountType == 'percentage'
                    ? [5, 10, 15, 20, 30, 50].map((pct) {
                        final isSelected = billingProvider.discountValue == pct;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ActionChip(
                            padding: EdgeInsets.zero,
                            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                            label: Text('$pct%'),
                            onPressed: () => billingProvider.setDiscount('percentage', pct.toDouble()),
                            backgroundColor: isSelected ? const Color(0xFFE8F5F3) : Colors.white,
                            side: BorderSide(color: isSelected ? const Color(0xFF006A61) : const Color(0xFFE2E8F0)),
                            labelStyle: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? const Color(0xFF006A61) : const Color(0xFF45464D),
                            ),
                          ),
                        );
                      }).toList()
                    : [50, 100, 200, 500].map((flat) {
                        final isSelected = billingProvider.discountValue == flat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ActionChip(
                            padding: EdgeInsets.zero,
                            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                            label: Text('₹$flat'),
                            onPressed: () => billingProvider.setDiscount('flat', flat.toDouble()),
                            backgroundColor: isSelected ? const Color(0xFFE8F5F3) : Colors.white,
                            side: BorderSide(color: isSelected ? const Color(0xFF006A61) : const Color(0xFFE2E8F0)),
                            labelStyle: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? const Color(0xFF006A61) : const Color(0xFF45464D),
                            ),
                          ),
                        );
                      }).toList(),
              ),
            ),
            const SizedBox(height: 10), // Shrank from 16
            // Math stats
            _buildSummaryRow('Subtotal', '₹${NumberFormat('#,##,###').format(billingProvider.subtotal)}'),
            _buildSummaryRow(
              'Discount (${billingProvider.activeDiscountCode})',
              '-₹${NumberFormat('#,##,###').format(billingProvider.discountAmount)}',
              textColor: const Color(0xFF006A61),
            ),
            if (billingProvider.taxAmount > 0)
              _buildSummaryRow('Tax', '₹${NumberFormat('#,##,###').format(billingProvider.taxAmount)}'),
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
      const SizedBox(height: 14),

      // Delivery Options Checkboxes
      Text(
        'DELIVERY METHOD',
        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF7C839B), letterSpacing: 1.0),
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('WhatsApp Integration is coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: false,
                        onChanged: null,
                        activeColor: const Color(0xFF4CAF50),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'WhatsApp (Soon)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                if (setModalState != null) {
                  setModalState(() {
                    _printReceipt = !_printReceipt;
                  });
                } else {
                  setState(() {
                    _printReceipt = !_printReceipt;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: BoxDecoration(
                  color: _printReceipt ? const Color(0xFFE0F2F1) : Colors.white,
                  border: Border.all(
                    color: _printReceipt ? const Color(0xFF009688) : const Color(0xFFE2E8F0),
                    width: _printReceipt ? 1.5 : 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _printReceipt,
                        activeColor: const Color(0xFF009688),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (val) {
                          if (setModalState != null) {
                            setModalState(() {
                              _printReceipt = val ?? false;
                            });
                          } else {
                            setState(() {
                              _printReceipt = val ?? false;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Print Receipt',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _printReceipt ? const Color(0xFF00796B) : const Color(0xFF45464D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
 
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
          _sendWhatsApp && _printReceipt
              ? 'Generate, Print & WhatsApp'
              : _sendWhatsApp
                  ? 'Generate & WhatsApp Invoice'
                  : _printReceipt
                      ? 'Generate & Print Invoice'
                      : 'Generate Invoice Only',
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
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.name],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomTextField(
                          controller: _newCustPhoneController,
                          label: 'Customer Phone',
                          placeholder: 'e.g. 9876543210',
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.telephoneNumber],
                          onFieldSubmitted: (_) => _createNewCustomer(),
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
                _updateFilteredData();
              });
            },
            textInputAction: TextInputAction.search,
            autocorrect: false,
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final bill = await billingProvider.checkout(
        branchId: billingProvider.selectedBranchId!,
        customerId: currentCustomer.id,
        customerName: currentCustomer.name,
        customerPhone: currentCustomer.phone,
        createdByStaffId: authProvider.currentUser?.staffId,
      );

      if (!mounted) return;

      // If we are on mobile, close the bottom sheet first
      if (MediaQuery.of(context).size.width <= 900) {
        Navigator.of(context).pop();
      }

      // Print logic if checked
      bool printSuccess = true;
      String? printErrorMessage;
      
      if (_printReceipt) {
        final printerProvider = Provider.of<BluetoothPrinterProvider>(context, listen: false);
        if (printerProvider.connectionState == PrinterConnectionState.connected) {
          printSuccess = await printerProvider.printBill(bill, businessName: bill.branchName ?? 'BillCom', business: _businessProfile);
          printErrorMessage = printerProvider.errorMessage;
        } else {
          // Attempt auto connect
          final success = await printerProvider.autoDetectAndConnect();
          if (success) {
            printSuccess = await printerProvider.printBill(bill, businessName: bill.branchName ?? 'BillCom', business: _businessProfile);
            printErrorMessage = printerProvider.errorMessage;
          } else {
            printSuccess = false;
            printErrorMessage = printerProvider.errorMessage ?? "No paired Bluetooth billing printer found.";
          }
        }
      }

      if (!mounted) return;

      // Build the feedback message
      String message = 'Invoice ${bill.billNumber} compiled successfully.';
      if (_sendWhatsApp && _printReceipt) {
        message = 'Invoice ${bill.billNumber} compiled! Queued for WhatsApp & ' + (printSuccess ? 'sent to printer.' : 'printer error: $printErrorMessage');
      } else if (_sendWhatsApp) {
        message = 'Invoice ${bill.billNumber} compiled & queued for WhatsApp delivery.';
      } else if (_printReceipt) {
        message = 'Invoice ${bill.billNumber} compiled & ' + (printSuccess ? 'sent to printer.' : 'printer error: $printErrorMessage');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          backgroundColor: printSuccess ? const Color(0xFF006A61) : const Color(0xFFBA1A1A),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('POS Error: $e'),
          backgroundColor: const Color(0xFFBA1A1A),
        ),
      );
    }
  }

  // --- Tree Category Filtering Helpers ---
  List<_CategoryNode> _buildCategoryTree(List<Category> flatCategories) {
    final Map<int, _CategoryNode> map = {
      for (var cat in flatCategories) cat.id: _CategoryNode(cat)
    };
    final List<_CategoryNode> roots = [];
    for (var node in map.values) {
      final pId = node.category.parentId;
      if (pId == null || !map.containsKey(pId)) {
        roots.add(node);
      } else {
        map[pId]!.children.add(node);
      }
    }
    return roots;
  }

  void _flattenTree(List<_CategoryNode> nodes, int depth, List<_FlattenedCategoryNode> result, Set<int> collapsedNodeIds) {
    for (var node in nodes) {
      final isCollapsed = collapsedNodeIds.contains(node.category.id);
      result.add(_FlattenedCategoryNode(
        node.category,
        depth,
        node.children.isNotEmpty,
      ));
      if (!isCollapsed && node.children.isNotEmpty) {
        _flattenTree(node.children, depth + 1, result, collapsedNodeIds);
      }
    }
  }

  Set<String> _getSelectedCategoryNamesAndDescendants() {
    if (_selectedCategoryIds.isEmpty) return {};
    final Set<String> names = {};
    final tree = _buildCategoryTree(_dbCategories);
    
    void addDescendants(List<_CategoryNode> nodes, bool parentSelected) {
      for (var node in nodes) {
        final isSelected = parentSelected || _selectedCategoryIds.contains(node.category.id);
        if (isSelected) {
          names.add(node.category.name.toLowerCase());
        }
        if (node.children.isNotEmpty) {
          addDescendants(node.children, isSelected);
        }
      }
    }
    
    addDescendants(tree, false);
    return names;
  }

  void _toggleCategoryCheck(int catId, bool checked, List<Category> allCats, Set<int> selectedIds) {
    if (checked) {
      selectedIds.add(catId);
    } else {
      selectedIds.remove(catId);
    }
    
    final children = allCats.where((c) => c.parentId == catId).toList();
    for (var child in children) {
      _toggleCategoryCheck(child.id, checked, allCats, selectedIds);
    }
  }

  Widget _buildFilterChipsRow() {
    final selectedCats = _dbCategories.where((c) => _selectedCategoryIds.contains(c.id)).toList();
    
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: [
          Material(
            color: _selectedCategoryIds.isNotEmpty ? const Color(0xFF006A61).withOpacity(0.1) : const Color(0xFFEFF4FF),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _showCategoryFilterBottomSheet,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_alt_outlined,
                      size: 16,
                      color: _selectedCategoryIds.isNotEmpty ? const Color(0xFF006A61) : const Color(0xFF45464D),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Categories',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _selectedCategoryIds.isNotEmpty ? const Color(0xFF006A61) : const Color(0xFF45464D),
                      ),
                    ),
                    if (_selectedCategoryIds.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF006A61),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${_selectedCategoryIds.length}',
                          style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          if (_selectedCategoryIds.isEmpty)
            ChoiceChip(
              label: Text(
                'All Categories',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              selected: true,
              selectedColor: const Color(0xFF006A61),
              onSelected: (_) {
                _showCategoryFilterBottomSheet();
              },
            )
          else
            ...selectedCats.map((cat) {
              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: InputChip(
                  label: Text(
                    cat.name,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF006A61),
                    ),
                  ),
                  backgroundColor: const Color(0xFF006A61).withOpacity(0.08),
                  selected: false,
                  onDeleted: () {
                    setState(() {
                      _toggleCategoryCheck(cat.id, false, _dbCategories, _selectedCategoryIds);
                      _updateFilteredData();
                    });
                  },
                  deleteIconColor: const Color(0xFF006A61),
                  deleteIcon: const Icon(Icons.close, size: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Color(0xFF006A61), width: 0.5),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showCategoryFilterBottomSheet() {
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
          if (!_hasInitializedCollapsedCategories && _dbCategories.isNotEmpty) {
            _collapsedCategoryIds.addAll(_dbCategories.map((c) => c.id));
            _hasInitializedCollapsedCategories = true;
          }
          final tree = _buildCategoryTree(_dbCategories);
          final List<_FlattenedCategoryNode> tempFlat = [];
          _flattenTree(tree, 0, tempFlat, _collapsedCategoryIds);

          return Container(
            height: 480,
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
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
                        'Filter by Service Categories',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: const Color(0xFF0B1C30),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setBottomSheetState(() {
                            _selectedCategoryIds.clear();
                          });
                          setState(() {
                            _updateFilteredData();
                          });
                        },
                        child: Text(
                          'Clear All',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFBA1A1A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: tempFlat.isEmpty
                      ? Center(
                          child: Text(
                            'No service categories created yet.',
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF7C839B), fontWeight: FontWeight.bold),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: tempFlat.length,
                          separatorBuilder: (c, i) => const Divider(height: 1),
                          itemBuilder: (ctx, idx) {
                            final node = tempFlat[idx];
                            final cat = node.category;
                            final isChecked = _selectedCategoryIds.contains(cat.id);
                            return Padding(
                              padding: EdgeInsets.only(left: node.depth * 20.0),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                                onTap: () {
                                  if (node.hasChildren) {
                                    setBottomSheetState(() {
                                      if (_collapsedCategoryIds.contains(cat.id)) {
                                        _collapsedCategoryIds.remove(cat.id);
                                      } else {
                                        _collapsedCategoryIds.add(cat.id);
                                      }
                                    });
                                  } else {
                                    final newVal = !isChecked;
                                    setBottomSheetState(() {
                                      _toggleCategoryCheck(cat.id, newVal, _dbCategories, _selectedCategoryIds);
                                    });
                                    setState(() {
                                      _updateFilteredData();
                                    });
                                  }
                                },
                                leading: node.hasChildren
                                    ? Icon(
                                        _collapsedCategoryIds.contains(cat.id)
                                            ? Icons.keyboard_arrow_right_rounded
                                            : Icons.keyboard_arrow_down_rounded,
                                        size: 20,
                                        color: const Color(0xFF006A61),
                                      )
                                    : Container(
                                        width: 20,
                                        alignment: Alignment.center,
                                        child: const Icon(Icons.subdirectory_arrow_right_rounded, size: 14, color: Color(0xFF7C839B)),
                                      ),
                                title: Row(
                                  children: [
                                    Checkbox(
                                      value: isChecked,
                                      activeColor: const Color(0xFF006A61),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setBottomSheetState(() {
                                            _toggleCategoryCheck(cat.id, val, _dbCategories, _selectedCategoryIds);
                                          });
                                          setState(() {
                                            _updateFilteredData();
                                          });
                                        }
                                      },
                                    ),
                                    Expanded(
                                      child: Text(
                                        cat.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: node.depth == 0 ? FontWeight.bold : FontWeight.w500,
                                          color: const Color(0xFF0B1C30),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006A61),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                    },
                    child: Text('Apply Filter', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditPriceDialog(BuildContext context, BillItem item, BillingProvider bp) {
    final controller = TextEditingController(text: item.unitPrice.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit Unit Price',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Change price for "${item.serviceName}":',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF7C839B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF0B1C30)),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFFC6C6CD)),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF006A61), width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF7C839B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006A61),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final newPrice = double.tryParse(controller.text);
              if (newPrice != null && newPrice >= 0) {
                bp.updateUnitPrice(item.serviceId, newPrice);
                Navigator.pop(ctx);
              }
            },
            child: Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildModernServiceCard(BuildContext context, Service service, BillingProvider billingProvider) {
    return Card(
      elevation: 0.5,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFF1F3F5), width: 1),
      ),
      child: InkWell(
        onTap: () {
          billingProvider.addService(service);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${service.name} added to cart.'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image / Placeholder Section
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ApiClient.resolveUrl(service.imageUrl).isNotEmpty
                        ? Image.network(
                            ApiClient.resolveUrl(service.imageUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                          )
                        : _buildPlaceholderImage(),
                  ),
                  // Price Badge - Modern pill top-left
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1C30).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        '₹${NumberFormat('#,##,###').format(service.basePrice)}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info Section
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF0B1C30),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Category name
                      Expanded(
                        child: Text(
                          service.category.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF006A61),
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      // Quick add circular plus icon
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F5F3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 14,
                          color: Color(0xFF006A61),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8F5F3), Color(0xFFEFF4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.bubble_chart_rounded,
          size: 32,
          color: Color(0xFF006A61),
        ),
      ),
    );
  }
}

class _CategoryNode {
  final Category category;
  final List<_CategoryNode> children = [];
  _CategoryNode(this.category);
}

class _FlattenedCategoryNode {
  final Category category;
  final int depth;
  final bool hasChildren;
  _FlattenedCategoryNode(this.category, this.depth, this.hasChildren);
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
