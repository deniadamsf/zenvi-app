import 'package:easy_localization/easy_localization.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/employee_permission_model.dart';
import '../../providers/employee_permission_provider.dart';
import '../../widgets/zenvi_header.dart';

class EmployeePermissionScreen extends StatefulWidget {
  const EmployeePermissionScreen({super.key});

  @override
  State<EmployeePermissionScreen> createState() => _EmployeePermissionScreenState();
}

class _EmployeePermissionScreenState extends State<EmployeePermissionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form states
  String _selectedType = 'leave'; // 'leave' or 'late'
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _estimatedTime = const TimeOfDay(hour: 9, minute: 0);
  final TextEditingController _reasonController = TextEditingController();
  File? _attachmentImage;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EmployeePermissionProvider>(context, listen: false).fetchPermissions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _attachmentImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('failed_pick_image'.tr(context: context, args: [e.toString()])),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Sumber Foto Bukti',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.camera_alt, color: Colors.green),
                ),
                title: Text('ambil_foto_dari_kamera_223'.tr(context: context)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(Icons.photo_library, color: Colors.blue),
                ),
                title: Text('pilih_dari_galeri_224'.tr(context: context)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('mohon_tuliskan_alasan_izin_225'.tr(context: context)),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    if (_attachmentImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('wajib_melampirkan_foto_bukti_226'.tr(context: context)),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = Provider.of<EmployeePermissionProvider>(context, listen: false);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final timeStr = _selectedType == 'late'
        ? '${_estimatedTime.hour.toString().padLeft(2, '0')}:${_estimatedTime.minute.toString().padLeft(2, '0')}'
        : null;

    final result = await provider.submitPermission(
      type: _selectedType,
      permissionDate: dateStr,
      estimatedArrivalTime: timeStr,
      reason: _reasonController.text.trim(),
      attachmentFile: _attachmentImage!,
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (result['success'] == true) {
        // Reset form
        _reasonController.clear();
        setState(() {
          _attachmentImage = null;
          _selectedDate = DateTime.now();
        });

        provider.setFilterStatus('all');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'permission_submitted_pending'.tr(context: context),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 4),
          ),
        );

        // Switch to history tab
        _tabController.animateTo(1);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal mengirim pengajuan.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: ZenviHeader(
        title: 'Pengajuan Izin Karyawan',
        showBackButton: true,
        bottom: Consumer<EmployeePermissionProvider>(
          builder: (context, provider, child) {
            return TabBar(
              controller: _tabController,
              indicatorColor: theme.colorScheme.primary,
              indicatorWeight: 3,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                const Tab(icon: Icon(Icons.edit_calendar, size: 18), text: 'Buat Pengajuan'),
                Tab(
                  icon: provider.pendingCount > 0
                      ? Badge(
                          label: Text(
                            '${provider.pendingCount}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: Colors.orange.shade800,
                          child: const Icon(Icons.history, size: 18),
                        )
                      : const Icon(Icons.history, size: 18),
                  text: 'Riwayat Izin',
                ),
              ],
            );
          },
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFormTab(theme, isDark),
          _buildHistoryTab(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildFormTab(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.blueGrey.shade900 : const Color(0xFFE8F4FD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.blueGrey.shade700 : const Color(0xFFB6E0FE),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: isDark ? Colors.lightBlueAccent : const Color(0xFF0288D1),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informasi Privasi & Penyimpanan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark ? Colors.lightBlueAccent : const Color(0xFF0277BD),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Foto bukti yang Anda lampirkan akan otomatis dihapus permanen oleh server setelah 3 hari untuk efisiensi penyimpanan.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade300 : const Color(0xFF37474F),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Pilihan Jenis Izin
          const Text(
            'Jenis Pengajuan Izin',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTypeOption(
                  type: 'leave',
                  title: 'Izin Libur',
                  subtitle: 'Cuti / Sakit / Tidak Masuk',
                  icon: Icons.beach_access,
                  theme: theme,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTypeOption(
                  type: 'late',
                  title: 'Izin Telat',
                  subtitle: 'Terlambat Masuk Shift',
                  icon: Icons.alarm,
                  theme: theme,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Pemilih Tanggal
          const Text(
            'Tanggal Izin',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 7)),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.indigo, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('EEEE, dd MMMM yyyy', 'id').format(_selectedDate),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Perkiraan Jam Tiba (Jika Telat)
          if (_selectedType == 'late') ...[
            const Text(
              'Perkiraan Jam Tiba di Toko',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _estimatedTime,
                );
                if (picked != null) {
                  setState(() => _estimatedTime = picked);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Pukul ${_estimatedTime.hour.toString().padLeft(2, '0')}:${_estimatedTime.minute.toString().padLeft(2, '0')} WIB',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Alasan
          const Text(
            'Alasan / Keterangan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Contoh: Sakit demam dengan surat dokter / Ban bocor di jalan...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 20),

          // Upload Bukti (Wajib)
          Row(
            children: [
              const Text(
                'Foto Bukti (Wajib Lampirkan)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(width: 6),
              Text(
                '*',
                style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_attachmentImage == null)
            InkWell(
              onTap: _showImageSourcePicker,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                ),
                child: Column(
                  children: [
                    Icon(Icons.add_a_photo, size: 40, color: theme.primaryColor),
                    const SizedBox(height: 10),
                    Text(
                      'Klik untuk Ambil Foto / Pilih Bukti',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Surat dokter, foto kondisi, atau surat izin resmi',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _attachmentImage!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () => setState(() => _attachmentImage = null),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, color: Colors.greenAccent, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Foto Bukti Terpilih',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 28),

          // Tombol Submit
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Kirim Pengajuan Izin',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTypeOption({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeData theme,
    required bool isDark,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? theme.primaryColor.withValues(alpha: 0.3) : theme.primaryColor.withValues(alpha: 0.1))
              : (isDark ? Colors.grey.shade900 : Colors.grey.shade100),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? theme.primaryColor : Colors.grey,
                  size: 24,
                ),
                const Spacer(),
                if (isSelected)
                  Icon(Icons.check_circle, color: theme.primaryColor, size: 20),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isSelected ? theme.primaryColor : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(ThemeData theme, bool isDark) {
    return Consumer<EmployeePermissionProvider>(
      builder: (context, provider, child) {
        final filters = [
          {'key': 'all', 'label': 'semua_5'.tr(context: context), 'icon': Icons.all_inbox_rounded},
          {'key': 'pending', 'label': 'pending_count_filter'.tr(context: context, args: [provider.pendingCount.toString()]), 'icon': Icons.hourglass_top_rounded},
          {'key': 'approved', 'label': 'approved_count_filter'.tr(context: context, args: [provider.approvedCount.toString()]), 'icon': Icons.check_circle_rounded},
          {'key': 'rejected', 'label': 'rejected_count_filter'.tr(context: context, args: [provider.rejectedCount.toString()]), 'icon': Icons.cancel_rounded},
        ];

        return Column(
          children: [
            // 1. Filter Chips Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: filters.map((f) {
                    final isSelected = provider.selectedFilterStatus == f['key'];
                    final key = f['key'];

                    Color chipColor = theme.primaryColor;
                    if (key == 'pending') chipColor = Colors.orange.shade800;
                    if (key == 'approved') chipColor = Colors.green.shade800;
                    if (key == 'rejected') chipColor = Colors.red.shade800;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        avatar: Icon(
                          f['icon'] as IconData,
                          size: 16,
                          color: isSelected ? Colors.white : chipColor,
                        ),
                        label: Text(
                          f['label'] as String,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: chipColor,
                        showCheckmark: false,
                        onSelected: (val) {
                          provider.setFilterStatus(f['key'] as String);
                        },
                        backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? chipColor : Colors.transparent,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // 2. Info Legend Card
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'permission_status_legend'.tr(context: context),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Permissions List
            Expanded(
              child: provider.isLoading && provider.permissions.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : provider.permissions.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  provider.selectedFilterStatus == 'all'
                                      ? 'Belum Ada Riwayat Izin'
                                      : 'Tidak ada izin dengan status ini',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Pengajuan izin libur atau telat masuk yang Anda buat akan tercatat di sini.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => provider.fetchPermissions(),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: provider.permissions.length,
                            separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                            itemBuilder: (ctx, i) {
                              final item = provider.permissions[i];
                              return _buildPermissionCard(item, theme, isDark, provider);
                            },
                          ),
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPermissionCard(
    EmployeePermission item,
    ThemeData theme,
    bool isDark,
    EmployeePermissionProvider provider,
  ) {
    Color statusColor;
    IconData statusIcon;
    String statusTitle;
    String statusExplanation;

    switch (item.status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        statusTitle = 'status_approved_caps'.tr(context: context);
        statusExplanation = item.type == 'late'
            ? 'status_explanation_late_approved'.tr(context: context)
            : 'status_explanation_leave_approved'.tr(context: context);
        if (item.reviewedAt != null) {
          final revDate = DateTime.tryParse(item.reviewedAt!);
          if (revDate != null) {
            statusExplanation += 'reviewed_time_approved'.tr(context: context, args: [DateFormat('dd/MM HH:mm').format(revDate)]);
          }
        }
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        statusTitle = 'status_rejected_caps'.tr(context: context);
        statusExplanation = (item.rejectionNote != null && item.rejectionNote!.isNotEmpty)
            ? 'owner_note_prefix'.tr(context: context, args: [item.rejectionNote!])
            : 'status_explanation_rejected'.tr(context: context);
        break;
      case 'pending':
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_top_rounded;
        statusTitle = 'status_pending_caps'.tr(context: context);
        statusExplanation = 'status_explanation_pending'.tr(context: context);
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: statusColor.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Prominent Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STATUS: $statusTitle',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusExplanation,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. Type and Date Row
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
                        item.typeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: item.type == 'late' ? Colors.orange.shade900 : Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      item.permissionDate,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                  ],
                ),
              ],
            ),
            if (item.type == 'late' && item.estimatedArrivalTime != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time_filled_rounded, size: 15, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text(
                    'Estimasi Tiba di Tempat: ${item.estimatedArrivalTime}',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.orange),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),

            // 3. Reason
            Text(
              'Alasan Pengajuan:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 3),
            Text(
              item.reason,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade200 : Colors.grey.shade900,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),

            // 4. Attachment status info
            if (item.attachmentUrl != null && !item.isAttachmentExpired)
              InkWell(
                onTap: () => _showFullImageDialog(item.attachmentUrl!),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.image, size: 16, color: Colors.indigo),
                      const SizedBox(width: 8),
                      const Text(
                        'Lihat Foto Bukti (Aktif < 3 Hari)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.indigo),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.open_in_new, size: 14, color: Colors.indigo),
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
                        'Bukti lampiran telah kedaluwarsa & dihapus otomatis (3 hari).',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),

            // 5. Cancel button if pending
            if (item.status == 'pending') ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _confirmDelete(item.id, provider),
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  label: Text('batalkan_pengajuan_245'.tr(context: context), style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
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
                    child: Text('gagal_memuat_gambar_atau_246'.tr(context: context), style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int id, EmployeePermissionProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('batalkan_pengajuan_247'.tr(context: context)),
        content: Text('apakah_anda_yakin_ingin_248'.tr(context: context)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('kembali_24'.tr(context: context))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.deletePermission(id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Pengajuan berhasil dibatalkan.' : 'Gagal membatalkan pengajuan.'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: Text('ya_batalkan_25'.tr(context: context)),
          ),
        ],
      ),
    );
  }
}
