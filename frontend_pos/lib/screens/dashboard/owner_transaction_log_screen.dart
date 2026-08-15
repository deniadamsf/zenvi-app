import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branch_provider.dart';
import '../../models/order_model.dart';
import '../pos/widgets/receipt_widget.dart';
import '../../widgets/zenvi_header.dart';

class OwnerTransactionLogScreen extends StatefulWidget {
  const OwnerTransactionLogScreen({super.key});

  @override
  State<OwnerTransactionLogScreen> createState() => _OwnerTransactionLogScreenState();
}

class _OwnerTransactionLogScreenState extends State<OwnerTransactionLogScreen> {
  DateTime _selectedDate = DateTime.now();
  int? _selectedBranchId;
  int? _selectedUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.token != null) {
        await Provider.of<BranchProvider>(context, listen: false).fetchBranches(authProvider.token!);
      }
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = Provider.of<OrderProvider>(context, listen: false);
    await provider.fetchOrders(
      date: _selectedDate.toIso8601String().split('T')[0],
      branchId: _selectedBranchId,
      userId: _selectedUserId,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData();
    }
  }

  void _showOrderDetails(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text('transaction_detail_number'.tr(context: context, args: [order.id.toString()]), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: ReceiptWidget(order: order),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          ZenviHeader.sliver(
            title: 'log_transaksi_18'.tr(context: context),
            subtitle: 'pantau_transaksi_dari_seluruh_165'.tr(context: context),
            showBackButton: true,
            bottom: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  // Date Filter
                  ActionChip(
                    avatar: const Icon(Icons.calendar_today, size: 16),
                    label: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                    onPressed: () => _selectDate(context),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  const SizedBox(width: 8),
                  
                  // Branch Filter
                  Consumer<BranchProvider>(
                    builder: (context, branchProvider, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            value: _selectedBranchId,
                            hint: Text('all_branches'.tr(context: context), style: const TextStyle(fontSize: 14)),
                            icon: const Icon(Icons.arrow_drop_down),
                            isDense: true,
                            items: [
                              DropdownMenuItem(value: null, child: Text('all_branches'.tr(context: context), style: const TextStyle(fontSize: 14))),
                              ...branchProvider.branches.map((branch) {
                                return DropdownMenuItem(value: branch.id, child: Text(branch.name, style: const TextStyle(fontSize: 14)));
                              })
                            ],
                            onChanged: (val) {
                              setState(() => _selectedBranchId = val);
                              _loadData();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // List
          Consumer<OrderProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }

              if (provider.orders.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 80, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('belum_ada_transaksi_sesuai_166'.tr(context: context), style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final order = provider.orders[index];
                      final isVoided = order.status == 'voided';
                      final kasirName = order.user?.name ?? 'unknown_7'.tr(context: context);
                      final branchName = order.shift?.branch?.name ?? 'Unknown Branch';
                      
                      return InkWell(
                        onTap: () => _showOrderDetails(context, order),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                            boxShadow: [
                              BoxShadow(color: theme.shadowColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))
                            ]
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isVoided ? Colors.red.withValues(alpha: 0.1) : theme.colorScheme.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isVoided ? Icons.cancel : Icons.receipt_long,
                                  color: isVoided ? Colors.red : theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order #${order.id}',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        decoration: isVoided ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Kasir: $kasirName • $branchName',
                                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                                    ),
                                    Text(
                                      DateFormat('hhmm_5'.tr(context: context)).format(DateTime.parse(order.createdAt).toLocal()),
                                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(order.totalAmount),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  if (isVoided)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text('void_167'.tr(context: context), style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                    )
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: provider.orders.length,
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

