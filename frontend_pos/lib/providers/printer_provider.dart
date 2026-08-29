import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import '../services/printer_service.dart';
import '../services/label_printer_service.dart';

class PrinterProvider extends ChangeNotifier {
  static const String _paperSizeKey = 'printer_paper_width_mm';
  static const String _printModeKey = 'printer_print_mode';

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

  /// Cetak sampel diagnosa memakai satu mode printer tertentu.
  ///
  /// Dipakai untuk mencari tahu bahasa apa yang dimengerti printer: kalau
  /// hanya salah satu mode yang menghasilkan tulisan, mode itulah yang benar.
  Future<bool> printTestWithMode(PrintMode mode, {String? storeName}) async {
    final name = (storeName ?? 'ZENVI POS').toUpperCase();
    final timestamp = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
    final label = _modeLabel(mode);

    if (mode == PrintMode.escPosText) {
      return printTestReceipt(storeName: storeName);
    }

    if (mode.render == PrintRender.text) {
      final lines = [name, 'MODE: $label', timestamp, 'Lebar: ${_paperWidthMm}mm'];
      switch (mode.language) {
        case PrintLanguage.tspl:
          return printBytes(LabelPrinterService.buildTsplText(lines));
        case PrintLanguage.cpcl:
          return printBytes(LabelPrinterService.buildCpclText(lines));
        case PrintLanguage.escPos:
          return printTestReceipt(storeName: storeName);
      }
    }

    final image = LabelPrinterService.buildDiagnosticImage(
      modeLabel: 'MODE: $label',
      dotWidth: ReceiptPaper.dotWidth(_paperWidthMm),
      storeName: name,
      timestamp: timestamp,
    );

    switch (mode.language) {
      case PrintLanguage.tspl:
        return printBytes(LabelPrinterService.buildTsplImage(image));
      case PrintLanguage.cpcl:
        return printBytes(LabelPrinterService.buildCpclImage(image));
      case PrintLanguage.escPos:
        return printBytes(await LabelPrinterService.buildEscPosImage(
          image,
          ReceiptPaper.toPaperSize(_paperWidthMm),
        ));
    }
  }

  static String _modeLabel(PrintMode mode) {
    final String lang = switch (mode.language) {
      PrintLanguage.escPos => 'ESC/POS',
      PrintLanguage.tspl => 'TSPL',
      PrintLanguage.cpcl => 'CPCL',
    };
    final String render = mode.render == PrintRender.text ? 'TEKS' : 'GAMBAR';
    return '$lang $render';
  }

  Future<bool> printTestReceipt({String? storeName}) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(ReceiptPaper.toPaperSize(_paperWidthMm), profile);
    List<int> bytes = [];

    bytes += generator.reset();
    bytes += generator.text(
      (storeName ?? 'ZENVI POS').toUpperCase(),
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );
    bytes += generator.text(
      'TEST PRINT BERHASIL',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.hr();
    bytes += generator.text('Waktu : ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}');
    bytes += generator.text('Status: Terhubung OK');
    bytes += generator.text('Kertas: ${_paperWidthMm}mm Thermal');
    bytes += generator.hr();
    // Penggaris karakter: kalau baris ini terpotong, lebar kertas kebesaran.
    final int maxChar = ReceiptPaper.maxChars(_paperWidthMm);
    final ruler = StringBuffer();
    for (int i = 1; i <= maxChar; i++) {
      ruler.write((i % 10).toString());
    }
    bytes += generator.text(ruler.toString());
    bytes += generator.text('1234567890 ABCD WXYZ');
    bytes += generator.feed(3);

    return printBytes(bytes);
  }
}
