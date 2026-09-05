import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/stock_management_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branch_provider.dart';
import '../../widgets/zenvi_header.dart';
import '../../theme/app_colors.dart';

class StockHistoryScreen extends StatefulWidget {
  const StockHistoryScreen({super.key});

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen> {
  int? _selectedBranchId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isOwner) {
        if (auth.token != null) {
          Provider.of<BranchProvider>(context, listen: false).fetchBranches(auth.token!);
        }
        context.read<StockManagementProvider>().fetchHistory();
      } else {
        _selectedBranchId = auth.user?.branchId;
        context.read<StockManagementProvider>().fetchHistory(branchId: _selectedBranchId);
      }
    });
  }

  void _onBranchFilterChanged(int? branchId) {
    setState(() {
      _selectedBranchId = branchId;
    });
    context.read<StockManagementProvider>().fetchHistory(branchId: branchId);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StockManagementProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: ZenviHeader(
        title: 'riwayat_stok_opname_455'.tr(context: context),
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Branch Filter Chips for Owner
          Consumer2<AuthProvider, BranchProvider>(
            builder: (context, auth, branchProv, child) {
              if (auth.isOwner && branchProv.branches.isNotEmpty) {
                return Container(
                  height: 48,
                  margin: const EdgeInsets.only(top: 8, bottom: 4),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('all_branches'.tr(context: context)),
                          selected: _selectedBranchId == null,
                          onSelected: (_) => _onBranchFilterChanged(null),
                          selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                          checkmarkColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                      ...branchProv.branches.map((b) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(b.name),
                          selected: _selectedBranchId == b.id,
                          onSelected: (_) => _onBranchFilterChanged(b.id),
                          selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                          checkmarkColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      )),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.histories.isEmpty
                    ? Center(child: Text('belum_ada_riwayat_stok_456'.tr(context: context)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.histories.length,
                        itemBuilder: (context, index) {
                          final item = provider.histories[index];
                          final isSuspicious = item.isSuspicious;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: isSuspicious ? AppColors.dangerSoft : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: isSuspicious ? BorderSide(color: AppColors.dangerFill, width: 2) : BorderSide.none,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.ingredientName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: isSuspicious ? AppColors.dangerText : null,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: item.qtyChange > 0 ? AppColors.successSoft : AppColors.dangerSoft,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${item.qtyChange > 0 ? '+' : ''}${item.qtyChange} ${item.ingredientUnit}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: item.qtyChange > 0 ? AppColors.successText : AppColors.dangerText,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 4,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.person, size: 14, color: theme.colorScheme.onSurfaceVariant),
                                          const SizedBox(width: 4),
                                          Text(item.userName, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                                        ],
                                      ),
                                      if (item.branchName != null)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.storefront_rounded, size: 14, color: theme.colorScheme.primary),
                                            const SizedBox(width: 4),
                                            Text(
                                              item.branchName!,
                                              style: TextStyle(
                                                color: theme.colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.access_time, size: 14, color: theme.colorScheme.onSurfaceVariant),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat('dd MMM yyyy, HH:mm').format(item.createdAt.toLocal()),
                                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'type_label_prefix'.tr(context: context, args: [item.type.toUpperCase()]),
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.indigo.shade700),
                                  ),
                                  if (item.notes.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text('notes_label_prefix'.tr(context: context, args: [item.notes]), style: const TextStyle(fontSize: 13)),
                                  ],
                                  if (isSuspicious) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.warning_rounded, color: AppColors.dangerText, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          'exceeds_tolerance_limit'.tr(context: context),
                                          style: TextStyle(color: AppColors.dangerText, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
