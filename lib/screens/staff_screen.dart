import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/staff.dart';
import '../services/staff_service.dart';
import '../widgets/sidebar_drawer.dart';
import '../widgets/custom_text_field.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({Key? key}) : super(key: key);

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final StaffService _staffService = StaffService();
  List<StaffMember> _staff = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  Future<void> _fetchStaff() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final list = await _staffService.getAll();
      if (!mounted) return;
      setState(() {
        _staff = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load staff: $e')),
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

  void _showAddEditDialog({StaffMember? member}) {
    final isEdit = member != null;
    final nameController = TextEditingController(text: member?.name ?? '');
    final empCodeController = TextEditingController(text: member?.empCode ?? '');
    final contactController = TextEditingController(text: member?.contact ?? '');
    String role = member?.role ?? 'Specialist';
    String status = member?.status ?? 'Active';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            isEdit ? 'Modify Personnel Details' : 'Onboard New Staff',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: nameController,
                  label: 'Name',
                  placeholder: 'e.g. David Miller',
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: empCodeController,
                  label: 'Employee Code',
                  placeholder: 'e.g. SB-102',
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: contactController,
                  label: 'Contact Number',
                  placeholder: 'e.g. 9876543210',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.telephoneNumber],
                ),
                const SizedBox(height: 12),
                _buildDropdownField(
                  label: 'Role',
                  child: DropdownButton<String>(
                    value: role,
                    isExpanded: true,
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          role = val;
                        });
                      }
                    },
                    items: ['Manager', 'Specialist', 'Technician'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)))).toList(),
                  ),
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
                final empCode = empCodeController.text.trim();
                final contact = contactController.text.trim();

                if (name.isEmpty || empCode.isEmpty || contact.isEmpty) return;

                final payload = {
                  'name': name,
                  'empCode': empCode,
                  'contact': contact,
                  'role': role,
                  'status': status,
                };

                try {
                  if (isEdit) {
                    await _staffService.update(member.id, payload);
                  } else {
                    await _staffService.create(payload);
                  }
                  Navigator.pop(ctx);
                  _fetchStaff();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Operation failed: $e')),
                  );
                }
              },
              child: Text(isEdit ? 'Save Changes' : 'Establish Profile', style: GoogleFonts.inter()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteStaff(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Decommission Staff Profile?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to permanently remove this staff profile?', style: GoogleFonts.inter()),
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
        await _staffService.delete(id);
        _fetchStaff();
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
    final filtered = _staff.where((s) {
      return s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.empCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.role.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text('Staff Directory', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchStaff),
        ],
      ),
      drawer: const SidebarDrawer(activeRoute: '/staff'),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        child: TextField(
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
                            hintText: 'Search staff by name, code or role...',
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
                                'No staff members found.',
                                style: GoogleFonts.inter(color: const Color(0xFF7C839B), fontWeight: FontWeight.bold),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              itemCount: filtered.length,
                              separatorBuilder: (c, i) => const SizedBox(height: 8),
                              itemBuilder: (ctx, idx) {
                                final member = filtered[idx];
                                final isActive = member.status == 'Active';

                                return Card(
                                  color: Colors.white,
                                  elevation: 1,
                                  margin: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      children: [
                                        ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
                                          leading: CircleAvatar(
                                            backgroundColor: const Color(0xFFEFF4FF),
                                            child: Text(
                                              member.name.substring(0, 1).toUpperCase(),
                                              style: GoogleFonts.outfit(color: const Color(0xFF006A61), fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          title: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  member.name,
                                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF0B1C30), fontSize: 13),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isActive ? const Color(0xFFE6F4EA) : const Color(0xFFFFDAD6),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  member.status,
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
                                              Text('Employee Code: ${member.empCode} | Role: ${member.role}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF45464D))),
                                              const SizedBox(height: 2),
                                              Text('Contact: ${member.contact}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF7C839B))),
                                            ],
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                icon: const Icon(Icons.edit_outlined, color: Color(0xFF006A61), size: 18),
                                                onPressed: () => _showAddEditDialog(member: member),
                                              ),
                                              IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                icon: const Icon(Icons.delete_outline, color: Color(0xFFBA1A1A), size: 18),
                                                onPressed: () => _deleteStaff(member.id),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Divider(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          children: [
                                            Column(
                                              children: [
                                                Text(
                                                  '${member.totalBills}',
                                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF0B1C30)),
                                                ),
                                                Text(
                                                  'BILLS AUDITED',
                                                  style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF7C839B), fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              children: [
                                                Text(
                                                  '₹${NumberFormat('#,##,###').format(member.revenueGen)}',
                                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF006A61)),
                                                ),
                                                Text(
                                                  'REVENUE GENERATED',
                                                  style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF7C839B), fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ],
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
