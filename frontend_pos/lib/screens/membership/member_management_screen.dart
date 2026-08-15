import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/member_provider.dart';
import '../../providers/member_promo_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/member_model.dart';
import '../../models/member_promo_model.dart';
import '../../widgets/zenvi_header.dart';

class MemberManagementScreen extends StatefulWidget {
  const MemberManagementScreen({super.key});

  @override
  State<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currencyFormat = NumberFormat('#,###', 'id_ID');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MemberProvider>().fetchMembers();
      context.read<MemberPromoProvider>().fetchPromos();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              title: 'membership_10'.tr(context: context),
              showBackButton: true,
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: theme.colorScheme.primary,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(icon: const Icon(Icons.people_rounded, size: 18), text: 'daftar_member_13'.tr(context: context)),
                  Tab(icon: const Icon(Icons.local_offer_rounded, size: 18), text: 'promo_member_12'.tr(context: context)),
                ],
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _MemberListTab(currencyFormat: _currencyFormat),
            _PromoListTab(currencyFormat: _currencyFormat),
          ],
        ),
      ),
    );
  }
}

// ============================
// TAB 1: Daftar Member
// ============================
class _MemberListTab extends StatefulWidget {
  final NumberFormat currencyFormat;
  const _MemberListTab({required this.currencyFormat});

  @override
  State<_MemberListTab> createState() => _MemberListTabState();
}

