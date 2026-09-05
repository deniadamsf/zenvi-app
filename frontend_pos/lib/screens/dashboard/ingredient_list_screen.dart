import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ingredient_provider.dart';
import '../../widgets/zenvi_header.dart';
import '../../theme/app_colors.dart';

class IngredientListScreen extends StatefulWidget {
  const IngredientListScreen({super.key});

  @override
  State<IngredientListScreen> createState() => _IngredientListScreenState();
}

class _IngredientListScreenState extends State<IngredientListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<IngredientProvider>(context, listen: false).fetchIngredients();
    });
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final unitController = TextEditingController();
    final stockController = TextEditingController();
    final toleranceController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text('tambah_bahan_baku_114'.tr(context: context)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'nama_bahan_misal_gula_24'.tr(context: context)),
              ),
              TextField(
                controller: unitController,
                decoration: InputDecoration(labelText: 'satuan_misal_gram_ml_29'.tr(context: context)),
              ),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'stok_awal_9'.tr(context: context)),
              ),
              TextField(
                controller: toleranceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'toleransi_susut_19'.tr(context: context)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('batal_5'.tr(context: context)),
            ),
            ElevatedButton(
              onPressed: () async {
                final prov = Provider.of<IngredientProvider>(dialogCtx, listen: false);
                final qty = double.tryParse(stockController.text) ?? 0.0;
                final tolerance = double.tryParse(toleranceController.text) ?? 0.0;
                
                final success = await prov.addIngredient(
                  nameController.text, 
                  unitController.text, 
                  qty,
                  tolerancePercent: tolerance,
                );
                
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                }
                if (mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('bahan_baku_ditambahkan_115'.tr(context: context))),
                  );
                }
              },
              child: Text('simpan_6'.tr(context: context)),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<IngredientProvider>(context);
    final fraudItems = provider.ingredients.where((i) => i.stockQty < 0).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.add_rounded),
      ),
      body: provider.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              ZenviHeader.sliver(
                title: 'manajemen_bahan_15'.tr(context: context),
                showBackButton: true,
              ),
              if (fraudItems.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.dangerSoft,
                      border: Border.all(color: AppColors.dangerFill),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppColors.dangerFill, size: 40),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'peringatan_indikasi_fraud_26'.tr(context: context),
                                style: TextStyle(color: AppColors.dangerText, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Terdapat ${fraudItems.length} bahan baku dengan stok minus.',
                                style: TextStyle(color: AppColors.dangerText, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = provider.ingredients[index];
                      final isMinus = item.stockQty < 0;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isMinus ? AppColors.dangerSoft : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isMinus ? AppColors.dangerFill : theme.colorScheme.outline.withValues(alpha: 0.1),
                            width: isMinus ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMinus ? AppColors.dangerFill.withValues(alpha: 0.1) : theme.colorScheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.kitchen_rounded, color: isMinus ? AppColors.dangerFill : theme.colorScheme.primary),
                          ),
                          title: Text(
                            item.name,
                            style: TextStyle(fontWeight: FontWeight.bold, color: isMinus ? AppColors.dangerText : null)
                          ),
                          subtitle: Text(
                            'Sisa Stok: ${item.stockQty} ${item.unit}',
                            style: TextStyle(
                              color: isMinus ? AppColors.dangerText : theme.colorScheme.onSurfaceVariant,
                              fontWeight: isMinus ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert_rounded, color: theme.colorScheme.onSurfaceVariant),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            onSelected: (value) {
                              if (value == 'edit') {
                                // Edit not implemented yet
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
                                    const Icon(Icons.delete_outline_rounded, color: AppColors.dangerText, size: 20),
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
                    childCount: provider.ingredients.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
    );
  }
}

