import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branch_provider.dart';
import '../../theme/app_colors.dart';
import 'branch_form_screen.dart';
import '../../widgets/zenvi_header.dart';

class BranchListScreen extends StatefulWidget {
  const BranchListScreen({super.key});

  @override
  State<BranchListScreen> createState() => _BranchListScreenState();
}

class _BranchListScreenState extends State<BranchListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        context.read<BranchProvider>().fetchBranches(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<BranchProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          ZenviHeader.sliver(
            title: 'kelola_cabang_13'.tr(context: context),
            showBackButton: true,
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Header Toko
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.business_rounded, color: theme.colorScheme.primary, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('nama_toko_utama_374'.tr(context: context), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Consumer<AuthProvider>(
                              builder: (context, auth, _) {
                                final companyName = auth.user?.company?['name'] ?? 'toko_belum_dinamai_18'.tr(context: context);
                                final storeCode = auth.user?.company?['code']?.toString() ?? 'znv8829_8'.tr(context: context);
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      companyName, 
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                    ),
                                    const SizedBox(height: 6),
                                    InkWell(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: storeCode));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('store_code_copied'.tr(context: context, args: [storeCode])),
                                            duration: const Duration(seconds: 2),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.qr_code_2_rounded, size: 14, color: theme.colorScheme.primary),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Kode: $storeCode',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                letterSpacing: 0.8,
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(Icons.copy_rounded, size: 12, color: theme.colorScheme.primary),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onSelected: (value) {
                          final auth = context.read<AuthProvider>();
                          final storeCode = auth.user?.company?['code']?.toString() ?? 'znv8829_8'.tr(context: context);
                          
                          if (value == 'copy_code') {
                            Clipboard.setData(ClipboardData(text: storeCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('store_code_copied'.tr(context: context, args: [storeCode])),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else if (value == 'edit') {
                            final currentName = auth.user?.company?['name'] ?? '';
                            final controller = TextEditingController(text: currentName);
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('edit_nama_toko_375'.tr(context: context)),
                                content: TextField(
                                  controller: controller,
                                  decoration: InputDecoration(
                                    labelText: 'store_name_label'.tr(context: context),
                                    border: const OutlineInputBorder(),
                                  ),
                                  autofocus: true,
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text('batal_5'.tr(context: context))),
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (controller.text.trim().isNotEmpty) {
                                        Navigator.pop(ctx);
                                        await auth.updateCompanyName(controller.text.trim());
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('nama_toko_diperbarui_376'.tr(context: context))));
                                        }
                                      }
                                    },
                                    child: Text('simpan_6'.tr(context: context)),
                                  ),
                                ],
                              ),
                            );
                          } else if (value == 'add') {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const BranchFormScreen()));
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'copy_code',
                            child: Row(
                              children: [
                                const Icon(Icons.copy_rounded, size: 20),
                                const SizedBox(width: 12),
                                Text('salin_kode_toko_377'.tr(context: context)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined, size: 20),
                                const SizedBox(width: 12),
                                Text('edit_nama_toko_375'.tr(context: context)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'add',
                            child: Row(
                              children: [
                                const Icon(Icons.add_circle_outline, size: 20),
                                const SizedBox(width: 12),
                                Text('tambah_cabang_378'.tr(context: context)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Store Code Banner for Owner
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    final storeCode = auth.user?.company?['code']?.toString() ?? 'znv8829_8'.tr(context: context);
                    return Container(
                      margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
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
                                  'store_code_for_employees'.tr(context: context),
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
                    );
                  },
                ),
              ],
            ),
          ),
          
          // List Cabang
          if (provider.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (provider.branches.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.storefront, size: 64, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text(
                      'no_branches_yet'.tr(context: context),
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final branch = provider.branches[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(20),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.store_mall_directory_rounded, color: theme.colorScheme.primary),
                        ),
                        title: Text(branch.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text('attendance_radius'.tr(context: context, args: [branch.radiusMeters.toString()])),
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          onSelected: (value) async {
                            if (value == 'edit') {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => BranchFormScreen(branch: branch)));
                            } else if (value == 'delete') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text('hapus_cabang_381'.tr(context: context)),
                                  content: Text('delete_branch_confirm'.tr(context: context, args: [branch.name])),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('batal_5'.tr(context: context))),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true), 
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerText, foregroundColor: Colors.white),
                                      child: Text('hapus_88'.tr(context: context)),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (confirm == true && context.mounted) {
                                final token = context.read<AuthProvider>().token!;
                                await provider.deleteBranch(token, branch.id);
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit_outlined, size: 20),
                                  const SizedBox(width: 12),
                                  Text('edit_118'.tr(context: context)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_outline, color: AppColors.dangerText, size: 20),
                                  const SizedBox(width: 12),
                                  Text('hapus_88'.tr(context: context), style: const TextStyle(color: AppColors.dangerText)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: provider.branches.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
