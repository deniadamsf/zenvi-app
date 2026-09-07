import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/zenvi_header.dart';
import '../../theme/app_colors.dart';

class EmployeeVerificationScreen extends StatefulWidget {
  const EmployeeVerificationScreen({super.key});

  @override
  State<EmployeeVerificationScreen> createState() => _EmployeeVerificationScreenState();
}

class _EmployeeVerificationScreenState extends State<EmployeeVerificationScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _pendingEmployees = [];
  List<Map<String, dynamic>> _activeEmployees = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchEmployees();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchEmployees() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final pending = await authProvider.fetchPendingEmployees();
    final active = await authProvider.fetchActiveEmployees();
    if (mounted) {
      setState(() {
        _pendingEmployees = pending;
        _activeEmployees = active;
        _isLoading = false;
      });
    }
  }

  void _showPermissionModal({required Map<String, dynamic> employee, required bool isApproving}) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Initial state from employee data
    String selectedRolePreset = 'kasir_5'.tr(context: context);
    String currentJobTitle = employee['job_title']?.toString() ?? 'kasir_5'.tr(context: context);
    
    Map<String, dynamic> existingPerms = employee['permissions'] != null && employee['permissions'] is Map
        ? Map<String, dynamic>.from(employee['permissions'])
        : {};

    // Detect preset if exists
    final titleLower = currentJobTitle.toLowerCase();
    if (titleLower.contains('kapster') || titleLower.contains('terapis') || titleLower.contains('layanan')) {
      selectedRolePreset = 'staf_layanan_12'.tr(context: context);
    } else if (titleLower.contains('dapur') || titleLower.contains('barista') || titleLower.contains('koki')) {
      selectedRolePreset = 'dapur_barista_15'.tr(context: context);
    } else if (titleLower.contains('gudang')) {
      selectedRolePreset = 'gudang_6'.tr(context: context);
    } else if (existingPerms.isNotEmpty && existingPerms['can_access_pos'] == false) {
      selectedRolePreset = 'kustom_6'.tr(context: context);
    }

    bool canAccessPos = existingPerms['can_access_pos'] ?? (selectedRolePreset == 'kasir_5'.tr(context: context));
    bool canAccessStock = existingPerms['can_access_stock'] ?? (selectedRolePreset == 'dapur_barista_15'.tr(context: context) || selectedRolePreset == 'gudang_6'.tr(context: context));
    bool canAccessReservations = existingPerms['can_access_reservations'] ?? (selectedRolePreset == 'kasir_5'.tr(context: context) || selectedRolePreset == 'staf_layanan_12'.tr(context: context));
    bool canAccessExpenses = existingPerms['can_access_expenses'] ?? (selectedRolePreset == 'kasir_5'.tr(context: context));
    bool canAccessKds = existingPerms['can_access_kds'] ?? (selectedRolePreset == 'dapur_barista_15'.tr(context: context));


    final titleController = TextEditingController(text: currentJobTitle);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            void applyPreset(String preset) {
              setModalState(() {
                selectedRolePreset = preset;
                if (preset == 'kasir_5'.tr(context: context)) {
                    titleController.text = 'kasir_5'.tr(context: context);
                    canAccessPos = true;
                    canAccessStock = false;
                    canAccessReservations = true;
                    canAccessExpenses = true;
                } else if (preset == 'staf_layanan_12'.tr(context: context)) {
                    titleController.text = 'kapster_terapis_17'.tr(context: context);
                    canAccessPos = false;
                    canAccessStock = false;
                    canAccessReservations = true;
                    canAccessExpenses = false;
                } else if (preset == 'dapur_barista_15'.tr(context: context)) {
                    titleController.text = 'staff_dapur_barista_21'.tr(context: context);
                    canAccessPos = false;
                    canAccessStock = true;
                    canAccessReservations = false;
                    canAccessExpenses = false;
                } else if (preset == 'gudang_6'.tr(context: context)) {
                    titleController.text = 'staff_gudang_12'.tr(context: context);
                    canAccessPos = false;
                    canAccessStock = true;
                    canAccessReservations = false;
                    canAccessExpenses = false;
                } else if (preset == 'kustom_6'.tr(context: context)) {
                    // Custom preset does nothing specific
                }
              });
            }

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
                top: 24,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outline.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            isApproving ? Icons.how_to_reg_rounded : Icons.admin_panel_settings_rounded,
                            color: theme.colorScheme.primary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isApproving ? 'setujui_tentukan_hak_akses_28'.tr(context: context) : 'kelola_hak_akses_karyawan_25'.tr(context: context),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              Text(
                                '${employee['name']} (${employee['email']})',
                                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Preset Role Selection
                    Text(
                      'verify_preset_section'.tr(context: context),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildPresetChip('kasir_5'.tr(context: context), '💵 Kasir', selectedRolePreset, () => applyPreset('kasir_5'.tr(context: context)), theme),
                        _buildPresetChip('staf_layanan_12'.tr(context: context), '✂️ Staf Layanan / Kapster', selectedRolePreset, () => applyPreset('staf_layanan_12'.tr(context: context)), theme),
                        _buildPresetChip('dapur_barista_15'.tr(context: context), '🍳 Dapur / Barista', selectedRolePreset, () => applyPreset('dapur_barista_15'.tr(context: context)), theme),
                        _buildPresetChip('gudang_6'.tr(context: context), '📦 Gudang', selectedRolePreset, () => applyPreset('gudang_6'.tr(context: context)), theme),
                        _buildPresetChip('kustom_6'.tr(context: context), '⚙️ Kustom', selectedRolePreset, () => applyPreset('kustom_6'.tr(context: context)), theme),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Jabatan/Posisi Input
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'verify_job_title_label'.tr(context: context),
                        hintText: 'verify_job_title_hint'.tr(context: context),
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Modular Permissions Switch
                    Text(
                      'verify_modules_section'.tr(context: context),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 10),

                    _buildPermissionSwitchTile(
                      icon: Icons.point_of_sale_rounded,
                      title: 'verify_module_pos_title'.tr(context: context),
                      subtitle: 'verify_module_pos_desc'.tr(context: context),
                      value: canAccessPos,
                      onChanged: (val) {
                        setModalState(() {
                          canAccessPos = val;
                          selectedRolePreset = 'kustom_6'.tr(context: context);
                        });
                      },
                      theme: theme,
                    ),
                    const SizedBox(height: 8),

                    _buildPermissionSwitchTile(
                      icon: Icons.inventory_2_rounded,
                      title: 'verify_module_stock_title'.tr(context: context),
                      subtitle: 'verify_module_stock_desc'.tr(context: context),
                      value: canAccessStock,
                      onChanged: (val) {
                        setModalState(() {
                          canAccessStock = val;
                          selectedRolePreset = 'kustom_6'.tr(context: context);
                        });
                      },
                      theme: theme,
                    ),
                    const SizedBox(height: 8),

                    _buildPermissionSwitchTile(
                      icon: Icons.event_seat_rounded,
                      title: 'verify_module_reservation_title'.tr(context: context),
                      subtitle: 'verify_module_reservation_desc'.tr(context: context),
                      value: canAccessReservations,
                      onChanged: (val) {
                        setModalState(() {
                          canAccessReservations = val;
                          selectedRolePreset = 'kustom_6'.tr(context: context);
                        });
                      },
                      theme: theme,
                    ),
                    const SizedBox(height: 8),

                    _buildPermissionSwitchTile(
                      icon: Icons.receipt_long_rounded,
                      title: 'verify_module_expense_title'.tr(context: context),
                      subtitle: 'verify_module_expense_desc'.tr(context: context),
                      value: canAccessExpenses,
                      onChanged: (val) {
                        setModalState(() {
                          canAccessExpenses = val;
                          selectedRolePreset = 'kustom_6'.tr(context: context);
                        });
                      },
                      theme: theme,
                    ),
                    const SizedBox(height: 8),
                    
                    _buildPermissionSwitchTile(
                      icon: Icons.kitchen_rounded,
                      title: 'verify_module_kds_title'.tr(context: context),
                      subtitle: 'verify_module_kds_desc'.tr(context: context),
                      value: canAccessKds,
                      onChanged: (val) {
                        setModalState(() {
                          canAccessKds = val;
                          selectedRolePreset = 'kustom_6'.tr(context: context);
                        });
                      },
                      theme: theme,
                    ),

                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 20, color: theme.colorScheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'verify_always_on_note'.tr(context: context),
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isApproving ? AppColors.successFill : theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () async {
                          Navigator.pop(modalContext);

                          final permsMap = {
                            'can_access_pos': canAccessPos,
                            'can_access_stock': canAccessStock,
                            'can_access_reservations': canAccessReservations,
                            'can_access_expenses': canAccessExpenses,
                            'can_access_kds': canAccessKds,
                          };

                          final jobTitle = titleController.text.trim().isNotEmpty
                              ? titleController.text.trim()
                              : 'karyawan_8'.tr(context: context);

                          if (isApproving) {
                            final success = await authProvider.approveEmployee(
                              employee['id'],
                              jobTitle: jobTitle,
                              permissions: permsMap,
                            );
                            if (mounted) {
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Karyawan ${employee['name']} berhasil disetujui sebagai $jobTitle.'),
                                    backgroundColor: AppColors.successFill,
                                  ),
                                );
                                _fetchEmployees();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('gagal_menyetujui_karyawan_82'.tr(context: context)),
                                    backgroundColor: AppColors.dangerFill,
                                  ),
                                );
                              }
                            }
                          } else {
                            final success = await authProvider.updateEmployeePermissions(
                              employee['id'],
                              jobTitle: jobTitle,
                              permissions: permsMap,
                            );
                            if (mounted) {
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Hak akses ${employee['name']} berhasil diperbarui.'),
                                    backgroundColor: AppColors.successFill,
                                  ),
                                );
                                _fetchEmployees();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('gagal_memperbarui_hak_akses_83'.tr(context: context)),
                                    backgroundColor: AppColors.dangerFill,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        child: Text(
                          isApproving
                              ? 'verify_approve_button'.tr(context: context)
                              : 'verify_save_access_button'.tr(context: context),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
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

  Widget _buildPresetChip(String key, String label, String selectedKey, VoidCallback onTap, ThemeData theme) {
    final isSelected = key == selectedKey;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ThemeData theme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: value ? theme.colorScheme.primary.withValues(alpha: 0.05) : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? theme.colorScheme.primary.withValues(alpha: 0.3) : theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: value ? theme.colorScheme.primary.withValues(alpha: 0.15) : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 22,
            color: value ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
        value: value,
        activeThumbColor: theme.colorScheme.primary,
        onChanged: onChanged,
      ),
    );
  }

  void _rejectEmployee(int index) async {
    final employee = _pendingEmployees[index];
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('tolak_pendaftar_84'.tr(context: context)),
        content: Text('Apakah Anda yakin ingin menolak pendaftaran ${employee['name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('batal_5'.tr(context: context))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerFill, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text('tolak_85'.tr(context: context))
          ),
        ],
      ),
    );
    
    if (confirm != true) return;

    final success = await authProvider.removeEmployee(employee['id']);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('registration_rejected_msg'.tr(context: context, args: [employee['name']])), backgroundColor: AppColors.successFill),
        );
        _fetchEmployees();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('gagal_menolak_pendaftaran_86'.tr(context: context)), backgroundColor: AppColors.dangerFill),
        );
      }
    }
  }
  
  void _removeEmployee(int index) async {
    final employee = _activeEmployees[index];
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Konfirmasi dulu
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('hapus_karyawan_87'.tr(context: context)),
        content: Text('delete_employee_confirm_desc'.tr(context: context, args: [employee['name']])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('batal_5'.tr(context: context))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerFill, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text('hapus_88'.tr(context: context))
          ),
        ],
      ),
    );
    
    if (confirm != true) return;

    final success = await authProvider.removeEmployee(employee['id']);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('employee_deleted_msg'.tr(context: context, args: [employee['name']])), backgroundColor: AppColors.successFill),
        );
        _fetchEmployees();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('gagal_menghapus_karyawan_89'.tr(context: context)), backgroundColor: AppColors.dangerFill),
        );
      }
    }
  }

  Widget _buildEmployeeList(List<Map<String, dynamic>> list, ThemeData theme, bool isActive) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              isActive ? 'no_active_employees'.tr(context: context) : 'no_new_applicants'.tr(context: context),
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 16),
            ),
          ],
        ),
      ).animate().fade();
    }
    
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final emp = list[index];
        final jobTitle = emp['job_title']?.toString() ?? (isActive ? 'kasir_5'.tr(context: context) : 'applicant_role'.tr(context: context));
        final perms = emp['permissions'] != null && emp['permissions'] is Map ? Map<String, dynamic>.from(emp['permissions']) : {};

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      emp['name'].toString().substring(0, 1).toUpperCase(),
                      style: TextStyle(color: theme.colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                emp['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                              ),
                            ),
                            if (isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  jobTitle,
                                  style: TextStyle(
                                    color: theme.colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(emp['email'], style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.storefront, size: 14, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              emp['branch']?['name'] ?? 'main_branch_default'.tr(context: context),
                              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (isActive) ...[
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (perms['can_access_pos'] == true || (perms.isEmpty && !jobTitle.toLowerCase().contains('kapster') && !jobTitle.toLowerCase().contains('dapur')))
                            _buildModuleBadge('module_cashier_pos'.tr(context: context), Icons.point_of_sale_rounded, theme),
                          if (perms['can_access_stock'] == true || jobTitle.toLowerCase().contains('gudang') || jobTitle.toLowerCase().contains('dapur'))
                            _buildModuleBadge('module_stock'.tr(context: context), Icons.inventory_2_rounded, theme),
                          if (perms['can_access_reservations'] == true || perms.isEmpty)
                            _buildModuleBadge('reservasi_9'.tr(context: context), Icons.event_seat_rounded, theme),
                          if (perms['can_access_expenses'] == true || (perms.isEmpty && !jobTitle.toLowerCase().contains('kapster')))
                            _buildModuleBadge('module_expenses'.tr(context: context), Icons.receipt_long_rounded, theme),
                          _buildModuleBadge('module_attendance_shift'.tr(context: context), Icons.access_time_rounded, theme),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: () => _showPermissionModal(employee: emp, isApproving: false),
                      icon: const Icon(Icons.tune_rounded, size: 20),
                      tooltip: 'set_permissions_tooltip'.tr(context: context),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => _removeEmployee(index),
                      icon: const Icon(Icons.delete_outline, color: AppColors.dangerText, size: 20),
                      tooltip: 'delete_employee_tooltip'.tr(context: context),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.dangerFill.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _rejectEmployee(index),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.dangerText,
                          side: const BorderSide(color: AppColors.dangerFill),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text('tolak_85'.tr(context: context)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showPermissionModal(employee: emp, isApproving: true),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: Text('setujui_90'.tr(context: context)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successFill,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ).animate().fade(delay: Duration(milliseconds: 100 + (index * 50))).slideX(begin: 0.05, end: 0);
      },
    );
  }

  Widget _buildModuleBadge(String label, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            ZenviHeader.sliver(
              title: 'manage_team_permissions'.tr(context: context),
              subtitle: 'manage_team_permissions_subtitle'.tr(context: context),
              showBackButton: true,
              bottom: TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                indicatorColor: theme.colorScheme.primary,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(text: 'new_applicants_tab'.tr(context: context)),
                  Tab(text: 'active_employees_tab'.tr(context: context)),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    final company = auth.user?.company;
                    final storeCode = company?['code']?.toString() ?? 'znv8829_8'.tr(context: context);
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.qr_code_2_rounded, size: 22, color: theme.colorScheme.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'your_store_code'.tr(context: context),
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  storeCode,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: storeCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('store_code_copied'.tr(context: context, args: [storeCode])),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: Text('salin_94'.tr(context: context), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fade(delay: 100.ms).slideY(begin: 0.1, end: 0);
                  },
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildEmployeeList(_pendingEmployees, theme, false),
            _buildEmployeeList(_activeEmployees, theme, true),
          ],
        ),
      ),
    );
  }
}

