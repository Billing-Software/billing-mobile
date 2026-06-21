import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/inventory.dart';
import '../services/inventory_service.dart';
import '../widgets/sidebar_drawer.dart';
import '../widgets/custom_text_field.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final InventoryService _inventoryService = InventoryService();
  List<InventoryItem> _items = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All' | 'Low Stock' | 'Fully Stocked'

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final list = await _inventoryService.getAll();
      if (!mounted) return;
      setState(() {
        _items = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load inventory: $e')),
      );
    }
  }

  void _showAddEditDialog({InventoryItem? item}) {
    final isEdit = item != null;
    final nameController = TextEditingController(text: item?.name ?? '');
    final skuController = TextEditingController(text: item?.sku ?? '');
    final categoryController = TextEditingController(text: item?.category ?? '');
    final currentStockController = TextEditingController(text: item?.currentStock.toString() ?? '0');
    final unitController = TextEditingController(text: item?.unit ?? 'pcs');
    final reorderLevelController = TextEditingController(text: item?.reorderLevel.toString() ?? '5');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isEdit ? 'Modify Inventory SKU' : 'Record New SKU Stock',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: nameController,
                label: 'Item Name',
                placeholder: 'e.g. Organic Shampoo',
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: skuController,
                label: 'SKU Code',
                placeholder: 'e.g. SH-01',
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: categoryController,
                label: 'Category',
                placeholder: 'e.g. Haircare',
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: currentStockController,
                label: 'Current Stock',
                placeholder: 'e.g. 50',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: unitController,
                label: 'Stock Unit',
                placeholder: 'e.g. bottles / pcs',
                textCapitalization: TextCapitalization.none,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: reorderLevelController,
                label: 'Reorder Level Limit',
                placeholder: 'e.g. 10',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
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
              final currentStock = int.tryParse(currentStockController.text) ?? 0;
              final unit = unitController.text.trim();
              final reorderLevel = int.tryParse(reorderLevelController.text) ?? 5;

              if (name.isEmpty || sku.isEmpty || category.isEmpty || unit.isEmpty) return;

              final payload = {
                'name': name,
                'sku': sku,
                'category': category,
                'currentStock': currentStock,
                'unit': unit,
                'reorderLevel': reorderLevel,
              };

              try {
                if (isEdit) {
                  await _inventoryService.update(item.id, payload);
                } else {
                  await _inventoryService.create(payload);
                }
                Navigator.pop(ctx);
                _fetchInventory();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Operation failed: $e')),
                );
              }
            },
            child: Text(isEdit ? 'Save Changes' : 'Enroll Stock', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete SKU Entry?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this item from database catalog?', style: GoogleFonts.inter()),
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
        await _inventoryService.delete(id);
        _fetchInventory();
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
    final filtered = _items.where((item) {
      final matchesQuery = item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.sku.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchQuery.toLowerCase());

      final isLow = item.currentStock <= item.reorderLevel;
      if (_selectedFilter == 'Low Stock') {
        return matchesQuery && isLow;
      } else if (_selectedFilter == 'Fully Stocked') {
        return matchesQuery && !isLow;
      }
      return matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text('Inventory Stock', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchInventory),
        ],
      ),
      drawer: const SidebarDrawer(activeRoute: '/inventory'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF006A61),
        foregroundColor: Colors.white,
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF006A61)))
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    children: [
                      // Filter bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        child: Column(
                          children: [
                            TextField(
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val;
                                });
                              },
                              style: GoogleFonts.inter(fontSize: 13),
                              textInputAction: TextInputAction.search,
                              autocorrect: false,
                              onSubmitted: (_) => FocusScope.of(context).unfocus(),
                              decoration: InputDecoration(
                              hintText: 'Search inventory by name, category or SKU...',
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
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text('FILTER STATUS: ', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF7C839B))),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: const Color(0xFFC6C6CD)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedFilter,
                                      isExpanded: true,
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0B1C30)),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            _selectedFilter = val;
                                          });
                                        }
                                      },
                                      items: ['All', 'Low Stock', 'Fully Stocked']
                                          .map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600))))
                                          .toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Inventory items
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No inventory items recorded.',
                                style: GoogleFonts.inter(color: const Color(0xFF7C839B), fontWeight: FontWeight.bold),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: filtered.length,
                              separatorBuilder: (c, i) => const SizedBox(height: 8),
                              itemBuilder: (ctx, idx) {
                                final item = filtered[idx];
                                final isLow = item.currentStock <= item.reorderLevel;

                                return Card(
                                  color: Colors.white,
                                  elevation: 1,
                                  margin: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: isLow ? const Color(0xFFBA1A1A).withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
                                      width: isLow ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                    visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
                                    leading: CircleAvatar(
                                      backgroundColor: isLow ? const Color(0xFFFFDAD6) : const Color(0xFFEFF4FF),
                                      child: Icon(
                                        isLow ? Icons.warning : Icons.inventory_2_outlined,
                                        color: isLow ? const Color(0xFFBA1A1A) : const Color(0xFF006A61),
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      item.name,
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF0B1C30), fontSize: 13),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 2),
                                        Text('SKU: ${item.sku} | Category: ${item.category}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF45464D))),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Stock limit: ${item.reorderLevel} ${item.unit}',
                                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF7C839B), fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${item.currentStock} ${item.unit}',
                                              style: GoogleFonts.outfit(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w900,
                                                color: isLow ? const Color(0xFFBA1A1A) : const Color(0xFF006A61),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              isLow ? 'CRITICAL' : 'OK',
                                              style: GoogleFonts.inter(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: isLow ? const Color(0xFFBA1A1A) : const Color(0xFF1E8E3E),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          icon: const Icon(Icons.edit_outlined, color: Color(0xFF006A61), size: 18),
                                          onPressed: () => _showAddEditDialog(item: item),
                                        ),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          icon: const Icon(Icons.delete_outline, color: Color(0xFFBA1A1A), size: 18),
                                          onPressed: () => _deleteItem(item.id),
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
      ),
    );
  }
}
