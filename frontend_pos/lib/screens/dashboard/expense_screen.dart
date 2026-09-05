import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/ingredient_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/zenvi_header.dart';
import '../../theme/app_colors.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _qtyController = TextEditingController();

  String _expenseType = 'ingredient_restock';
  int? _selectedIngredientId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExpenseProvider>(context, listen: false).fetchExpenses();
      Provider.of<IngredientProvider>(context, listen: false).fetchIngredients();
    });
  }

  void _showAddExpenseSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (builderCtx, setDialogState) {
            final ingredientProvider = Provider.of<IngredientProvider>(builderCtx);
            final theme = Theme.of(builderCtx);
            
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(builderCtx).viewInsets.bottom + 24),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2))
                    )
                  ),
                  const SizedBox(height: 24),
                  Text('catat_pengeluaran_baru_97'.tr(context: context), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _expenseType,
                            decoration: InputDecoration(
                              labelText: 'jenis_pengeluaran_17'.tr(context: context),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                            ),
                            items: [
                              DropdownMenuItem(value: 'ingredient_restock', child: Text('order_bahan_restock_98'.tr(context: context))),
                              if (Provider.of<AuthProvider>(builderCtx, listen: false).isOwner)
                                DropdownMenuItem(value: 'salary', child: Text('gaji_karyawan_99'.tr(context: context))),
                              DropdownMenuItem(value: 'operational', child: Text('operasional_lainnya_100'.tr(context: context))),
                            ],
                            onChanged: (val) {
                              setDialogState(() {
                                _expenseType = val!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          if (_expenseType == 'ingredient_restock') ...[
                            DropdownButtonFormField<int>(
                              decoration: InputDecoration(
                                labelText: 'pilih_bahan_baku_16'.tr(context: context),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                              ),
                              initialValue: _selectedIngredientId,
                              items: ingredientProvider.ingredients.map((ing) {
                                return DropdownMenuItem<int>(
                                  value: ing.id,
                                  child: Text('${ing.name} (${ing.unit})'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setDialogState(() {
                                  _selectedIngredientId = val;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _qtyController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Jumlah Kuantitas (Stok Bertambah)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
      
                          TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Total Biaya (Rp)', 
                              prefixText: 'rp_3'.tr(context: context),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _descController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Keterangan (Opsional)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final provider = Provider.of<ExpenseProvider>(builderCtx, listen: false);
                      final amount = double.tryParse(_amountController.text) ?? 0;
                      
                      if (amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('total_biaya_tidak_valid_101'.tr(context: context))));
                        return;
                      }
      
                      double? qty;
                      if (_expenseType == 'ingredient_restock') {
                        if (_selectedIngredientId == null) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('pilih_bahan_baku_102'.tr(context: context))));
                           return;
                        }
                        qty = double.tryParse(_qtyController.text) ?? 0;
                        if (qty <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('kuantitas_tidak_valid_103'.tr(context: context))));
                          return;
                        }
                      }
      
                      final success = await provider.addExpense(
                        expenseType: _expenseType,
                        amount: amount,
                        description: _descController.text.isNotEmpty ? _descController.text : null,
                        ingredientId: _selectedIngredientId,
                        qtyAdded: qty,
                      );
      
                      if (success) {
                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('pengeluaran_berhasil_dicatat_104'.tr(context: context))));
                        }
                        // Reset forms
                        _amountController.clear();
                        _descController.clear();
                        _qtyController.clear();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    child: Text('simpan_pengeluaran_105'.tr(context: context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseSheet,
        icon: const Icon(Icons.money_off),
        label: Text('catat_pengeluaran_106'.tr(context: context)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          ZenviHeader.sliver(
            title: 'Catatan Pengeluaran',
            showBackButton: true,
          ),
          
          Builder(
            builder: (context) {
              final isOwner = Provider.of<AuthProvider>(context, listen: false).isOwner;
              final visibleExpenses = isOwner 
                  ? provider.expenses 
                  : provider.expenses.where((e) => e.expenseType != 'salary').toList();

              if (provider.isLoading) {
                 return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }

              if (visibleExpenses.isEmpty) {
                return SliverFillRemaining(child: Center(child: Text('belum_ada_pengeluaran_tercatat_108'.tr(context: context))));
              }

              return SliverPadding(
                padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                    final exp = visibleExpenses[index];
                    IconData icon;
                    Color color;
                    String titleStr;
                    
                    final theme = Theme.of(context);

                    if (exp.expenseType == 'ingredient_restock') {
                      icon = Icons.inventory_2_rounded;
                      color = Colors.orange;
                      titleStr = 'Restock Bahan';
                    } else if (exp.expenseType == 'salary') {
                      icon = Icons.payments_rounded;
                      color = Colors.purple;
                      titleStr = 'Gaji Karyawan';
                    } else {
                      icon = Icons.receipt_long_rounded;
                      color = Colors.blueGrey;
                      titleStr = 'Lainnya';
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                        boxShadow: [
                          BoxShadow(color: theme.shadowColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                        ]
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  titleStr,
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                if (exp.description != null)
                                  Text(
                                    exp.description!,
                                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                Text(
                                  'Oleh: ${exp.userName} • ${exp.createdAt.toLocal().toString().split('.')[0]}',
                                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '- Rp ${exp.amount.toStringAsFixed(0)}',
                            style: const TextStyle(color: AppColors.dangerText, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: visibleExpenses.length,
                ),
              ),
            );
          },
        ),
      ],
      ),
    );
  }
}

