import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bill.dart';
import '../models/business.dart';
import '../services/bluetooth_printer_service.dart';
import '../services/business_service.dart';

class BluetoothPrinterProvider extends ChangeNotifier {
  final BluetoothPrinterService _service = BluetoothPrinterService();

  bool _isScanning = false;
  List<BluetoothDevice> _scannedDevices = [];
  String? _errorMessage;
  String? _savedPrinterAddress;
  String? _savedPrinterName;

  BluetoothPrinterProvider() {
    loadSavedPrinter().then((_) {
      autoDetectAndConnect();
    });
  }

  bool get isScanning => _isScanning;
  List<BluetoothDevice> get scannedDevices => _scannedDevices;
  String? get errorMessage => _errorMessage;
  String? get savedPrinterAddress => _savedPrinterAddress;
  String? get savedPrinterName => _savedPrinterName;

  PrinterConnectionState get connectionState => _service.connectionState;
  BluetoothDevice? get connectedDevice => _service.connectedDevice;

  Future<void> loadSavedPrinter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _savedPrinterAddress = prefs.getString('saved_printer_address');
      _savedPrinterName = prefs.getString('saved_printer_name');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading saved printer: $e');
    }
  }

  Future<void> savePrinter(String address, String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_printer_address', address);
      await prefs.setString('saved_printer_name', name);
      _savedPrinterAddress = address;
      _savedPrinterName = name;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving printer: $e');
    }
  }

  Future<void> clearSavedPrinter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_printer_address');
      await prefs.remove('saved_printer_name');
      _savedPrinterAddress = null;
      _savedPrinterName = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing saved printer: $e');
    }
  }

  Future<bool> autoDetectAndConnect() async {
    _isScanning = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Request permissions on Android
      final connectStatus = await Permission.bluetoothConnect.request();
      final scanStatus = await Permission.bluetoothScan.request();

      if (connectStatus.isDenied || scanStatus.isDenied) {
        throw Exception("Bluetooth permissions denied. Please grant permissions in app settings.");
      }

      // 2. Check if Bluetooth is turned on
      final isBtOn = await _service.isBluetoothOn();
      if (!isBtOn) {
        throw Exception("Bluetooth is turned off. Please turn it on in mobile system settings.");
      }

      // 3. Get paired (bonded) devices
      final devices = await _service.scanForPrinters();
      _scannedDevices = devices;
      
      if (devices.isEmpty) {
        throw Exception("No paired Bluetooth devices found in your mobile system settings.");
      }

      BluetoothDevice? matchedDevice;

      // Try matching by previously saved address
      if (_savedPrinterAddress != null) {
        try {
          matchedDevice = devices.firstWhere((d) => d.address == _savedPrinterAddress);
        } catch (_) {}
      }

      // Try matching by printer keywords in the device name
      if (matchedDevice == null) {
        final keywords = ['print', 'pos', 'thermal', 'mpt', 'ept', 'wsp', 'billing', 'mach'];
        try {
          matchedDevice = devices.firstWhere((d) {
            final name = d.name.toLowerCase();
            return keywords.any((kw) => name.contains(kw));
          });
         } catch (_) {}
      }

      // Fallback: if only one paired device exists, use it
      if (matchedDevice == null && devices.length == 1) {
        matchedDevice = devices.first;
      }

      if (matchedDevice == null) {
        throw Exception("Could not automatically identify a billing printer. Please pair it in mobile settings.");
      }

      // Save matched configuration
      await savePrinter(matchedDevice.address, matchedDevice.name);

      // Connect if not already connected
      if (connectionState == PrinterConnectionState.connected && connectedDevice?.address == matchedDevice.address) {
        return true;
      }

      return await connectToDevice(matchedDevice);
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      debugPrint('Error auto-detecting/connecting printer: $e');
      return false;
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> startScan() async {
    await autoDetectAndConnect();
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    _errorMessage = null;
    notifyListeners(); // Updates status to connecting
    try {
      final success = await _service.connect(device);
      if (success) {
        await savePrinter(device.address, device.name);
      }
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      debugPrint('Error connecting to printer: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> connectToSavedPrinter() async {
    return await autoDetectAndConnect();
  }

  Future<void> disconnectDevice() async {
    try {
      await _service.disconnect();
      notifyListeners();
    } catch (e) {
      debugPrint('Error disconnecting printer: $e');
      notifyListeners();
    }
  }

  Future<bool> printBill(Bill bill, {String businessName = 'BillCom', Business? business}) async {
    _errorMessage = null;
    try {
      Business? activeBusiness = business;
      try {
        activeBusiness = await BusinessService().getProfile().timeout(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('Failed to fetch fresh business profile for printing: $e');
        // fall back to the passed parameter
      }
      await _service.printReceipt(bill, businessName: businessName, business: activeBusiness);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      notifyListeners();
      return false;
    }
  }

  String formatReceipt(Bill bill, {String businessName = 'BillCom', Business? business}) {
    return _service.formatReceipt(bill, businessName: businessName, business: business);
  }
}
