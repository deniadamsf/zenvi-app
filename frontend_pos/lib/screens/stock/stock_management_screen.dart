import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ingredient_provider.dart';
import '../../providers/stock_management_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branch_provider.dart';
import 'stock_history_screen.dart';
import '../../widgets/zenvi_header.dart';
import 'stock_transfer_screen.dart';
import '../../theme/app_colors.dart';

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
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
        Provider.of<IngredientProvider>(context, listen: false).fetchIngredients();
      } else {
        _selectedBranchId = auth.user?.branchId;
        Provider.of<IngredientProvider>(context, listen: false).fetchIngredients(branchId: _selectedBranchId);
      }
    });
  }

  void _onBranchChanged(int? branchId) {
    setState(() {
      _selectedBranchId = branchId;
    });
    Provider.of<IngredientProvider>(context, listen: false).fetchIngredients(branchId: branchId);
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final unitController = TextEditingController();
    final stockController = TextEditingController();
    final priceController = TextEditingController(text: '0');
    final toleranceController = TextEditingController(text: '0');
    int? addBranchId = _selectedBranchId;

    final branches = Provider.of<BranchProvider>(context, listen: false).branches;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              title: Text('tambah_bahan_baku_114'.tr(context: context)),
              content: SingleChildScrollView(
                child: Column(
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: 'stok_awal_9'.tr(context: context)),
                    ),
                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: 'total_harga_beli_awal_26'.tr(context: context)),
                    ),
                    TextField(
                      controller: toleranceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: 'toleransi_susut_19'.tr(context: context)),
                    ),
                    if (branches.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int?>(
                        initialValue: addBranchId,
                        decoration: InputDecoration(labelText: 'stock_location_label'.tr(context: context)),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text('all_branches'.tr(context: context)),
                          ),
                          ...branches.map((b) => DropdownMenuItem<int?>(
                            value: b.id,
                            child: Text(b.name),
                          )),
                        ],
                        onChanged: (val) {
                          setModalState(() {
                            addBranchId = val;
                          });
                        },
                      ),
                    ],
                  ],
                ),
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
                    final price = double.tryParse(priceController.text) ?? 0.0;
                    
                    final success = await prov.addIngredient(
                      nameController.text, 
                      unitController.text, 
                      qty,
                      tolerancePercent: tolerance,
                      price: price,
                      branchId: addBranchId,
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
          },
        );
      }
    );
  }

  void _showActionDialog(String type, int ingredientId, String ingredientName) {
    final qtyController = TextEditingController();
    final priceController = TextEditingController();
    final notesController = TextEditingController();
    final theme = Theme.of(context);
    
    final branches = Provider.of<BranchProvider>(context, listen: false).branches;
    int? actionBranchId = _selectedBranchId ?? (branches.isNotEmpty ? branches.first.id : null);

    String title = '';
    String qtyLabel = '';
    if (type == 'restock') {
      title = 'dialog_restock_title'.tr(context: context, args: [ingredientName]);
      qtyLabel = 'restock_qty_label'.tr(context: context);
    } else if (type == 'wastage') {
      title = 'dialog_wastage_title'.tr(context: context, args: [ingredientName]);
      qtyLabel = 'wastage_qty_label'.tr(context: context);
    } else if (type == 'opname') {
      title = 'dialog_opname_title'.tr(context: context, args: [ingredientName]);
      qtyLabel = 'opname_qty_label'.tr(context: context);
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (branches.isNotEmpty && Provider.of<AuthProvider>(context, listen: false).isOwner) ...[
                      DropdownButtonFormField<int?>(
                        initialValue: actionBranchId,
                        decoration: InputDecoration(labelText: 'stock_location_label'.tr(context: context)),
                        items: branches.map((b) => DropdownMenuItem<int?>(
                          value: b.id,
                          child: Text(b.name),
                        )).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            actionBranchId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: qtyController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: qtyLabel),
                    ),
                    if (type == 'restock')
                      TextField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: 'total_price_rp_label'.tr(context: context)),
                      ),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(labelText: 'notes_optional_label'.tr(context: context)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text('batal_5'.tr(context: context)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final qty = double.tryParse(qtyController.text);
                    if (qty == null || qty < 0) return;

                    double price = 0.0;
                    if (type == 'restock') {
                      price = double.tryParse(priceController.text) ?? 0.0;
                      if (price <= 0) {
                        if (dialogCtx.mounted) {
                          ScaffoldMessenger.of(dialogCtx).showSnackBar(
                            SnackBar(content: Text('harga_tidak_boleh_kosong_458'.tr(context: context))),
                          );
                        }
                        return;
                      }
                    }

                    final prov = Provider.of<StockManagementProvider>(dialogCtx, listen: false);
                    bool success = false;
                    
                    if (type == 'restock') {
                      success = await prov.restock(ingredientId, qty, price, notesController.text, branchId: actionBranchId);
                    } else if (type == 'wastage') {
                      success = await prov.wastage(ingredientId, qty, notesController.text, branchId: actionBranchId);
                    } else if (type == 'opname') {
                      success = await prov.opname(ingredientId, qty, notesController.text, branchId: actionBranchId);
                    }

                    if (dialogCtx.mounted) {
                      Navigator.pop(dialogCtx);
                    }
                    if (mounted) {
                      if (success) {
                        Provider.of<IngredientProvider>(context, listen: false).fetchIngredients(branchId: _selectedBranchId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('type_processed_success'.tr(context: context, args: [type]))),
                        );
                      } else {
                        final err = prov.lastErrorMessage.isNotEmpty ? prov.lastErrorMessage : 'failed_process_type'.tr(context: context, args: [type]);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(err),
                            backgroundColor: AppColors.dangerFill,
                          ),
                        );
                      }
                    }
                  },
                  child: Text('simpan_6'.tr(context: context)),
                ),
              ],
            );
          },
        );
      }
    );
  }


  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<IngredientProvider>(context);
    final theme = Theme.of(context);
    final fraudItems = provider.ingredients.where((i) => i.stockQty < 0).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          'bahan_baru_459'.tr(context: context),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.2),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
            ZenviHeader.sliver(
              title: 'manajemen_stok_14'.tr(context: context),
              showBackButton: true,
              actions: [
                // Transfer antar cabang: fitur paket Bisnis. Ditampilkan untuk
                // semua paket - server yang menolak, dan ApiClient mengubah
                // penolakan itu jadi tawaran upgrade. Menyembunyikannya berarti
                // pemilik satu toko tidak pernah tahu fiturnya ada.
                IconButton(
                  icon: Icon(Icons.swap_horiz_rounded, color: theme.colorScheme.primary, size: 22),
                  tooltip: 'stock_transfer_title'.tr(context: context),
                  onPressed: () async {
                    final changed = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StockTransferScreen()),
                    );
                    if (changed == true && context.mounted) {
                      Provider.of<IngredientProvider>(context, listen: false)
                          .fetchIngredients(branchId: _selectedBranchId);
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.history, color: theme.colorScheme.primary, size: 22),
                  tooltip: 'stock_history_tooltip'.tr(context: context),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StockHistoryScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: theme.colorScheme.primary, size: 22),
                  tooltip: 'refresh_tooltip'.tr(context: context),
                  onPressed: () => Provider.of<IngredientProvider>(context, listen: false).fetchIngredients(branchId: _selectedBranchId),
                ),
              ],
            ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                // Branch Selector for Owner or Info for Employee
                Consumer2<AuthProvider, BranchProvider>(
                  builder: (context, auth, branchProv, child) {
                    if (auth.isOwner && branchProv.branches.isNotEmpty) {
                      return Container(
                        height: 48,
                        margin: const EdgeInsets.only(top: 8, bottom: 8),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text('all_branches'.tr(context: context)),
                                selected: _selectedBranchId == null,
                                onSelected: (_) => _onBranchChanged(null),
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
                                onSelected: (_) => _onBranchChanged(b.id),
                                selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                                checkmarkColor: theme.colorScheme.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            )),
                          ],
                        ),
                      );
                    } else if (!auth.isOwner && auth.user?.branchName != null) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.storefront_rounded, color: theme.colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'branch_locked_notice'.tr(context: context, args: [auth.user!.branchName!]),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                Consumer<AuthProvider>(
                  builder: (_, auth, child) {
                    if (!auth.isOwner) return const SizedBox.shrink();
                    final requireOpname = auth.user?.company?['require_opname_on_shift_close'] == 1 || 
                                          auth.user?.company?['require_opname_on_shift_close'] == true;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SwitchListTile(
                          title: Text('wajibkan_opname_saat_tutup_461'.tr(context: context), style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('karyawan_harus_mengisi_stok_462'.tr(context: context)),
                          value: requireOpname,
                          activeThumbColor: theme.colorScheme.primary,
                          onChanged: (val) async {
                            final successMsg = 'settings_saved'.tr(context: context);
                            final failMsg = 'settings_failed'.tr(context: context);
                            final sm = ScaffoldMessenger.of(context);
                            final success = await auth.updateCompanySetting(requireOpname: val);
                            if (mounted) {
                              sm.showSnackBar(
                                SnackBar(content: Text(success ? successMsg : failMsg)),
                              );
                            }
                          },
                        ),
                        const Divider(),
                      ],
                    );
                  },
                ),
                if (fraudItems.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.dangerSoft,
                      border: Border.all(color: AppColors.dangerFill),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.dangerFill, size: 40),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'fraud_warning_title'.tr(context: context),
                                style: const TextStyle(color: AppColors.dangerText, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'fraud_warning_desc'.tr(context: context, args: [fraudItems.length.toString()]),
                                style: TextStyle(color: AppColors.dangerText, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = provider.ingredients[index];
                      final isMinus = item.stockQty < 0;
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMinus ? AppColors.dangerFill.withValues(alpha: 0.05) : theme.colorScheme.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isMinus ? AppColors.dangerFill.withValues(alpha: 0.3) : theme.colorScheme.outline.withValues(alpha: 0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Theme(
                          data: theme.copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isMinus ? AppColors.dangerFill.withValues(alpha: 0.1) : theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.inventory_2_rounded, color: isMinus ? AppColors.dangerFill : theme.colorScheme.primary),
                            ),
                            title: Text(item.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: isMinus ? AppColors.dangerText : null)),
                            subtitle: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    color: isMinus ? AppColors.dangerFill.withValues(alpha: 0.1) : theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${NumberFormat.decimalPattern('id').format(item.stockQty)} ${item.unit}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isMinus ? AppColors.dangerText : theme.colorScheme.onSecondaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (item.branchName != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    margin: const EdgeInsets.only(top: 4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.branchName!,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'tolerance_label'.tr(context: context, args: [item.tolerancePercent.toString()]),
                                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Row(
                                  children: [
                                    _buildStockActionButton(
                                      context: context,
                                      label: 'restock_464'.tr(context: context),
                                      icon: Icons.add_shopping_cart_rounded,
                                      color: AppColors.successFill,
                                      onTap: () => _showActionDialog('restock', item.id, item.name),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildStockActionButton(
                                      context: context,
                                      label: 'opname_465'.tr(context: context),
                                      icon: Icons.fact_check_rounded,
                                      color: theme.colorScheme.primary,
                                      onTap: () => _showActionDialog('opname', item.id, item.name),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildStockActionButton(
                                      context: context,
                                      label: 'wastage_466'.tr(context: context),
                                      icon: Icons.delete_outline_rounded,
                                      color: AppColors.dangerFill,
                                      onTap: () => _showActionDialog('wastage', item.id, item.name),
                                    ),
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
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 88),
                  ),
                ],
              ),
    );
  }

  Widget _buildStockActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


