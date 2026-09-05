import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shift_provider.dart';
import '../../models/shift_model.dart';
import '../../widgets/zenvi_header.dart';
import '../../theme/app_colors.dart';

class ShiftLogScreen extends StatefulWidget {
  const ShiftLogScreen({super.key});

  @override
  State<ShiftLogScreen> createState() => _ShiftLogScreenState();
}

class _ShiftLogScreenState extends State<ShiftLogScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        context.read<ShiftProvider>().fetchShiftLogs(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ShiftProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      body: RefreshIndicator(
        onRefresh: () async {
          final token = context.read<AuthProvider>().token;
          if (token != null) {
            await provider.fetchShiftLogs(token);
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            ZenviHeader.sliver(
              title: 'log_shift_karyawan_18'.tr(context: context),
              showBackButton: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'refresh_7'.tr(context: context),
                  onPressed: () {
                    final token = context.read<AuthProvider>().token;
                    if (token != null) {
                      provider.fetchShiftLogs(token);
                    }
                  },
                ),
              ],
            ),
            if (provider.isLoading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (provider.shiftLogs.isEmpty)
              SliverFillRemaining(child: _buildEmptyState(theme))
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final shift = provider.shiftLogs[index];
                      return _buildShiftCard(context, shift, theme);
                    },
                    childCount: provider.shiftLogs.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history_toggle_off_rounded, size: 54, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'belum_ada_data_shift_20'.tr(context: context),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'riwayat_buka_dan_tutup_73'.tr(context: context),
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftCard(BuildContext context, ShiftModel shift, ThemeData theme) {
    final DateFormat timeFormat = DateFormat('hhmm_5'.tr(context: context));
    final DateFormat dateFormat = DateFormat('eeee_dd_mmm_yyyy_17'.tr(context: context), context.locale.languageCode);
    final numFormat = NumberFormat.decimalPattern('id');

    final bool isActive = shift.status == 'active';
    final bool isAutoClosed = shift.status == 'auto_closed';

    final Color statusBg = isActive
        ? AppColors.successFill.withValues(alpha: 0.12)
        : (isAutoClosed ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5) : theme.colorScheme.primary.withValues(alpha: 0.10));
    final Color statusColor = isActive
        ? AppColors.successText
        : (isAutoClosed ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.primary);
    final String statusLabel = isActive
        ? 'sedang_aktif_12'.tr(context: context)
        : (isAutoClosed ? 'otomatis_tutup_14'.tr(context: context) : 'selesai_7'.tr(context: context));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive 
              ? theme.colorScheme.primary.withValues(alpha: 0.35) 
              : theme.dividerColor.withValues(alpha: 0.08),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: User Profile, Date, and Status Badge
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Selfie Avatar
                  GestureDetector(
                    onTap: shift.selfieUrl != null
                        ? () => _showFullImage(context, shift.selfieUrl!)
                        : null,
                    child: Stack(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.surfaceContainerHighest,
                            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15), width: 1.5),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: shift.selfieUrl != null
                              ? Image.network(
                                  shift.selfieUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Icon(Icons.person_rounded, size: 26, color: theme.colorScheme.onSurfaceVariant),
                                )
                              : Icon(Icons.person_rounded, size: 26, color: theme.colorScheme.onSurfaceVariant),
                        ),
                        if (shift.selfieUrl != null)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.search_rounded, size: 10, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name & Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shift.userName ?? 'karyawan_8'.tr(context: context),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateFormat.format(shift.startTime.toLocal()),
                          style: GoogleFonts.outfit(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      statusLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.08)),

            // Middle: Key Metrics (Jam, Omzet, Durasi, Kedisiplinan)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.access_time_rounded,
                          iconColor: theme.colorScheme.primary,
                          label: 'waktu_shift_11'.tr(context: context),
                          value: '${timeFormat.format(shift.startTime.toLocal())} - ${shift.endTime != null ? timeFormat.format(shift.endTime!.toLocal()) : 'sekarang_8'.tr(context: context)}',
                          subValue: shift.totalWorkHours != null ? 'hours_unit'.tr(context: context, args: [shift.totalWorkHours!.toStringAsFixed(1)]) : null,
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.payments_rounded,
                          iconColor: theme.colorScheme.primary,
                          label: 'total_revenue_label'.tr(context: context),
                          value: 'Rp ${numFormat.format(shift.totalRevenue ?? 0)}',
                          valueColor: theme.colorScheme.primary,
                          theme: theme,
                        ),
                      ),
                    ],
                  ),

                  if ((shift.lateMinutes != null && shift.lateMinutes! > 0) ||
                      (shift.overtimeHours != null && shift.overtimeHours! > 0)) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (shift.lateMinutes != null && shift.lateMinutes! > 0)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.dangerFill.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.dangerText),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'late_by_minutes'.tr(context: context, args: [shift.lateMinutes.toString()]),
                                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.dangerText),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if ((shift.lateMinutes != null && shift.lateMinutes! > 0) &&
                            (shift.overtimeHours != null && shift.overtimeHours! > 0))
                          const SizedBox(width: 8),
                        if (shift.overtimeHours != null && shift.overtimeHours! > 0)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.successFill.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.add_alarm_rounded, size: 14, color: AppColors.successText),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'overtime_by_hours'.tr(context: context, args: [shift.overtimeHours!.toStringAsFixed(1)]),
                                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.successText),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Bottom Section: Payment Methods Breakdown & Cash Drawer Discrepancy
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.20),
                border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.08))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment breakdown 3 items
                  Row(
                    children: [
                      Expanded(
                        child: _buildPaymentMiniCard(
                          emoji: '💵',
                          title: 'cash_payment_title'.tr(context: context),
                          amount: 'Rp ${numFormat.format(shift.cashRevenue ?? 0)}',
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildPaymentMiniCard(
                          emoji: '📱',
                          title: 'qris_4'.tr(context: context),
                          amount: 'Rp ${numFormat.format(shift.qrisRevenue ?? 0)}',
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildPaymentMiniCard(
                          emoji: '🏦',
                          title: 'transfer_8'.tr(context: context),
                          amount: 'Rp ${numFormat.format(shift.transferRevenue ?? 0)}',
                          theme: theme,
                        ),
                      ),
                    ],
                  ),

                  // Physical Cash & Discrepancy Check
                  if (shift.closingBalance != null) ...[
                    const SizedBox(height: 10),
                    Builder(builder: (context) {
                      final double expected = shift.expectedCashBalance ?? (shift.openingBalance + (shift.cashRevenue ?? 0));
                      final double actual = shift.closingBalance!;
                      final double diff = actual - expected;
                      final bool isMatch = diff == 0;
                      final bool isOver = diff > 0;

                      final Color diffBg = isMatch
                          ? AppColors.successFill.withValues(alpha: 0.08)
                          : (isOver ? theme.colorScheme.primary.withValues(alpha: 0.08) : AppColors.dangerFill.withValues(alpha: 0.08));
                      final Color diffColor = isMatch
                          ? AppColors.successText
                          : (isOver ? theme.colorScheme.primary : AppColors.dangerText);
                      final Color diffBorder = isMatch
                          ? AppColors.successFill.withValues(alpha: 0.25)
                          : (isOver ? theme.colorScheme.primary.withValues(alpha: 0.25) : AppColors.dangerFill.withValues(alpha: 0.25));

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: diffBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: diffBorder),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'physical_cash_drawer'.tr(context: context),
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Rp ${numFormat.format(actual)}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isMatch
                                          ? Icons.check_circle_rounded
                                          : (isOver ? Icons.info_outline_rounded : Icons.cancel_rounded),
                                      size: 14,
                                      color: diffColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isMatch
                                          ? 'physical_cash_status'.tr(context: context)
                                          : (isOver ? 'cash_diff_surplus'.tr(context: context) : 'cash_diff_shortage'.tr(context: context)),
                                      style: GoogleFonts.outfit(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: diffColor,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  isMatch ? 'cash_status_matched'.tr(context: context) : (isOver ? '+Rp ${numFormat.format(diff.abs())}' : '-Rp ${numFormat.format(diff.abs())}'),
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: diffColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String? subValue,
    Color? valueColor,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subValue != null) ...[
            const SizedBox(height: 2),
            Text(
              subValue,
              style: GoogleFonts.outfit(
                fontSize: 10.5,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMiniCard({
    required String emoji,
    required String title,
    required String amount,
    required ThemeData theme,
    Color? accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 10)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: accentColor ?? theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: accentColor ?? theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

