import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../providers/auth_provider.dart';
import '../../providers/shift_provider.dart';
import '../../providers/reservation_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/order_provider.dart';

import '../pos/pos_screen.dart';
import '../shift/shift_screen.dart';
import '../settings/settings_screen.dart';
import '../chat/chat_list_screen.dart';
import '../reservation/reservation_list_screen.dart';
import '../stock/stock_management_screen.dart';
import '../notifications/notification_center_screen.dart';
import '../permission/employee_permission_screen.dart';
import '../kds/kds_screen.dart';
import '../pos/order_history_screen.dart';
import 'expense_screen.dart';

class _NavItemData {
  final IconData icon;
  final String label;
  final Widget page;
  _NavItemData(this.icon, this.label, this.page);
}

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token != null) {
        await authProvider.fetchUserData();
        if (mounted) {
          Provider.of<ShiftProvider>(context, listen: false).fetchActiveShift(token);
          Provider.of<OrderProvider>(context, listen: false).loadAllOrders();
          if (authProvider.canAccessReservations) {
            Provider.of<ReservationProvider>(context, listen: false).fetchReservations();
          }
          Provider.of<NotificationProvider>(context, listen: false).fetchNotifications(token: token, silent: true);
        }
      }
    });
  }

  void _navigateToTab(int index) {
    if (index >= 0) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final authProvider = Provider.of<AuthProvider>(context);

    final canAccessPos = authProvider.canAccessPos;
    final canAccessStock = authProvider.canAccessStock;
    final canAccessReservations = authProvider.canAccessReservations;
    final canAccessExpenses = authProvider.canAccessExpenses;

    final bool isKdsEnabled = authProvider.isKdsEnabled;
    final canAccessKds = (authProvider.user?.canAccessKds ?? false) && isKdsEnabled;

    final List<_NavItemData> navItems = [];

    // 1. Beranda / Dashboard Operasional (Tab Utama Karyawan)
    navItems.add(_NavItemData(
      Icons.dashboard_rounded,
      'dashboard'.tr(context: context),
      _EmployeeOverviewScreen(
        canAccessPos: canAccessPos,
        canAccessReservations: canAccessReservations,
        canAccessStock: canAccessStock,
        canAccessExpenses: canAccessExpenses,
        canAccessKds: canAccessKds,
        onNavigateToPos: () {
          final posIdx = navItems.indexWhere((item) => item.label == 'pos'.tr());
          if (posIdx != -1) _navigateToTab(posIdx);
        },
        onNavigateToShift: () {
          final shiftIdx = navItems.indexWhere((item) => item.label == 'shift'.tr());
          if (shiftIdx != -1) _navigateToTab(shiftIdx);
        },
      ),
    ));

    // 2. Kasir POS (jika diizinkan)
    if (canAccessPos) {
      navItems.add(_NavItemData(
        Icons.point_of_sale_rounded,
        'pos'.tr(context: context),
        POSScreen(
          onNavigateToShift: () {
            final shiftIdx = navItems.indexWhere((item) => item.label == 'shift'.tr());
            if (shiftIdx != -1) _navigateToTab(shiftIdx);
          },
          onNavigateBack: () {
            _navigateToTab(0);
          },
        ),
      ));
    }

    // 3. Shift (Absensi & Kasir)
    navItems.add(_NavItemData(
      Icons.access_time_filled_rounded,
      'shift'.tr(context: context),
      const ShiftScreen(),
    ));

    // 4. Chat Internal
    navItems.add(_NavItemData(
      Icons.chat_bubble_rounded,
      'chat_4'.tr(context: context),
      const ChatListScreen(),
    ));

    // 5. Profil & Pengaturan
    navItems.add(_NavItemData(
      Icons.person_rounded,
      'profile_subtitle'.tr(context: context),
      const SettingsScreen(),
    ));

    if (_selectedIndex >= navItems.length) {
      _selectedIndex = 0;
    }

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() {
          _selectedIndex = 0;
        });
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      ...previousChildren,
                      ?currentChild,
                    ],
                  );
                },
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_selectedIndex),
                  child: navItems[_selectedIndex].page,
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: isKeyboardOpen ? null : _buildBottomNav(theme, context, navItems),
      ),
    );
  }

  Widget _buildBottomNav(ThemeData theme, BuildContext context, List<_NavItemData> navItems) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(navItems.length, (index) {
                  final item = navItems[index];
                  return Expanded(
                    child: _buildNavItem(index, item.icon, item.label, theme),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, ThemeData theme) {
    final isSelected = _selectedIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToTab(index),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  size: isSelected ? 22 : 20,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 10.5,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OVERVIEW SCREEN: Hub Operasional & Beranda Karyawan
// ─────────────────────────────────────────────────────────────────────────────

class _EmployeeOverviewScreen extends StatelessWidget {
  final bool canAccessPos;
  final bool canAccessReservations;
  final bool canAccessStock;
  final bool canAccessExpenses;
  final bool canAccessKds;
  final VoidCallback onNavigateToPos;
  final VoidCallback onNavigateToShift;

  const _EmployeeOverviewScreen({
    required this.canAccessPos,
    required this.canAccessReservations,
    required this.canAccessStock,
    required this.canAccessExpenses,
    required this.canAccessKds,
    required this.onNavigateToPos,
    required this.onNavigateToShift,
  });

  String _getGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour < 11) {
      return 'good_morning'.tr(context: context);
    } else if (hour < 15) {
      return 'good_afternoon'.tr(context: context);
    } else if (hour < 18) {
      return 'good_evening'.tr(context: context);
    } else {
      return 'good_night'.tr(context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final shiftProvider = Provider.of<ShiftProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final topPadding = MediaQuery.of(context).padding.top;
    final activeShift = shiftProvider.activeShift;
    final isShiftActive = activeShift != null;

    final branchName = user?.branch?['name']?.toString() ?? user?.company?['name']?.toString() ?? 'Zenvi POS';
    final jobTitle = user?.jobTitle != null && user!.jobTitle!.isNotEmpty
        ? user.jobTitle!
        : 'staff_badge_default'.tr(context: context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          final token = auth.token;
          if (token != null) {
            await Future.wait([
              shiftProvider.fetchActiveShift(token),
              orderProvider.loadAllOrders(),
              notifProvider.fetchNotifications(token: token, silent: true),
            ]);
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // ── Sticky Header: Profil & Greeting ──
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(
                height: 88 + topPadding,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: EdgeInsets.only(left: 20, right: 20, top: 4 + topPadding, bottom: 8),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.85),
                        border: Border(
                          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.08), width: 1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${_getGreeting(context)}, ',
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Flexible(
                                      child: Text(
                                        user?.name ?? 'Karyawan',
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurface,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'employee_dashboard_title'.tr(context: context),
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        jobTitle,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(Icons.store_rounded, size: 12, color: theme.colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        branchName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Tombol Notifikasi Bell dengan Unread Counter & Interaksi Tactile
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(7.5),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                                  boxShadow: [
                                    BoxShadow(color: theme.shadowColor.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
                                  ],
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Icon(Icons.notifications_outlined, color: theme.colorScheme.onSurface, size: 20),
                                    if (notifProvider.unreadCount > 0)
                                      Positioned(
                                        top: -4,
                                        right: -4,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.error,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                          child: Text(
                                            notifProvider.unreadCount > 9 ? '9+' : notifProvider.unreadCount.toString(),
                                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, height: 1),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Konten Dashboard ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 1. DASHBOARD PENJUALAN KARYAWAN (HERO SALES SUMMARY) ──
                        _buildEmployeeSalesCard(context, theme, orderProvider),

                        const SizedBox(height: 14),

                        // ── 2. CARD STATUS SHIFT ──
                        _buildShiftStatusHeroCard(context, theme, activeShift, isShiftActive),

                        const SizedBox(height: 16),

                        // ── 3. GRID OPERASIONAL & LAYANAN (MINIMALIST THEME COLOR) ──
                        Row(
                          children: [
                            Icon(Icons.grid_view_rounded, size: 15, color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              'quick_operations_header'.tr(context: context).toUpperCase(),
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        _buildOperationsGrid(context, theme),
                      ],
                    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.04, end: 0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ─── Hero Sales Dashboard Card for Employee ───
  Widget _buildEmployeeSalesCard(BuildContext context, ThemeData theme, OrderProvider orderProvider) {
    final orders = orderProvider.orders.where((o) => o.status != 'voided').toList();
    final offlineOrders = orderProvider.offlineOrders;

    double totalSales = 0.0;
    for (var o in orders) {
      totalSales += o.totalAmount;
    }
    for (var off in offlineOrders) {
      totalSales += (double.tryParse(off['total_amount']?.toString() ?? '0') ?? 0.0);
    }

    final totalCount = orders.length + offlineOrders.length;
    final avgOrder = totalCount > 0 ? (totalSales / totalCount) : 0.0;
    final offlineCount = offlineOrders.length;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
            );
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(Icons.analytics_rounded, color: theme.colorScheme.primary, size: 17),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ringkasan_penjualan_saya'.tr(context: context),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (offlineCount > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.cloud_off_rounded, size: 11, color: theme.colorScheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  'termasuk_offline_orders'.tr(context: context, args: [offlineCount.toString()]),
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Icon(Icons.chevron_right_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'penjualan_hari_ini'.tr(context: context),
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11.5, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rp ${NumberFormat('#,###', 'id_ID').format(totalSales)}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    fontSize: 22,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'total_transaksi_label'.tr(context: context),
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'transaksi_count_unit'.tr(context: context, args: [totalCount.toString()]),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 24,
                        width: 1,
                        color: theme.dividerColor.withValues(alpha: 0.12),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'rata_rata_transaksi_label'.tr(context: context),
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rp ${NumberFormat('#,###', 'id_ID').format(avgOrder)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShiftStatusHeroCard(BuildContext context, ThemeData theme, dynamic activeShift, bool isShiftActive) {
    String startTimeFormatted = '-';
    double openingBalance = 0.0;

    if (isShiftActive && activeShift != null) {
      openingBalance = double.tryParse(activeShift.openingBalance?.toString() ?? '0') ?? 0.0;
      if (activeShift.startTime != null) {
        try {
          final dt = DateTime.parse(activeShift.startTime.toString()).toLocal();
          startTimeFormatted = DateFormat('HH:mm').format(dt);
        } catch (_) {
          startTimeFormatted = activeShift.startTime.toString();
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onNavigateToShift,
          borderRadius: BorderRadius.circular(20),
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isShiftActive ? Icons.timer_rounded : Icons.timer_off_rounded,
                        color: theme.colorScheme.primary,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: isShiftActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isShiftActive
                                    ? 'shift_status_active'.tr(context: context)
                                    : 'shift_status_inactive'.tr(context: context),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: isShiftActive ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isShiftActive
                                ? 'shift_started_at_time'.tr(context: context, args: [startTimeFormatted])
                                : 'shift_inactive_desc'.tr(context: context),
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isShiftActive) ...[
                  const SizedBox(height: 12),
                  Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.08)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'opening_balance'.tr(context: context),
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Rp ${NumberFormat('#,###', 'id_ID').format(openingBalance)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                        ],
                      ),
                      FilledButton.tonalIcon(
                        onPressed: onNavigateToShift,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                        label: Text(
                          'manage_shift_btn'.tr(context: context),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onNavigateToShift,
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: Text(
                        'open_shift_now_btn'.tr(context: context),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOperationsGrid(BuildContext context, ThemeData theme) {
    final notifProvider = Provider.of<NotificationProvider>(context);

    final List<_OperationCardData> cards = [];

    // 1. Kasir POS
    if (canAccessPos) {
      cards.add(_OperationCardData(
        title: 'pos_cashier_title'.tr(context: context),
        subtitle: 'pos_cashier_desc'.tr(context: context),
        icon: Icons.point_of_sale_rounded,
        onTap: onNavigateToPos,
      ));
    }

    // 2. Shift & Presensi
    cards.add(_OperationCardData(
      title: 'shift_presensi_title'.tr(context: context),
      subtitle: 'shift_presensi_desc'.tr(context: context),
      icon: Icons.access_time_filled_rounded,
      onTap: onNavigateToShift,
    ));

    // 3. KDS Dapur (jika diizinkan & aktif)
    if (canAccessKds) {
      cards.add(_OperationCardData(
        title: 'kds_kitchen_title'.tr(context: context),
        subtitle: 'kds_kitchen_desc'.tr(context: context),
        icon: Icons.kitchen_rounded,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const KdsScreen()));
        },
      ));
    }

    // 4. Reservasi Meja & Jasa (jika diizinkan)
    if (canAccessReservations) {
      cards.add(_OperationCardData(
        title: 'reservation_menu_title'.tr(context: context),
        subtitle: 'reservation_menu_desc'.tr(context: context),
        icon: Icons.event_seat_rounded,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ReservationListScreen()));
        },
      ));
    }

    // 5. Manajemen Stok & Bahan Baku (jika diizinkan)
    if (canAccessStock) {
      cards.add(_OperationCardData(
        title: 'stock_management_title'.tr(context: context),
        subtitle: 'stock_management_desc'.tr(context: context),
        icon: Icons.inventory_2_rounded,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const StockManagementScreen()));
        },
      ));
    }

    // 6. Catat Pengeluaran (jika diizinkan)
    if (canAccessExpenses) {
      cards.add(_OperationCardData(
        title: 'expense_menu_title'.tr(context: context),
        subtitle: 'expense_menu_desc'.tr(context: context),
        icon: Icons.receipt_long_rounded,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseScreen()));
        },
      ));
    }

    // 7. Pengajuan Izin / Cuti Karyawan (Tersedia untuk semua staf)
    cards.add(_OperationCardData(
      title: 'permission_menu_title'.tr(context: context),
      subtitle: 'permission_menu_desc'.tr(context: context),
      icon: Icons.event_note_rounded,
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeePermissionScreen()));
      },
    ));

    // 8. Pusat Notifikasi
    cards.add(_OperationCardData(
      title: 'notification_menu_title'.tr(context: context),
      subtitle: 'notification_menu_desc'.tr(context: context),
      icon: Icons.notifications_rounded,
      badgeCount: notifProvider.unreadCount,
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationCenterScreen()));
      },
    ));

    final isTablet = MediaQuery.of(context).size.width > 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isTablet ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: isTablet ? 1.4 : 1.22,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final item = cards[index];
            return _buildOperationCard(context, theme, item);
          },
        );
      },
    );
  }

  Widget _buildOperationCard(BuildContext context, ThemeData theme, _OperationCardData item) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.12),
          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, color: theme.colorScheme.primary, size: 18),
                    ),
                    if (item.badgeCount != null && item.badgeCount! > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.badgeCount! > 9 ? '9+' : item.badgeCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                        height: 1.15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OperationCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final int? badgeCount;
  final VoidCallback onTap;

  _OperationCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.badgeCount,
    required this.onTap,
  });
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  _StickyHeaderDelegate({required this.child, required this.height});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => height;
  @override
  double get minExtent => height;
  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) => true;
}
