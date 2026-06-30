import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/bill.dart';
import '../../models/business.dart';
import '../../providers/bluetooth_printer_provider.dart';
import '../../services/bluetooth_printer_service.dart';

class PrinterPage extends StatefulWidget {
  final Business? businessProfile;

  const PrinterPage({
    Key? key,
    required this.businessProfile,
  }) : super(key: key);

  @override
  State<PrinterPage> createState() => _PrinterPageState();
}

class _PrinterPageState extends State<PrinterPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final printerProvider = Provider.of<BluetoothPrinterProvider>(context, listen: false);
        if (printerProvider.connectionState != PrinterConnectionState.connected) {
          printerProvider.startScan();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Printer', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: Consumer<BluetoothPrinterProvider>(
        builder: (context, printerProvider, child) {
          final isConnected = printerProvider.connectionState == PrinterConnectionState.connected;
          final isConnecting = printerProvider.connectionState == PrinterConnectionState.connecting;
          final hasSavedPrinter = printerProvider.savedPrinterAddress != null;

          return ListView(
            children: [
              const SizedBox(height: 8),

              // Status indicator
              _buildStatusSection(isConnected, isConnecting, hasSavedPrinter),

              const Divider(height: 32),

              // Connected printer info
              if (isConnected && printerProvider.connectedDevice != null) ...[
                _buildConnectedSection(printerProvider),
              ] else if (hasSavedPrinter) ...[
                _buildSavedPrinterSection(printerProvider, isConnecting),
              ] else ...[
                _buildNoPrinterSection(printerProvider),
              ],

              // Error display
              if (printerProvider.errorMessage != null) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            printerProvider.errorMessage!,
                            style: GoogleFonts.inter(
                              color: const Color(0xFFDC2626),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Test print (when connected)
              if (isConnected) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF006A61),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _printTestReceipt(printerProvider),
                    icon: const Icon(Icons.print_rounded, size: 20),
                    label: Text('Print test receipt', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusSection(bool isConnected, bool isConnecting, bool hasSavedPrinter) {
    Color statusColor;
    Color statusBgColor;
    String statusText;
    IconData statusIcon;

    if (isConnected) {
      statusColor = const Color(0xFF16A34A);
      statusBgColor = const Color(0xFFF0FDF4);
      statusText = 'Connected';
      statusIcon = Icons.check_circle_rounded;
    } else if (isConnecting) {
      statusColor = const Color(0xFFD97706);
      statusBgColor = const Color(0xFFFFFBEB);
      statusText = 'Connecting...';
      statusIcon = Icons.sync_rounded;
    } else if (hasSavedPrinter) {
      statusColor = const Color(0xFF006A61);
      statusBgColor = const Color(0xFFE8F5F3);
      statusText = 'Paired';
      statusIcon = Icons.bluetooth_rounded;
    } else {
      statusColor = const Color(0xFF6B7280);
      statusBgColor = const Color(0xFFF3F4F6);
      statusText = 'Not connected';
      statusIcon = Icons.bluetooth_disabled_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: statusBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Printer status',
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedSection(BluetoothPrinterProvider printerProvider) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5F3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.print_rounded, color: Color(0xFF006A61), size: 20),
          ),
          title: Text(
            printerProvider.connectedDevice!.name,
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            printerProvider.connectedDevice!.address,
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => printerProvider.disconnectDevice(),
            child: Text('Disconnect', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedPrinterSection(BluetoothPrinterProvider printerProvider, bool isConnecting) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.print_rounded, color: Color(0xFF6B7280), size: 20),
          ),
          title: Text(
            printerProvider.savedPrinterName ?? 'Saved printer',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            printerProvider.savedPrinterAddress ?? '',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ElevatedButton(
            onPressed: isConnecting ? null : () => printerProvider.connectToSavedPrinter(),
            child: Text(
              isConnecting ? 'Connecting...' : 'Connect',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF006A61),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: printerProvider.isScanning ? null : () => printerProvider.autoDetectAndConnect(),
            icon: printerProvider.isScanning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF006A61)),
                  )
                : const Icon(Icons.search_rounded, size: 20),
            label: Text(
              printerProvider.isScanning ? 'Scanning...' : 'Scan for printers',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoPrinterSection(BluetoothPrinterProvider printerProvider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.print_rounded, color: Color(0xFFD1D5DB), size: 40),
                const SizedBox(height: 12),
                Text(
                  'No printer found',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pair your thermal printer via Bluetooth settings first, then scan here to connect.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ElevatedButton.icon(
            onPressed: printerProvider.isScanning ? null : () => printerProvider.autoDetectAndConnect(),
            icon: printerProvider.isScanning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.search_rounded, size: 20),
            label: Text(
              printerProvider.isScanning ? 'Scanning...' : 'Scan for printers',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  void _printTestReceipt(BluetoothPrinterProvider printerProvider) async {
    final testBill = Bill(
      id: 0,
      customerId: 0,
      billNumber: 'INV-TEST-99',
      subtotal: 350.0,
      discountCode: 'WELCOME',
      discountAmount: 50.0,
      taxAmount: 15.0,
      totalAmount: 315.0,
      paymentMethod: 'UPI',
      status: 'Paid',
      createdAt: DateTime.now().toIso8601String(),
      customerName: 'Test Customer',
      customerPhone: '9876543210',
      staffName: 'Admin',
      branchName: widget.businessProfile?.tradingName ?? 'Main Branch',
      items: [
        BillItem(
          serviceId: 1,
          serviceName: 'Hair Styling & Wash',
          unitPrice: 350.0,
          quantity: 1,
          lineTotal: 350.0,
        ),
      ],
    );

    final success = await printerProvider.printBill(
      testBill,
      businessName: widget.businessProfile?.legalName ?? 'BillCom',
      business: widget.businessProfile,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Test receipt printed' : 'Print failed: ${printerProvider.errorMessage ?? "Unknown error"}',
          ),
        ),
      );
    }
  }
}