class _MemberListTabState extends State<_MemberListTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddMemberDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final discountCtrl = TextEditingController(text: '0');
    final notesCtrl = TextEditingController();
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
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.person_add_rounded, color: theme.colorScheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'tambah_member_baru_184'.tr(context: context),
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'nama_lengkap_14'.tr(context: context),
                        hintText: 'misal_budi_santoso_19'.tr(context: context),
                        prefixIcon: const Icon(Icons.person_rounded),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      decoration: InputDecoration(
                        labelText: 'no_whatsapp_hp_19'.tr(context: context),
                        hintText: 'misal_08123456789_18'.tr(context: context),
                        prefixIcon: const Icon(Icons.phone_rounded),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      decoration: InputDecoration(
                        labelText: 'email_opsional_16'.tr(context: context),
                        hintText: 'budi@example.com',
                        prefixIcon: const Icon(Icons.email_rounded),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressCtrl,
                      decoration: InputDecoration(
                        labelText: 'alamat_opsional_17'.tr(context: context),
                        prefixIcon: const Icon(Icons.location_on_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: discountCtrl,
                      decoration: InputDecoration(
                        labelText: 'diskon_khusus_member_24'.tr(context: context),
                        hintText: '0 - 100',
                        prefixIcon: const Icon(Icons.percent_rounded),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      decoration: InputDecoration(
                        labelText: 'catatan_opsional_18'.tr(context: context),
                        prefixIcon: const Icon(Icons.note_rounded),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(modalCtx).showSnackBar(
                                    SnackBar(
                                      content: Text('nama_dan_no_telepon_185'.tr(context: context)),
                                      backgroundColor: theme.colorScheme.error,
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
                                  address: addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : null,
                                  customDiscountPercent: double.tryParse(discountCtrl.text) ?? 0.0,
                                  notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                                );

                                if (!modalCtx.mounted || !mounted) return;
                                setModalState(() => isSubmitting = false);

                                if (newMember != null) {
                                  Navigator.pop(modalCtx);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Member "${newMember.name}" (${newMember.memberCode}) berhasil ditambahkan! 🎉'),
                                        backgroundColor: theme.colorScheme.primary,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } else {
                                  final error = memberProvider.errorMessage ?? 'gagal_menambahkan_member_25'.tr(context: context);
                                  ScaffoldMessenger.of(modalCtx).showSnackBar(
                                    SnackBar(
                                      content: Text(error),
                                      backgroundColor: theme.colorScheme.error,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                        icon: isSubmitting
                            ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary))
                            : const Icon(Icons.person_add_rounded),
                        label: Text(isSubmitting ? 'Menyimpan...' : 'Simpan Member'),
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

  void _showMemberDetail(MemberModel member) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              CircleAvatar(
                radius: 36,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                child: Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(member.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  member.memberCode,
                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(height: 18),
              _detailRow(theme, Icons.phone_rounded, 'Telepon', member.phone),
              if (member.email != null && member.email!.isNotEmpty) _detailRow(theme, Icons.email_rounded, 'Email', member.email!),
              if (member.address != null && member.address!.isNotEmpty) _detailRow(theme, Icons.location_on_rounded, 'Alamat', member.address!),
              if (context.read<AuthProvider>().isPointsEnabled)
                _detailRow(theme, Icons.stars_rounded, 'Poin', '${member.points} poin'),
              _detailRow(theme, Icons.shopping_bag_outlined, 'Total Transaksi', '${member.totalTransactions}x'),
              _detailRow(theme, Icons.account_balance_wallet_outlined, 'Total Belanja', 'Rp ${widget.currencyFormat.format(member.totalSpend)}'),
              if (member.customDiscountPercent > 0)
                _detailRow(theme, Icons.percent_rounded, 'Diskon Member', '${member.customDiscountPercent.toStringAsFixed(0)}%'),
              if (member.notes != null && member.notes!.isNotEmpty)
                _detailRow(theme, Icons.note_rounded, 'Catatan', member.notes!),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: Text('hapus_member_186'.tr(context: context)),
                            content: Text('delete_member_confirm'.tr(context: context, args: [member.name])),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: Text('batal_5'.tr(context: context))),
                              FilledButton(
                                onPressed: () => Navigator.pop(c, true),
                                style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
                                child: Text('hapus_88'.tr(context: context)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && mounted) {
                          await context.read<MemberProvider>().deleteMember(member.id);
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: Text('hapus_88'.tr(context: context)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: Text('tutup_136'.tr(context: context)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(ThemeData theme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Text('$label: ', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMemberDialog,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.person_add_rounded),
        label: Text('tambah_49'.tr(context: context), style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama, telepon, atau kode member...',
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: theme.colorScheme.onSurfaceVariant),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          context.read<MemberProvider>().fetchMembers();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (value) {
                context.read<MemberProvider>().fetchMembers(query: value);
                setState(() {});
              },
            ),
          ),
          // Member list
          Expanded(
            child: Consumer<MemberProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) return const Center(child: CircularProgressIndicator());
                final members = provider.members;
                if (members.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline_rounded, size: 56, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text('belum_ada_member_terdaftar_187'.tr(context: context), style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('tap_untuk_menambah_member_188'.tr(context: context), style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 12)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => provider.fetchMembers(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                    itemCount: members.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return Dismissible(
                        key: ValueKey(member.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.delete_rounded, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: Text('hapus_member_186'.tr(context: context)),
                              content: Text('delete_member_confirm'.tr(context: context, args: [member.name])),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: Text('batal_5'.tr(context: context))),
                                FilledButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
                                  child: Text('hapus_88'.tr(context: context)),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) => provider.deleteMember(member.id),
                        child: _buildMemberCard(theme, member),
                      ).animate().fade(delay: Duration(milliseconds: 40 * index)).slideX(begin: 0.02);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(ThemeData theme, MemberModel member) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _showMemberDetail(member),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                  child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              member.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              member.memberCode,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.phone_rounded, size: 13, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            member.phone,
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          if (context.watch<AuthProvider>().isPointsEnabled) ...[
                            Icon(Icons.stars_rounded, size: 14, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              '${member.points} poin',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Icon(Icons.shopping_bag_outlined, size: 13, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            '${member.totalTransactions}x',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Rp ${widget.currencyFormat.format(member.totalSpend)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================
// TAB 2: Promo Member
// ============================
class _PromoListTab extends StatelessWidget {
  final NumberFormat currencyFormat;
  const _PromoListTab({required this.currencyFormat});

  void _showCreatePromoDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final minPurchaseCtrl = TextEditingController(text: '0');
    String discountType = 'percent';
    final selectedProductIds = <int>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final bottomPadding = MediaQuery.of(ctx).viewInsets.bottom;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final products = context.read<ProductProvider>().products;
            return Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
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
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text('buat_promo_member_189'.tr(context: context), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Promo *', prefixIcon: Icon(Icons.local_offer_rounded))),
                    const SizedBox(height: 12),
                    TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Deskripsi', prefixIcon: Icon(Icons.description_rounded)), maxLines: 2),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: discountType,
                      decoration: const InputDecoration(labelText: 'Tipe Diskon', prefixIcon: Icon(Icons.category_rounded)),
                      items: [
                        DropdownMenuItem(value: 'percent', child: Text('persentase_190'.tr(context: context))),
                        DropdownMenuItem(value: 'nominal', child: Text('potongan_nominal_rp_191'.tr(context: context))),
                        DropdownMenuItem(value: 'fixed_price', child: Text('harga_tetap_rp_192'.tr(context: context))),
                      ],
                      onChanged: (val) => setModalState(() => discountType = val ?? 'percent'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: valueCtrl,
                      decoration: InputDecoration(
                        labelText: discountType == 'percent' ? 'Nilai Diskon (%)' : 'Nilai (Rp)',
                        prefixIcon: const Icon(Icons.discount_rounded),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: minPurchaseCtrl,
                      decoration: const InputDecoration(labelText: 'Min. Pembelian (Rp)', prefixIcon: Icon(Icons.money_rounded)),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Text('pilih_produk_berlaku_193'.tr(context: context), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (products.isEmpty)
                      Text('belum_ada_produk_169'.tr(context: context), style: TextStyle(color: theme.colorScheme.onSurfaceVariant))
                    else
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: products.length,
                          itemBuilder: (_, i) {
                            final p = products[i];
                            final isChecked = selectedProductIds.contains(p.id);
                            return CheckboxListTile(
                              value: isChecked,
                              activeColor: theme.colorScheme.primary,
                              onChanged: (val) {
                                setModalState(() {
                                  if (val == true) {
                                    selectedProductIds.add(p.id);
                                  } else {
                                    selectedProductIds.remove(p.id);
                                  }
                                });
                              },
                              title: Text(p.name, style: const TextStyle(fontSize: 13)),
                              subtitle: Text('Rp ${currencyFormat.format(p.price)}', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () async {
                          if (nameCtrl.text.trim().isEmpty || valueCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('nama_dan_nilai_diskon_194'.tr(context: context))));
                            return;
                          }
                          if (selectedProductIds.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('pilih_minimal_satu_produk_195'.tr(context: context))));
                            return;
                          }
                          final success = await context.read<MemberPromoProvider>().createPromo(
                            name: nameCtrl.text.trim(),
                            description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                            discountType: discountType,
                            discountValue: double.tryParse(valueCtrl.text) ?? 0.0,
                            minPurchase: double.tryParse(minPurchaseCtrl.text) ?? 0.0,
                            productIds: selectedProductIds.toList(),
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('promo_berhasil_dibuat_196'.tr(context: context)),
                                backgroundColor: theme.colorScheme.primary,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.save_rounded),
                        label: Text('simpan_promo_197'.tr(context: context)),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePromoDialog(context),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded),
        label: Text('buat_promo_198'.tr(context: context), style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Consumer<MemberPromoProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          final promos = provider.promos;
          if (promos.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_offer_outlined, size: 56, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text('belum_ada_promo_member_199'.tr(context: context), style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('buat_promo_khusus_untuk_200'.tr(context: context), style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 12)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.fetchPromos(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              itemCount: promos.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final promo = promos[index];
                return Dismissible(
                  key: ValueKey(promo.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.delete_rounded, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: Text('hapus_promo_201'.tr(context: context)),
                        content: Text('Yakin ingin menghapus promo "${promo.name}"?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('batal_5'.tr(context: context))),
                          FilledButton(
                            onPressed: () => Navigator.pop(c, true),
                            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
                            child: Text('hapus_88'.tr(context: context)),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) => provider.deletePromo(promo.id),
                  child: _buildPromoCard(theme, promo),
                ).animate().fade(delay: Duration(milliseconds: 40 * index)).slideX(begin: 0.02);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPromoCard(ThemeData theme, MemberPromoModel promo) {
    String discountLabel;
    if (promo.discountType == 'percent') {
      discountLabel = '${promo.discountValue.toStringAsFixed(0)}%';
    } else if (promo.discountType == 'nominal') {
      discountLabel = 'Rp ${currencyFormat.format(promo.discountValue)}';
    } else {
      discountLabel = 'Rp ${currencyFormat.format(promo.discountValue)} (harga tetap)';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.local_offer_rounded, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      promo.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (promo.description != null && promo.description!.isNotEmpty)
                      Text(
                        promo.description!,
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: promo.isActive ? theme.colorScheme.primary.withValues(alpha: 0.12) : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  promo.isActive ? 'Aktif' : 'Nonaktif',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: promo.isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _promoChip(theme, Icons.discount_rounded, discountLabel),
              _promoChip(theme, Icons.inventory_2_rounded, '${promo.productIds.length} produk'),
              if (promo.minPurchase > 0)
                _promoChip(theme, Icons.money_rounded, 'Min. Rp ${currencyFormat.format(promo.minPurchase)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _promoChip(ThemeData theme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
