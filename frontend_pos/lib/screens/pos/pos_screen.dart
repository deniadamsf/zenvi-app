import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'printer_settings_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../database/database_helper.dart';
import '../../models/product_model.dart';
import '../../services/sync_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'order_history_screen.dart' as order_history;
import 'widgets/receipt_preview_modal.dart';
import 'widgets/payment_modal.dart';
import '../../providers/shift_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/member_promo_provider.dart';
import '../../providers/reservation_provider.dart';
import '../../models/reservation_model.dart';
import 'member_selection_modal.dart';
import 'reservation_selection_modal.dart';
import '../../widgets/product_image.dart';
import '../../widgets/zenvi_header.dart';

class POSScreen extends StatefulWidget {
  final VoidCallback? onNavigateToShift;
  final VoidCallback? onNavigateBack;
  const POSScreen({super.key, this.onNavigateToShift, this.onNavigateBack});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  List<ProductModel> _localProducts = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchActiveShift();
      final auth = Provider.of<AuthProvider>(context, listen: false);
      auth.fetchActiveEmployees();
      final company = auth.user?.company;
      final isMembershipEnabled = company?['is_membership_enabled'] == true || company?['is_membership_enabled'] == 1;
      if (isMembershipEnabled) {
        Provider.of<MemberProvider>(context, listen: false).fetchMembers();
        Provider.of<MemberPromoProvider>(context, listen: false).fetchPromos().then((_) {
          if (mounted) {
            final promos = Provider.of<MemberPromoProvider>(context, listen: false).activePromos;
            Provider.of<CartProvider>(context, listen: false).setActivePromos(promos);
          }
        });
      }

