import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/service.dart';
import '../services/service_catalog_service.dart';
import '../widgets/sidebar_drawer.dart';
import '../widgets/custom_text_field.dart';

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({Key? key}) : super(key: key);

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  final ServiceCatalogService _serviceCatalogService = ServiceCatalogService();
  List<Service> _services = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final list = await _serviceCatalogService.getAll();
      if (!mounted) return;
      setState(() {
        _services = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load services: $e')),
      );
    }
  }

  Widget _buildDropdownField({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            color: const Color(0xFF7C839B),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFC6C6CD), width: 1.0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(child: child),
        ),
      ],
    );
  }

  void _showAddEditDialog({Service? service}) {
    final isEdit = service != null;
    final nameController = TextEditingController(text: service?.name ?? '');
    final skuController = TextEditingController(text: service?.sku ?? '');
    final categoryController = TextEditingController(text: service?.category ?? '');
    final priceController = TextEditingController(text: service?.basePrice.toString() ?? '');
    final taxController = TextEditingController(text: service?.taxRate.toString() ?? '5.0');
    String status = service?.status ?? 'Active';
    String iconName = service?.iconName ?? 'content_cut';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            isEdit ? 'Modify Service Catalog' : 'Create Service Entry',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: nameController,
                  label: 'Service Name',
                  placeholder: 'e.g. Haircut & Trim',
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: skuController,
                  label: 'SKU Code',
                  placeholder: 'e.g. HC-01',
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: categoryController,
                  label: 'Category',
                  placeholder: 'e.g. Haircut',
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: priceController,
                  label: 'Base Price (₹)',
                  placeholder: 'e.g. 299',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: taxController,
                  label: 'Tax Rate (%)',
                  placeholder: 'e.g. 5.0',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _buildDropdownField(
                  label: 'Status',
                  child: DropdownButton<String>(
                    value: status,
                    isExpanded: true,
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          status = val;
                        });
                      }
                    },
                    items: ['Active', 'Inactive'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)))).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                _buildDropdownField(
                  label: 'Icon Map',
                  child: DropdownButton<String>(
                    value: iconName,
                    isExpanded: true,
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          iconName = val;
                        });
                      }
                    },
                    items: ['content_cut', 'face', 'spa', 'brush', 'water_drop'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)))).toList(),
                  ),
                ),
              ],
            ),
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
                final sku = skuController.text.trim();
                final category = categoryController.text.trim();
                final price = double.tryParse(priceController.text) ?? 0.0;
                final tax = double.tryParse(taxController.text) ?? 0.0;

                if (name.isEmpty || sku.isEmpty || category.isEmpty) return;

                final payload = {
                  'name': name,
                  'sku': sku,
                  'category': category,
                  'basePrice': price,
                  'taxRate': tax,
                  'status': status,
                  'iconName': iconName,
                };

                try {
                  if (isEdit) {
                    await _serviceCatalogService.update(service.id, payload);
                  } else {
                    await _serviceCatalogService.create(payload);
                  }
                  Navigator.pop(ctx);
                  _fetchServices();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Operation failed: $e')),
                  );
                }
              },
              child: Text(isEdit ? 'Save Changes' : 'Establish Item', style: GoogleFonts.inter()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteService(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove Catalog Entry?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this service entry from your catalog?', style: GoogleFonts.inter()),
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
        await _serviceCatalogService.delete(id);
        _fetchServices();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  Widget _buildCategoryIcon(String iconName) {
    switch (iconName) {
      case 'content_cut':
        return const Text('✂️', style: TextStyle(fontSize: 16));
      case 'face':
        return const Text('👤', style: TextStyle(fontSize: 16));
      case 'spa':
        return const Text('🌸', style: TextStyle(fontSize: 16));
      case 'brush':
        return const Text('🎨', style: TextStyle(fontSize: 16));
      case 'water_drop':
        return const Text('💧', style: TextStyle(fontSize: 16));
      default:
        return const Text('📦', style: TextStyle(fontSize: 16));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', ..._services.map((s) => s.category).toSet().toList()];

    final filtered = _services.where((s) {
      final matchesCategory = _selectedCategory == 'All' || s.category == _selectedCategory;
      final matchesQuery = s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.sku.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text('Services Catalog', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchServices),
        ],
      ),
      drawer: const SidebarDrawer(activeRoute: '/services'),
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
                    // Filters
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
                          hintText: 'Search catalog by name or SKU...',
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
                    // Categories
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
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
                                  fontSize: 11,
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
                    const SizedBox(height: 6),
                    const Divider(height: 1),

                    // Services List
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No services in catalog.',
                                style: GoogleFonts.inter(color: const Color(0xFF7C839B), fontWeight: FontWeight.bold),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: filtered.length,
                              separatorBuilder: (c, i) => const SizedBox(height: 8),
                              itemBuilder: (ctx, idx) {
                                final service = filtered[idx];
                                final isActive = service.status == 'Active';
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
                                      child: _buildCategoryIcon(service.iconName),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            service.name,
                                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF0B1C30), fontSize: 13),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isActive ? const Color(0xFFE6F4EA) : const Color(0xFFFFDAD6),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            service.status,
                                            style: GoogleFonts.inter(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: isActive ? const Color(0xFF1E8E3E) : const Color(0xFFBA1A1A),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 2),
                                        Text('SKU: ${service.sku} | Category: ${service.category}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF45464D))),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Price: ₹${NumberFormat('#,##,###').format(service.basePrice)} (Tax: ${service.taxRate}%)',
                                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF006A61)),
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          icon: const Icon(Icons.edit_outlined, color: Color(0xFF006A61), size: 18),
                                          onPressed: () => _showAddEditDialog(service: service),
                                        ),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          icon: const Icon(Icons.delete_outline, color: Color(0xFFBA1A1A), size: 18),
                                          onPressed: () => _deleteService(service.id),
                                        ),
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
