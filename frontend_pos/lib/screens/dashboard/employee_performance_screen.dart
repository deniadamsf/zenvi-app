import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/employee_performance_provider.dart';
import '../../models/employee_performance_model.dart';
import '../../widgets/zenvi_header.dart';

class EmployeePerformanceScreen extends StatefulWidget {
  const EmployeePerformanceScreen({super.key});

  @override
  State<EmployeePerformanceScreen> createState() => _EmployeePerformanceScreenState();
}

class _EmployeePerformanceScreenState extends State<EmployeePerformanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EmployeePerformanceProvider>(context, listen: false).fetchPerformanceReport();
    });
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'rp_3'.tr(context: context), decimalDigits: 0);
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      body: Consumer<EmployeePerformanceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.report == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.report == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 64, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => provider.fetchPerformanceReport(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text('coba_lagi_67'.tr(context: context)),
                    ),
                  ],
                ),
              ),
            );
          }

          final report = provider.report;
          
          return RefreshIndicator(
            onRefresh: () => provider.fetchPerformanceReport(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                ZenviHeader.sliver(
                  title: 'performa_karyawan_17'.tr(context: context),
                  showBackButton: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'segarkan_data_13'.tr(context: context),
                      onPressed: () {
                        Provider.of<EmployeePerformanceProvider>(context, listen: false).fetchPerformanceReport();
                      },
                    ),
                  ],
                ),
                if (report == null)
                  const SliverFillRemaining(child: SizedBox())
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Period Selector Chips
                          _buildPeriodSelector(theme, provider),
                          const SizedBox(height: 16),

                          // 2. Overview Banner (Fixed Overflow)
                          _buildOverviewCard(theme, report.summary, _getLocalizedPeriodLabel(context, report.period, report.periodLabel)),
                          const SizedBox(height: 20),

                          // 3. Top Performers Podium (Leaderboard)
                          _buildTopPerformersSection(theme, report.topPerformers, isDesktop),
                          const SizedBox(height: 20),

                          // 4. Employee List
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'employee_details_count'.tr(context: context, args: [report.employees.length.toString()]),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                              ),
                              Text(
                                'sort_highest_revenue'.tr(context: context),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (report.employees.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                              ),
                              child: Center(
                                child: Text(
                                  'no_employee_perf_data'.tr(context: context),
                                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ),
                            )
                          else
                            ...report.employees.asMap().entries.map((entry) {
                              final rank = entry.key + 1;
                              final emp = entry.value;
                              return _buildEmployeeCard(context, theme, emp, rank);
                            }),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector(ThemeData theme, EmployeePerformanceProvider provider) {
    final periods = [
      {'key': 'today', 'label': 'filter_today'.tr(context: context)},
      {'key': '7days', 'label': 'filter_7_days'.tr(context: context)},
      {'key': 'this_month', 'label': 'filter_this_month'.tr(context: context)},
      {'key': '30days', 'label': 'filter_30_days'.tr(context: context)},
      {'key': 'all', 'label': 'semua_5'.tr(context: context)},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: periods.map((p) {
          final isSelected = provider.selectedPeriod == p['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(p['label']!),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  provider.setPeriod(p['key']!);
                }
              },
              selectedColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              backgroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? theme.colorScheme.primary : theme.dividerColor.withValues(alpha: 0.15),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOverviewCard(ThemeData theme, PerformanceOverviewSummary summary, String periodLabel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Flexible / Expanded to prevent overflow
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'team_performance_summary'.tr(context: context),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  periodLabel,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'team_total_sales'.tr(context: context),
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatCurrency(summary.totalSales),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: Colors.white24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'total_transaksi_label'.tr(context: context),
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'total_completed_receipts'.tr(context: context, args: [summary.totalOrders.toString()]),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildOverviewMiniItem(
                  Icons.people_outline_rounded,
                  'total_employees_count'.tr(context: context, args: [summary.totalEmployees.toString()]),
                ),
              ),
              Expanded(
                child: _buildOverviewMiniItem(
                  Icons.access_time_rounded,
                  'total_work_hours_count'.tr(context: context, args: [summary.totalWorkHours.toString()]),
                ),
              ),
              Expanded(
                child: _buildOverviewMiniItem(
                  Icons.receipt_rounded,
                  'aov_avg_order_val'.tr(context: context, args: [_formatCurrency(summary.averageOrderValue)]),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildOverviewMiniItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 13),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTopPerformersSection(ThemeData theme, TopPerformersPodium podium, bool isDesktop) {
    final badges = [
      if (podium.topSales != null) podium.topSales!,
      if (podium.mostOrders != null) podium.mostOrders!,
      if (podium.bestAccuracy != null) podium.bestAccuracy!,
      if (podium.mostPunctual != null) podium.mostPunctual!,
      if (podium.mostHours != null) podium.mostHours!,
    ];

    if (badges.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 20),
            const SizedBox(width: 8),
            Text(
              'best_performance_leaderboard'.tr(context: context),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 3 : 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: isDesktop ? 1.45 : 1.02,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            final badge = badges[index];
            return _buildPodiumBadgeCard(theme, badge, index);
          },
        ),
      ],
    );
  }

  String _getLocalizedPeriodLabel(BuildContext context, String period, String serverLabel) {
    switch (period) {
      case 'today':
        return 'filter_today'.tr(context: context);
      case '7days':
        return 'period_last_7_days'.tr(context: context);
      case '30days':
        return 'period_last_30_days'.tr(context: context);
      case 'this_month':
        return 'filter_this_month'.tr(context: context);
      case 'all':
        return 'period_all_time'.tr(context: context);
      default:
        return serverLabel;
    }
  }

  String _localizeBadgeTitle(BuildContext context, String rawBadge) {
    if (rawBadge.contains('Omzet')) return 'top_revenue_badge'.tr(context: context);
    if (rawBadge.contains('Produktif')) return 'most_productive_badge'.tr(context: context);
    if (rawBadge.contains('Akurat')) return 'most_accurate_badge'.tr(context: context);
    if (rawBadge.contains('Waktu')) return 'most_punctual_badge'.tr(context: context);
    if (rawBadge.contains('Rajin')) return 'most_diligent_badge'.tr(context: context);
    return rawBadge;
  }

  String _localizeBadgeValue(BuildContext context, TopPerformerBadge badge) {
    if (badge.badge.contains('Omzet')) {
      return badge.value;
    } else if (badge.badge.contains('Produktif')) {
      final numbers = RegExp(r'\d+').firstMatch(badge.value)?.group(0) ?? '';
      return 'badge_orders_value'.tr(context: context, args: [numbers]);
    } else if (badge.badge.contains('Akurat')) {
      final numbers = RegExp(r'\d+').firstMatch(badge.value)?.group(0) ?? '100';
      return 'badge_accuracy_value'.tr(context: context, args: [numbers]);
    } else if (badge.badge.contains('Rajin')) {
      final numbers = RegExp(r'[\d\.]+').firstMatch(badge.value)?.group(0) ?? '';
      return 'badge_hours_value'.tr(context: context, args: [numbers]);
    } else if (badge.badge.contains('Waktu')) {
      final numbers = RegExp(r'\d+').firstMatch(badge.value)?.group(0) ?? '100';
      return 'badge_punctual_value'.tr(context: context, args: [numbers]);
    }
    return badge.value;
  }

  String _localizeBadgeSubValue(BuildContext context, TopPerformerBadge badge) {
    if (badge.badge.contains('Omzet')) {
      final percentMatch = RegExp(r'[\d\.]+%').firstMatch(badge.subValue)?.group(0) ?? '';
      return 'badge_revenue_subvalue'.tr(context: context, args: [percentMatch]);
    } else if (badge.badge.contains('Produktif')) {
      final avgMatch = RegExp(r'Rp\s*[\d\.,]+').firstMatch(badge.subValue)?.group(0) ?? '';
      return 'badge_orders_subvalue'.tr(context: context, args: [avgMatch]);
    } else if (badge.badge.contains('Akurat')) {
      final shiftsMatch = RegExp(r'\((\d+)\s*shift\)').firstMatch(badge.subValue)?.group(1) ?? '0';
      if (badge.subValue.contains('Pas') || badge.subValue.contains('0')) {
        return 'badge_accuracy_subvalue_exact'.tr(context: context, args: [shiftsMatch]);
      } else {
        final diffAmount = RegExp(r'[+-]Rp\s*[\d\.,]+').firstMatch(badge.subValue)?.group(0) ?? '';
        return 'badge_accuracy_subvalue_diff'.tr(context: context, args: [diffAmount, shiftsMatch]);
      }
    } else if (badge.badge.contains('Rajin')) {
      final shiftsMatch = RegExp(r'\d+').firstMatch(badge.subValue)?.group(0) ?? '0';
      return 'badge_hours_subvalue'.tr(context: context, args: [shiftsMatch]);
    } else if (badge.badge.contains('Waktu')) {
      if (badge.subValue.contains('0x Telat') || badge.subValue.contains('0x Late')) {
        final shiftsMatch = RegExp(r'\((\d+)\s*Shift').firstMatch(badge.subValue)?.group(1) ?? '0';
        return 'badge_punctual_subvalue_zero'.tr(context: context, args: [shiftsMatch]);
      } else {
        final lateCount = RegExp(r'(\d+)x').firstMatch(badge.subValue)?.group(1) ?? '0';
        final lateMins = RegExp(r'Total\s*(\d+)\s*mnt').firstMatch(badge.subValue)?.group(1) ?? '0';
        return 'badge_punctual_subvalue_late'.tr(context: context, args: [lateCount, lateMins]);
      }
    }
    return badge.subValue;
  }

  String _localizeRole(BuildContext context, String? roleOrTitle) {
    if (roleOrTitle == null || roleOrTitle.isEmpty) return 'role_staff'.tr(context: context);
    if (roleOrTitle == 'Owner') return 'role_owner'.tr(context: context);
    if (roleOrTitle == 'Admin') return 'role_admin'.tr(context: context);
    if (roleOrTitle == 'Employee') return 'role_employee'.tr(context: context);
    if (roleOrTitle == 'Staff') return 'role_staff'.tr(context: context);
    if (roleOrTitle == 'Kasir' || roleOrTitle == 'Cashier') return 'role_cashier'.tr(context: context);
    if (roleOrTitle.contains('Kapster') || roleOrTitle.contains('Terapis')) return 'kapster_terapis_17'.tr(context: context);
    return roleOrTitle;
  }

  String _formatShiftDuration(BuildContext context, String rawDuration) {
    final match = RegExp(r'(\d+)j\s*(\d+)m').firstMatch(rawDuration);
    if (match != null) {
      final hours = match.group(1);
      final mins = match.group(2);
      if (hours == '0') {
        return 'duration_mins_only'.tr(context: context, args: [mins!]);
      }
      return 'duration_hours_mins'.tr(context: context, args: [hours!, mins!]);
    }
    return rawDuration;
  }

  String _localizeShiftName(BuildContext context, String shiftName) {
    if (shiftName == 'Shift Reguler' || shiftName == 'Regular Shift') {
      return 'shift_reguler_default'.tr(context: context);
    }
    return shiftName;
  }

  Widget _buildPodiumBadgeCard(ThemeData theme, TopPerformerBadge badge, int index) {
    Color primaryColor;
    Color secondaryColor;
    IconData iconData;

    if (badge.badge.contains('Omzet')) {
      primaryColor = const Color(0xFFF59E0B);
      secondaryColor = const Color(0xFFD97706);
      iconData = Icons.emoji_events_rounded;
    } else if (badge.badge.contains('Produktif')) {
      primaryColor = const Color(0xFF0284C7);
      secondaryColor = const Color(0xFF0369A1);
      iconData = Icons.bolt_rounded;
    } else if (badge.badge.contains('Akurat')) {
      primaryColor = const Color(0xFF10B981);
      secondaryColor = const Color(0xFF059669);
      iconData = Icons.verified_user_rounded;
    } else if (badge.badge.contains('Waktu')) {
      primaryColor = const Color(0xFF0D9488); // Teal
      secondaryColor = const Color(0xFF0F766E);
      iconData = Icons.alarm_on_rounded;
    } else {
      primaryColor = const Color(0xFF8B5CF6);
      secondaryColor = const Color(0xFF6D28D9);
      iconData = Icons.timer_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryColor, secondaryColor]),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: Colors.white, size: 14),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _localizeBadgeTitle(context, badge.badge),
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                badge.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _localizeBadgeValue(context, badge),
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          Text(
            _localizeBadgeSubValue(context, badge),
            style: TextStyle(
              fontSize: 9.5,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 60 * index)).scale(begin: const Offset(0.92, 0.92));
  }

  Widget _buildEmployeeCard(BuildContext context, ThemeData theme, EmployeePerformanceItem emp, int rank) {
    Color rankBadgeColor;
    if (rank == 1) {
      rankBadgeColor = const Color(0xFFF59E0B);
    } else if (rank == 2) {
      rankBadgeColor = const Color(0xFF94A3B8);
    } else if (rank == 3) {
      rankBadgeColor = const Color(0xFFD97706);
    } else {
      rankBadgeColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showEmployeeDetailModal(context, theme, emp),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Rank + Avatar + Name + Role + Omzet
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: rankBadgeColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: rankBadgeColor.withValues(alpha: 0.4)),
                      ),
                      child: Center(
                        child: Text(
                          '#$rank',
                          style: TextStyle(
                            color: rankBadgeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
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
                                  emp.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  _localizeRole(context, emp.jobTitle ?? emp.role),
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            emp.email,
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatCurrency(emp.totalSales),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                        Text(
                          'revenue_contribution'.tr(context: context, args: [emp.salesContributionPercent.toString()]),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Contribution Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (emp.salesContributionPercent / 100).clamp(0.0, 1.0),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    minHeight: 4,
                  ),
                ),

                const SizedBox(height: 12),

                // 2x2 Grid of Metrics for spacious layout
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricItem(
                              theme,
                              'transactions_short'.tr(context: context),
                              '${'total_completed_receipts'.tr(context: context, args: [emp.totalOrders.toString()])} (AOV ${_formatCurrency(emp.averageOrderValue)})',
                              Icons.receipt_long_rounded,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricItem(
                              theme,
                              'work_hours_short'.tr(context: context),
                              'work_hours_and_shifts'.tr(context: context, args: [emp.totalWorkHours.toString(), emp.totalShifts.toString()]),
                              Icons.schedule_rounded,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6.0),
                        child: Divider(height: 1),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricItem(
                              theme,
                              'cashier_accuracy'.tr(context: context),
                              emp.closedShiftsCount == 0 
                                  ? 'no_closed_shift_yet'.tr(context: context) 
                                  : 'accuracy_accurate'.tr(context: context, args: [emp.accuracyPercentage.toString()]),
                              emp.totalCashVariance == 0 ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                              valueColor: emp.totalCashVariance == 0 ? Colors.green : (emp.totalCashVariance < 0 ? Colors.red : Colors.orange),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricItem(
                              theme,
                              'attendance_discipline'.tr(context: context),
                              emp.lateShiftsCount == 0 
                                  ? 'punctuality_zero_late'.tr(context: context, args: ['${emp.punctualityPercentage}%']) 
                                  : 'punctuality_late_count'.tr(context: context, args: ['${emp.punctualityPercentage}%', emp.lateShiftsCount.toString()]),
                              emp.lateShiftsCount == 0 ? Icons.alarm_on_rounded : Icons.timer_off_rounded,
                              valueColor: emp.lateShiftsCount == 0 ? Colors.teal : Colors.orange,
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
      ),
    );
  }

  Widget _buildMetricItem(ThemeData theme, String label, String value, IconData icon, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: valueColor ?? theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _showEmployeeDetailModal(BuildContext context, ThemeData theme, EmployeePerformanceItem emp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                      style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(emp.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        Text('${_localizeRole(context, emp.role)} • ${emp.email}', style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('rincian_pembayaran_transaksi_75'.tr(context: context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildPaymentTypePill(theme, 'tunai_cash_12'.tr(context: context), _formatCurrency(emp.cashSales), Colors.green),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildPaymentTypePill(theme, 'qris_4'.tr(context: context), _formatCurrency(emp.qrisSales), Colors.blue),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildPaymentTypePill(theme, 'transfer_8'.tr(context: context), _formatCurrency(emp.transferSales), Colors.purple),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('disiplin_absensi_kehadiran_76'.tr(context: context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  Text('ontime_shifts_ratio'.tr(context: context, args: [emp.onTimeShiftsCount.toString(), emp.totalShifts.toString()]), 
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: (emp.lateShiftsCount == 0 ? Colors.teal : Colors.orange).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: (emp.lateShiftsCount == 0 ? Colors.teal : Colors.orange).withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(emp.lateShiftsCount == 0 ? Icons.verified_rounded : Icons.info_outline_rounded,
                            size: 16, color: emp.lateShiftsCount == 0 ? Colors.teal : Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              emp.lateShiftsCount == 0 
                                  ? 'excellent_attendance_no_late'.tr(context: context) 
                                  : 'late_occurrence_detail'.tr(context: context, args: [emp.lateShiftsCount.toString(), emp.totalLateMinutes.toString()]),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: emp.lateShiftsCount == 0 ? Colors.teal : Colors.orange,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${emp.punctualityPercentage}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: emp.lateShiftsCount == 0 ? Colors.teal : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              if (emp.approvedLeaves.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event_available_rounded, size: 15, color: Colors.blue),
                          const SizedBox(width: 6),
                          Text(
                            'approved_leaves_history'.tr(context: context, args: [emp.approvedLeaves.length.toString()]),
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...emp.approvedLeaves.map((leave) {
                        String formattedDate = leave.date;
                        try {
                          final parsedDate = DateTime.parse(leave.date);
                          formattedDate = DateFormat('dd MMM yyyy', context.locale.languageCode).format(parsedDate);
                        } catch (_) {}
                        return Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('• $formattedDate: ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Text(leave.reason, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('riwayat_shift_terakhir_77'.tr(context: context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  Text('total_shifts_count_label'.tr(context: context, args: [emp.totalShifts.toString()]), style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 8),
              if (emp.recentShifts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text('belum_ada_riwayat_shift_78'.tr(context: context), style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: emp.recentShifts.length,
                    separatorBuilder: (context, index) => const Divider(height: 10),
                    itemBuilder: (ctx, idx) {
                      final s = emp.recentShifts[idx];
                      final startFormatted = s.startTime != null 
                          ? DateFormat('dd MMM yyyy, HH:mm', context.locale.languageCode).format(DateTime.parse(s.startTime!)) 
                          : '-';
                      
                      String varianceText = 'exact_balance_zero'.tr(context: context);
                      Color varianceColor = Colors.green;
                      if (s.cashVariance != null && s.cashVariance != 0) {
                        if (s.cashVariance! > 0) {
                          varianceText = '+${_formatCurrency(s.cashVariance!)}';
                          varianceColor = Colors.orange;
                        } else {
                          varianceText = '-${_formatCurrency(s.cashVariance!.abs())}';
                          varianceColor = Colors.red;
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(startFormatted, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                      const SizedBox(width: 6),
                                      if (s.isExcused)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${'excused_late_label'.tr(context: context)}${s.excuseReason != null ? ': ${s.excuseReason}' : ''}',
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: (s.isLate ? Colors.orange : Colors.teal).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            s.isLate ? 'late_minutes_badge'.tr(context: context, args: [s.lateMinutes.toString()]) : 'on_time_badge'.tr(context: context),
                                            style: TextStyle(
                                              color: s.isLate ? Colors.orange : Colors.teal,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text('${_localizeShiftName(context, s.shiftName)} • ${_formatShiftDuration(context, s.durationFormatted)} • ${'revenue_label_prefix'.tr(context: context, args: [_formatCurrency(s.totalRevenue)])}', 
                                    style: TextStyle(fontSize: 10.5, color: theme.colorScheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: varianceColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                varianceText,
                                style: TextStyle(color: varianceColor, fontSize: 10.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentTypePill(ThemeData theme, String label, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 9.5, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(amount, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }
}

