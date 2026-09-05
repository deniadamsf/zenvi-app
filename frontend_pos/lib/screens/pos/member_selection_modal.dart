import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/member_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/member_model.dart';
import '../../theme/app_colors.dart';

class MemberSelectionModal extends StatefulWidget {
  final MemberModel? currentMember;

  const MemberSelectionModal({super.key, this.currentMember});

  /// Shows the modal and returns the selected member (or null if dismissed / cleared)
  static Future<MemberModel?> show(BuildContext context, {MemberModel? currentMember}) {
    return showModalBottomSheet<MemberModel?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MemberSelectionModal(currentMember: currentMember),
    );
  }

  @override
  State<MemberSelectionModal> createState() => _MemberSelectionModalState();
}

class _MemberSelectionModalState extends State<MemberSelectionModal> {
  final TextEditingController _searchController = TextEditingController();
  final _currencyFormat = NumberFormat('#,###', 'id_ID');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MemberProvider>().fetchMembers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  void _showQuickAddMemberDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final discountCtrl = TextEditingController(text: '0');
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final bottomPadding = MediaQuery.of(ctx).viewInsets.bottom;
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomPadding),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.warningFill.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.person_add_rounded, color: AppColors.warningText, size: 20),
                        ),
                        SizedBox(width: 12),
                        Text('daftar_member_baru_kasir_262'.tr(context: context), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'nama_lengkap_14'.tr(context: context),
                        hintText: 'misal_rina_wijaya_18'.tr(context: context),
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      decoration: InputDecoration(
                        labelText: 'no_whatsapp_hp_19'.tr(context: context),
                        hintText: 'misal_08123456789_18'.tr(context: context),
                        prefixIcon: Icon(Icons.phone_rounded),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      decoration: InputDecoration(
                        labelText: 'email_opsional_16'.tr(context: context),
                        hintText: 'rina@example.com',
                        prefixIcon: Icon(Icons.email_rounded),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: discountCtrl,
                      decoration: InputDecoration(
                        labelText: 'diskon_khusus_member_24'.tr(context: context),
                        hintText: '0',
                        prefixIcon: Icon(Icons.percent_rounded),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(modalCtx).showSnackBar(
                                    SnackBar(
                                      content: Text('nama_dan_no_telepon_185'.tr(context: context)),
                                      backgroundColor: AppColors.dangerFill,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() => isSubmitting = true);

                                final memberProvider = context.read<MemberProvider>();
                                final newMember = await memberProvider.createMember(
                                  name: nameCtrl.text.trim(),
                                  phone: phoneCtrl.text.trim(),
                                  email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                                  customDiscountPercent: double.tryParse(discountCtrl.text) ?? 0.0,
                                );

                                if (!modalCtx.mounted || !mounted) return;
                                setModalState(() => isSubmitting = false);

                                if (newMember != null) {
                                  Navigator.pop(modalCtx); // Close create sheet
                                  if (mounted) {
                                    Navigator.pop(context, newMember); // Select into cart & close selection modal!
                                  }
                                } else {
                                  final error = memberProvider.errorMessage ?? 'gagal_menambahkan_member_25'.tr(context: context);
                                  ScaffoldMessenger.of(modalCtx).showSnackBar(
                                    SnackBar(
                                      content: Text(error),
                                      backgroundColor: AppColors.dangerFill,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                        icon: isSubmitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_circle_rounded),
                        label: Text(isSubmitting ? 'mendaftarkan_15'.tr(context: context) : 'simpan_pilih_member_21'.tr(context: context)),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warningFill.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.card_membership_rounded, color: AppColors.warningFill, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('pilih_member_263'.tr(context: context), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text('cari_atau_daftarkan_member_264'.tr(context: context), style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _showQuickAddMemberDialog,
                  icon: const Icon(Icons.person_add_rounded, size: 16),
                  label: Text('tambah_49'.tr(context: context), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                if (widget.currentMember != null) ...[
                  const SizedBox(width: 6),
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context, null),
                    icon: const Icon(Icons.person_off_rounded, size: 18),
                    label: Text('hapus_88'.tr(context: context), style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: AppColors.dangerText),
                  ),
                ],
              ],
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'cari_member_14'.tr(context: context),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          context.read<MemberProvider>().fetchMembers();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                context.read<MemberProvider>().fetchMembers(query: value);
                setState(() {});
              },
            ),
          ),
          const Divider(height: 1),
          // Member List
          Expanded(
            child: Consumer<MemberProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                final members = provider.members;
                if (members.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline_rounded, size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text('belum_ada_member_terdaftar_187'.tr(context: context), style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _showQuickAddMemberDialog,
                            icon: const Icon(Icons.person_add_rounded),
                            label: Text('daftarkan_member_baru_265'.tr(context: context)),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: members.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final isSelected = widget.currentMember?.id == member.id;
                    return _MemberCard(
                      member: member,
                      isSelected: isSelected,
                      currencyFormat: _currencyFormat,
                      onTap: () => Navigator.pop(context, member),
                    ).animate().fade(delay: Duration(milliseconds: 40 * index)).slideX(begin: 0.05);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final MemberModel member;
  final bool isSelected;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;

  const _MemberCard({
    required this.member,
    required this.isSelected,
    required this.currencyFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.6)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.warningFill.withValues(alpha: 0.2),
                child: Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.warningText, fontSize: 18),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            member.memberCode,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone_rounded, size: 13, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(member.phone, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                        if (context.watch<AuthProvider>().isPointsEnabled) ...[
                          const Spacer(),
                          const Icon(Icons.star_rounded, size: 14, color: AppColors.warningText),
                          const SizedBox(width: 2),
                          Text('member_points_count'.tr(context: context, args: [member.points.toString()]), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                        ],
                      ],
                    ),
                    if (member.customDiscountPercent > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        'member_discount_percent_label'.tr(context: context, args: [member.customDiscountPercent.toStringAsFixed(0)]),
                        style: TextStyle(fontSize: 11, color: AppColors.successText, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
