import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart' as native_bt;
import '../models/bill.dart';
import '../models/business.dart';

enum PrinterConnectionState {
  disconnected,
  connecting,
  connected,
}

class BluetoothDevice {
  final String name;
  final String address;
  final dynamic nativeDevice; // holds native print_bluetooth_thermal BluetoothInfo reference

  BluetoothDevice({
    required this.name,
    required this.address,
    this.nativeDevice,
  });
}

class BluetoothPrinterService {
  static final BluetoothPrinterService _instance = BluetoothPrinterService._internal();
  factory BluetoothPrinterService() => _instance;
  BluetoothPrinterService._internal();

  PrinterConnectionState _connectionState = PrinterConnectionState.disconnected;
  BluetoothDevice? _connectedDevice;

  PrinterConnectionState get connectionState => _connectionState;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  Future<bool> isBluetoothOn() async {
    try {
      final bool isOn = await native_bt.PrintBluetoothThermal.bluetoothEnabled;
      return isOn;
    } catch (_) {
      return false;
    }
  }

  Future<List<BluetoothDevice>> scanForPrinters() async {
    try {
      final List<native_bt.BluetoothInfo> devices = await native_bt.PrintBluetoothThermal.pairedBluetooths;
      return devices.map((d) {
        return BluetoothDevice(
          name: d.name,
          address: d.macAdress,
          nativeDevice: d,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting bonded bluetooth devices: $e');
      return [];
    }
  }

  Future<bool> connect(BluetoothDevice device) async {
    _connectionState = PrinterConnectionState.connecting;
    
    try {
      final bool isConnected = await native_bt.PrintBluetoothThermal.connectionStatus;
      if (isConnected) {
        await native_bt.PrintBluetoothThermal.disconnect;
      }
      
      final bool success = await native_bt.PrintBluetoothThermal.connect(macPrinterAddress: device.address);
      if (success) {
        _connectionState = PrinterConnectionState.connected;
        _connectedDevice = device;
        return true;
      } else {
        _connectionState = PrinterConnectionState.disconnected;
        _connectedDevice = null;
        return false;
      }
    } catch (e) {
      _connectionState = PrinterConnectionState.disconnected;
      _connectedDevice = null;
      rethrow;
    }
  }

  Future<void> disconnect() async {
    try {
      await native_bt.PrintBluetoothThermal.disconnect;
    } finally {
      _connectionState = PrinterConnectionState.disconnected;
      _connectedDevice = null;
    }
  }

  Future<void> printReceipt(Bill bill, {String businessName = 'BillCom', Business? business}) async {
    final bool isConnected = await native_bt.PrintBluetoothThermal.connectionStatus;
    if (!isConnected) {
      throw Exception("Printer is not connected. Connect in settings first.");
    }

    final receiptText = formatReceipt(bill, businessName: businessName, business: business);
    
    final bool success = await native_bt.PrintBluetoothThermal.writeString(
      printText: native_bt.PrintTextSize(
        size: 1,
        text: receiptText,
      ),
    );
    if (!success) {
      throw Exception("Failed to send print job to Bluetooth device.");
    }
  }

  String formatReceipt(Bill bill, {String businessName = 'BillCom', Business? business}) {
    final buffer = StringBuffer();
    final int width = (business?.receiptTemplateType == 'Thermal58mm') ? 30 : 42;
    final divider = '-' * width;
    final doubleDivider = '=' * width;

    String centerText(String text) {
      if (text.length >= width) return text.substring(0, width);
      int padding = (width - text.length) ~/ 2;
      return ' ' * padding + text;
    }

    String justifyText(String left, String right) {
      int spaceNeeded = width - left.length - right.length;
      if (spaceNeeded <= 0) {
        return '$left $right';
      }
      return left + ' ' * spaceNeeded + right;
    }

    buffer.writeln(doubleDivider);
    
    // Shop Name (Business Name)
    final activeBusiness = business;
    final String? tName = activeBusiness?.tradingName;
    final String lName = activeBusiness?.legalName ?? '';
    
    final String shopName = (tName != null && tName.trim().isNotEmpty)
        ? tName.trim()
        : (lName.trim().isNotEmpty)
            ? lName.trim()
            : 'SHOP RECEIPT';
            
    buffer.writeln(centerText(shopName.toUpperCase()));
    
    // Receipt Header (e.g. welcome message)
    if (business?.receiptHeader != null && business!.receiptHeader!.trim().isNotEmpty) {
      buffer.writeln(centerText(business.receiptHeader!.trim()));
      buffer.writeln(divider);
    }
    
    buffer.writeln(centerText('POS TERMINAL RECEIPT'));
    
    // Branch Name (if different from shop name)
    if (bill.branchName != null && 
        bill.branchName!.isNotEmpty && 
        bill.branchName!.toLowerCase() != 'billcom' &&
        bill.branchName!.toLowerCase() != shopName.toLowerCase()) {
      buffer.writeln(centerText('Branch: ${bill.branchName}'));
    }
    buffer.writeln(doubleDivider);
    
    // Brand Logo Indicator if selected
    if (business?.showLogoOnReceipt == true && business?.logoUrl != null && business!.logoUrl!.trim().isNotEmpty) {
      buffer.writeln(centerText('[ Logo: ${business.logoUrl!.trim().split("/").last} ]'));
      buffer.writeln(divider);
    }

    buffer.writeln('Invoice: ${bill.billNumber}');
    buffer.writeln('Date: ${bill.createdAt.replaceAll('T', ' ').substring(0, 19)}');
    if (bill.customerName != null) {
      buffer.writeln('Client: ${bill.customerName}');
    }
    if (bill.staffName != null) {
      buffer.writeln('Operator: ${bill.staffName}');
    }
    buffer.writeln(divider);
    buffer.writeln(justifyText('Item (Qty x Price)', 'Total'));
    buffer.writeln(divider);

    for (final item in bill.items) {
      final String itemLabel = '${item.serviceName} (${item.quantity}x${item.unitPrice.toStringAsFixed(0)})';
      final String priceLabel = 'Rs. ${item.lineTotal.toStringAsFixed(0)}';
      
      if (itemLabel.length + priceLabel.length + 1 > width) {
        buffer.writeln(itemLabel);
        buffer.writeln(justifyText('', priceLabel));
      } else {
        buffer.writeln(justifyText(itemLabel, priceLabel));
      }
    }

    buffer.writeln(divider);
    buffer.writeln(justifyText('Subtotal:', 'Rs. ${bill.subtotal.toStringAsFixed(0)}'));
    
    if (bill.discountAmount > 0) {
      final discountLabel = 'Discount (${bill.discountCode ?? 'Code'}):';
      buffer.writeln(justifyText(discountLabel, '-Rs. ${bill.discountAmount.toStringAsFixed(0)}'));
    }
    
    buffer.writeln(justifyText('Tax Amount:', 'Rs. ${bill.taxAmount.toStringAsFixed(0)}'));
    buffer.writeln(doubleDivider);
    buffer.writeln(justifyText('GRAND TOTAL:', 'Rs. ${bill.totalAmount.toStringAsFixed(0)}'));
    buffer.writeln(doubleDivider);
    buffer.writeln('Payment Mode: ${bill.paymentMethod.toUpperCase()}');
    buffer.writeln('Bill Status: ${bill.status.toUpperCase()}');
    buffer.writeln(doubleDivider);

    // Receipt Footer
    if (business?.receiptFooter != null && business!.receiptFooter!.trim().isNotEmpty) {
      buffer.writeln(centerText(business.receiptFooter!.trim()));
    } else {
      buffer.writeln(centerText('Thank you for your business!'));
    }
    
    buffer.writeln(divider);
    buffer.writeln(centerText('Powered by BillCom'));
    buffer.writeln(doubleDivider);
    
    // Add extra line feeds at the end to prevent the text from getting cut off when tearing the paper
    buffer.writeln();
    buffer.writeln();
    buffer.writeln();
    buffer.writeln();

    return buffer.toString();
  }
}
