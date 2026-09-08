import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/printer_service.dart';
import '../services/label_printer_service.dart';

class PrinterProvider extends ChangeNotifier {
  static const String _paperSizeKey = 'printer_paper_width_mm';
  static const String _printModeKey = 'printer_print_mode';

  /// Penanda bahwa setelan mode warisan sudah dinetralkan sekali.
  static const String _printModeResetKey = 'printer_print_mode_reset_v1';

  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;
  bool _isLoading = false;
  int _paperWidthMm = ReceiptPaper.defaultWidthMm;
  PrintMode _printMode = PrintMode.escPosText;

  List<BluetoothDevice> get devices => _devices;
  BluetoothDevice? get selectedDevice => _selectedDevice;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;

  /// Lebar kertas thermal aktif dalam mm (58 / 72 / 80).
  int get paperWidthMm => _paperWidthMm;
  List<int> get supportedPaperWidths => ReceiptPaper.supportedWidthsMm;

  /// Bahasa + cara render yang dipakai saat mencetak.
  PrintMode get printMode => _printMode;

  PrinterProvider() {
    _initPrinter();
  }

  Future<void> _initPrinter() async {
    await _loadPrintSettings();

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

  Future<void> _loadPrintSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_paperSizeKey);
    if (saved != null) {
      _paperWidthMm = ReceiptPaper.normalize(saved);
    }
    // Sampai versi 1.2.0 pilihan mode printer tidak berpengaruh apa pun saat
    // mencetak - semua struk keluar sebagai ESC/POS teks apa pun chip yang
    // dipilih, dan chip itu berdampingan dengan tombol tes yang berfungsi. Jadi
    // setelan yang tersimpan bisa saja sisa coba-coba, bukan pilihan sadar.
    // Begitu modenya benar-benar dipakai, setelan warisan itu dinetralkan
    // sekali supaya tidak ada kasir yang struknya mendadak kosong setelah
    // update tanpa tahu sebabnya.
    if (!(prefs.getBool(_printModeResetKey) ?? false)) {
      await prefs.remove(_printModeKey);
      await prefs.setBool(_printModeResetKey, true);
    }

    _printMode = PrintMode.fromStorage(prefs.getString(_printModeKey));
  }

  /// Ubah bahasa + cara render printer dan simpan permanen.
  Future<void> setPrintMode(PrintMode mode) async {
    if (mode == _printMode) return;
    _printMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_printModeKey, mode.storageKey);
  }

  /// Ubah lebar kertas thermal (58 / 72 / 80 mm) dan simpan permanen.
  Future<void> setPaperWidth(int widthMm) async {
    final normalized = ReceiptPaper.normalize(widthMm);
    if (normalized == _paperWidthMm) return;
    _paperWidthMm = normalized;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_paperSizeKey, normalized);
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
      
      final match = _devices.where((d) => d.address == address).firstOrNull;
      if (match != null) {
        _selectedDevice = match;
        // Try to connect automatically
        if (!_isConnected) {
          await connect(_selectedDevice!);
        }
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
      // Chunked transmission to prevent UART buffer overflow on 58mm bluetooth printers
      const int chunkSize = 80;
      for (int i = 0; i < bytes.length; i += chunkSize) {
        final end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        final chunk = bytes.sublist(i, end);
        await _bluetooth.writeBytes(Uint8List.fromList(chunk));
        await Future.delayed(const Duration(milliseconds: 25));
      }
      return true;
    } catch (e) {
      debugPrint("Print error: $e");
      return false;
    }
  }

}
