import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/employee_permission_model.dart';
import '../../providers/employee_permission_provider.dart';
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
                            ? Colors.orange.shade900
                            : theme.primaryColor)
                        : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                  ),
                ),
                selected: isSelected,
                onSelected: (val) {
                  provider.setFilterStatus(f['key']!);
                },
                backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                selectedColor: isPendingFilter && provider.pendingCount > 0
                    ? Colors.orange.shade100
                    : theme.primaryColor.withValues(alpha: 0.15),
                checkmarkColor: isPendingFilter && provider.pendingCount > 0
                    ? Colors.orange.shade900
                    : theme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? (isPendingFilter && provider.pendingCount > 0
                            ? Colors.orange.shade400
                            : theme.primaryColor)
                        : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
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
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Tidak Ada Pengajuan Izin',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Saat ini belum ada pengajuan izin dari karyawan pada filter ini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionReviewCard(EmployeePermission item, ThemeData theme,
      bool isDark, EmployeePermissionProvider provider) {
    final statusColor = item.status == 'approved'
        ? Colors.green
        : (item.status == 'rejected' ? Colors.red : Colors.orange);
    final statusIcon = item.status == 'approved'
        ? Icons.check_circle
        : (item.status == 'rejected' ? Icons.cancel : Icons.hourglass_top);

    final statusText = item.status == 'approved'
        ? 'status_approved'.tr(context: context)
        : (item.status == 'rejected' ? 'status_rejected'.tr(context: context) : 'status_pending'.tr(context: context));

    final typeText = item.type == 'late'
        ? 'permission_late_type'.tr(context: context)
        : 'permission_leave_type'.tr(context: context);

    final empName = item.user?.name ?? 'Karyawan';
    final empRole = item.user?.role ?? 'Staff';

    return Card(
      elevation: item.status == 'pending' ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: item.status == 'pending'
              ? Colors.orange.shade300
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
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
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
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
                    color: item.type == 'late' ? Colors.orange.shade50 : Colors.blue.shade50,
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
                        color: item.type == 'late' ? Colors.orange.shade900 : Colors.blue.shade900,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        typeText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: item.type == 'late' ? Colors.orange.shade900 : Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  item.permissionDate,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),

            if (item.type == 'late' && item.estimatedArrivalTime != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text(
                    'estimated_arrival_outlet'.tr(context: context, args: [item.estimatedArrivalTime ?? '']),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
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
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                item.reason,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
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
                    color: isDark ? Colors.grey.shade800 : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.attach_file, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Buka Foto Bukti Lampiran',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.open_in_new, size: 14, color: Colors.blue),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_delete_outlined, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Bukti lampiran telah terhapus otomatis oleh sistem (>3 hari).',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
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
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  'Catatan Penolakan: ${item.rejectionNote}',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade900),
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
                      icon: const Icon(Icons.close, color: Colors.red, size: 18),
                      label: Text('tolak_85'.tr(context: context), style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmApprove(item.id, provider),
                      icon: const Icon(Icons.check, color: Colors.white, size: 18),
                      label: Text('setujui_90'.tr(context: context), style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.approvePermission(id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Izin karyawan berhasil disetujui.' : 'Gagal menyetujui izin.'),
                    backgroundColor: success ? Colors.green : Colors.red,
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
                hintText: 'Contoh: Jadwal shift sudah padat / Dokumen kurang jelas',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('batal_5'.tr(context: context))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.rejectPermission(id, rejectionNote: noteController.text.trim());
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Pengajuan izin telah ditolak.' : 'Gagal menolak pengajuan.'),
                    backgroundColor: success ? Colors.orange : Colors.red,
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

