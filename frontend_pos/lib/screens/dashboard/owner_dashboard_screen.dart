import 'package:easy_localization/easy_localization.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/ingredient_provider.dart';
import '../../providers/branch_provider.dart';
import '../../providers/reservation_provider.dart';
import '../../providers/notification_provider.dart';

import 'shift_log_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/branch_list_screen.dart';
import 'product_list_screen.dart';
import 'expense_screen.dart';
import '../stock/stock_management_screen.dart';
import 'owner_transaction_log_screen.dart';
import 'employee_verification_screen.dart';
import 'employee_performance_screen.dart';
import '../chat/chat_list_screen.dart';
import '../permission/owner_permission_management_screen.dart';
import '../reservation/reservation_list_screen.dart';
import '../membership/member_management_screen.dart';
import '../notifications/notification_center_screen.dart';
import '../../widgets/zenvi_header.dart';
import '../../services/export_service.dart';
import '../../widgets/premium_gate.dart';
import '../../theme/app_colors.dart';

class _NavItemData {
  final IconData icon;
  final String label;
  final Widget page;
  _NavItemData(this.icon, this.label, this.page);
}

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    
    final List<_NavItemData> navItems = [
      _NavItemData(Icons.dashboard_rounded, 'dashboard'.tr(context: context), const _DashboardOverview()),
      _NavItemData(Icons.chat_bubble_rounded, 'chat_4'.tr(context: context), const ChatListScreen()),
      _NavItemData(Icons.person_rounded, 'profile_subtitle'.tr(context: context), const SettingsScreen()),
      _NavItemData(Icons.grid_view_rounded, 'other'.tr(context: context), _MoreMenuScreen(onNavigate: (w) {})),
    ];

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
        extendBody: true, // Untuk efek floating bottom nav
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutBack,
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
        bottomNavigationBar: isKeyboardOpen ? null : _buildFullWidthBottomNav(theme, context, navItems),
      ),
    );
  }

  Widget _buildFullWidthBottomNav(ThemeData theme, BuildContext context, List<_NavItemData> navItems) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ]
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ...List.generate(navItems.length, (index) {
                    final item = navItems[index];
                    return Expanded(
                      child: _buildNavItem(index, item.icon, item.label, theme, isDesktop),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, ThemeData theme, bool isDesktop) {
    final isSelected = _selectedIndex == index;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ] : null,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  size: isSelected ? 24 : 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 11,
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

// ---------------------------------------------------------
// DASHBOARD OVERVIEW - Modern Analytics
// ---------------------------------------------------------
class _DashboardOverview extends StatefulWidget {
  const _DashboardOverview();

  @override
  State<_DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<_DashboardOverview> {
  String _selectedPeriod = 'today';
  String _selectedBranch = 'all';
  DateTime _selectedDate = DateTime.now();
  DateTimeRange? _selectedDateRange;
  int _selectedAnalyticsTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadDashboardData() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token != null) {
      Provider.of<BranchProvider>(context, listen: false).fetchBranches(token);
      Provider.of<ExpenseProvider>(context, listen: false).fetchExpenses();
      _fetchReport();
      if (auth.isReservationEnabled) {
        Provider.of<ReservationProvider>(context, listen: false).fetchReservations();
      }
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications(token: token, silent: true);
    }
  }

  void _openAddExpenseDialog() {
    final theme = Theme.of(context);
    final amountController = TextEditingController();
    final descController = TextEditingController();
    final qtyController = TextEditingController();
    String expenseType = 'operational';
    int? selectedIngredientId;

    // Fetch ingredients for restock option
    Provider.of<IngredientProvider>(context, listen: false).fetchIngredients();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final ingredientProvider = Provider.of<IngredientProvider>(modalCtx);
            final auth = Provider.of<AuthProvider>(modalCtx, listen: false);

            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 32,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.dangerFill.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.money_off_rounded, color: AppColors.dangerFill, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'catat_pengeluaran_baru_22'.tr(context: context),
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, fontSize: 18),
                              ),
                              Text(
                                'catat_biaya_operasional_gaji_47'.tr(context: context),
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: expenseType,
                      decoration: InputDecoration(
                        labelText: 'jenis_pengeluaran_17'.tr(context: context),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.category_rounded, size: 20),
                      ),
                      items: [
                        DropdownMenuItem(value: 'operational', child: Text('operasional_tagihan_listrik_124'.tr(context: context))),
                        DropdownMenuItem(value: 'ingredient_restock', child: Text('order_bahan_restock_stok_125'.tr(context: context))),
                        if (auth.isOwner)
                          DropdownMenuItem(value: 'salary', child: Text('gaji_karyawan_99'.tr(context: context))),
                        DropdownMenuItem(value: 'other', child: Text('pengeluaran_lainnya_126'.tr(context: context))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            expenseType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    if (expenseType == 'ingredient_restock') ...[
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: 'pilih_bahan_baku_16'.tr(context: context),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.kitchen_rounded, size: 20),
                        ),
                        initialValue: selectedIngredientId,
                        items: ingredientProvider.ingredients.map((ing) {
                          return DropdownMenuItem<int>(
                            value: ing.id,
                            child: Text('${ing.name} (${ing.unit})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            selectedIngredientId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: qtyController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'expense_qty_purchased_label'.tr(context: context),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'expense_cost_amount_label'.tr(context: context),
                        prefixText: 'rp_3'.tr(context: context),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.payments_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(
                        labelText: 'expense_note_label'.tr(context: context),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        prefixIcon: Icon(Icons.notes_rounded, size: 20),
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(modalCtx),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text('batal_5'.tr(context: context), style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () async {
                              final provider = Provider.of<ExpenseProvider>(context, listen: false);
                              final amount = double.tryParse(amountController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;

                              if (amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('nominal_biaya_tidak_valid_127'.tr(context: context))),
                                );
                                return;
                              }

                              double? qty;
                              if (expenseType == 'ingredient_restock') {
                                if (selectedIngredientId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('pilih_bahan_baku_terlebih_128'.tr(context: context))),
                                  );
                                  return;
                                }
                                qty = double.tryParse(qtyController.text.replaceAll(',', '.')) ?? 0;
                                if (qty <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('jumlah_kuantitas_tidak_valid_129'.tr(context: context))),
                                  );
                                  return;
                                }
                              }

                              final success = await provider.addExpense(
                                expenseType: expenseType,
                                amount: amount,
                                description: descController.text.trim().isNotEmpty ? descController.text.trim() : null,
                                ingredientId: selectedIngredientId,
                                qtyAdded: qty,
                              );

                              if (success) {
                                if (modalCtx.mounted) {
                                  Navigator.pop(modalCtx);
                                }
                                if (mounted) {
                                  _fetchReport();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('pengeluaran_berhasil_dicatat_data_130'.tr(context: context)),
                                      backgroundColor: AppColors.successFill,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.dangerFill,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text('simpan_pengeluaran_105'.tr(context: context), style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _fetchReport() {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    expenseProvider.fetchFinancialReport(
      period: _selectedPeriod,
      branchId: _selectedBranch,
      date: _selectedDate,
      startDate: _selectedDateRange?.start,
      endDate: _selectedDateRange?.end,
    );
  }



  Widget _buildQuickFilterChip(String periodId, String label, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isSelected = _selectedPeriod == periodId;
    return ActionChip(
      label: Text(label),
      backgroundColor: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: onTap,
    );
  }

  Future<void> _openDateSelectorModal() async {
    final theme = Theme.of(context);
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.calendar_month_rounded, color: theme.colorScheme.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'pilih_tanggal_laporan_131'.tr(context: context),
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, fontSize: 18),
                        ),
                        Text(
                          'filter_ringkasan_finansial_dan_132'.tr(context: context),
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('filter_cepat_133'.tr(context: context), style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickFilterChip('7_days', 'last_7_days'.tr(context: context), () {
                    setState(() {
                      _selectedPeriod = '7_days';
                      _selectedDateRange = DateTimeRange(start: DateTime.now().subtract(const Duration(days: 6)), end: DateTime.now());
                    });
                    Navigator.pop(ctx);
                    _fetchReport();
                  }),
                  _buildQuickFilterChip('this_month', 'this_month'.tr(context: context), () {
                    setState(() {
                      _selectedPeriod = 'this_month';
                      final now = DateTime.now();
                      _selectedDateRange = DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
                    });
                    Navigator.pop(ctx);
                    _fetchReport();
                  }),
                  _buildQuickFilterChip('this_year', 'last_1_year'.tr(context: context), () {
                    setState(() {
                      _selectedPeriod = 'this_year';
                      final now = DateTime.now();
                      _selectedDateRange = DateTimeRange(start: DateTime(now.year - 1, now.month, now.day), end: now);
                    });
                    Navigator.pop(ctx);
                    _fetchReport();
                  }),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _pickSingleDate();
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.event_available_rounded, color: theme.colorScheme.primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('pilih_satu_tanggal_spesifik_134'.tr(context: context), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(
                                'current_date_prefix'.tr(context: context, args: [DateFormat('dd MMMM yyyy', 'id').format(_selectedDate)]),
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: theme.colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _pickDateRange();
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.date_range_rounded, color: theme.colorScheme.secondary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('pilih_rentang_tanggal_kustom_135'.tr(context: context), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(
                                _selectedDateRange != null
                                    ? '${DateFormat('dd MMM yyyy', 'id').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy', 'id').format(_selectedDateRange!.end)}'
                                    : 'specify_date_range'.tr(context: context),
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: theme.colorScheme.secondary),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickSingleDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'pick_report_date_help'.tr(context: context),
      cancelText: 'cancel'.tr(context: context),
      confirmText: 'apply_btn'.tr(context: context),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedPeriod = 'date';
        _selectedDateRange = null;
      });
      _fetchReport();
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 6)),
            end: DateTime.now(),
          ),
      helpText: 'pick_date_range_help'.tr(context: context),
      cancelText: 'cancel'.tr(context: context),
      confirmText: 'apply_btn'.tr(context: context),
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _selectedPeriod = 'custom';
      });
      _fetchReport();
    }
  }

  void _showMetricDetailDialog({
    required String title,
    required String value,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(fontSize: 13.5, color: theme.colorScheme.onSurfaceVariant, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('tutup_136'.tr(context: context), style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final branchProvider = Provider.of<BranchProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final reservationProvider = Provider.of<ReservationProvider>(context);
    
    final branches = branchProvider.branches;

    final topPadding = MediaQuery.of(context).padding.top;

    return RefreshIndicator(
      onRefresh: () async {
        _loadDashboardData();
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyHeaderDelegate(
              height: (isDesktop ? 200 : 190) + topPadding,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    color: theme.colorScheme.surface.withValues(alpha: 0.90),
                    padding: EdgeInsets.only(
                      left: isDesktop ? 32 : 16, 
                      right: isDesktop ? 32 : 16, 
                      top: 6 + topPadding, 
                      bottom: 8,
                    ),
                    child: MediaQuery.withClampedTextScaling(
                      minScaleFactor: 0.85,
                      maxScaleFactor: 1.10,
                      child: _buildHeaderAndFilters(theme, authProvider, branches, isDesktop),
                    ),
                  ),
                ),
              ),
            ),
          ),
            SliverPadding(
              padding: EdgeInsets.only(
                left: isDesktop ? 40 : 20, 
                right: isDesktop ? 40 : 20, 
                top: 16, 
                bottom: 120
              ), 
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 2. Reservation notification banner
                  if (authProvider.isReservationEnabled && reservationProvider.pendingCount > 0) ...[
                    _buildReservationBanner(theme, reservationProvider),
                    const SizedBox(height: 20),
                  ],

                  // 3. Hero KPI Summary Cards (Net Profit, Sales, Expenses, AOV)
                  //
                  // Sengaja TIDAK digerbangi. Ini angka yang membuat pemilik
                  // toko membuka aplikasi tiap hari - menguncinya menahan justru
                  // kebiasaan yang paling ingin ditumbuhkan. Yang berbayar
                  // adalah bedah analitiknya, bukan ringkasannya.
                  _buildKPICards(theme, expenseProvider, isDesktop),

                  const SizedBox(height: 20),

                  // 5. Quick Actions Shortcut Bar (Catat Pengeluaran, Kelola Cabang, etc)
                  _buildQuickActionsBar(theme),

                  const SizedBox(height: 24),

                  // 6. Minimalist Analytics Slider / Carousel (Tren Omzet, Jam Sibuk, Metode Bayar, Menu Terlaris)
                  _buildAnalyticsSliderCard(theme, expenseProvider, isDesktop),

                  const SizedBox(height: 24),

                  // 7. Branch Performance & Today's Cashier Shift Summary
                  //
                  // Perbandingan antar cabang adalah fitur paket Bisnis. Sengaja
                  // ditampilkan bergembok, bukan disembunyikan: pemilik satu toko
                  // jadi tahu fiturnya ada saat nanti membuka cabang kedua.
                  //
                  // Analitik (tren omzet, jam ramai, menu terlaris, metode bayar)
                  // TIDAK dikunci - pembedanya sudah datang sendiri dari batas
                  // riwayat 30 hari di paket gratis.
                  if (branches.isNotEmpty) ...[
                    PremiumGate(
                      locked: !authProvider.hasFeature('consolidated_report'),
                      feature: 'consolidated_report',
                      requiredPlan: 'business',
                      child: _buildBranchPerformanceCard(theme, expenseProvider, branches),
                    ),
                    const SizedBox(height: 24),
                  ],

                  _buildShiftSummaryCard(theme, expenseProvider),
                ]),
              ),
            ),
          ],
        ),
    );
  }

  // ---------------------------------------------------------------------------
  // ---------------------------------------------------------------------------
  // 1. Header Widget & Unified Filters
  // ---------------------------------------------------------------------------
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

  Widget _buildHeaderAndFilters(ThemeData theme, AuthProvider auth, List<dynamic> branches, bool isDesktop) {
    final company = auth.user?.company;
    final companyName = company?['name'] ?? 'toko_saya_9'.tr(context: context);
    final companyCode = company?['code']?.toString() ?? '';
    final userName = auth.user?.name ?? 'owner_5'.tr(context: context);
    final dateStr = DateFormat('EEEE, d MMM yyyy', context.locale.languageCode).format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Top Bar: Owner Portal Badge, Company Code & Live Status / Notification
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_user_rounded, size: 13, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'owner_portal_12'.tr(context: context),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                if (companyCode.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
                    ),
                    child: Text(
                      companyCode,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            // Live Status Pill & Notification Bell
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: AppColors.successFill.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.successFill,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'live_system_status'.tr(context: context) == 'live_system_status'
                            ? 'dashboard_live_system'.tr(context: context)
                            : 'live_system_status'.tr(context: context),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.successText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Consumer<NotificationProvider>(
                  builder: (context, notifProv, _) {
                    final unread = notifProv.unreadCount;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationCenterScreen()));
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
                              if (unread > 0)
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
                                      unread > 9 ? '9+' : unread.toString(),
                                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, height: 1),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 10),

        // 2. Greeting & Contextual Store Info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${_getGreeting(context)}, ',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          userName,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'financial_summary'.tr(context: context),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                      fontSize: isDesktop ? 22 : 18.5,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.storefront_rounded, size: 12, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      companyName,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 10),

        // 3. Unified Filters Row (Branch & Period)
        Row(
          children: [
            // Branch Dropdown / Button
            Expanded(
              child: _buildDropdownFilterButton(
                theme: theme,
                icon: Icons.storefront_rounded,
                label: () {
                  if (_selectedBranch == 'all' || branches.isEmpty) {
                    return 'all_branches'.tr(context: context);
                  }
                  final match = branches.where((b) => b.id.toString() == _selectedBranch);
                  if (match.isNotEmpty) {
                    return match.first.name;
                  }
                  return 'all_branches'.tr(context: context);
                }(),
                onTap: () => _showBranchSelector(theme, branches),
              ),
            ),
            const SizedBox(width: 10),
            // Period Dropdown / Button
            Expanded(
              child: _buildDropdownFilterButton(
                theme: theme,
                icon: Icons.calendar_month_rounded,
                label: _selectedPeriod == 'date'
                    ? DateFormat('dd MMM', 'id').format(_selectedDate)
                    : (_selectedPeriod == 'custom' && _selectedDateRange != null
                        ? '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}'
                        : _getPeriodLabel()),
                onTap: _openDateSelectorModal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 'today': return 'today'.tr(context: context);
      case '7_days': return 'last_7_days'.tr(context: context);
      case '30_days': return 'last_30_days'.tr(context: context);
      case 'this_month': return 'this_month'.tr(context: context);
      case 'this_year': return 'this_year'.tr(context: context);
      default: return 'select_time'.tr(context: context);
    }
  }

  Widget _buildDropdownFilterButton({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(color: theme.shadowColor.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 15, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: -0.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  void _showBranchSelector(ThemeData theme, List<dynamic> branches) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 24),
              Text('pilih_cabang_138'.tr(context: context), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: Text('all_branches'.tr(context: context), style: const TextStyle(fontWeight: FontWeight.w700)),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _selectedBranch == 'all' ? theme.colorScheme.primary.withValues(alpha: 0.15) : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.store_rounded, color: _selectedBranch == 'all' ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
                        ),
                        trailing: _selectedBranch == 'all' ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary) : null,
                        onTap: () {
                          setState(() => _selectedBranch = 'all');
                          _fetchReport();
                          Navigator.pop(ctx);
                        },
                      ),
                      ...branches.map((b) => ListTile(
                        title: Text(b.name ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _selectedBranch == b.id.toString() ? theme.colorScheme.primary.withValues(alpha: 0.15) : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.storefront_rounded, color: _selectedBranch == b.id.toString() ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
                        ),
                        trailing: _selectedBranch == b.id.toString() ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary) : null,
                        onTap: () {
                          setState(() => _selectedBranch = b.id.toString());
                          _fetchReport();
                          Navigator.pop(ctx);
                        },
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Reservation Banner
  // ---------------------------------------------------------------------------
  Widget _buildReservationBanner(ThemeData theme, ReservationProvider resProvider) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReservationListScreen()),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.notifications_active_rounded, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'pending_reservations_banner_title'.tr(context: context, args: [resProvider.pendingCount.toString()]),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'pending_reservations_banner_desc'.tr(context: context),
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    ).animate().fade().slideY(begin: -0.1, end: 0);
  }

  // (Period filter moved to Header)

  // ---------------------------------------------------------------------------
  // 4. Hero KPI Summary Cards (Zenvi Teal Theme with Embedded Details)
  // ---------------------------------------------------------------------------
  Widget _buildKPICards(ThemeData theme, ExpenseProvider provider, bool isDesktop) {
    final netProfit = provider.netProfit;
    final totalSales = provider.totalSales;
    final totalCogs = provider.totalCogs;
    final grossProfit = provider.grossProfit;
    final grossMargin = provider.grossMarginPercent.toStringAsFixed(1);
    final totalExpenses = provider.totalExpenses;
    final netMargin = provider.netMarginPercent.toStringAsFixed(1);
    final aov = provider.averageOrderValue;
    final totalOrders = provider.totalOrders;

    return _buildHeroKPICard(
      theme: theme,
      title: 'real_net_profit_title'.tr(context: context),
      value: 'Rp ${NumberFormat.decimalPattern('id').format(netProfit)}',
      badgeText: 'Net Margin $netMargin%',
      grossProfitBadge: 'Laba Kotor: Rp ${NumberFormat.decimalPattern('id').format(grossProfit)} ($grossMargin%)',
      icon: Icons.account_balance_wallet_rounded,
      totalSales: totalSales,
      totalCogs: totalCogs,
      grossProfit: grossProfit,
      grossMargin: grossMargin,
      totalExpenses: totalExpenses,
      aov: aov,
      totalOrders: totalOrders,
      onTap: () {
        _showMetricDetailDialog(
          title: 'real_net_profit_title'.tr(context: context),
          value: 'Rp ${NumberFormat.decimalPattern('id').format(netProfit)}',
          description: 'financial_formula_expl'.tr(
            context: context,
            args: [
              NumberFormat.decimalPattern('id').format(totalSales),
              NumberFormat.decimalPattern('id').format(totalCogs),
              NumberFormat.decimalPattern('id').format(totalExpenses),
            ],
          ),
          icon: Icons.account_balance_wallet_rounded,
          color: theme.colorScheme.primary,
        );
      },
    );
  }

  Widget _buildHeroKPICard({
    required ThemeData theme,
    required String title,
    required String value,
    required String badgeText,
    required String grossProfitBadge,
    required IconData icon,
    required double totalSales,
    required double totalCogs,
    required double grossProfit,
    required String grossMargin,
    required double totalExpenses,
    required double aov,
    required int totalOrders,
    VoidCallback? onTap,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [
                  Color(0xFF0F766E), // Deep Teal
                  Color(0xFF115E59), // Slate Teal
                  Color(0xFF134E4A), // Dark Slate Teal
                ]
              : const [
                  Color(0xFF0F766E), // Teal Accent / Deep
                  Color(0xFF0D9488), // Zenvi Primary Teal
                  Color(0xFF14B8A6), // Zenvi Bright Teal
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF0F766E) : const Color(0xFF0D9488)).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          splashColor: Colors.white.withValues(alpha: 0.12),
          highlightColor: Colors.white.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Icon, Title & Margin Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'net_revenue_after_expenses'.tr(context: context),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Main Net Profit Figure
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Embedded Detailed Financial Breakdown (4 Columns)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    children: [
                      // 1. Gross Revenue
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'gross_revenue'.tr(context: context),
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 9, fontWeight: FontWeight.w600, height: 1.15),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rp ${NumberFormat.decimalPattern('id').format(totalSales)}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'orders_count'.tr(context: context, args: [totalOrders.toString()]),
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 9),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(height: 28, width: 1, color: Colors.white.withValues(alpha: 0.18)),
                      const SizedBox(width: 8),

                      // 2. Total COGS / HPP
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'total_cogs_title'.tr(context: context),
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 9, fontWeight: FontWeight.w600, height: 1.15),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rp ${NumberFormat.decimalPattern('id').format(totalCogs)}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'materials_cogs_subtitle'.tr(context: context),
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 9),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(height: 28, width: 1, color: Colors.white.withValues(alpha: 0.18)),
                      const SizedBox(width: 8),

                      // 3. Gross Profit
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'gross_profit_title'.tr(context: context),
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 9, fontWeight: FontWeight.w600, height: 1.15),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rp ${NumberFormat.decimalPattern('id').format(grossProfit)}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'gross_margin_percent_subtitle'.tr(context: context, args: [grossMargin]),
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 9),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(height: 28, width: 1, color: Colors.white.withValues(alpha: 0.18)),
                      const SizedBox(width: 8),

                      // 4. Total Expenses (Operasional)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'total_expense'.tr(context: context),
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 9, fontWeight: FontWeight.w600, height: 1.15),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rp ${NumberFormat.decimalPattern('id').format(totalExpenses)}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'operational_expenses'.tr(context: context),
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 9),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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

  // ---------------------------------------------------------------------------
  // 5. Unified All-in-One Analytics Card (Tabs & Segment Switcher)
  // ---------------------------------------------------------------------------
  Widget _buildAnalyticsSliderCard(ThemeData theme, ExpenseProvider provider, bool isDesktop) {
    final tabs = [
      {'icon': Icons.trending_up_rounded, 'label': 'revenue_trend_tab'.tr(context: context)},
      {'icon': Icons.emoji_events_rounded, 'label': 'top_selling_menu_tab'.tr(context: context)},
      {'icon': Icons.access_time_rounded, 'label': 'peak_hours_tab'.tr(context: context)},
      {'icon': Icons.payment_rounded, 'label': 'payment_methods_tab'.tr(context: context)},
    ];

    Widget currentChart;
    switch (_selectedAnalyticsTab) {
      case 0:
        currentChart = _buildSlideRevenueTrend(theme, provider);
        break;
      case 1:
        currentChart = _buildSlideTopProducts(theme, provider);
        break;
      case 2:
        currentChart = _buildSlidePeakHours(theme, provider);
        break;
      case 3:
      default:
        currentChart = _buildSlidePaymentMethods(theme, provider);
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Tab Switcher
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.analytics_rounded, color: theme.colorScheme.primary, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'business_reports_analytics'.tr(context: context),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 15.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Horizontal Tabs Selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: List.generate(tabs.length, (i) {
                      final isSelected = _selectedAnalyticsTab == i;
                      final t = tabs[i];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedAnalyticsTab = i;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.dividerColor.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    t['icon'] as IconData,
                                    size: 14,
                                    color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    t['label'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.08)),
          const SizedBox(height: 12),

          // Chart Display Area with Fixed Height (320px)
          SizedBox(
            height: 320,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(
                key: ValueKey<int>(_selectedAnalyticsTab),
                child: currentChart,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideRevenueTrend(ThemeData theme, ExpenseProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                'revenue_profit_trend'.tr(context: context),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildChartLegend(color: AppColors.chartRevenue, label: 'revenue_label'.tr(context: context)),
                  _buildChartLegend(color: AppColors.chartProfit, label: 'profit_label'.tr(context: context)),
                  _buildChartLegend(color: AppColors.chartExpense, label: 'expense_label'.tr(context: context)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'revenue_vs_expense_comparison'.tr(context: context),
            style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.chartData.isEmpty
                    ? Center(
                        child: Text(
                          'no_transaction_data_range'.tr(context: context),
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12.5),
                        ),
                      )
                    : _buildDynamicLineChart(theme, provider.chartData),
          ),
        ],
      ),
    );
  }

  Widget _buildSlidePeakHours(ThemeData theme, ExpenseProvider provider) {
    final hourly = provider.hourlySales;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                'peak_hours_analysis'.tr(context: context),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('24_jam_145'.tr(context: context), style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'sales_distribution_by_hour'.tr(context: context),
            style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : hourly.isEmpty
                    ? Center(
                        child: Text(
                          'no_transaction_data'.tr(context: context),
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12.5),
                        ),
                      )
                    : _buildPeakHoursBarChart(theme, hourly),
          ),
        ],
      ),
    );
  }

  Widget _buildSlidePaymentMethods(ThemeData theme, ExpenseProvider provider) {
    final paymentMethods = provider.paymentMethods;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'metode_pembayaran_17'.tr(context: context),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
          ),
          const SizedBox(height: 4),
          Text(
            'payment_method_proportion'.tr(context: context),
            style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: paymentMethods.isEmpty
                ? Center(
                    child: Text('belum_ada_transaksi_150'.tr(context: context), style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12.5)),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: paymentMethods.length,
                    itemBuilder: (context, index) {
                      final pm = paymentMethods[index];
                      final label = pm['label']?.toString() ?? 'lainnya_14'.tr(context: context);
                      final total = (pm['total'] as num?)?.toDouble() ?? 0.0;
                      final percent = (pm['percent'] as num?)?.toDouble() ?? 0.0;
                      final hexColor = pm['color']?.toString() ?? '#0D9488';
                      Color color;
                      try {
                        color = Color(int.parse(hexColor.replaceAll('#', '0xFF')));
                      } catch (_) {
                        color = theme.colorScheme.primary;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 9,
                                      height: 9,
                                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                                  ],
                                ),
                                Text(
                                  'Rp ${NumberFormat.decimalPattern('id').format(total)} ($percent%)',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: theme.colorScheme.onSurface),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: (percent / 100).clamp(0.0, 1.0),
                                minHeight: 5.5,
                                backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideTopProducts(ThemeData theme, ExpenseProvider provider) {
    final topProducts = provider.topProducts;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'menu_terlaris_top_5_151'.tr(context: context),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
          ),
          const SizedBox(height: 4),
          Text(
            'top_5_sold_menu'.tr(context: context),
            style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: topProducts.isEmpty
                ? Center(
                    child: Text('belum_ada_data_penjualan_153'.tr(context: context), style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12.5)),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: topProducts.length,
                    itemBuilder: (context, idx) {
                      final p = topProducts[idx];
                      final name = p['name']?.toString() ?? 'produk_510'.tr(context: context);
                      final qty = (p['qty'] as num?)?.toDouble() ?? 0.0;
                      final total = (p['total'] as num?)?.toDouble() ?? (p['revenue'] as num?)?.toDouble() ?? 0.0;
                      final cogs = (p['cogs'] as num?)?.toDouble() ?? 0.0;
                      final profit = (p['profit'] as num?)?.toDouble() ?? (total - cogs);
                      final margin = (p['margin_percent'] as num?)?.toDouble() ?? (total > 0 ? ((profit / total) * 100) : 0.0);

                      final badgeColors = [
                        theme.colorScheme.primary, // 1st Zenvi Primary
                        theme.colorScheme.secondary, // 2nd Zenvi Secondary
                        const Color(0xFF94A3B8), // 3rd Muted Slate
                      ];

                      final rankColor = idx < 3 ? badgeColors[idx] : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: rankColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${idx + 1}',
                                style: TextStyle(color: rankColor, fontWeight: FontWeight.w900, fontSize: 11),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), overflow: TextOverflow.ellipsis),
                                  Text(
                                    '${'items_sold_count'.tr(context: context, args: [qty.toInt().toString()])}${cogs > 0 ? ' • HPP: Rp ${NumberFormat.decimalPattern('id').format(cogs)}' : ''}',
                                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Rp ${NumberFormat.decimalPattern('id').format(total)}',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: theme.colorScheme.onSurface),
                                ),
                                if (cogs > 0)
                                  Text(
                                    '+Rp ${NumberFormat.decimalPattern('id').format(profit)} (${margin.toStringAsFixed(0)}%)',
                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.successText),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildDynamicLineChart(ThemeData theme, List<Map<String, dynamic>> chartData) {
    if (chartData.isEmpty) {
      return Center(
        child: Text(
          'no_transaction_data_range'.tr(context: context),
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12.5),
        ),
      );
    }

    double minVal = 0.0;
    double maxVal = 0.0;
    bool hasNonZero = false;

    for (var d in chartData) {
      final s = (d['sales'] as num?)?.toDouble() ?? 0.0;
      final e = (d['expense'] as num?)?.toDouble() ?? 0.0;
      final p = (d['profit'] as num?)?.toDouble() ?? (d['net_profit'] as num?)?.toDouble() ?? 0.0;
      
      if (s > maxVal) maxVal = s;
      if (e > maxVal) maxVal = e;
      if (p > maxVal) maxVal = p;
      if (s < minVal) minVal = s;
      if (e < minVal) minVal = e;
      if (p < minVal) minVal = p;

      if (s != 0 || e != 0 || p != 0) {
        hasNonZero = true;
      }
    }

    double minY = minVal < 0 ? minVal * 1.25 : 0.0;
    double maxY = maxVal > 0 ? maxVal * 1.25 : 100000.0;
    if (maxY <= minY) {
      maxY = minY + 100000.0;
    }

    final rangeY = maxY - minY;
    final intervalY = (rangeY > 0 ? rangeY / 4 : 25000.0).clamp(1.0, double.infinity);
    final maxX = (chartData.length <= 1 ? 1.0 : (chartData.length - 1).toDouble());

    double clampY(double val) => val.clamp(minY, maxY);

    final omzetSpots = List.generate(chartData.length, (i) {
      final s = (chartData[i]['sales'] as num?)?.toDouble() ?? 0.0;
      return FlSpot(i.toDouble(), clampY(s));
    });

    final profitSpots = List.generate(chartData.length, (i) {
      final p = (chartData[i]['profit'] as num?)?.toDouble() ?? (chartData[i]['net_profit'] as num?)?.toDouble() ?? 0.0;
      return FlSpot(i.toDouble(), clampY(p));
    });

    final expenseSpots = List.generate(chartData.length, (i) {
      final e = (chartData[i]['expense'] as num?)?.toDouble() ?? 0.0;
      return FlSpot(i.toDouble(), clampY(e));
    });

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: intervalY,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              strokeWidth: 1,
              dashArray: [4, 4],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: 1,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < 0 || index >= chartData.length) return const SizedBox();

                if (chartData.length > 7 && index % (chartData.length ~/ 4 == 0 ? 1 : chartData.length ~/ 4) != 0) {
                  return const SizedBox();
                }

                final label = chartData[index]['label']?.toString() ?? '';
                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(
                    label,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: intervalY,
              reservedSize: 46,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value >= maxY * 0.98) return const SizedBox();
                return Text(
                  NumberFormat.compact(locale: 'id').format(value),
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 9.5, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.right,
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          // Omzet Line (Chart Series 0)
          LineChartBarData(
            spots: omzetSpots,
            isCurved: chartData.length > 1,
            curveSmoothness: 0.35,
            color: AppColors.chartRevenue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: chartData.length <= 1 || !hasNonZero),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.chartRevenue.withValues(alpha: 0.25),
                  AppColors.chartRevenue.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Laba Bersih Line (Chart Series 1)
          LineChartBarData(
            spots: profitSpots,
            isCurved: chartData.length > 1,
            curveSmoothness: 0.35,
            color: AppColors.chartProfit,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(show: chartData.length <= 1 || !hasNonZero),
          ),
          // Expense Line (Chart Series 2)
          LineChartBarData(
            spots: expenseSpots,
            isCurved: chartData.length > 1,
            curveSmoothness: 0.35,
            color: AppColors.chartExpense,
            barWidth: 2,
            dashArray: [4, 4],
            dotData: FlDotData(show: chartData.length <= 1 || !hasNonZero),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => theme.colorScheme.surfaceContainerHighest,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final label = spot.barIndex == 0
                    ? 'revenue_label'.tr(context: context)
                    : spot.barIndex == 1
                        ? 'profit_label'.tr(context: context)
                        : 'expense_label'.tr(context: context);
                final color = spot.barIndex == 0 ? AppColors.chartRevenue : spot.barIndex == 1 ? AppColors.chartProfit : AppColors.chartExpense;
                return LineTooltipItem(
                  '$label: Rp ${NumberFormat.decimalPattern('id').format(spot.y)}',
                  TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPeakHoursBarChart(ThemeData theme, List<Map<String, dynamic>> hourly) {
    if (hourly.isEmpty) {
      return Center(
        child: Text(
          'no_transaction_data'.tr(context: context),
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12.5),
        ),
      );
    }

    double maxSales = 0;
    for (var h in hourly) {
      final s = (h['sales'] as num?)?.toDouble() ?? 0.0;
      if (s > maxSales) maxSales = s;
    }
    double maxY = maxSales > 0 ? maxSales * 1.25 : 100000;
    final intervalY = (maxY / 4).clamp(1.0, double.infinity);

    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: intervalY,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              strokeWidth: 1,
              dashArray: [4, 4],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: 1,
              getTitlesWidget: (value, meta) {
                int hour = value.toInt();
                if (hour % 4 != 0) return const SizedBox();
                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 9.5, fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: intervalY,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value >= maxY * 0.98) return const SizedBox();
                return Text(
                  NumberFormat.compact(locale: 'id').format(value),
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 9, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.right,
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        maxY: maxY,
        minY: 0,
        barGroups: hourly.map((h) {
          final hour = (h['hour'] as num?)?.toInt() ?? 0;
          final sales = (h['sales'] as num?)?.toDouble() ?? 0.0;
          final isTopHour = sales == maxSales && sales > 0;

          return BarChartGroupData(
            x: hour,
            barRods: [
              BarChartRodData(
                toY: sales.clamp(0.0, maxY),
                gradient: LinearGradient(
                  colors: isTopHour
                      ? [theme.colorScheme.primary, theme.colorScheme.secondary]
                      : [theme.colorScheme.primary.withValues(alpha: 0.5), theme.colorScheme.primary.withValues(alpha: 0.25)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 7,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => theme.colorScheme.surfaceContainerHighest,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex < 0 || groupIndex >= hourly.length) return null;
              final h = hourly[groupIndex];
              return BarTooltipItem(
                'Jam ${h['label'] ?? ''}\nRp ${NumberFormat.decimalPattern('id').format(rod.toY)}\n(${h['orders'] ?? 0} Order)',
                TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w800, fontSize: 11),
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 9. Branch Performance Matrix Card
  // ---------------------------------------------------------------------------
  Widget _buildBranchPerformanceCard(ThemeData theme, ExpenseProvider provider, List<dynamic> branches) {
    final performance = provider.branchPerformance;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'performa_antar_cabang_154'.tr(context: context),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, fontSize: 17),
              ),
              Icon(Icons.storefront_rounded, size: 20, color: theme.colorScheme.primary),
            ],
          ),
          const SizedBox(height: 16),
          if (performance.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('belum_ada_data_cabang_155'.tr(context: context), style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              ),
            )
          else ...[
            ...performance.map((b) {
              final name = b['name']?.toString() ?? 'cabang_6'.tr(context: context);
              final sales = (b['sales'] as num?)?.toDouble() ?? 0.0;
              final orders = (b['orders'] as num?)?.toInt() ?? 0;
              final activeShifts = (b['active_shifts'] as num?)?.toInt() ?? 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.store_mall_directory_rounded, size: 20, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Rp ${NumberFormat.decimalPattern('id').format(sales)}',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: theme.colorScheme.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'orders_count_label'.tr(context: context, args: [orders.toString()]),
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                              ),
                              if (activeShifts > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.successFill.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.successFill, shape: BoxShape.circle)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'active_cashiers_count_label'.tr(context: context, args: [activeShifts.toString()]),
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.successText),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 10. Today's Cashier Shift Summary Card
  // ---------------------------------------------------------------------------
  Widget _buildShiftSummaryCard(ThemeData theme, ExpenseProvider provider) {
    final shiftSummaries = provider.shiftSummaries;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.badge_rounded, color: theme.colorScheme.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'log_kasir_shift_17'.tr(context: context),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ShiftLogScreen()));
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'lihat_semua_11'.tr(context: context),
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 16, color: theme.colorScheme.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (shiftSummaries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'belum_ada_shift_kasir_53'.tr(context: context),
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                ),
              ),
            )
          else ...[
            ...shiftSummaries.map((s) {
              final name = s['employee_name']?.toString() ?? 'kasir_5'.tr(context: context);
              final branchName = s['branch_name']?.toString() ?? 'cabang_6'.tr(context: context);
              final revenue = (s['revenue'] as num?)?.toDouble() ?? 0.0;
              final status = s['status']?.toString() ?? 'active';
              final isClosed = status == 'closed' || status == 'auto_closed';
              final startTime = s['start_time']?.toString() ?? '';
              final endTime = s['end_time']?.toString() ?? '';

              String timeInfo = '';
              if (startTime.isNotEmpty && endTime.isNotEmpty) {
                timeInfo = '$startTime - $endTime';
              } else if (startTime.isNotEmpty) {
                timeInfo = 'shift_since_time'.tr(context: context, args: [startTime]);
              }

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ShiftLogScreen()));
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: isClosed ? theme.colorScheme.onSurface.withValues(alpha: 0.15) : AppColors.successFill.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isClosed ? Icons.lock_clock_rounded : Icons.point_of_sale_rounded,
                            size: 18,
                            color: isClosed ? theme.colorScheme.onSurfaceVariant : AppColors.successText,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Rp ${NumberFormat.decimalPattern('id').format(revenue)}',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: theme.colorScheme.primary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Wrap(
                                spacing: 8,
                                runSpacing: 3,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    timeInfo.isNotEmpty ? '$branchName • $timeInfo' : branchName,
                                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isClosed ? theme.colorScheme.onSurface.withValues(alpha: 0.15) : AppColors.successFill.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isClosed ? 'shift_closed_short'.tr(context: context) : 'shift_active_short'.tr(context: context),
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: isClosed ? theme.colorScheme.onSurfaceVariant : AppColors.successText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 11. Quick Actions Bar
  // ---------------------------------------------------------------------------
  /// Menawarkan export laporan keuangan sebagai PDF atau CSV.
  ///
  /// Kalau paket toko tidak mencakup fitur ini, yang muncul adalah tawaran
  /// upgrade - bukan tombol yang gagal saat ditekan.
  void _openExportSheet() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.hasFeature('export')) {
      showPremiumUpsellSheet(
        context,
        const PremiumLock(feature: 'export', requiredPlan: 'premium'),
      );
      return;
    }

    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    final report = provider.reportAsMap;
    final storeName = auth.user?.company?['name']?.toString() ?? 'Zenvi';
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('export_report_title'.tr(context: ctx),
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'export_report_desc'.tr(context: ctx),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            _buildExportOption(
              theme: theme,
              icon: Icons.picture_as_pdf_rounded,
              title: 'export_as_pdf'.tr(context: ctx),
              subtitle: 'export_as_pdf_desc'.tr(context: ctx),
              onTap: () {
                Navigator.pop(ctx);
                _runExport(() => ExportService.financialReportToPdf(report, storeName: storeName));
              },
            ),
            const SizedBox(height: 12),
            _buildExportOption(
              theme: theme,
              icon: Icons.table_chart_rounded,
              title: 'export_as_excel'.tr(context: ctx),
              subtitle: 'export_as_excel_desc'.tr(context: ctx),
              onTap: () {
                Navigator.pop(ctx);
                _runExport(() => ExportService.financialReportToCsv(report, storeName: storeName));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runExport(Future<void> Function() task) async {
    try {
      await task();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('export_failed'.tr(context: context))),
      );
    }
  }

  Widget _buildExportOption({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsBar(ThemeData theme) {
    final actions = [
      {
        'label': 'quick_expenses'.tr(context: context),
        'icon': Icons.money_off_rounded,
        'onTap': () => _openAddExpenseDialog(),
      },
      {
        'label': 'quick_branch'.tr(context: context),
        'icon': Icons.storefront_rounded,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BranchListScreen())),
      },
      {
        'label': 'quick_transactions'.tr(context: context),
        'icon': Icons.receipt_long_rounded,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerTransactionLogScreen())),
      },
      {
        'label': 'quick_stock'.tr(context: context),
        'icon': Icons.inventory_rounded,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockManagementScreen())),
      },
      {
        'label': 'quick_shift'.tr(context: context),
        'icon': Icons.access_time_filled_rounded,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShiftLogScreen())),
      },
      {
        'label': 'quick_export'.tr(context: context),
        'icon': Icons.ios_share_rounded,
        'onTap': () => _openExportSheet(),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'quick_actions_title'.tr(context: context),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: -0.2,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 94,
          child: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.white, Colors.white, Colors.transparent],
              stops: [0.0, 0.93, 1.0],
            ).createShader(rect),
            blendMode: BlendMode.dstIn,
            child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: actions.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final act = actions[index];

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: act['onTap'] as VoidCallback,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Icon(act['icon'] as IconData, size: 20, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          act['label'] as String,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          ),
        ),
      ],
    );
  }


}

