import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../services/dashboard_service.dart';
import '../widgets/sidebar_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _dashboardService.getDashboardData();
      if (!mounted) return;
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception:', '').trim();
        _isLoading = false;
      });
    }
  }

  Widget _buildMetricsCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Icon(icon, size: 28, color: color.withValues(alpha: 0.12)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: textColor?.withValues(alpha: 0.8) ?? const Color(0xFF45464D),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: textColor ?? const Color(0xFF0B1C30),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: textColor?.withValues(alpha: 0.7) ?? const Color(0xFF7C839B),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentBranch = authProvider.currentBranch;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text(
          'SmartBill Pro',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        actions: [
          // Branch selector dropdown
          DropdownButton<String>(
            value: currentBranch,
            underline: Container(),
            icon: const Icon(Icons.location_on, color: Color(0xFF006A61)),
            onChanged: (String? val) {
              if (val != null) {
                authProvider.changeBranch(val);
                _fetchData();
              }
            },
            items: <String>['Main', 'Downtown'].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  '$value Branch',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const SidebarDrawer(activeRoute: '/dashboard'),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF006A61)),
                  const SizedBox(height: 12),
                  Text(
                    'Compiling Terminal Analytics...',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF7C839B),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Color(0xFFBA1A1A)),
                        const SizedBox(height: 12),
                        Text(
                          'Synchronization Error\n$_error',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFFBA1A1A)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchData,
                          child: Text('Try Again', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row
                           Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Today\'s Overview',
                                    style: GoogleFonts.outfit(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF0B1C30),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Live metrics for $currentBranch Branch',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF45464D),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF006A61),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pushReplacementNamed('/billing');
                                },
                                child: Text(
                                  'New Quick Bill',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12), // Shrank from 16

                          // Bento Stats Row (Responsive Layout)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              final crossAxisCount = width > 900 ? 4 : (width > 600 ? 2 : 2);
                              final childAspectRatio = width > 900 ? 2.4 : (width > 600 ? 2.6 : 1.45);
                              return GridView.count(
                                crossAxisCount: crossAxisCount,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 10, // Shrank from 12
                                mainAxisSpacing: 10,  // Shrank from 12
                                childAspectRatio: childAspectRatio,
                                children: [
                                  _buildMetricsCard(
                                    title: 'Revenue',
                                    value: '₹${NumberFormat('#,##,###').format(_dashboardData?['summary']['totalRevenue'] ?? 0)}',
                                    subtitle: 'Live catalog data',
                                    icon: Icons.monetization_on_outlined,
                                    color: const Color(0xFF006A61),
                                  ),
                                  _buildMetricsCard(
                                    title: 'Bills',
                                    value: '${_dashboardData?['summary']['totalBills'] ?? 0}',
                                    subtitle: 'Invoices created',
                                    icon: Icons.receipt_long_outlined,
                                    color: const Color(0xFF86F2E4),
                                  ),
                                  _buildMetricsCard(
                                    title: 'Customers',
                                    value: '${_dashboardData?['summary']['totalCustomers'] ?? 0}',
                                    subtitle: 'Active CRM accounts',
                                    icon: Icons.people_outline,
                                    color: const Color(0xFF45464D),
                                  ),
                                  _buildMetricsCard(
                                    title: 'Low Stock',
                                    value: '${_dashboardData?['summary']['lowStockCount'] ?? 0}',
                                    subtitle: 'SKUs below safety',
                                    icon: Icons.warning_amber_outlined,
                                    color: const Color(0xFFBA1A1A),
                                    backgroundColor: const Color(0xFFFFDAD6).withValues(alpha: 0.2),
                                    textColor: const Color(0xFFBA1A1A),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 12), // Shrank from 20),

                          LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              if (width > 900) {
                                return Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: _buildRevenueTrendCard(),
                                        ),
                                        const SizedBox(width: 12), // Shrank from 20
                                        Expanded(
                                          flex: 1,
                                          child: _buildTopServicesCard(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12), // Shrank from 20
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: _buildRecentInvoicesCard(),
                                        ),
                                        const SizedBox(width: 12), // Shrank from 20
                                        Expanded(
                                          flex: 1,
                                          child: _buildLowStockCard(),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              } else {
                                return Column(
                                  children: [
                                    _buildRevenueTrendCard(),
                                    const SizedBox(height: 12), // Shrank from 20
                                    _buildTopServicesCard(),
                                    const SizedBox(height: 12),
                                    _buildRecentInvoicesCard(),
                                    const SizedBox(height: 12),
                                    _buildLowStockCard(),
                                  ],
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildRevenueTrendCard() {
    final list = _dashboardData?['salesTrend'] as List? ?? [];
    // Chronological last 7 days calculation
    final List<Map<String, dynamic>> trendData = [];
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final label = DateFormat('E, d').format(date);

      double rev = 0.0;
      final matched = list.firstWhere(
        (item) {
          final sDate = item['salesDate']?.toString() ?? '';
          return sDate.startsWith(dateStr);
        },
        orElse: () => null,
      );
      if (matched != null) {
        rev = (matched['dailyRevenue'] as num).toDouble();
      }

      trendData.add({
        'label': label,
        'revenue': rev,
      });
    }

    double maxRevenue = trendData.fold<double>(
      1.0,
      (max, item) => item['revenue'] > max ? item['revenue'] : max,
    );    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12), // Shrank from 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Trend',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0B1C30)),
          ),
          Text(
            'Daily billing aggregates (last 7 days)',
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF7C839B)),
          ),
          const SizedBox(height: 12), // Shrank from 16
          // Chart view
          Container(
            height: 140, // Shrank from 150
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: trendData.map((d) {
                final double revenue = d['revenue'];
                final double percent = revenue / maxRevenue;
                final double height = (percent * 90).clamp(6.0, 90.0); // Adjusted height

                return Expanded(
                  child: Tooltip(
                    message: '₹${NumberFormat('#,##,###').format(revenue)}',
                    triggerMode: TooltipTriggerMode.tap,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 20,
                          height: height,
                          decoration: BoxDecoration(
                            color: const Color(0xFF006A61).withValues(alpha: percent > 0.8 ? 1.0 : 0.4),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          d['label'],
                          style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFF7C839B)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopServicesCard() {
    final list = _dashboardData?['topServices'] as List? ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12), // Shrank from 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Services',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0B1C30)),
          ),
          Text(
            'By revenue contribution',
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF7C839B)),
          ),
          const SizedBox(height: 8), // Shrank from 12
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No sales data available yet.',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF7C839B), fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (c, idx) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
              itemBuilder: (ctx, idx) {
                final item = list[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0), // Shrank from 8.0
                  child: Row(
                    children: [
                      Container(
                        width: 32, // Shrank from 36
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF86F2E4).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.content_cut, color: Color(0xFF006A61), size: 14),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['serviceName'] ?? 'Service',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0B1C30)),
                            ),
                            Text(
                              '${item['totalQuantity'] ?? 0} bookings',
                              style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF7C839B), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${NumberFormat('#,##,###').format(item['totalRevenue'] ?? 0)}',
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0B1C30)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRecentInvoicesCard() {
    final list = _dashboardData?['recentBills'] as List? ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12), // Shrank from 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Activity Logs',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0B1C30)),
                  ),
                  Text(
                    'Real-time point-of-sale audits',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF7C839B)),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/billing');
                },
                child: Text(
                  'POS Terminal →',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF006A61)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4), // Shrank from 8
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No recent invoices recorded.',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF7C839B), fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (c, idx) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
              itemBuilder: (ctx, idx) {
                final item = list[idx];
                final time = DateTime.tryParse(item['createdAt'] ?? '') ?? DateTime.now();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0), // Shrank from 10.0
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['billNumber'] ?? '',
                              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF006A61)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item['customerName'] ?? 'Walk-In Customer'} • ${DateFormat.jm().format(time)}',
                              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF45464D), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F4EA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Paid',
                          style: GoogleFonts.inter(color: const Color(0xFF1E8E3E), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '₹${NumberFormat('#,##,###').format(item['totalAmount'] ?? 0)}',
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0B1C30)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLowStockCard() {
    final list = _dashboardData?['lowStockItems'] as List? ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12), // Shrank from 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stock Safeguards',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0B1C30)),
          ),
          Text(
            'Critical reorder status',
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF7C839B)),
          ),
          const SizedBox(height: 8), // Shrank from 12
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, color: Color(0xFF1E8E3E), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'All items fully stocked!',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1E8E3E), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (c, idx) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
              itemBuilder: (ctx, idx) {
                final item = list[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0), // Shrank from 8.0
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Color(0xFFBA1A1A), size: 16), // Shrank from 18
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] ?? '',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0B1C30)),
                            ),
                            Text(
                              item['sku'] ?? '',
                              style: GoogleFonts.shareTechMono(fontSize: 9, color: const Color(0xFFBA1A1A), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${item['currentStock'] ?? 0} ${item['unit'] ?? ''}',
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFFBA1A1A)),
                          ),
                          Text(
                            'Limit: ${item['reorderLevel'] ?? 0}',
                            style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF7C839B), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
