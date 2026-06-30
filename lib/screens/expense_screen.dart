import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dropdown_field.dart';
import '../widgets/confirm_sheet.dart';
import '../models/category.dart';
import '../services/category_service.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({Key? key}) : super(key: key);

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final CategoryService _categoryService = CategoryService();
  List<Expense> _expenses = [];
  List<Category> _dbCategories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategoryFilter = 'All';

  List<Expense> _filteredExpenses = [];
  double _totalExpenses = 0.0;

  void _updateFilteredData() {
    _filteredExpenses = _expenses.where((exp) {
      final matchesQuery = exp.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          exp.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategoryFilter == 'All' || exp.category == _selectedCategoryFilter;
      return matchesQuery && matchesCategory;
    }).toList();
    _totalExpenses = _filteredExpenses.fold(0.0, (sum, exp) => sum + exp.amount);
  }



  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final list = await _expenseService.getAll();
      final catList = await CategoryService().getAll();
      final expCats = catList.where((c) => c.type == 'Expense').toList();
      if (!mounted) return;
      setState(() {
        _expenses = list;
        _dbCategories = expCats;
        _isLoading = false;
        _updateFilteredData();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load expenses: $e')),
      );
    }
  }

  void _showAddBottomSheet() {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    final expenseCategoryNames = getExpenseCategoryNames();
    String selectedCategory = expenseCategoryNames.isNotEmpty ? expenseCategoryNames.first : 'Other';
    DateTime selectedDate = DateTime.now();

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
                          'Log Business Expense',
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
                          controller: descController,
                          label: 'Description',
                          placeholder: 'e.g. Broadband Office Bill',
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: amountController,
                          label: 'Amount (₹)',
                          placeholder: 'e.g. 1500',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 12),
                        CustomDropdownField<String>(
                          label: 'Category',
                          value: selectedCategory,
                          items: expenseCategoryNames,
                          itemLabel: (s) => s,
                          onChanged: (val) {
                            if (val != null) {
                              setBottomSheetState(() {
                                selectedCategory = val;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Date Picker
                        Text(
                          'EXPENSE DATE',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF7C839B),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final picker = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picker != null) {
                              setBottomSheetState(() {
                                selectedDate = picker;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFFC6C6CD)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('yyyy-MM-dd').format(selectedDate),
                                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0B1C30), fontWeight: FontWeight.w600),
                                ),
                                const Icon(Icons.calendar_today, size: 16, color: Color(0xFF006A61)),
                              ],
                            ),
                          ),
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
                            final desc = descController.text.trim();
                            final amountText = amountController.text.trim();
                            final amount = double.tryParse(amountText) ?? 0.0;

                            if (desc.isEmpty || amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a description and positive amount.')),
                              );
                              return;
                            }

                            final payload = {
                              'description': desc,
                              'amount': amount,
                              'category': selectedCategory,
                              'expenseDate': selectedDate.toIso8601String(),
                            };

                            try {
                              await _expenseService.create(payload);
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                              _fetchExpenses();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Expense logged successfully!')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Operation failed: $e')),
                                );
                              }
                            }
                          },
                          child: Text('Log Expense', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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

  Future<void> _deleteExpense(int id) async {
    final confirm = await ConfirmSheet.show(
      context: context,
      title: 'Delete Expense Record?',
      message: 'Are you sure you want to permanently erase this transaction from bookkeeping?',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirm == true) {
      try {
        await _expenseService.delete(id);
        _fetchExpenses();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense record deleted.')),
        );
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
    final filtered = _filteredExpenses;

    final double totalExpenses = _totalExpenses;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text('Expense Ledger', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Manage Categories',
            onPressed: _showCategoryManagementBottomSheet,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'expense_fab',
        backgroundColor: const Color(0xFF006A61),
        foregroundColor: Colors.white,
        onPressed: _showAddBottomSheet,
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
                      // Top KPI HUD banner
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF006A61), Color(0xFF004D46)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF006A61).withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_outlined,
                                color: Color(0xFF86F2E4),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TOTAL BOOKKEEPIN EXPENDITURE',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF86F2E4),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${NumberFormat('#,##,###').format(totalExpenses)}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Filter Controls
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                        child: Column(
                          children: [
                            TextField(
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val;
                                  _updateFilteredData();
                                });
                              },
                              style: GoogleFonts.inter(fontSize: 13),
                              textInputAction: TextInputAction.search,
                              autocorrect: false,
                              decoration: InputDecoration(
                                hintText: 'Search expenses description or category...',
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
                              label: 'Filter Category',
                              value: _selectedCategoryFilter,
                              items: ['All', ..._dbCategories.map((c) => c.name)],
                              itemLabel: (s) => s,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedCategoryFilter = val;
                                    _updateFilteredData();
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),

                      // Expenses List
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'No expense logs found.',
                                  style: GoogleFonts.inter(color: const Color(0xFF7C839B), fontWeight: FontWeight.bold),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: filtered.length,
                                separatorBuilder: (c, i) => const SizedBox(height: 8),
                                itemBuilder: (ctx, idx) {
                                  final exp = filtered[idx];
                                  final displayDate = exp.expenseDate.length >= 10
                                      ? exp.expenseDate.substring(0, 10)
                                      : exp.expenseDate;
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
                                        backgroundColor: const Color(0xFFFFDAD6),
                                        child: const Icon(
                                          Icons.trending_down,
                                          color: Color(0xFFBA1A1A),
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        exp.description,
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF0B1C30), fontSize: 13),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFEFF4FF),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    exp.category.toUpperCase(),
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFF006A61)),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Date: $displayDate',
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF7C839B), fontWeight: FontWeight.w500),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '₹${NumberFormat('#,##,###').format(exp.amount)}',
                                            style: GoogleFonts.outfit(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                              color: const Color(0xFFBA1A1A),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            icon: const Icon(Icons.delete_outline, color: Color(0xFFBA1A1A), size: 18),
                                            onPressed: () => _deleteExpense(exp.id),
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

  void _showCategoryManagementBottomSheet() {
    final TextEditingController newCatController = TextEditingController();
    
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
          final expenseCategories = _dbCategories;
          
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              height: 450,
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
                          'Manage Expense Categories',
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
                    child: Row(
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
                            
                            if (_dbCategories.any((c) => c.name.toLowerCase() == name.toLowerCase())) {
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
                                'type': 'Expense',
                              });
                              newCatController.clear();
                              final updatedList = await _categoryService.getAll();
                              final expCats = updatedList.where((c) => c.type == 'Expense').toList();
                              setState(() {
                                _dbCategories = expCats;
                              });
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
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: expenseCategories.isEmpty
                        ? Center(
                            child: Text(
                              'No categories created yet.',
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF7C839B), fontWeight: FontWeight.bold),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: expenseCategories.length,
                            separatorBuilder: (c, i) => const Divider(height: 1),
                            itemBuilder: (ctx, idx) {
                              final cat = expenseCategories[idx];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  cat.name,
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0B1C30)),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Color(0xFFBA1A1A), size: 18),
                                  onPressed: () async {
                                    final confirm = await ConfirmSheet.show(
                                      context: context,
                                      title: 'Delete Category?',
                                      message: 'Are you sure you want to delete "${cat.name}"?',
                                      confirmText: 'Delete',
                                      cancelText: 'Cancel',
                                      isDestructive: true,
                                    );
                                    if (confirm == true) {
                                      try {
                                        await _categoryService.delete(cat.id);
                                        final updatedList = await _categoryService.getAll();
                                        final expCats = updatedList.where((c) => c.type == 'Expense').toList();
                                        setState(() {
                                          _dbCategories = expCats;
                                        });
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

  List<String> getExpenseCategoryNames() {
    return _dbCategories.map((c) => c.name).toSet().toList();
  }
}
