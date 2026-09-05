import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/branch_model.dart';
import '../../models/ingredient_model.dart';
import '../../providers/branch_provider.dart';
import '../../providers/ingredient_provider.dart';
import '../../providers/stock_management_provider.dart';
import '../../widgets/zenvi_header.dart';

/// Memindahkan stok bahan baku antar cabang (paket Bisnis).
///
/// Layar ini tidak melakukan pemeriksaan izin sendiri: server yang memutuskan,
/// dan balasan 403 bertipe diubah ApiClient jadi tawaran upgrade. Yang dicegah
/// di sini hanya hal-hal yang jelas keliru sebelum permintaan dikirim - cabang
/// asal sama dengan tujuan, atau kolom yang belum terisi.
class StockTransferScreen extends StatefulWidget {
  const StockTransferScreen({super.key});

  @override
  State<StockTransferScreen> createState() => _StockTransferScreenState();
}

class _StockTransferScreenState extends State<StockTransferScreen> {
  IngredientModel? _ingredient;
  int? _fromBranchId;
  int? _toBranchId;
  final _qtyController = TextEditingController();
  final _notesController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IngredientProvider>().fetchIngredients();
      final token = context.read<BranchProvider>();
      if (token.branches.isEmpty) token.fetchBranches('');
    });
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final qty = double.tryParse(_qtyController.text.replaceAll(',', '.')) ?? 0;

    if (_ingredient == null || _fromBranchId == null || _toBranchId == null || qty <= 0) {
      _snack('transfer_pick_all'.tr(context: context));
      return;
    }
    if (_fromBranchId == _toBranchId) {
      _snack('transfer_same_branch'.tr(context: context));
      return;
    }

    setState(() => _submitting = true);
    final provider = context.read<StockManagementProvider>();
    final ok = await provider.transfer(
      ingredientId: _ingredient!.id,
      fromBranchId: _fromBranchId!,
      toBranchId: _toBranchId!,
      qty: qty,
      notes: _notesController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      _snack('transfer_success'.tr(context: context));
      Navigator.pop(context, true);
    } else if (provider.lastErrorMessage.isNotEmpty) {
      // Kosong berarti ApiClient sudah menampilkan tawaran upgrade; menimpanya
      // dengan snackbar error hanya membingungkan.
      _snack(provider.lastErrorMessage);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final branches = context.watch<BranchProvider>().branches;
    final ingredients = context.watch<IngredientProvider>().ingredients;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ZenviHeader(
              title: 'stock_transfer_title'.tr(context: context),
              subtitle: 'stock_transfer_desc'.tr(context: context),
              showBackButton: true,
            ),
            Expanded(
              child: branches.length < 2
                  ? _buildNeedBranches(theme)
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _label(theme, 'transfer_ingredient'.tr(context: context)),
                        DropdownButtonFormField<IngredientModel>(
                          initialValue: _ingredient,
                          isExpanded: true,
                          decoration: _decoration(theme),
                          items: ingredients
                              .map((i) => DropdownMenuItem(
                                    value: i,
                                    child: Text('${i.name} (${i.unit})',
                                        overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _ingredient = v),
                        ),
                        const SizedBox(height: 18),
                        _label(theme, 'transfer_from_branch'.tr(context: context)),
                        _branchDropdown(theme, branches, _fromBranchId,
                            (v) => setState(() => _fromBranchId = v)),
                        const SizedBox(height: 18),
                        _label(theme, 'transfer_to_branch'.tr(context: context)),
                        _branchDropdown(theme, branches, _toBranchId,
                            (v) => setState(() => _toBranchId = v)),
                        const SizedBox(height: 18),
                        _label(theme, 'transfer_qty'.tr(context: context)),
                        TextField(
                          controller: _qtyController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: _decoration(theme).copyWith(
                            suffixText: _ingredient?.unit ?? '',
                          ),
                        ),
                        const SizedBox(height: 18),
                        _label(theme, 'transfer_notes'.tr(context: context)),
                        TextField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: _decoration(theme),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: _submitting ? null : _submit,
                            icon: _submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.swap_horiz_rounded),
                            label: Text('transfer_submit'.tr(context: context)),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Transfer tidak masuk akal dengan satu cabang, jadi lebih baik menjelaskan
  /// alasannya daripada menampilkan formulir yang pasti gagal.
  Widget _buildNeedBranches(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_rounded,
                size: 44, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 14),
            Text(
              'transfer_need_branches'.tr(context: context),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _branchDropdown(ThemeData theme, List<BranchModel> branches, int? value,
      ValueChanged<int?> onChanged) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: _decoration(theme),
      items: branches
          .map((b) => DropdownMenuItem(
                value: b.id,
                child: Text(b.name, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _label(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
      );

  InputDecoration _decoration(ThemeData theme) => InputDecoration(
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}
