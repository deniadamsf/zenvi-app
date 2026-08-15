import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterProvider extends ChangeNotifier {
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;
  bool _isLoading = false;

  List<BluetoothDevice> get devices => _devices;
  BluetoothDevice? get selectedDevice => _selectedDevice;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;

  PrinterProvider() {
    _initPrinter();
  }

  Future<void> _initPrinter() async {
    _bluetooth.onStateChanged().listen((state) {
      switch (state) {
        case BlueThermalPrinter.CONNECTED:
          _isConnected = true;
          break;
        case BlueThermalPrinter.DISCONNECTED:
        case BlueThermalPrinter.DISCONNECT_REQUESTED:
          _isConnected = false;
          break;
        default:
          break;
      }
      notifyListeners();
    });
    
    // Check if connected
    _isConnected = (await _bluetooth.isConnected) ?? false;
    
    await scanDevices();
    await _loadSavedPrinter();
  }

  Future<void> scanDevices() async {
    _isLoading = true;
    notifyListeners();
    try {
      _devices = await _bluetooth.getBondedDevices();
    } catch (e) {
      debugPrint("Error scanning bluetooth devices: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> connect(BluetoothDevice device) async {
    if (_isConnected) {
      await _bluetooth.disconnect();
    }
    
    try {
      final isSuccess = await _bluetooth.connect(device);
      if (isSuccess == true) {
        _selectedDevice = device;
        _isConnected = true;
        await _savePrinter(device);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error connecting to printer: $e");
    }
    return false;
  }

  Future<void> disconnect() async {
    await _bluetooth.disconnect();
    _isConnected = false;
    notifyListeners();
  }

  Future<void> _savePrinter(BluetoothDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'name': device.name,
      'address': device.address,
    };
    await prefs.setString('saved_printer', jsonEncode(data));
  }

  Future<void> _loadSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('saved_printer');
    if (savedData != null) {
      final data = jsonDecode(savedData);
      final address = data['address'];
      
      // Find in scanned devices
      try {
        _selectedDevice = _devices.firstWhere((d) => d.address == address);
        // Try to connect automatically
        if (!_isConnected) {
          await connect(_selectedDevice!);
        }
      } catch (e) {
        // Device not found in paired list
      }
    }
  }

  Future<bool> printBytes(List<int> bytes) async {
    if (!_isConnected) {
      if (_selectedDevice != null) {
        bool reconnected = await connect(_selectedDevice!);
        if (!reconnected) return false;
      } else {
        return false;
      }
    }
    
    try {
      await _bluetooth.writeBytes(Uint8List.fromList(bytes));
      return true;
    } catch (e) {
      debugPrint("Print error: $e");
      return false;
    }
  }
}
