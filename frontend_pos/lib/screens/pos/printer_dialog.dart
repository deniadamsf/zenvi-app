import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/printer_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/printer_service.dart';
import 'printer_settings_screen.dart';

class PrinterDialog extends StatefulWidget {
  final double totalAmount;
  final double subtotal;
  final double tax;
  final List<dynamic> items;
  final String? receiptNumber;
  final DateTime? transactionTime;
  final String paymentMethod;
  final double? cashReceived;
  final double? cashChange;
  final String? memberName;
  final String? memberPhone;
  final double? memberDiscountAmount;

  const PrinterDialog({
    super.key, 
    required this.totalAmount,
    required this.subtotal,
    required this.tax,
    required this.items,
    this.receiptNumber,
    this.transactionTime,
    this.paymentMethod = 'cash',
    this.cashReceived,
    this.cashChange,
    this.memberName,
    this.memberPhone,
    this.memberDiscountAmount,
  });

  @override
  State<PrinterDialog> createState() => _PrinterDialogState();
}

class _PrinterDialogState extends State<PrinterDialog> {
  int _step = 0; // 0: Connecting, 1: Printing, 2: Success, 3: Failed
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPrinting();
    });
  }

  void _startPrinting() async {
    final printerProvider = Provider.of<PrinterProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (printerProvider.selectedDevice == null) {
      if (mounted) {
        setState(() {
          _step = 3;
          _errorMessage = 'Belum ada printer yang dipilih.\nSilakan atur printer bluetooth terlebih dahulu.';
        });
      }
      return;
    }

    if (mounted) setState(() => _step = 0);
    
    bool connected = printerProvider.isConnected;
    if (!connected) {
      connected = await printerProvider.connect(printerProvider.selectedDevice!);
    }

    if (!connected) {
      if (mounted) {
        setState(() {
          _step = 3;
          _errorMessage = 'Gagal terhubung ke printer bluetooth (${printerProvider.selectedDevice?.name ?? 'device_6'.tr(context: context)}).';
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() => _step = 1);
    
    try {
      final user = authProvider.user;
      final company = user?.company ?? {
        'name': 'toko_saya_9'.tr(context: context),
        'location': '',
        'phone': '',
        'logo_url': null,
      };
      
      final receiptNo = widget.receiptNumber ?? 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

      final bytes = await PrinterService.generateReceiptBytes(
        company,
        widget.items,
        widget.totalAmount,
        widget.subtotal,
        widget.tax,
        user?.name ?? 'kasir_5'.tr(context: context),
        receiptNo,
        transactionTime: widget.transactionTime,
        paymentMethod: widget.paymentMethod,
        cashReceived: widget.cashReceived,
        cashChange: widget.cashChange,
        memberName: widget.memberName,
        memberPhone: widget.memberPhone,
        memberDiscountAmount: widget.memberDiscountAmount,
      );
      
      final success = await printerProvider.printBytes(bytes);
      
      if (mounted) {
        setState(() {
          _step = success ? 2 : 3;
          if (!success) _errorMessage = 'Gagal mengirim data cetak ke printer.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _step = 3;
          _errorMessage = 'Error saat mencetak: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(theme),
            const SizedBox(height: 20),
            _buildTitle(),
            const SizedBox(height: 8),
            _buildSubtitle(theme),
            const SizedBox(height: 28),
            if (_step == 2) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('selesai_301'.tr(context: context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ] else if (_step == 3) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('tutup_136'.tr(context: context)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _startPrinting,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('coba_lagi_67'.tr(context: context), style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()),
                  );
                },
                icon: const Icon(Icons.settings_bluetooth, size: 18),
                label: Text('buka_pengaturan_printer_302'.tr(context: context), style: TextStyle(fontSize: 13)),
              )
            ] else ...[
              LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeData theme) {
    IconData icon;
    Color color;

    switch (_step) {
      case 0:
        icon = Icons.bluetooth_connected;
        color = Colors.blueAccent;
        break;
      case 1:
        icon = Icons.print;
        color = Colors.orange;
        break;
      case 3:
        icon = Icons.error_outline;
        color = Colors.red;
        break;
      case 2:
      default:
        icon = Icons.check_circle_outline;
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 56, color: color),
    );
  }

  Widget _buildTitle() {
    String title;
    switch (_step) {
      case 0:
        title = 'Menghubungkan...';
        break;
      case 1:
        title = 'Mencetak Struk...';
        break;
      case 3:
        title = 'Gagal Mencetak';
        break;
      case 2:
      default:
        title = 'Cetak Selesai!';
        break;
    }
    return Text(
      title,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle(ThemeData theme) {
    String subtitle;
    switch (_step) {
      case 0:
        subtitle = 'Sedang memastikan koneksi ke printer bluetooth.';
        break;
      case 1:
        subtitle = 'Mohon tunggu, struk sedang dicetak ke printer thermal.';
        break;
      case 3:
        subtitle = _errorMessage;
        break;
      case 2:
      default:
        subtitle = 'Struk berhasil dicetak.';
        break;
    }
    return Text(
      subtitle,
      style: TextStyle(color: _step == 3 ? Colors.red : theme.colorScheme.onSurfaceVariant, fontSize: 14),
      textAlign: TextAlign.center,
    );
  }
}