      final isReservationEnabled = company?['is_reservation_enabled'] == true || company?['is_reservation_enabled'] == 1;
      if (isReservationEnabled || auth.isOwner) {
        Provider.of<ReservationProvider>(context, listen: false).fetchReservations(
          date: 'today',
          branchId: auth.user?.branchId,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final cats = _localProducts
        .map((p) => p.category?.trim())
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    cats.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return cats;
  }

  List<ProductModel> get _filteredProducts {
    return _localProducts.where((product) {
      // Category filter
      bool matchCat = true;
      if (_selectedCategory != 'all') {
        matchCat = (product.category?.trim().toLowerCase() == _selectedCategory.toLowerCase());
      }

      // Search filter
      bool matchSearch = true;
      if (_searchQuery.isNotEmpty) {
        final name = product.name.toLowerCase();
        final cat = (product.category ?? '').toLowerCase();
        matchSearch = name.contains(_searchQuery) || cat.contains(_searchQuery);
      }

      return matchCat && matchSearch;
    }).toList();
  }

  Future<void> _fetchActiveShift() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      await Provider.of<ShiftProvider>(context, listen: false).fetchActiveShift(authProvider.token!);
    }
  }

  Future<void> _loadProducts() async {
    // 1. Sinkronisasi background
    await SyncService().pullProducts();

    // 2. Load dari lokal
    final products = await DatabaseHelper.instance.getLocalProducts();
    setState(() {
      _localProducts = products;
      _isLoading = false;
    });
  }

  bool _checkShiftOrShowDialog(BuildContext context) {
    final shift = Provider.of<ShiftProvider>(context, listen: false);
    if (shift.activeShift != null) {
      return true;
    }

    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 16,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_clock_rounded,
                  color: theme.colorScheme.primary,
                  size: 38,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'shift_belum_dibuka_title'.tr(context: context),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'shift_belum_dibuka_desc'.tr(context: context),
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (widget.onNavigateToShift != null) {
                      widget.onNavigateToShift!();
                    }
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text(
                    'open_shift_now_btn'.tr(context: context),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'nanti_saja_btn'.tr(context: context),
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return false;
  }

  void _showMobileCart(BuildContext context, ThemeData theme, Size size) {
    if (!_checkShiftOrShowDialog(context)) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: size.height * 0.85,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(color: theme.shadowColor.withValues(alpha: 0.2), blurRadius: 40, spreadRadius: 10),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: _buildCartPanel(ctx),
        ),
      ),
    );
  }

  void _showReservationModal(BuildContext context) async {
    final selectedRes = await showModalBottomSheet<ReservationModel?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ReservationSelectionModal(),
    );

    if (selectedRes != null && mounted) {
      _applyReservationToPos(selectedRes);
    }
  }

  void _applyReservationToPos(ReservationModel res) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.setSelectedReservation(res);

    // Auto select member if phone or name matches
    final memberProv = Provider.of<MemberProvider>(context, listen: false);
    final matchingMember = memberProv.members.where((m) =>
      (m.phone.isNotEmpty && m.phone == res.customerPhone) ||
      (m.name.isNotEmpty && m.name.toLowerCase() == res.customerName.toLowerCase())
    ).firstOrNull;

    if (matchingMember != null) {
      cart.setSelectedMember(matchingMember);
    }

    // Auto add matching services / products
    if (res.serviceNames != null && res.serviceNames!.isNotEmpty) {
      final services = res.serviceNames!.split(RegExp(r'[,;|\n]')).map((s) => s.trim().toLowerCase()).where((s) => s.isNotEmpty);
      for (final serviceName in services) {
        final matchingProduct = _localProducts.where((p) => p.name.toLowerCase().contains(serviceName) || serviceName.contains(p.name.toLowerCase())).firstOrNull;
        if (matchingProduct != null) {
          cart.addToCart(matchingProduct);
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('reservation_loaded_msg'.tr(context: context, args: [res.customerName])),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Future<void> _handleCheckout(BuildContext context) async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final shift = Provider.of<ShiftProvider>(context, listen: false);

    if (cart.items.isEmpty) return;

    if (!_checkShiftOrShowDialog(context)) {
      return;
    }

    final company = auth.user?.company;
    final isQrisEnabled = company?['is_qris_enabled'] == 1 || company?['is_qris_enabled'] == true;
    final isTransferEnabled = company?['is_transfer_enabled'] == 1 || company?['is_transfer_enabled'] == true;
    final isPointsEnabled = auth.isPointsEnabled;
    final pointRedeemRate = auth.pointRedeemRate;

    PaymentModal.show(
      context: context,
      totalAmount: cart.finalAmount,
      isQrisEnabled: isQrisEnabled,
      isTransferEnabled: isTransferEnabled,
      staffList: auth.activeEmployees,
      currentUserId: auth.user?.id,
      currentUserName: auth.user?.name,
      member: cart.selectedMember,
      memberDiscountAmount: cart.memberDiscountAmount,
      isPointsEnabled: isPointsEnabled,
      pointRedeemRate: pointRedeemRate,
      onConfirm: (
        paymentMethod,
        cashReceived,
        cashChange,
        servicedByUserId,
        servicedByName,
        pointsRedeemed,
        pointRedeemAmount,
      ) async {
        final shiftId = shift.activeShift?.id ?? 0;
        final userId = auth.user?.id ?? 0;
        final companyId = auth.user?.company?['id'];

        final success = await cart.checkout(
          shiftId,
          paymentMethod: paymentMethod,
          cashReceived: cashReceived,
          cashChange: cashChange,
          companyId: companyId,
          userId: userId,
          servicedByUserId: servicedByUserId,
          servicedByName: servicedByName,
          pointsRedeemed: pointsRedeemed,
          pointRedeemAmount: pointRedeemAmount,
        );

        if (success && context.mounted) {
          final now = DateTime.now();
          final receiptNum = 'POS-${now.millisecondsSinceEpoch.toString().substring(5)}';

          await ReceiptPreviewModal.show(
            context: context,
            items: cart.items.map((e) => {
              'name': e.variantName != null ? '${e.product.name} - ${e.variantName}' : e.product.name,
              'price': e.variantPrice ?? e.product.finalPrice,
              'quantity': e.quantity,
              'subtotal': e.subtotal,
            }).toList(),
            totalAmount: cart.finalAmount,
            receiptNumber: receiptNum,
            transactionTime: now,
            paymentMethod: paymentMethod,
            cashReceived: cashReceived,
            cashChange: cashChange,
            member: cart.selectedMember,
            memberDiscountAmount: cart.memberDiscountAmount,
            pointsRedeemed: pointsRedeemed,
            pointRedeemAmount: pointRedeemAmount,
          );

          cart.clearCart();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final cart = Provider.of<CartProvider>(context);
    final totalItems = cart.items.fold<int>(0, (sum, item) => sum + item.quantity);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Column(
            children: [
              // ── 1. HEADER POS ELEGAN ──
              _buildGlassHeader(context, theme, size, isDesktop),

              // ── 2. KONTEN UTAMA: GRID MENU & DESKTOP CART ──
              Expanded(
                child: Row(
                  children: [
                    // KIRI: Grid Menu Makanan
                    Expanded(
                      flex: 7,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // FILTER & KATEGORI BAR
                            _buildFilterAndCategoryBar(theme),

                            Expanded(
                              child: _isLoading
                                  ? _buildShimmerLoading(theme, isDesktop)
                                  : _localProducts.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.inventory_2_outlined,
                                                size: 72,
                                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                                              ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds),
                                              const SizedBox(height: 16),
                                              Text(
                                                'menu_kosong_atau_belum_282'.tr(context: context),
                                                style: TextStyle(
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : _filteredProducts.isEmpty
                                          ? Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.search_off_rounded,
                                                    size: 60,
                                                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    'tidak_ada_produk_cocok'.tr(context: context),
                                                    style: TextStyle(
                                                      color: theme.colorScheme.onSurfaceVariant,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  TextButton.icon(
                                                    onPressed: () {
                                                      setState(() {
                                                        _selectedCategory = 'all';
                                                        _searchQuery = '';
                                                        _searchController.clear();
                                                      });
                                                    },
                                                    icon: const Icon(Icons.refresh_rounded, size: 16),
                                                    label: Text('reset_filter_284'.tr(context: context)),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : GridView.builder(
                                              padding: EdgeInsets.only(
                                                top: 10,
                                                bottom: isDesktop
                                                    ? 40
                                                    : (totalItems > 0 ? 190 : 120),
                                              ),
                                              physics: const BouncingScrollPhysics(),
                                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: isDesktop ? 4 : 2,
                                                childAspectRatio: isDesktop ? 0.78 : 0.72,
                                                crossAxisSpacing: 14,
                                                mainAxisSpacing: 14,
                                              ),
                                              itemCount: _filteredProducts.length,
                                              itemBuilder: (context, index) {
                                                return _buildMenuCard(context, _filteredProducts[index])
                                                    .animate(delay: (index * 30).ms)
                                                    .fade(duration: 300.ms)
                                                    .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
                                              },
                                            ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // KANAN: Keranjang Belanja Premium (Hanya Desktop)
                    if (isDesktop) ...[
                      Container(
                        width: 380,
                        margin: const EdgeInsets.fromLTRB(0, 16, 20, 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withValues(alpha: 0.04),
                              blurRadius: 24,
                              offset: const Offset(-4, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: _buildCartPanel(context),
                        ),
                      ).animate().fade(duration: 400.ms).slideX(begin: 0.1, end: 0, curve: Curves.easeOutQuart),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // ── 3. FLOATING CART SUMMARY BAR (UNTUK MOBILE SAAT ADA ITEM) ──
          if (!isDesktop && totalItems > 0)
            Positioned(
              left: 20,
              right: 20,
              bottom: 95, // Di atas floating bottom nav
              child: _buildFloatingCartSummary(context, theme, cart, totalItems, size),
            ),
        ],
      ),
    );
  }

  /// ─── Floating Checkout Bar untuk Mobile POS ───
  Widget _buildFloatingCartSummary(
    BuildContext context,
    ThemeData theme,
    CartProvider cart,
    int totalItems,
    Size size,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showMobileCart(context, theme, size),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.shopping_bag_rounded, color: theme.colorScheme.primary, size: 20),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          totalItems.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'total_bayar_label'.tr(context: context),
                      style: TextStyle(fontSize: 10.5, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Rp ${NumberFormat('#,###', 'id_ID').format(cart.finalAmount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showMobileCart(context, theme, size),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(
                  'lihat_keranjang_bayar'.tr(context: context),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildGlassHeader(BuildContext context, ThemeData theme, Size size, bool isDesktop) {
    return ZenviHeader(
      title: 'pos_title'.tr(context: context),
      subtitle: 'pos_header_subtitle'.tr(context: context),
      showBackButton: widget.onNavigateBack != null || Navigator.of(context).canPop(),
      onBackPressed: () {
        if (widget.onNavigateBack != null) {
          widget.onNavigateBack!();
        } else if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      padding: EdgeInsets.only(
        left: isDesktop ? 24 : 16,
        right: isDesktop ? 24 : 16,
        top: MediaQuery.of(context).padding.top + 4.0,
        bottom: 6.0,
      ),
      actions: [
        // Reservation Button
        Consumer<ReservationProvider>(
          builder: (context, resProv, child) {
            final activeResCount = resProv.allReservations.where((r) => r.status == 'pending' || r.status == 'confirmed').length;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                _buildHeaderActionButton(
                  theme: theme,
                  icon: Icons.event_available_rounded,
                  tooltip: 'pos_reservation_tooltip'.tr(context: context),
                  onTap: () => _showReservationModal(context),
                ),
                if (activeResCount > 0)
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        activeResCount > 9 ? '9+' : activeResCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 6),

        // Sync Button
        _buildHeaderActionButton(
          theme: theme,
          icon: Icons.sync_rounded,
          tooltip: 'sync_data_tooltip'.tr(context: context),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('menyinkronkan_data_286'.tr(context: context))),
            );
            _loadProducts();
            SyncService().pushOfflineOrders();
          },
        ),
        const SizedBox(width: 6),

        // Order History Button
        _buildHeaderActionButton(
          theme: theme,
          icon: Icons.history_rounded,
          tooltip: 'transaction_history_tooltip'.tr(context: context),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const order_history.OrderHistoryScreen()),
            );
          },
        ),
        const SizedBox(width: 6),

        // Printer Settings Button
        _buildHeaderActionButton(
          theme: theme,
          icon: Icons.print_outlined,
          tooltip: 'printer_settings_tooltip'.tr(context: context),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PrinterSettingsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeaderActionButton({
    required ThemeData theme,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: theme.colorScheme.onSurface, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(ThemeData theme, bool isDesktop) {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 14, bottom: 120),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 2,
        childAspectRatio: isDesktop ? 0.78 : 0.72,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(height: 14, width: double.infinity, color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)),
                      const SizedBox(height: 8),
                      Container(height: 16, width: 70, color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 1.5.seconds, color: theme.colorScheme.primary.withValues(alpha: 0.08));
      },
    );
  }

  Widget _buildFilterAndCategoryBar(ThemeData theme) {
    final categories = _categories;

    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search box
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'cari_produk_hint'.tr(context: context),
                hintStyle: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                prefixIcon: Icon(Icons.search_rounded, size: 19, color: theme.colorScheme.onSurfaceVariant),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Horizontal scrollable category pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildCategoryPill(
                  theme: theme,
                  label: 'semua_5'.tr(context: context),
                  count: _localProducts.length,
                  isSelected: _selectedCategory == 'all',
                  onTap: () {
                    setState(() {
                      _selectedCategory = 'all';
                    });
                  },
                ),
                ...categories.map((cat) {
                  final count = _localProducts.where((p) => p.category?.trim().toLowerCase() == cat.toLowerCase()).length;
                  return _buildCategoryPill(
                    theme: theme,
                    label: cat,
                    count: count,
                    isSelected: _selectedCategory.toLowerCase() == cat.toLowerCase(),
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill({
    required ThemeData theme,
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.dividerColor.withValues(alpha: 0.12),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: theme.shadowColor.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.25)
                        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getProductCategoryIcon(ProductModel product) {
    final cat = (product.category ?? '').toLowerCase();
    final name = product.name.toLowerCase();
    final combined = '$cat $name';

    if (combined.contains('kopi') ||
        combined.contains('coffee') ||
        combined.contains('tea') ||
        combined.contains('teh') ||
        combined.contains('minum') ||
        combined.contains('drink') ||
        combined.contains('jus') ||
        combined.contains('juice') ||
        combined.contains('latte') ||
        combined.contains('boba')) {
      return Icons.local_cafe_rounded;
    }
    if (combined.contains('potong') ||
        combined.contains('cukur') ||
        combined.contains('rambut') ||
        combined.contains('hair') ||
        combined.contains('barber') ||
        combined.contains('salon') ||
        combined.contains('creambath') ||
        combined.contains('shampoo') ||
        combined.contains('facial') ||
        combined.contains('massage') ||
        combined.contains('pijat') ||
        combined.contains('spa') ||
        combined.contains('treatment') ||
        combined.contains('service') ||
        combined.contains('jasa') ||
        combined.contains('cuci')) {
      return Icons.content_cut_rounded;
    }
    if (combined.contains('baju') ||
        combined.contains('kaos') ||
        combined.contains('pakaian') ||
        combined.contains('cloth') ||
        combined.contains('retail') ||
        combined.contains('barang')) {
      return Icons.shopping_bag_rounded;
    }
    return Icons.restaurant_rounded;
  }

  Widget _buildMenuCard(BuildContext context, ProductModel product) {
    final theme = Theme.of(context);
    final isProductImageEnabled = Provider.of<AuthProvider>(context, listen: false).isProductImageEnabled;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            if (!_checkShiftOrShowDialog(context)) return;
            if (product.variants.isNotEmpty) {
              _showVariantSelectionDialog(context, product);
            } else {
              Provider.of<CartProvider>(context, listen: false).addToCart(product);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Gambar Produk
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      (isProductImageEnabled && product.imageUrl != null && product.imageUrl!.isNotEmpty)
                          ? ProductImage(
                              imageUrl: product.imageUrl,
                              fit: BoxFit.cover,
                              fallback: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getProductCategoryIcon(product),
                                    size: 34,
                                    color: theme.colorScheme.primary.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getProductCategoryIcon(product),
                                  size: 34,
                                  color: theme.colorScheme.primary.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                      if (product.category != null && product.category!.trim().isNotEmpty)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
                            ),
                            child: Text(
                              product.category!.trim(),
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Detail & Harga
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (product.price != product.finalPrice)
                                  Text(
                                    'Rp ${NumberFormat('#,###', 'id_ID').format(product.price)}',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 10.5,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                Text(
                                  'Rp ${NumberFormat('#,###', 'id_ID').format(product.finalPrice)}',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartPanel(BuildContext context) {
    final theme = Theme.of(context);
    final cart = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final company = authProvider.user?.company;
    final isMembershipEnabled = company?['is_membership_enabled'] == true || company?['is_membership_enabled'] == 1;

    return Column(
      children: [
        // Cart Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 20, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.shopping_bag_rounded, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'cart_title'.tr(context: context),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              if (cart.items.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.delete_sweep_rounded, color: theme.colorScheme.error, size: 20),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Text('kosongkan_keranjang_287'.tr(context: context)),
                        content: Text('semua_produk_di_keranjang_288'.tr(context: context)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text('batal_5'.tr(context: context)),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              cart.clearCart();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.error,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('kosongkan_289'.tr(context: context)),
                          ),
                        ],
                      ),
                    );
                  },
                  tooltip: 'clear_all_tooltip'.tr(context: context),
                ),
            ],
          ),
        ),

        // Reservation Banner (Jika ada reservasi yang sedang dimuat)
        if (cart.selectedReservation != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.event_available_rounded, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'active_reservation_banner'.tr(
                            context: context,
                            args: [
                              cart.selectedReservation!.customerName,
                              cart.selectedReservation!.reservationTime,
                            ],
                          ),
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: theme.colorScheme.primary),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cart.selectedReservation!.serviceNames ??
                              (cart.selectedReservation!.numberOfPeople > 1
                                  ? 'guests_count_label'.tr(context: context, args: [cart.selectedReservation!.numberOfPeople.toString()])
                                  : cart.selectedReservation!.customerPhone),
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 16, color: theme.colorScheme.error),
                    onPressed: () => cart.clearReservation(),
                    tooltip: 'detach_reservation_tooltip'.tr(context: context),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),

        // Member Bar (Jika fitur membership aktif)
        if (isMembershipEnabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: cart.selectedMember == null
                ? InkWell(
                    onTap: () async {
                      final promoProvider = Provider.of<MemberPromoProvider>(context, listen: false);
                      final selected = await MemberSelectionModal.show(context);
                      if (selected != null) {
                        cart.setSelectedMember(selected, activePromos: promoProvider.activePromos);
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.card_membership_rounded, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'pilih_member_btn'.tr(context: context),
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.star_rounded, size: 14, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      cart.selectedMember!.name,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      cart.selectedMember!.memberCode,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9.5, color: theme.colorScheme.primary),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'member_poin_info'.tr(context: context, args: [cart.selectedMember!.points.toString(), cart.selectedMember!.phone]),
                                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, size: 16, color: theme.colorScheme.error),
                          onPressed: () => cart.clearMember(),
                          tooltip: 'hapus_member_tooltip'.tr(context: context),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
          ),

        // Cart Items List
        Expanded(
          child: cart.items.isEmpty
              ? _buildEmptyState(theme).animate().fade().scale()
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: cart.items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    final unitPrice = item.variantPrice ?? item.product.finalPrice;
                    final displayName = item.variantName != null
                        ? '${item.product.name} - ${item.variantName}'
                        : item.product.name;

                    return Dismissible(
                      key: ValueKey('cart_${item.product.id}_${item.variantName ?? ''}_${item.hashCode}'),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) {
                        cart.removeItem(item);
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Rp ${NumberFormat('#,###', 'id_ID').format(unitPrice)}',
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Rp ${NumberFormat('#,###', 'id_ID').format(item.subtotal)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Tombol Hapus Produk Tunggal
                                InkWell(
                                  onTap: () => cart.removeItem(item),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.delete_outline_rounded, size: 14, color: theme.colorScheme.error),
                                        const SizedBox(width: 4),
                                        Text(
                                          'hapus_logo'.tr(context: context),
                                          style: TextStyle(
                                            color: theme.colorScheme.error,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Stepper Pengurang / Penambah Jumlah: [-] [qty] [+]
                                Container(
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_rounded, size: 14),
                                        onPressed: () => cart.decreaseQty(item),
                                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                        padding: EdgeInsets.zero,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        child: Text(
                                          item.quantity.toString(),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_rounded, size: 14),
                                        onPressed: () => cart.increaseQty(item),
                                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Checkout Panel
        if (cart.items.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.08))),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('subtotal_label'.tr(context: context), style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                    Text('Rp ${NumberFormat('#,###', 'id_ID').format(cart.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
                if (cart.memberDiscountAmount > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('member_discount_label'.tr(context: context), style: TextStyle(color: theme.colorScheme.primary, fontSize: 12)),
                      Text('- Rp ${NumberFormat('#,###', 'id_ID').format(cart.memberDiscountAmount)}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.08)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('total_bayar_label'.tr(context: context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                      'Rp ${NumberFormat('#,###', 'id_ID').format(cart.finalAmount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleCheckout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('checkout_btn'.tr(context: context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 56, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            'keranjang_masih_kosong_291'.tr(context: context),
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showVariantSelectionDialog(BuildContext context, ProductModel product) {
    final theme = Theme.of(context);
    ProductVariantModel? selectedVariant = product.variants.isNotEmpty ? product.variants.first : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('select_variant_label'.tr(context: context), style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: product.variants.map((v) {
                    final isSelected = selectedVariant?.id == v.id;
                    return InkWell(
                      onTap: () => setModalState(() => selectedVariant = v),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? theme.colorScheme.primary : theme.dividerColor.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          '${v.name} (Rp ${NumberFormat('#,###', 'id_ID').format(v.price)})',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedVariant == null
                        ? null
                        : () {
                            Provider.of<CartProvider>(context, listen: false).addToCart(
                              product,
                              variantName: selectedVariant!.name,
                              variantPrice: selectedVariant!.price,
                            );
                            Navigator.pop(ctx);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('add_to_cart_label'.tr(context: context), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
