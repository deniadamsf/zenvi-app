import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/employee_permission_model.dart';
import '../../providers/employee_permission_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/zenvi_header.dart';

class OwnerPermissionManagementScreen extends StatefulWidget {
  const OwnerPermissionManagementScreen({super.key});

  @override
  State<OwnerPermissionManagementScreen> createState() =>
      _OwnerPermissionManagementScreenState();
}

class _OwnerPermissionManagementScreenState
    extends State<OwnerPermissionManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EmployeePermissionProvider>(context, listen: false).fetchPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      body: Consumer<EmployeePermissionProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () => provider.fetchPermissions(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                ZenviHeader.sliver(
                  title: 'persetujuan_izin_16'.tr(context: context),
                  showBackButton: true,
                  actions: [
                    IconButton(
                      icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
                      onPressed: () {
                        provider.fetchPermissions();
                      },
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: _buildFilterSection(provider, theme, isDark),
                ),
                if (provider.isLoading && provider.permissions.isEmpty)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                else if (provider.permissions.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState(isDark))
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final item = provider.permissions[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildPermissionReviewCard(item, theme, isDark, provider),
                          );
                        },
                        childCount: provider.permissions.length,
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

  Widget _buildFilterSection(
      EmployeePermissionProvider provider, ThemeData theme, bool isDark) {
    final filters = [
      {'key': 'all', 'label': 'semua_5'.tr(context: context)},
      {'key': 'pending', 'label': 'pending_count_filter'.tr(context: context, args: [provider.pendingCount.toString()])},
      {'key': 'approved', 'label': 'approved_count_filter'.tr(context: context, args: [provider.approvedCount.toString()])},
      {'key': 'rejected', 'label': 'rejected_count_filter'.tr(context: context, args: [provider.rejectedCount.toString()])},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = provider.selectedFilterStatus == f['key'];
            final isPendingFilter = f['key'] == 'pending';

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  f['label']!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? (isPendingFilter && provider.pendingCount > 0
                            ? AppColors.warningText
                            : theme.primaryColor)
                        : theme.colorScheme.onSurface,
                  ),
                ),
                selected: isSelected,
                onSelected: (val) {
                  provider.setFilterStatus(f['key']!);
                },
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                selectedColor: isPendingFilter && provider.pendingCount > 0
                    ? AppColors.warningSoft
                    : theme.primaryColor.withValues(alpha: 0.15),
                checkmarkColor: isPendingFilter && provider.pendingCount > 0
                    ? AppColors.warningText
                    : theme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? (isPendingFilter && provider.pendingCount > 0
                            ? AppColors.warningFill
                            : theme.primaryColor)
                        : theme.colorScheme.outline,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mark_email_read_outlined,
                size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'tidak_ada_pengajuan_izin_251'.tr(context: context),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'saat_ini_belum_ada_252'.tr(context: context),
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPermissionDate(BuildContext context, String rawDate) {
    try {
      final date = DateTime.parse(rawDate);
      return DateFormat('EEEE, d MMM yyyy', context.locale.languageCode).format(date);
    } catch (_) {
      return rawDate;
    }
  }

  Widget _buildPermissionReviewCard(EmployeePermission item, ThemeData theme,
      bool isDark, EmployeePermissionProvider provider) {
    final statusFillColor = item.status == 'approved'
        ? AppColors.successFill
        : (item.status == 'rejected' ? AppColors.dangerFill : AppColors.warningFill);
    final statusTextColor = item.status == 'approved'
        ? AppColors.successText
        : (item.status == 'rejected' ? AppColors.dangerText : AppColors.warningText);
    final statusIcon = item.status == 'approved'
        ? Icons.check_circle
        : (item.status == 'rejected' ? Icons.cancel : Icons.hourglass_top);

    final statusText = item.status == 'approved'
        ? 'status_approved'.tr(context: context)
        : (item.status == 'rejected' ? 'status_rejected'.tr(context: context) : 'status_pending'.tr(context: context));

    final typeText = item.type == 'late'
        ? 'permission_late_type'.tr(context: context)
        : 'permission_leave_type'.tr(context: context);

    final empName = item.user?.name ?? 'permission_review_employee_fallback'.tr(context: context);
    final empRole = item.user?.role ?? 'Staff';

    return Card(
      elevation: item.status == 'pending' ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: item.status == 'pending'
              ? AppColors.warningFill
              : theme.colorScheme.outline,
          width: item.status == 'pending' ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Employee Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.primaryColor.withValues(alpha: 0.15),
                  child: Text(
                    empName.isNotEmpty ? empName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        empName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        empRole,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusFillColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusTextColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Type Badge & Permission Date
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.type == 'late' ? AppColors.warningSoft : AppColors.infoSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: item.type == 'late' ? Colors.orange.shade200 : Colors.blue.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.type == 'late' ? Icons.alarm : Icons.beach_access,
                        size: 14,
                        color: item.type == 'late' ? AppColors.warningText : AppColors.infoText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        typeText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: item.type == 'late' ? AppColors.warningText : AppColors.infoText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  _formatPermissionDate(context, item.permissionDate),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),

            if (item.type == 'late' && item.estimatedArrivalTime != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: AppColors.warningText),
                  const SizedBox(width: 6),
                  Text(
                    'estimated_arrival_outlet'.tr(context: context, args: [item.estimatedArrivalTime ?? '']),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warningText,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 10),
            // Reason
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                item.reason,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Attachment Link / Status
            if (item.attachmentUrl != null && !item.isAttachmentExpired)
              InkWell(
                onTap: () => _showFullImageDialog(item.attachmentUrl!),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? theme.colorScheme.surfaceContainerHighest : AppColors.infoSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.attach_file, size: 16, color: AppColors.infoText),
                      const SizedBox(width: 8),
                      Text(
                        'permission_review_open_attachment'.tr(context: context),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.infoText,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.open_in_new, size: 14, color: AppColors.infoText),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_delete_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Bukti lampiran telah terhapus otomatis oleh sistem (>3 hari).',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Rejection Note
            if (item.status == 'rejected' && item.rejectionNote != null && item.rejectionNote!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  'Catatan Penolakan: ${item.rejectionNote}',
                  style: const TextStyle(fontSize: 12, color: AppColors.dangerText),
                ),
              ),
            ],

            // Action Buttons for Pending State
            if (item.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(item.id, provider),
                      icon: const Icon(Icons.close, color: AppColors.dangerText, size: 18),
                      label: Text('tolak_85'.tr(context: context), style: const TextStyle(color: AppColors.dangerText)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.dangerText),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmApprove(item.id, provider),
                      icon: const Icon(Icons.check, color: Colors.white, size: 18),
                      label: Text('setujui_90'.tr(context: context), style: const TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successFill,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFullImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 250,
                    color: Colors.black87,
                    child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                  );
                },
                errorBuilder: (ctx, err, stack) => Container(
                  height: 200,
                  color: Colors.black87,
                  child: Center(
                    child: Text('gagal_memuat_gambar_atau_246'.tr(context: context),
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmApprove(int id, EmployeePermissionProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('setujui_izin_karyawan_255'.tr(context: context)),
        content: Text('pengajuan_izin_ini_akan_256'.tr(context: context)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('batal_5'.tr(context: context))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.successFill, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.approvePermission(id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'permission_approve_success'.tr(context: context)
                        : 'permission_approve_failed'.tr(context: context)),
                    backgroundColor: success ? AppColors.successFill : AppColors.dangerFill,
                  ),
                );
              }
            },
            child: Text('ya_setujui_257'.tr(context: context)),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(int id, EmployeePermissionProvider provider) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('tolak_pengajuan_izin_258'.tr(context: context)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('tuliskan_alasan_penolakan_untuk_259'.tr(context: context)),
            SizedBox(height: 10),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'permission_reject_reason_hint'.tr(context: context),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('batal_5'.tr(context: context))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerFill, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.rejectPermission(id, rejectionNote: noteController.text.trim());
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'permission_reject_success'.tr(context: context)
                        : 'permission_reject_failed'.tr(context: context)),
                    backgroundColor: success ? AppColors.warningFill : AppColors.dangerFill,
                  ),
                );
              }
            },
            child: Text('tolak_izin_260'.tr(context: context)),
          ),
        ],
      ),
    );
  }
}

