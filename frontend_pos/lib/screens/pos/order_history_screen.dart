import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import 'widgets/receipt_widget.dart';
import 'printer_dialog.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/zenvi_header.dart';
import '../../theme/app_colors.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = Provider.of<OrderProvider>(context, listen: false);
    await provider.loadAllOrders();
  }

  Future<void> _shareReceipt(OrderModel order) async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final company = authProvider.user?.company;
    final storeName = company?['name'] ?? 'toko_saya_9'.tr(context: context);
    final storeLoc = company?['location']?.toString() ?? '';
    final storeTelp = company?['phone']?.toString() ?? '';
    final cashier = authProvider.user?.name ?? 'kasir_5'.tr(context: context);
    String? lUrl = company?['logo_url']?.toString();
    if ((lUrl == null || lUrl.isEmpty) && company?['logo_path'] != null) {
      final path = company!['logo_path'].toString();
      lUrl = path.startsWith('http') ? path : 'https://zenvi.cellanoma.my.id/uploads/logos/$path';
    }
    final shareText = 'receipt_share_text'.tr(context: context, args: [order.id.toString()]);
    final failShareText = 'failed_share_receipt'.tr(context: context);

    try {
      // 1. Coba capture langsung dari Screenshot widget yang sudah terpasang
      Uint8List? image;
      try {
        image = await _screenshotController.capture(
          pixelRatio: 2.0,
          delay: const Duration(milliseconds: 50),
        );
      } catch (e) {
        debugPrint('Direct screenshot capture error: $e');
      }

      // 2. Fallback captureFromWidget dengan data lengkap jika capture langsung null
      if (image == null || image.isEmpty) {
        image = await _screenshotController.captureFromWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Material(
              color: Colors.white,
              child: ReceiptWidget(
                order: order,
                storeName: storeName,
                storeLocation: storeLoc,
                storePhone: storeTelp,
                cashierName: cashier,
                logoUrl: lUrl,
              ),
            ),
          ),
          context: mounted ? context : null,
          delay: const Duration(milliseconds: 150),
          pixelRatio: 2.0,
        );
      }

      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/struk_${order.id}.png').create();
      await imagePath.writeAsBytes(image);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(imagePath.path)],
          text: shareText,
        ),
      );
    } catch (e) {
      debugPrint('Error sharing receipt: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$failShareText $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  void _showOrderDetails(BuildContext context, OrderModel order, {bool isOffline = false, int? offlineId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text('detail_transaksi_269'.tr(context: context), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Screenshot(
                    controller: _screenshotController,
                    child: ReceiptWidget(order: order, isOffline: isOffline),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (!isOffline && order.status != 'voided') ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.cancel_outlined, color: AppColors.dangerText, size: 18),
                      label: Text('void_270'.tr(context: context), style: const TextStyle(color: AppColors.dangerText)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.dangerText),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _handleVoidOrder(ctx, order, isOffline, offlineId),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (isOffline) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline, color: AppColors.dangerText, size: 18),
                      label: Text('hapus_88'.tr(context: context), style: const TextStyle(color: AppColors.dangerText)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.dangerText),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _handleVoidOrder(ctx, order, isOffline, offlineId),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    icon: _isCapturing 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                        : const Icon(Icons.share, size: 18),
                    label: Text('share_271'.tr(context: context)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isCapturing ? null : () => _shareReceipt(order),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.print, size: 18),
                    label: Text('cetak_nota_272'.tr(context: context)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => PrinterDialog(
                          totalAmount: order.totalAmount,
                          subtotal: order.totalAmount + (order.memberDiscountAmount ?? 0.0),
                          tax: 0.0,
                          items: order.items,
                          receiptNumber: isOffline ? 'OFFLINE-${order.id}' : 'INV-${order.id}',
                          transactionTime: DateTime.tryParse(order.createdAt)?.toLocal(),
                          paymentMethod: order.paymentMethod,
                          cashReceived: order.cashReceived,
                          cashChange: order.cashChange,
                          memberName: order.memberName,
                          memberPhone: order.memberPhone,
                          memberDiscountAmount: order.memberDiscountAmount,
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _handleVoidOrder(BuildContext ctx, OrderModel order, bool isOffline, int? offlineId) async {
    final provider = Provider.of<OrderProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(ctx);

    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: Text('konfirmasi_void_273'.tr(context: context)),
        content: Text('apakah_anda_yakin_ingin_274'.tr(context: context)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('batal_5'.tr(context: context))),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text('ya_void_275'.tr(context: context), style: const TextStyle(color: AppColors.dangerText, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      bool success = false;
      
      if (isOffline && offlineId != null) {
        success = await provider.voidOfflineOrder(offlineId);
      } else {
        success = await provider.voidOrder(order.id);
      }

      if (success) {
        if (mounted) {
          navigator.pop(); // Tutup bottom sheet
          scaffoldMessenger.showSnackBar(SnackBar(content: Text('transaksi_berhasil_dibatalkan_276'.tr(context: context))));
        }
      } else {
        if (mounted) {
          scaffoldMessenger.showSnackBar(SnackBar(content: Text('gagal_membatalkan_transaksi_277'.tr(context: context))));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      body: Consumer<OrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.orders.isEmpty && provider.offlineOrders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Gabungkan offline + online orders
          final allItems = [
            ...provider.offlineOrders.map((o) => {'isOffline': true, 'data': o}),
            ...provider.orders.map((o) => {'isOffline': false, 'data': o}),
          ];

          if (allItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 80, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('belum_ada_transaksi_hari_278'.tr(context: context), style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        provider.errorMessage!,
                        style: TextStyle(color: AppColors.warningText, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    label: Text('coba_lagi_67'.tr(context: context)),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              ZenviHeader.sliver(
                title: 'order_history_title'.tr(context: context),
                showBackButton: true,
                actions: [
                  IconButton(
                    icon: Icon(Icons.refresh_rounded, color: theme.colorScheme.primary),
                    onPressed: _loadData,
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
              // Banner peringatan jika ada error
              if (provider.errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: AppColors.warningFill.withValues(alpha: 0.15),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off, color: AppColors.warningText, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.errorMessage!,
                          style: TextStyle(color: AppColors.warningText, fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadData,
                        child: Text('retry_280'.tr(context: context), style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                  ],
                ),
              ),
              // List transaksi
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = allItems[index];
                    final isOffline = item['isOffline'] as bool;
                    
                    if (isOffline) {
                      final data = item['data'] as Map<String, dynamic>;
                      final offlineId = data['local_id'];
                      final rawItems = data['items'] as List<dynamic>? ?? [];
                      final dummyItems = rawItems.map((x) {
                        final pName = x['product_name'] ?? x['variant_name'] ?? 'product_fallback_name'.tr(context: context);
                        final qty = int.tryParse(x['qty']?.toString() ?? '1') ?? 1;
                        final subtotal = double.tryParse(x['subtotal']?.toString() ?? '0') ?? 0.0;
                        return OrderItemModel(
                          id: 0,
                          productId: int.tryParse(x['product_id']?.toString() ?? '0') ?? 0,
                          qty: qty,
                          subtotal: subtotal,
                          product: ProductModel(
                            id: int.tryParse(x['product_id']?.toString() ?? '0') ?? 0,
                            companyId: 0,
                            name: pName.toString(),
                            price: qty > 0 ? (subtotal / qty) : subtotal,
                            isActive: true,
                          ),
                        );
                      }).toList();

                      // Dummy OrderModel for offline display
                      final dummyOrder = OrderModel(
                        id: 0,
                        companyId: 0,
                        userId: 0,
                        shiftId: data['shift_id'] ?? 0,
                        totalAmount: (data['total_amount'] as num).toDouble(),
                        paymentMethod: data['payment_method'] ?? 'cash',
                        cashReceived: data['cash_received'] != null ? (data['cash_received'] as num).toDouble() : null,
                        cashChange: data['cash_change'] != null ? (data['cash_change'] as num).toDouble() : null,
                        status: 'offline',
                        createdAt: data['created_at'] ?? DateTime.now().toIso8601String(),
                        items: dummyItems,
                      );
                      
                      return _buildTransactionCard(
                        context: context, 
                        order: dummyOrder, 
                        isOffline: true,
                        onTap: () => _showOrderDetails(context, dummyOrder, isOffline: true, offlineId: offlineId)
                      );
                    } else {
                      final order = item['data'] as OrderModel;
                      return _buildTransactionCard(
                        context: context, 
                        order: order, 
                        isOffline: false,
                        onTap: () => _showOrderDetails(context, order)
                      );
                    }
                  },
                  childCount: allItems.length,
                ),
              ),
            ),
          ],
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard({required BuildContext context, required OrderModel order, required bool isOffline, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final isVoided = order.status == 'voided';
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(color: theme.shadowColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))
          ]
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isVoided ? AppColors.dangerFill.withValues(alpha: 0.1) : (isOffline ? AppColors.warningFill.withValues(alpha: 0.1) : theme.colorScheme.primary.withValues(alpha: 0.1)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isVoided ? Icons.cancel : (isOffline ? Icons.cloud_off : Icons.receipt_long),
                color: isVoided ? AppColors.dangerFill : (isOffline ? AppColors.warningFill : theme.colorScheme.primary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOffline ? 'order_offline_label'.tr(context: context) : 'Order #${order.id}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: isVoided ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(order.createdAt).toLocal()),
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(order.totalAmount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16,
                    color: isVoided ? AppColors.dangerText : theme.colorScheme.primary,
                    decoration: isVoided ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (isVoided)
                  Text('void_167'.tr(context: context), style: const TextStyle(color: AppColors.dangerText, fontWeight: FontWeight.bold, fontSize: 12))
                else if (isOffline)
                  Text('belum_sync_281'.tr(context: context), style: const TextStyle(color: AppColors.warningText, fontSize: 12)),
              ],
            )
          ],
        ),
      ),
    ).animate().fade().slideY(begin: 0.1, end: 0);
  }
}

