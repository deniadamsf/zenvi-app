import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branch_provider.dart';
import '../../services/api_client.dart';
import '../../widgets/premium_gate.dart';
import '../../widgets/zenvi_header.dart';
import '../../theme/app_colors.dart';

class KdsScreen extends StatefulWidget {
  const KdsScreen({super.key});

  @override
  State<KdsScreen> createState() => _KdsScreenState();
}

class _KdsScreenState extends State<KdsScreen> {
  Timer? _pollTimer;
  bool _isLoading = true;
  List<dynamic> _orders = [];
  String? _errorMessage;
  PremiumLock? _lock;
  int? _selectedBranchId;
  String _selectedTab = 'active'; // 'active', 'preparing', 'ready'
  bool _isTvDisplayMode = false; // TV Monitor Hands-Free View Only mode

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isOwner) {
        if (auth.token != null) {
          Provider.of<BranchProvider>(context, listen: false).fetchBranches(auth.token!);
        }
      } else {
        _selectedBranchId = auth.user?.branchId;
      }
      _fetchKdsOrders();
    });

    // Auto poll every 12 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (mounted) {
        _fetchKdsOrders(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchKdsOrders({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final queryParams = <String, String>{};
      if (_selectedBranchId != null) {
        queryParams['branch_id'] = _selectedBranchId.toString();
      }
      if (_selectedTab == 'ready') {
        queryParams['status'] = 'ready';
      } else if (_selectedTab == 'preparing') {
        queryParams['status'] = 'preparing';
      }

      final response = await ApiClient.get('/orders/kds', query: queryParams);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _orders = data['data'] ?? [];
          _isLoading = false;
          _errorMessage = null;
          _lock = null;
        });
        return;
      }

      // 403 bertipe: paket toko tidak mencakup KDS. Polling dihentikan supaya
      // tawaran upgrade tidak muncul lagi tiap 12 detik, dan layarnya
      // menerangkan apa yang terkunci alih-alih memasang tombol "Coba lagi"
      // yang tidak akan pernah berhasil.
      final lock = ApiClient.parseLock(response);
      if (lock != null) {
        _pollTimer?.cancel();
        setState(() {
          _lock = lock;
          _orders = [];
          _errorMessage = null;
          _isLoading = false;
        });
        return;
      }

      if (!silent) {
        setState(() {
          _errorMessage = response.statusCode == 401
              ? 'sesi_telah_berakhir_silakan_43'.tr(context: context)
              : 'failed_process_type_code'
                  .tr(context: context, args: ['KDS', '${response.statusCode}']);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _errorMessage = 'terjadi_kesalahan_jaringan_178'.tr(context: context);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateKdsStatus(int orderId, String newStatus) async {
    try {
      final response = await ApiClient.patch(
        '/orders/$orderId/kds-status',
        body: {'kds_status': newStatus},
      );

      if (response.statusCode == 200) {
        _fetchKdsOrders(silent: true);
      } else {
        // Respons terkunci sudah memunculkan tawaran upgrade sendiri; snackbar
        // "gagal memperbarui" di atasnya hanya menutupi alasan sebenarnya.
        if (!mounted || ApiClient.parseLock(response) != null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('gagal_memperbarui_status_pesanan_177'.tr(context: context))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('terjadi_kesalahan_jaringan_178'.tr(context: context))),
      );
    }
  }

  Future<void> _updateItemKdsStatus(int orderId, int itemId, String newStatus) async {
    try {
      final response = await ApiClient.patch(
        '/orders/$orderId/items/$itemId/kds-status',
        body: {'kds_status': newStatus},
      );

      if (response.statusCode == 200) {
        _fetchKdsOrders(silent: true);
      } else {
        // Respons terkunci sudah memunculkan tawaran upgrade sendiri; snackbar
        // "gagal memperbarui" di atasnya hanya menutupi alasan sebenarnya.
        if (!mounted || ApiClient.parseLock(response) != null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('gagal_memperbarui_status_pesanan_177'.tr(context: context))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('terjadi_kesalahan_jaringan_178'.tr(context: context))),
      );
    }
  }

  void _onBranchChanged(int? branchId) {
    setState(() {
      _selectedBranchId = branchId;
    });
    _fetchKdsOrders();
  }

  void _onTabChanged(String tab) {
    setState(() {
      _selectedTab = tab;
    });
    _fetchKdsOrders();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ZenviHeader(
        title: 'kds_title'.tr(context: context),
        showBackButton: true,
        actions: [
          // Mode Toggle Button (TV Monitor Display Only vs Interactive)
          Tooltip(
            message: _isTvDisplayMode
                ? 'kds_mode_tv_tooltip'.tr(context: context)
                : 'kds_mode_interactive_tooltip'.tr(context: context),
            child: InkWell(
              onTap: () {
                setState(() {
                  _isTvDisplayMode = !_isTvDisplayMode;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _isTvDisplayMode
                      ? theme.colorScheme.primary.withValues(alpha: 0.18)
                      : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isTvDisplayMode
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.2),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isTvDisplayMode ? Icons.tv_rounded : Icons.touch_app_rounded,
                      size: 16,
                      color: _isTvDisplayMode ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isTvDisplayMode
                          ? 'kds_mode_tv_display'.tr(context: context)
                          : 'kds_mode_interactive'.tr(context: context),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: _isTvDisplayMode ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'refresh_tooltip'.tr(context: context),
            onPressed: () => _fetchKdsOrders(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Informative TV Monitor Banner
          if (_isTvDisplayMode)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.tv_rounded, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'kds_tv_banner_info'.tr(context: context),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isTvDisplayMode = false;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        'kds_switch_mode_btn'.tr(context: context),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Branch selector if Owner
          Consumer2<AuthProvider, BranchProvider>(
            builder: (context, auth, branchProv, child) {
              if (auth.isOwner && branchProv.branches.isNotEmpty) {
                return Container(
                  height: 44,
                  margin: const EdgeInsets.only(top: 6, bottom: 4),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('all_branches'.tr(context: context)),
                          selected: _selectedBranchId == null,
                          onSelected: (_) => _onBranchChanged(null),
                          selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                          checkmarkColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                      ...branchProv.branches.map((b) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(b.name),
                          selected: _selectedBranchId == b.id,
                          onSelected: (_) => _onBranchChanged(b.id),
                          selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                          checkmarkColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      )),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Status Filter Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildStatusTab(
                  label: 'tab_all_queue'.tr(context: context),
                  tabKey: 'active',
                  icon: Icons.receipt_long_rounded,
                  theme: theme,
                ),
                _buildStatusTab(
                  label: 'tab_in_progress'.tr(context: context),
                  tabKey: 'preparing',
                  icon: Icons.hourglass_top_rounded,
                  theme: theme,
                ),
                _buildStatusTab(
                  label: 'tab_ready'.tr(context: context),
                  tabKey: 'ready',
                  icon: Icons.check_circle_outline_rounded,
                  theme: theme,
                ),
              ],
            ),
          ),

          // Main Orders Grid / List
          Expanded(
            child: _buildBody(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTab({
    required String label,
    required String tabKey,
    required IconData icon,
    required ThemeData theme,
  }) {
    final isSelected = _selectedTab == tabKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabChanged(tabKey),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading && _orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_lock != null && _orders.isEmpty) {
      final lock = _lock!;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PremiumBadge(plan: lock.requiredPlan ?? 'premium'),
              const SizedBox(height: 16),
              Text(
                'feature_locked_title'.tr(context: context),
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                lock.message ?? 'feature_locked_desc'.tr(context: context),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => showPremiumUpsellSheet(context, lock),
                icon: const Icon(Icons.workspace_premium_rounded),
                label: Text('upsell_cta'.tr(context: context)),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null && _orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.dangerFill),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _fetchKdsOrders(),
              icon: const Icon(Icons.refresh_rounded),
              label: Text('coba_lagi_67'.tr(context: context)),
            )
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 72, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'no_active_orders_found'.tr(context: context),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchKdsOrders(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 600;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: _isTvDisplayMode ? 460 : 420,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: isTablet ? (_isTvDisplayMode ? 1.05 : 0.85) : (_isTvDisplayMode ? 0.95 : 0.78),
            ),
            itemCount: _orders.length,
            itemBuilder: (context, index) {
              return _buildTicketCard(theme, _orders[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildTicketCard(ThemeData theme, dynamic order) {
    final items = order['items'] as List<dynamic>? ?? [];
    final orderStatus = order['kds_status'] ?? 'pending';
    final orderTime = DateTime.parse(order['created_at']).toLocal();
    final timeStr = DateFormat('HH:mm').format(orderTime);
    final servicedBy = order['serviced_by'] != null ? order['serviced_by']['name'] : null;
    final branchName = order['shift']?['branch']?['name'];

    Color statusFillColor;
    Color statusTextColor;
    String statusBadgeText;
    if (orderStatus == 'ready') {
      statusFillColor = AppColors.successFill;
      statusTextColor = AppColors.successText;
      statusBadgeText = 'item_status_ready'.tr(context: context);
    } else if (orderStatus == 'preparing') {
      statusFillColor = AppColors.infoFill;
      statusTextColor = AppColors.infoText;
      statusBadgeText = 'item_status_preparing'.tr(context: context);
    } else {
      statusFillColor = AppColors.warningFill;
      statusTextColor = AppColors.warningText;
      statusBadgeText = 'item_status_pending'.tr(context: context);
    }

    final hasPendingItems = items.any((i) => (i['kds_status'] ?? 'pending') == 'pending');
    final allItemsReady = items.isNotEmpty && items.every((i) => (i['kds_status'] ?? 'pending') == 'ready');

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusFillColor.withValues(alpha: 0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: statusFillColor.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ticket Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: statusFillColor.withValues(alpha: 0.1),
                  border: Border(bottom: BorderSide(color: statusFillColor.withValues(alpha: 0.2))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '#${order['id']} - ${order['member_name'] ?? 'pelanggan_9'.tr(context: context)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: _isTvDisplayMode ? 17 : 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusFillColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time_rounded, size: 13, color: statusTextColor),
                              const SizedBox(width: 4),
                              Text(
                                timeStr,
                                style: TextStyle(fontWeight: FontWeight.bold, color: statusTextColor, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusFillColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusBadgeText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusTextColor,
                            ),
                          ),
                        ),
                        if (branchName != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.storefront_rounded, size: 13, color: theme.colorScheme.primary),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              branchName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                        if (servicedBy != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.badge_outlined, size: 13, color: theme.colorScheme.secondary),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              'serviced_by_label'.tr(context: context, args: [servicedBy]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: theme.colorScheme.secondary, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Items with Item-level Status or TV Display Tag
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (context, _) => const Divider(height: 12),
                  itemBuilder: (context, idx) {
                    final item = items[idx];
                    final product = item['product'] ?? {};
                    final itemStatus = item['kds_status'] ?? 'pending';

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Quantity Chip
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: _isTvDisplayMode ? 10 : 8,
                            vertical: _isTvDisplayMode ? 7 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item['qty']}x',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                              fontSize: _isTvDisplayMode ? 15 : 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Item name & variant
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'] ?? 'Item',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: _isTvDisplayMode ? 16 : 14,
                                  decoration: itemStatus == 'ready' ? TextDecoration.lineThrough : null,
                                  color: itemStatus == 'ready'
                                      ? theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)
                                      : null,
                                ),
                              ),
                              if (item['variant_name'] != null)
                                Text(
                                  item['variant_name'],
                                  style: TextStyle(
                                    fontSize: _isTvDisplayMode ? 13 : 12,
                                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // In TV Mode: Show clean static status pill. In Interactive Mode: Show clickable action button
                        _isTvDisplayMode
                            ? _buildTvStatusPill(
                                theme: theme,
                                status: itemStatus,
                              )
                            : _buildItemStatusAction(
                                theme: theme,
                                orderId: order['id'],
                                itemId: item['id'],
                                status: itemStatus,
                              ),
                      ],
                    );
                  },
                ),
              ),

              // Footer Batch Action Buttons (Hidden in TV Monitor Hands-Free Display Mode)
              if (!_isTvDisplayMode)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    border: Border(top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1))),
                  ),
                  child: Row(
                    children: [
                      if (hasPendingItems) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.infoText,
                              side: BorderSide(color: AppColors.infoFill.withValues(alpha: 0.4)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _updateKdsStatus(order['id'], 'preparing'),
                            icon: const Icon(Icons.play_arrow_rounded, size: 18),
                            label: Text(
                              'action_start_all'.tr(context: context),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: allItemsReady ? AppColors.successFill : theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _updateKdsStatus(order['id'], 'ready'),
                          icon: Icon(allItemsReady ? Icons.check_circle_rounded : Icons.done_all_rounded, size: 18),
                          label: Text(
                            allItemsReady
                                ? 'action_archive_order'.tr(context: context)
                                : 'action_complete_all'.tr(context: context),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTvStatusPill({
    required ThemeData theme,
    required String status,
  }) {
    Color fillColor;
    Color textColor;
    String text;
    IconData icon;

    if (status == 'ready') {
      fillColor = AppColors.successFill;
      textColor = AppColors.successText;
      text = 'item_status_ready'.tr(context: context);
      icon = Icons.check_circle_rounded;
    } else if (status == 'preparing') {
      fillColor = AppColors.infoFill;
      textColor = AppColors.infoText;
      text = 'item_status_preparing'.tr(context: context);
      icon = Icons.hourglass_top_rounded;
    } else {
      fillColor = AppColors.warningFill;
      textColor = AppColors.warningText;
      text = 'item_status_pending'.tr(context: context);
      icon = Icons.access_time_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: fillColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fillColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemStatusAction({
    required ThemeData theme,
    required int orderId,
    required int itemId,
    required String status,
  }) {
    if (status == 'pending') {
      return InkWell(
        onTap: () => _updateItemKdsStatus(orderId, itemId, 'preparing'),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.warningFill.withValues(alpha: 0.12),
            border: Border.all(color: AppColors.warningFill.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_circle_outline_rounded, size: 14, color: AppColors.warningText),
              const SizedBox(width: 4),
              Text(
                'action_start_item'.tr(context: context),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.warningText),
              ),
            ],
          ),
        ),
      );
    } else if (status == 'preparing') {
      return InkWell(
        onTap: () => _updateItemKdsStatus(orderId, itemId, 'ready'),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.infoFill.withValues(alpha: 0.15),
            border: Border.all(color: AppColors.infoFill.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.infoText),
              const SizedBox(width: 4),
              Text(
                'action_complete_item'.tr(context: context),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.infoText),
              ),
            ],
          ),
        ),
      );
    } else {
      // Ready
      return PopupMenuButton<String>(
        onSelected: (val) {
          if (val == 'revert') {
            _updateItemKdsStatus(orderId, itemId, 'preparing');
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'revert',
            child: Row(
              children: [
                const Icon(Icons.undo_rounded, size: 16, color: AppColors.warningText),
                const SizedBox(width: 8),
                Text('action_revert_item'.tr(context: context)),
              ],
            ),
          ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.successFill.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_rounded, size: 14, color: AppColors.successText),
              const SizedBox(width: 4),
              Text(
                'item_status_ready'.tr(context: context),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.successText),
              ),
            ],
          ),
        ),
      );
    }
  }
}