// ---------------------------------------------------------
// MORE MENU SCREEN
// ---------------------------------------------------------
class _MoreMenuItem {
  final IconData icon;
  final String label;
  final String description;
  final Widget page;

  _MoreMenuItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.page,
  });
}

class _MoreMenuGroup {
  final String title;
  final Color accent;
  final List<_MoreMenuItem> items;

  _MoreMenuGroup({
    required this.title,
    required this.accent,
    required this.items,
  });
}

class _MoreMenuScreen extends StatelessWidget {
  final Function(Widget) onNavigate;

  const _MoreMenuScreen({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final company = authProvider.user?.company;
    final isMembershipEnabled = company?['is_membership_enabled'] == true || company?['is_membership_enabled'] == 1;

    final List<_MoreMenuGroup> groups = [
      _MoreMenuGroup(
        title: 'more_group_daily'.tr(context: context),
        accent: theme.colorScheme.primary,
        items: [
          _MoreMenuItem(
            icon: Icons.event_seat_rounded,
            label: 'reservasi_506'.tr(context: context),
            description: 'more_desc_reservation'.tr(context: context),
            page: const ReservationListScreen(),
          ),
          _MoreMenuItem(
            icon: Icons.receipt_long,
            label: 'log_transaksi_512'.tr(context: context),
            description: 'more_desc_transaction_log'.tr(context: context),
            page: const OwnerTransactionLogScreen(),
          ),
          _MoreMenuItem(
            icon: Icons.access_time_filled_rounded,
            label: 'shift_log_514'.tr(context: context),
            description: 'more_desc_shift_log'.tr(context: context),
            page: const ShiftLogScreen(),
          ),
        ],
      ),
      _MoreMenuGroup(
        title: 'more_group_catalog'.tr(context: context),
        accent: AppColors.infoText,
        items: [
          _MoreMenuItem(
            icon: Icons.inventory_2_rounded,
            label: 'produk_510'.tr(context: context),
            description: 'more_desc_product'.tr(context: context),
            page: const ProductListScreen(),
          ),
          _MoreMenuItem(
            icon: Icons.inventory,
            label: 'stok_511'.tr(context: context),
            description: 'more_desc_stock'.tr(context: context),
            page: const StockManagementScreen(),
          ),
        ],
      ),
      _MoreMenuGroup(
        title: 'more_group_team'.tr(context: context),
        accent: AppColors.warningText,
        items: [
          _MoreMenuItem(
            icon: Icons.how_to_reg,
            label: 'karyawan_509'.tr(context: context),
            description: 'more_desc_employee'.tr(context: context),
            page: const EmployeeVerificationScreen(),
          ),
          _MoreMenuItem(
            icon: Icons.approval_rounded,
            label: 'persetujuan_izin_505'.tr(context: context),
            description: 'more_desc_permission_approval'.tr(context: context),
            page: const OwnerPermissionManagementScreen(),
          ),
          _MoreMenuItem(
            icon: Icons.emoji_events_rounded,
            label: 'performa_508'.tr(context: context),
            description: 'more_desc_performance'.tr(context: context),
            page: const EmployeePerformanceScreen(),
          ),
        ],
      ),
      _MoreMenuGroup(
        title: 'more_group_business'.tr(context: context),
        accent: AppColors.successText,
        items: [
          _MoreMenuItem(
            icon: Icons.storefront_rounded,
            label: 'kelola_cabang_504'.tr(context: context),
            description: 'more_desc_branch'.tr(context: context),
            page: const BranchListScreen(),
          ),
          if (isMembershipEnabled)
            _MoreMenuItem(
              icon: Icons.card_membership_rounded,
              label: 'membership_507'.tr(context: context),
              description: 'more_desc_membership'.tr(context: context),
              page: const MemberManagementScreen(),
            ),
          _MoreMenuItem(
            icon: Icons.money_off,
            label: 'pengeluaran_513'.tr(context: context),
            description: 'more_desc_expense'.tr(context: context),
            page: const ExpenseScreen(),
          ),
          _MoreMenuItem(
            icon: Icons.notifications_rounded,
            label: 'pusat_notifikasi_503'.tr(context: context),
            description: 'more_desc_notification_center'.tr(context: context),
            page: const NotificationCenterScreen(),
          ),
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          ZenviHeader.sliver(
            title: 'kelola_bisnis_501'.tr(context: context),
            subtitle: 'eksplorasi_semua_fitur_502'.tr(context: context),
            actions: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.business_center_rounded, color: theme.colorScheme.primary, size: 20),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, groupIndex) {
                  final group = groups[groupIndex];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
                        child: Text(
                          group.title,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.colorScheme.outline),
                        ),
                        child: Column(
                          children: [
                            for (int i = 0; i < group.items.length; i++) ...[
                              if (i > 0)
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  indent: 62,
                                  color: theme.dividerColor,
                                ),
                              _MoreMenuRow(item: group.items[i], accent: group.accent),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ).animate().fade(delay: Duration(milliseconds: 60 * groupIndex)).slideY(begin: 0.05, end: 0);
                },
                childCount: groups.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreMenuRow extends StatelessWidget {
  final _MoreMenuItem item;
  final Color accent;

  const _MoreMenuRow({required this.item, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => item.page));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(item.icon, size: 19, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
