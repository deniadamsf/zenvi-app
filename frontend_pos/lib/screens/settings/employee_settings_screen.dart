import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/premium_gate.dart';
import '../../widgets/zenvi_header.dart';


class EmployeeSettingsScreen extends StatefulWidget {
  const EmployeeSettingsScreen({super.key});

  @override
  State<EmployeeSettingsScreen> createState() => _EmployeeSettingsScreenState();
}

class _EmployeeSettingsScreenState extends State<EmployeeSettingsScreen> {
  bool _parseBool(dynamic val) {
    if (val == null) return false;
    if (val == 1 || val == true || val == '1' || val == 'true') return true;
    return false;
  }

  void _showAddScheduleDialog(BuildContext context, ThemeData theme, AuthProvider authProvider, List<Map<String, String>> currentSchedules) {
    String name = 'shift_pagi_10'.tr(context: context);
    String start = '08:00';
    String end = '16:00';
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('tambah_shift_baru_383'.tr(context: context)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'nama_shift_misal_shift_30'.tr(context: context)),
                onChanged: (v) => name = v,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'mulai_hhmm_13'.tr(context: context)),
                onChanged: (v) => start = v,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'selesai_hhmm_15'.tr(context: context)),
                onChanged: (v) => end = v,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('batal_5'.tr(context: context))),
            ElevatedButton(
              onPressed: () {
                List<Map<String, String>> newS = List.from(currentSchedules);
                newS.add({'name': name, 'start': start, 'end': end});
                authProvider.updateCompanySetting(shiftSchedules: newS);
                Navigator.pop(ctx);
              },
              child: Text('simpan_6'.tr(context: context)),
            )
          ],
        );
      },
    );
  }

  Widget _buildShiftScheduleSettings(BuildContext context, ThemeData theme, AuthProvider authProvider) {
    final company = authProvider.user?.company;
    final int tolerance = int.tryParse(company?['late_tolerance_minutes']?.toString() ?? '0') ?? 0;
    
    // Parse schedules
    List<Map<String, String>> schedules = [];
    if (company?['shift_schedules'] != null) {
      try {
        final List<dynamic> parsed = company!['shift_schedules'];
        for (var s in parsed) {
          if (s is Map) {
            schedules.add({
              'name': s['name']?.toString() ?? 'shift_5'.tr(context: context),
              'start': s['start']?.toString() ?? '00:00',
              'end': s['end']?.toString() ?? '00:00',
            });
          }
        }
      } catch (e) {
        // Fallback or ignore
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('toleransi_telat_menit_384'.tr(context: context), style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
              SizedBox(
                width: 80,
                height: 36,
                child: TextFormField(
                  initialValue: tolerance.toString(),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onFieldSubmitted: (val) {
                    final t = int.tryParse(val);
                    if (t != null) {
                      authProvider.updateCompanySetting(lateToleranceMinutes: t);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('jadwal_shift_385'.tr(context: context), style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 8),
          
          if (schedules.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('belum_ada_jadwal_shift_386'.tr(context: context), 
                style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
            )
          else
            ...schedules.asMap().entries.map((entry) {
              int idx = entry.key;
              var s = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${s['start']} - ${s['end']}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: theme.colorScheme.error, size: 20),
                      onPressed: () {
                        List<Map<String, String>> newSchedules = List.from(schedules);
                        newSchedules.removeAt(idx);
                        authProvider.updateCompanySetting(shiftSchedules: newSchedules);
                      },
                    ),
                  ],
                ),
              );
            }),
            
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddScheduleDialog(context, theme, authProvider, schedules),
              icon: Icon(Icons.add, size: 18),
              label: Text('tambah_shift_387'.tr(context: context)),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final isOwner = authProvider.user?.role.toLowerCase() == 'owner' || authProvider.user?.role.toLowerCase() == 'admin';
    final company = authProvider.user?.company;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            ZenviHeader.sliver(
              title: 'pengaturan_pegawai_388'.tr(context: context),
              showBackButton: true,
            ),
            SliverPadding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0, bottom: 120.0),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isOwner) ...[
                  // Shift Settings
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withValues(alpha: 0.05),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded, color: theme.colorScheme.primary, size: 22),
                              const SizedBox(width: 8),
                              Text('pengaturan_absensi_shift_389'.tr(context: context), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            title: Row(
                              children: [
                                Flexible(child: Text('foto_absen_opsional_390'.tr(context: context))),
                                if (!authProvider.hasFeature('attendance_selfie')) ...[
                                  const SizedBox(width: 6),
                                  const PremiumBadge(compact: true),
                                ],
                              ],
                            ),
                            subtitle: Text('karyawan_wajib_foto_saat_391'.tr(context: context)),
                            trailing: PremiumSwitch(
                              locked: !authProvider.hasFeature('attendance_selfie'),
                              feature: 'attendance_selfie',
                              value: _parseBool(company?['require_attendance']),
                              onChanged: (val) => authProvider.updateCompanySetting(requireAttendance: val),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          SwitchListTile(
                            title: Text('mekanisme_jam_masuk_shift_392'.tr(context: context)),
                            subtitle: Text('karyawan_tidak_bisa_absen_393'.tr(context: context)),
                            value: _parseBool(company?['require_schedule']),
                            onChanged: (val) => authProvider.updateCompanySetting(requireSchedule: val),
                            activeThumbColor: theme.colorScheme.primary,
                            contentPadding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 16),
                          _buildShiftScheduleSettings(context, theme, authProvider),
                        ],
                      ),
                    ),
                  ).animate().fade(delay: 100.ms).slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 16),
                  
                  // Role features
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withValues(alpha: 0.05),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.admin_panel_settings_rounded, color: theme.colorScheme.primary, size: 22),
                              const SizedBox(width: 8),
                              Text('akses_fitur_karyawan_394'.tr(context: context), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: Text('stok_opname_saat_tutup_395'.tr(context: context)),
                            subtitle: Text('wajib_cek_stok_fisik_396'.tr(context: context)),
                            value: _parseBool(company?['require_opname_on_shift_close']),
                            onChanged: (val) => authProvider.updateCompanySetting(requireOpname: val),
                            activeThumbColor: theme.colorScheme.primary,
                            contentPadding: EdgeInsets.zero,
                          ),
                          SwitchListTile(
                            title: Text('kasir_input_total_uang_397'.tr(context: context)),
                            subtitle: Text('wajib_input_modal_awal_398'.tr(context: context)),
                            value: _parseBool(company?['require_cash_drawer_balance']),
                            onChanged: (val) => authProvider.updateCompanySetting(requireCashDrawerBalance: val),
                            activeThumbColor: theme.colorScheme.primary,
                            contentPadding: EdgeInsets.zero,
                          ),
                          ListTile(
                            title: Row(
                              children: [
                                Flexible(child: Text('kds_kitchen_display_system_399'.tr(context: context))),
                                if (!authProvider.hasFeature('kds')) ...[
                                  const SizedBox(width: 6),
                                  const PremiumBadge(compact: true),
                                ],
                              ],
                            ),
                            subtitle: Text('tampilkan_layar_pesanan_untuk_400'.tr(context: context)),
                            trailing: PremiumSwitch(
                              locked: !authProvider.hasFeature('kds'),
                              feature: 'kds',
                              value: _parseBool(company?['is_kds_enabled']),
                              onChanged: (val) => authProvider.updateCompanySetting(isKdsEnabled: val),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ).animate().fade(delay: 150.ms).slideY(begin: 0.1, end: 0),
                ],

                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
