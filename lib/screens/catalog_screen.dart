import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_client.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../models/service.dart';
import '../models/inventory.dart';
import '../models/category.dart';
import '../services/service_catalog_service.dart';
import '../services/inventory_service.dart';
import '../services/category_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dropdown_field.dart';
import '../widgets/confirm_sheet.dart';
import 'package:provider/provider.dart';
import '../providers/billing_provider.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  // Services & Inventory Services
  final ServiceCatalogService _serviceCatalogService = ServiceCatalogService();
  final InventoryService _inventoryService = InventoryService();
  final CategoryService _categoryService = CategoryService();

  // General state
  bool _isLoading = true;
  String _activeTab = 'Services'; // 'Services' | 'Inventory'

  // Services specific state
  List<Service> _services = [];
  List<Category> _serviceDbCategories = [];
  String _servicesSearchQuery = '';
  String _servicesSelectedCategory = 'All';



  // Inventory specific state
  List<InventoryItem> _inventoryItems = [];
  List<Category> _inventoryDbCategories = [];
  String _inventorySearchQuery = '';
  String _inventorySelectedFilter = 'All'; // 'All' | 'Low Stock' | 'Fully Stocked'

  List<String> _serviceCategories = ['All'];
  List<Service> _filteredServices = [];
  List<InventoryItem> _filteredInventory = [];

  void _updateFilteredData() {
    _serviceCategories = ['All', ..._services.map((s) => s.category).toSet()];
    _filteredServices = _services.where((s) {
      final matchesCategory = _servicesSelectedCategory == 'All' || s.category == _servicesSelectedCategory;
      final matchesQuery = s.name.toLowerCase().contains(_servicesSearchQuery.toLowerCase()) ||
          s.sku.toLowerCase().contains(_servicesSearchQuery.toLowerCase()) ||
          s.category.toLowerCase().contains(_servicesSearchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();

    _filteredInventory = _inventoryItems.where((item) {
      final matchesQuery = item.name.toLowerCase().contains(_inventorySearchQuery.toLowerCase()) ||
          item.sku.toLowerCase().contains(_inventorySearchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(_inventorySearchQuery.toLowerCase());

      final isLow = item.currentStock <= item.reorderLevel;
      if (_inventorySelectedFilter == 'Low Stock') {
        return matchesQuery && isLow;
      } else if (_inventorySelectedFilter == 'Fully Stocked') {
        return matchesQuery && !isLow;
      }
      return matchesQuery;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final servicesList = await _serviceCatalogService.getAll();
      final inventoryList = await _inventoryService.getAll();
      final catList = await _categoryService.getAll();

      final serviceCats = catList.where((c) => c.type == 'Service').toList();
      final invCats = catList.where((c) => c.type == 'Inventory').toList();

      if (!mounted) return;
      setState(() {
        _services = servicesList;
        _inventoryItems = inventoryList;
        _serviceDbCategories = serviceCats;
        _inventoryDbCategories = invCats;
        _isLoading = false;
        _updateFilteredData();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load catalog data: $e')),
      );
    }
  }

  void _refreshAllDataAndBilling() {
    _fetchAllData();
    if (mounted) {
      Provider.of<BillingProvider>(context, listen: false).triggerRefresh();
    }
  }

  // --- Category tree helpers ---
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

  List<Category> _getIndentedCategories(List<Category> cats) {
    final tree = _buildCategoryTree(cats);
    final List<_FlattenedCategoryNode> tempFlat = [];
    _flattenTree(tree, 0, tempFlat, {});
    return tempFlat.map((n) => n.category).toList();
  }

  Map<int, int> _calculateCategoryDepths(List<Category> cats) {
    final tree = _buildCategoryTree(cats);
    final List<_FlattenedCategoryNode> tempFlat = [];
    _flattenTree(tree, 0, tempFlat, {});
    return {for (var n in tempFlat) n.category.id: n.depth};
  }

  List<DropdownMenuItem<int?>> _buildParentDropdownItems(List<Category> cats) {
    final tree = _buildCategoryTree(cats);
    final List<_FlattenedCategoryNode> flatCategories = [];
    _flattenTree(tree, 0, flatCategories, {});

    return [
      DropdownMenuItem<int?>(
        value: null,
        child: Text(
          'No parent',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0B1C30)),
        ),
      ),
      ...flatCategories.map((node) {
        return DropdownMenuItem<int?>(
          value: node.category.id,
          child: Text(
            '${'  ' * node.depth}${node.category.name}',
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0B1C30)),
          ),
        );
      }),
    ];
  }

  // --- Category management bottom sheet ---
  void _showCategoryManagementBottomSheet() {
    final TextEditingController newCatController = TextEditingController();
    int? selectedParentId;
    Set<int>? collapsedNodeIds;
    final isServices = _activeTab == 'Services';
    final categoryType = isServices ? 'Service' : 'Inventory';
 
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
          final categoriesList = isServices ? _serviceDbCategories : _inventoryDbCategories;
          collapsedNodeIds ??= categoriesList.map((c) => c.id).toSet();
          final tree = _buildCategoryTree(categoriesList);
          final List<_FlattenedCategoryNode> tempFlat = [];
          _flattenTree(tree, 0, tempFlat, collapsedNodeIds!);

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              height: 520,
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  // Grab handle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC6C6CD),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Title and close
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Manage $categoryType Categories',
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
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: newCatController,
                                style: GoogleFonts.inter(fontSize: 13),
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  hintText: 'New Category Name',
                                  hintStyle: GoogleFonts.inter(color: const Color(0x997C839B), fontSize: 13),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF006A61),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                minimumSize: const Size(48, 48),
                              ),
                              onPressed: () async {
                                final name = newCatController.text.trim();
                                if (name.isEmpty) return;
                                
                                // Prevent duplicate category names
                                if (categoriesList.any((c) => c.name.toLowerCase() == name.toLowerCase())) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Category already exists.')),
                                    );
                                  }
                                  return;
                                }
                                try {
                                  await _categoryService.create({
                                    'name': name,
                                    'type': categoryType,
                                    'parentId': selectedParentId,
                                  });
                                  newCatController.clear();
                                  selectedParentId = null;
                                  final updatedList = await _categoryService.getAll();
                                  final freshCats = updatedList.where((c) => c.type == categoryType).toList();
                                  setState(() {
                                    if (isServices) {
                                      _serviceDbCategories = freshCats;
                                    } else {
                                      _inventoryDbCategories = freshCats;
                                    }
                                  });
                                  if (context.mounted) {
                                    Provider.of<BillingProvider>(context, listen: false).triggerRefresh();
                                  }
                                  setBottomSheetState(() {});
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to add category: $e')),
                                    );
                                  }
                                }
                              },
                              child: const Icon(Icons.add, size: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            _showCategoryPickerDialog(
                              categoriesList: categoriesList,
                              currentValue: () {
                                try {
                                  return categoriesList.firstWhere((c) => c.id == selectedParentId);
                                } catch (_) {
                                  return null;
                                }
                              }(),
                              onSelected: (val) {
                                setBottomSheetState(() {
                                  selectedParentId = val?.id;
                                });
                              },
                              allowClear: true,
                            );
                          },
                          child: AbsorbPointer(
                            child: CustomTextField(
                              controller: TextEditingController(
                                text: () {
                                  try {
                                    return categoriesList.firstWhere((c) => c.id == selectedParentId).name;
                                  } catch (_) {
                                    return 'No parent';
                                  }
                                }(),
                              ),
                              label: 'Parent Category (Optional)',
                              placeholder: 'Select parent category',
                              readOnly: true,
                              suffixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6B7280)),
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
                              'No categories created yet.',
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
                              return Padding(
                                padding: EdgeInsets.only(left: node.depth * 20.0),
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                                  onTap: node.hasChildren ? () {
                                    setBottomSheetState(() {
                                      if (collapsedNodeIds!.contains(cat.id)) {
                                        collapsedNodeIds!.remove(cat.id);
                                      } else {
                                        collapsedNodeIds!.add(cat.id);
                                      }
                                    });
                                  } : null,
                                  leading: node.hasChildren
                                      ? Icon(
                                          collapsedNodeIds!.contains(cat.id)
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
                                  title: Text(
                                    cat.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: node.depth == 0 ? FontWeight.bold : FontWeight.w500,
                                      color: const Color(0xFF0B1C30),
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Color(0xFFBA1A1A), size: 18),
                                    onPressed: () async {
                                      final confirm = await ConfirmSheet.show(
                                        context: context,
                                        title: 'Delete Category?',
                                        message: 'Are you sure you want to delete "${cat.name}" and all its subcategories?',
                                        confirmText: 'Delete',
                                        cancelText: 'Cancel',
                                        isDestructive: true,
                                      );
                                      if (confirm == true) {
                                        try {
                                          await _categoryService.delete(cat.id);
                                          final updatedList = await _categoryService.getAll();
                                          final freshCats = updatedList.where((c) => c.type == categoryType).toList();
                                          setState(() {
                                            if (isServices) {
                                              _serviceDbCategories = freshCats;
                                            } else {
                                              _inventoryDbCategories = freshCats;
                                            }
                                          });
                                          if (context.mounted) {
                                            Provider.of<BillingProvider>(context, listen: false).triggerRefresh();
                                          }
                                          setBottomSheetState(() {});
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Failed to delete category: $e')),
                                            );
                                          }
                                        }
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
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

  void _showCategoryPickerDialog({
    required List<Category> categoriesList,
    required Category? currentValue,
    required ValueChanged<Category?> onSelected,
    bool allowClear = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        Set<int>? collapsedNodeIds;
        
        return StatefulBuilder(
          builder: (context, setPickerState) {
            collapsedNodeIds ??= categoriesList.map((c) => c.id).toSet();
            final tree = _buildCategoryTree(categoriesList);
            final List<_FlattenedCategoryNode> tempFlat = [];
            _flattenTree(tree, 0, tempFlat, collapsedNodeIds!);
 
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Grab handle
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
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Select Category Group',
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
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: tempFlat.length + (allowClear ? 1 : 0),
                          separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          itemBuilder: (context, index) {
                            if (allowClear && index == 0) {
                              final isSelected = currentValue == null;
                              return InkWell(
                                onTap: () {
                                  onSelected(null);
                                  Navigator.pop(ctx);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          onSelected(null);
                                          Navigator.pop(ctx);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 8.0),
                                          child: Icon(
                                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                            size: 20,
                                            color: isSelected ? const Color(0xFF006A61) : const Color(0xFF7C839B),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF7C839B)),
                                      const SizedBox(width: 8),
                                      Text(
                                        'No parent (Root Category)',
                                        style: GoogleFonts.inter(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 14,
                                          color: isSelected ? const Color(0xFF006A61) : const Color(0xFF0B1C30),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final nodeIdx = allowClear ? index - 1 : index;
                            final node = tempFlat[nodeIdx];
                            final isCollapsed = collapsedNodeIds!.contains(node.category.id);
                            final isSelected = currentValue?.id == node.category.id;
 
                            return InkWell(
                              onTap: () {
                                if (node.hasChildren) {
                                  setPickerState(() {
                                    if (isCollapsed) {
                                      collapsedNodeIds!.remove(node.category.id);
                                    } else {
                                      collapsedNodeIds!.add(node.category.id);
                                    }
                                  });
                                } else {
                                  onSelected(node.category);
                                  Navigator.pop(ctx);
                                }
                              },
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: 16.0 + (node.depth * 20.0),
                                  right: 16.0,
                                  top: 12.0,
                                  bottom: 12.0,
                                ),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        onSelected(node.category);
                                        Navigator.pop(ctx);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: Icon(
                                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                          size: 20,
                                          color: isSelected ? const Color(0xFF006A61) : const Color(0xFF7C839B),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      node.hasChildren ? Icons.folder_outlined : (node.depth > 0 ? Icons.subdirectory_arrow_right : Icons.insert_drive_file_outlined),
                                      size: 16,
                                      color: isSelected ? const Color(0xFF006A61) : const Color(0xFF7C839B),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        node.category.name,
                                        style: GoogleFonts.inter(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 14,
                                          color: isSelected ? const Color(0xFF006A61) : const Color(0xFF0B1C30),
                                        ),
                                      ),
                                    ),
                                    if (node.hasChildren) ...[
                                      Icon(
                                        isCollapsed ? Icons.keyboard_arrow_right : Icons.keyboard_arrow_down,
                                        size: 20,
                                        color: const Color(0xFF7C839B),
                                      ),
                                    ] else ...[
                                      const SizedBox(width: 20),
                                    ]
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // --- Services bottom sheet handler ---
  void _showAddEditServiceBottomSheet({Service? service}) {
    final isEdit = service != null;
    final nameController = TextEditingController(text: service?.name ?? '');
    final skuController = TextEditingController(text: service?.sku ?? '');
    final categoryController = TextEditingController(text: service?.category ?? '');
    final priceController = TextEditingController(text: service?.basePrice.toString() ?? '');
    final taxController = TextEditingController(text: service?.taxRate.toString() ?? '5.0');
    String serviceStatus = service?.status ?? 'Active';
    String serviceImageUrl = service?.imageUrl ?? '';
    Uint8List? selectedImageBytes;
    String? selectedImageName;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setBottomSheetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  ),
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
                              isEdit ? 'Modify Service Catalog' : 'Create Service Entry',
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
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Image Upload Container
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FF),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFEFF4FF)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFC6C6CD)),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: selectedImageBytes != null
                                            ? Image.memory(
                                                selectedImageBytes!,
                                                fit: BoxFit.cover,
                                              )
                                            : ApiClient.resolveUrl(serviceImageUrl).isNotEmpty
                                                ? Image.network(
                                                    ApiClient.resolveUrl(serviceImageUrl),
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => const Icon(
                                                      Icons.image_outlined,
                                                      color: Color(0xFF7C839B),
                                                      size: 20,
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.image_outlined,
                                                    color: Color(0xFF7C839B),
                                                    size: 20,
                                                  ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Service Image',
                                              style: GoogleFonts.outfit(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: const Color(0xFF0B1C30),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Upload a photo for this service',
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                color: const Color(0xFF7C839B),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF006A61),
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                    minimumSize: Size.zero,
                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                  onPressed: () async {
                                                    final ImagePicker picker = ImagePicker();
                                                    final XFile? pickedFile = await picker.pickImage(
                                                      source: ImageSource.gallery,
                                                      maxWidth: 800,
                                                      maxHeight: 800,
                                                      imageQuality: 85,
                                                    );
                                                    if (pickedFile != null) {
                                                      try {
                                                        final bytes = await pickedFile.readAsBytes();
                                                        setBottomSheetState(() {
                                                          selectedImageBytes = bytes;
                                                          selectedImageName = pickedFile.name;
                                                        });
                                                      } catch (err) {
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(content: Text('Failed to load selected image: $err')),
                                                          );
                                                        }
                                                      }
                                                    }
                                                  },
                                                  icon: const Icon(Icons.upload, size: 12),
                                                  label: Text(
                                                    'Upload',
                                                    style: GoogleFonts.inter(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                                if (serviceImageUrl.isNotEmpty || selectedImageBytes != null) ...[
                                                  const SizedBox(width: 8),
                                                  TextButton(
                                                    style: TextButton.styleFrom(
                                                      foregroundColor: Colors.red,
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                      minimumSize: Size.zero,
                                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    ),
                                                    onPressed: () {
                                                      setBottomSheetState(() {
                                                        serviceImageUrl = '';
                                                        selectedImageBytes = null;
                                                        selectedImageName = null;
                                                      });
                                                    },
                                                    child: Text(
                                                      'Remove',
                                                      style: GoogleFonts.inter(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                CustomTextField(
                                  controller: nameController,
                                  label: 'Service Name *',
                                  placeholder: 'e.g. Haircut & Trim',
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 12),
                                CustomTextField(
                                  controller: skuController,
                                  label: 'SKU Code *',
                                  placeholder: 'e.g. HC-01',
                                  textCapitalization: TextCapitalization.characters,
                                  autocorrect: false,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 12),
                                 GestureDetector(
                                  onTap: () {
                                    _showCategoryPickerDialog(
                                      categoriesList: _serviceDbCategories,
                                      currentValue: () {
                                        try {
                                          return _serviceDbCategories.firstWhere((c) => c.name == categoryController.text);
                                        } catch (_) {
                                          return null;
                                        }
                                      }(),
                                      onSelected: (val) {
                                        if (val != null) {
                                          setBottomSheetState(() {
                                            categoryController.text = val.name;
                                          });
                                        }
                                      },
                                    );
                                  },
                                  child: AbsorbPointer(
                                    child: CustomTextField(
                                      controller: categoryController,
                                      label: 'Category Group *',
                                      placeholder: 'Select category group',
                                      readOnly: true,
                                      suffixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6B7280)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                CustomTextField(
                                  controller: priceController,
                                  label: 'Base Rate (₹) *',
                                  placeholder: 'e.g. 500',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 12),
                                CustomTextField(
                                  controller: taxController,
                                  label: 'Service Tax Rate (%) *',
                                  placeholder: 'e.g. 18.0',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 12),
                                CustomDropdownField<String>(
                                  label: 'Catalog Status *',
                                  value: serviceStatus,
                                  items: const ['Active', 'Inactive'],
                                  itemLabel: (s) => s,
                                  onChanged: (val) {
                                    if (val != null) {
                                      setBottomSheetState(() {
                                        serviceStatus = val;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF006A61),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: isSaving ? null : () async {
                                    final name = nameController.text.trim();
                                    final sku = skuController.text.trim();
                                    final category = categoryController.text.trim();
                                    final price = double.tryParse(priceController.text) ?? 0.0;
                                    final tax = double.tryParse(taxController.text) ?? 0.0;

                                    if (name.isEmpty || sku.isEmpty || category.isEmpty || price <= 0) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please complete all fields with valid entries.')),
                                      );
                                      return;
                                    }

                                    setBottomSheetState(() {
                                      isSaving = true;
                                    });

                                    try {
                                      String uploadedUrl = serviceImageUrl;
                                      
                                      // Upload to R2 only when Establish Item is clicked
                                      if (selectedImageBytes != null && selectedImageName != null) {
                                        final uploadResponse = await ApiClient().uploadImage(
                                          '/upload',
                                          selectedImageBytes!,
                                          selectedImageName!,
                                        );
                                        if (uploadResponse.statusCode == 200) {
                                          final data = jsonDecode(uploadResponse.body);
                                          uploadedUrl = data['url'] ?? '';
                                        } else {
                                          throw Exception('Image upload failed: ${uploadResponse.statusCode}');
                                        }
                                      }

                                      final payload = {
                                        'name': name,
                                        'sku': sku,
                                        'category': category,
                                        'basePrice': price,
                                        'taxRate': tax,
                                        'status': serviceStatus,
                                        'imageUrl': uploadedUrl,
                                      };

                                      if (isEdit) {
                                        await _serviceCatalogService.update(service.id, payload);
                                      } else {
                                        await _serviceCatalogService.create(payload);
                                      }
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                      _refreshAllDataAndBilling();
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Operation failed: $e')),
                                        );
                                      }
                                    } finally {
                                      setBottomSheetState(() {
                                        isSaving = false;
                                      });
                                    }
                                  },
                                  child: isSaving
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          isEdit ? 'Save Changes' : 'Establish Item',
                                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteService(int id) async {
    final confirm = await ConfirmSheet.show(
      context: context,
      title: 'Remove Catalog Entry?',
      message: 'Are you sure you want to delete this service entry from your catalog?',
      confirmText: 'Remove',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirm == true) {
      try {
        await _serviceCatalogService.delete(id);
        _refreshAllDataAndBilling();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete service: $e')),
          );
        }
      }
    }
  }

  // --- Inventory bottom sheet handlers ---
  void _showAddEditInventoryBottomSheet({InventoryItem? item}) {
    final isEdit = item != null;
    final nameController = TextEditingController(text: item?.name ?? '');
    final skuController = TextEditingController(text: item?.sku ?? '');
    final categoryController = TextEditingController(text: item?.category ?? '');
    final currentStockController = TextEditingController(text: item?.currentStock.toString() ?? '0');
    final unitController = TextEditingController(text: item?.unit ?? 'pcs');
    final reorderLevelController = TextEditingController(text: item?.reorderLevel.toString() ?? '5');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setBottomSheetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  ),
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
                              isEdit ? 'Modify Inventory SKU' : 'Record New SKU Stock',
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
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                GestureDetector(
                                  onTap: () {
                                    _showCategoryPickerDialog(
                                      categoriesList: _inventoryDbCategories,
                                      currentValue: () {
                                        try {
                                          return _inventoryDbCategories.firstWhere((c) => c.name == categoryController.text);
                                        } catch (_) {
                                          return null;
                                        }
                                      }(),
                                      onSelected: (val) {
                                        if (val != null) {
                                          setBottomSheetState(() {
                                            categoryController.text = val.name;
                                          });
                                        }
                                      },
                                    );
                                  },
                                  child: AbsorbPointer(
                                    child: CustomTextField(
                                      controller: categoryController,
                                      label: 'Category *',
                                      placeholder: 'Select category group',
                                      readOnly: true,
                                      suffixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6B7280)),
                                    ),
                                  ),
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
                                      if (ctx.mounted) {
                                        Navigator.pop(ctx);
                                      }
                                      _refreshAllDataAndBilling();
                                    } catch (e) {
                                      if (ctx.mounted) {
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          SnackBar(content: Text('Operation failed: $e')),
                                        );
                                      }
                                    }
                                  },
                                  child: Text(
                                    isEdit ? 'Save Changes' : 'Enroll Stock',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteInventoryItem(int id) async {
    final confirm = await ConfirmSheet.show(
      context: context,
      title: 'Delete SKU Entry?',
      message: 'Are you sure you want to delete this item from database catalog?',
      confirmText: 'Remove',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirm == true) {
      try {
        await _inventoryService.delete(id);
        _refreshAllDataAndBilling();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  Widget _buildSegmentedControl() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeTab = 'Services';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTab == 'Services' ? const Color(0xFF006A61) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Services',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _activeTab == 'Services' ? Colors.white : const Color(0xFF45464D),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeTab = 'Inventory';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTab == 'Inventory' ? const Color(0xFF006A61) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Inventory Stock',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _activeTab == 'Inventory' ? Colors.white : const Color(0xFF45464D),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Services Sub-views ---
  Widget _buildServicesView(List<String> serviceCategories, List<Service> filteredServices) {
    return Column(
      children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _servicesSearchQuery = val;
                  _updateFilteredData();
                });
              },
              style: GoogleFonts.inter(fontSize: 13),
              textInputAction: TextInputAction.search,
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
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              itemCount: serviceCategories.length,
              itemBuilder: (context, index) {
                final cat = serviceCategories[index];
                final isSelected = _servicesSelectedCategory == cat;
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
                        _servicesSelectedCategory = cat;
                        _updateFilteredData();
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          const Divider(height: 1),
          Expanded(
            child: filteredServices.isEmpty
                ? Center(
                    child: Text(
                      'No services in catalog.',
                      style: GoogleFonts.inter(color: const Color(0xFF7C839B), fontWeight: FontWeight.bold),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredServices.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final service = filteredServices[idx];
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
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF4FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: ApiClient.resolveUrl(service.imageUrl).isNotEmpty
                                ? Image.network(
                                    ApiClient.resolveUrl(service.imageUrl),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.auto_awesome_outlined,
                                      size: 16,
                                      color: Color(0xFF006A61),
                                    ),
                                  )
                                : const Icon(
                                    Icons.auto_awesome_outlined,
                                    size: 16,
                                    color: Color(0xFF006A61),
                                  ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  service.name,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
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
                                onPressed: () => _showAddEditServiceBottomSheet(service: service),
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
    );
  }





  // --- Inventory Sub-views ---
  Widget _buildInventoryView(List<InventoryItem> filteredInventory) {
    return Column(
      children: [
        // Search & filters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              TextField(
                onChanged: (val) {
                  setState(() {
                    _inventorySearchQuery = val;
                    _updateFilteredData();
                  });
                },
                style: GoogleFonts.inter(fontSize: 13),
                textInputAction: TextInputAction.search,
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
              CustomDropdownField<String>(
                label: 'Filter Status',
                value: _inventorySelectedFilter,
                items: const ['All', 'Low Stock', 'Fully Stocked'],
                itemLabel: (s) => s,
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _inventorySelectedFilter = val;
                      _updateFilteredData();
                    });
                  }
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: filteredInventory.isEmpty
              ? Center(
                  child: Text(
                    'No inventory items recorded.',
                    style: GoogleFonts.inter(color: const Color(0xFF7C839B), fontWeight: FontWeight.bold),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredInventory.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final item = filteredInventory[idx];
                    final isLow = item.currentStock <= item.reorderLevel;
                    return Card(
                      color: Colors.white,
                      elevation: 1,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
                        leading: CircleAvatar(
                          backgroundColor: isLow ? const Color(0xFFFFDAD6) : const Color(0xFFE6F4EA),
                          child: Icon(
                            isLow ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
                            color: isLow ? const Color(0xFFBA1A1A) : const Color(0xFF1E8E3E),
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
                              'Stock: ${item.currentStock} ${item.unit} (Limit: ${item.reorderLevel})',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isLow ? const Color(0xFFBA1A1A) : const Color(0xFF006A61),
                              ),
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
                                  '${item.currentStock}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
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
                              onPressed: () => _showAddEditInventoryBottomSheet(item: item),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              icon: const Icon(Icons.delete_outline, color: Color(0xFFBA1A1A), size: 18),
                              onPressed: () => _deleteInventoryItem(item.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Services filtering
    final serviceCategories = _serviceCategories;
    final filteredServices = _filteredServices;

    // Inventory filtering
    final filteredInventory = _filteredInventory;

    final isServices = _activeTab == 'Services';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text(
          isServices ? 'Services Catalog' : 'Inventory Stock',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Manage Categories',
            onPressed: _showCategoryManagementBottomSheet,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'catalog_fab',
        backgroundColor: const Color(0xFF006A61),
        foregroundColor: Colors.white,
        onPressed: () {
          if (_activeTab == 'Services') {
            _showAddEditServiceBottomSheet();
          } else {
            _showAddEditInventoryBottomSheet();
          }
        },
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
                      _buildSegmentedControl(),
                      Expanded(
                        child: _activeTab == 'Services'
                            ? _buildServicesView(serviceCategories, filteredServices)
                            : _buildInventoryView(filteredInventory),
                      ),
                    ],
                  ),
                ),
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
