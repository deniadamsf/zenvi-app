import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../models/member_model.dart';
import '../../../theme/app_colors.dart';

class PaymentModal extends StatefulWidget {
  final double totalAmount;
  final bool isQrisEnabled;
  final bool isTransferEnabled;
  final List<Map<String, dynamic>> staffList;
  final int? currentUserId;
  final String? currentUserName;
  final MemberModel? member;
  final double memberDiscountAmount;
  final bool isPointsEnabled;
  final double pointRedeemRate;
  final Function(
    String paymentMethod,
    double? cashReceived,
    double? cashChange,
    int? servicedByUserId,
    String? servicedByName,
    int pointsRedeemed,
    double pointRedeemAmount,
  ) onConfirm;

  const PaymentModal({
    super.key,
    required this.totalAmount,
    required this.isQrisEnabled,
    required this.isTransferEnabled,
    this.staffList = const [],
    this.currentUserId,
    this.currentUserName,
    this.member,
    this.memberDiscountAmount = 0.0,
    this.isPointsEnabled = true,
    this.pointRedeemRate = 1.0,
    required this.onConfirm,
  });

  static Future<void> show({
    required BuildContext context,
    required double totalAmount,
    required bool isQrisEnabled,
    required bool isTransferEnabled,
    List<Map<String, dynamic>> staffList = const [],
    int? currentUserId,
    String? currentUserName,
    MemberModel? member,
    double memberDiscountAmount = 0.0,
    bool isPointsEnabled = true,
    double pointRedeemRate = 1.0,
    required Function(
      String paymentMethod,
      double? cashReceived,
      double? cashChange,
      int? servicedByUserId,
      String? servicedByName,
      int pointsRedeemed,
      double pointRedeemAmount,
    ) onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: PaymentModal(
          totalAmount: totalAmount,
          isQrisEnabled: isQrisEnabled,
          isTransferEnabled: isTransferEnabled,
          staffList: staffList,
          currentUserId: currentUserId,
          currentUserName: currentUserName,
          member: member,
          memberDiscountAmount: memberDiscountAmount,
          isPointsEnabled: isPointsEnabled,
          pointRedeemRate: pointRedeemRate,
          onConfirm: onConfirm,
        ),
      ),
    );
  }

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  late String _selectedMethod; // 'cash', 'qris', 'transfer'
  final TextEditingController _cashInputController = TextEditingController();
  final TextEditingController _pointsInputController = TextEditingController();
  double _cashReceived = 0.0;
  int? _selectedStaffId;
  String? _selectedStaffName;

  bool _usePoints = false;
  int _pointsRedeemed = 0;
  double _pointRedeemAmount = 0.0;

  late final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'rp_3'.tr(), decimalDigits: 0);

  double get _netPayableAmount {
    final net = widget.totalAmount - _pointRedeemAmount;
    return net < 0 ? 0.0 : net;
  }

  @override
  void initState() {
    super.initState();
    _selectedMethod = 'cash';
    _cashReceived = widget.totalAmount;
    _cashInputController.text = widget.totalAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _cashInputController.dispose();
    _pointsInputController.dispose();
    super.dispose();
  }

  void _onPointsChanged(String val) {
    final parsed = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final maxMemberPoints = widget.member?.points ?? 0;
    final rate = widget.pointRedeemRate > 0 ? widget.pointRedeemRate : 1.0;
    final maxNeededPoints = (widget.totalAmount / rate).ceil();
    final allowedMax = maxMemberPoints < maxNeededPoints ? maxMemberPoints : maxNeededPoints;
    
    final finalPts = parsed.clamp(0, allowedMax);
    setState(() {
      _pointsRedeemed = finalPts;
      _pointRedeemAmount = (_pointsRedeemed * rate).clamp(0.0, widget.totalAmount);
      if (_selectedMethod == 'cash') {
        _cashReceived = _netPayableAmount;
        _cashInputController.text = _netPayableAmount.toStringAsFixed(0);
      }
    });
  }

  void _toggleUsePoints(bool val) {
    setState(() {
      _usePoints = val;
      if (val) {
        final maxMemberPoints = widget.member?.points ?? 0;
        final rate = widget.pointRedeemRate > 0 ? widget.pointRedeemRate : 1.0;
        final maxNeededPoints = (widget.totalAmount / rate).ceil();
        final autoPts = maxMemberPoints < maxNeededPoints ? maxMemberPoints : maxNeededPoints;
        _pointsRedeemed = autoPts;
        _pointRedeemAmount = (_pointsRedeemed * rate).clamp(0.0, widget.totalAmount);
        _pointsInputController.text = _pointsRedeemed.toString();
      } else {
        _pointsRedeemed = 0;
        _pointRedeemAmount = 0.0;
        _pointsInputController.clear();
      }
      if (_selectedMethod == 'cash') {
        _cashReceived = _netPayableAmount;
        _cashInputController.text = _netPayableAmount.toStringAsFixed(0);
      }
    });
  }

  void _onQuickCashSelected(double amount) {
    setState(() {
      _cashReceived = amount;
      _cashInputController.text = amount.toStringAsFixed(0);
    });
  }

  List<double> _generateQuickAmounts() {
    final total = _netPayableAmount;
    final Set<double> suggestions = {total}; // Uang pas

    // Standard Indonesian Banknotes
    final standardNotes = [10000.0, 20000.0, 50000.0, 100000.0, 150000.0, 200000.0, 500000.0];
    for (var note in standardNotes) {
      if (note > total) {
        suggestions.add(note);
      }
    }

    // Rounding to nearest 10,000 or 50,000 if total is large
    if (total > 50000) {
      final next50k = ((total / 50000).ceil()) * 50000.0;
      suggestions.add(next50k);
    }
    if (total > 10000) {
      final next10k = ((total / 10000).ceil()) * 10000.0;
      suggestions.add(next10k);
    }

    final list = suggestions.toList()..sort();
    return list.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payable = _netPayableAmount;
    final double change = _cashReceived - payable;
    final bool isCashValid = payable == 0 ? true : (_cashReceived >= payable);

    final availableMethods = <Map<String, dynamic>>[
      {'id': 'cash', 'label': 'tunai_cash_12'.tr(context: context), 'icon': Icons.payments_rounded, 'color': Colors.green},
    ];
    if (widget.isQrisEnabled) {
      availableMethods.add({'id': 'qris', 'label': 'qris_4'.tr(context: context), 'icon': Icons.qr_code_2_rounded, 'color': Colors.blueAccent});
    }
    if (widget.isTransferEnabled) {
      availableMethods.add({'id': 'transfer', 'label': 'transfer_8'.tr(context: context), 'icon': Icons.account_balance_rounded, 'color': Colors.purpleAccent});
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
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

            // Title & Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('metode_pembayaran_148'.tr(context: context), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('pilih_cara_pembayaran_transaksi_309'.tr(context: context), style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Tukar Poin Member Card (Hanya jika member ada, fitur poin aktif, dan punya saldo poin)
            if (widget.member != null && widget.isPointsEnabled && widget.member!.points > 0) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _usePoints
                      ? AppColors.warningFill.withValues(alpha: 0.08)
                      : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _usePoints ? AppColors.warningFill.withValues(alpha: 0.4) : theme.dividerColor.withValues(alpha: 0.1),
                    width: _usePoints ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.warningFill.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.stars_rounded, color: AppColors.warningFill, size: 22),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Tukar Poin Member',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.warningFill.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${widget.member!.points} Poin',
                                            style: const TextStyle(color: AppColors.warningText, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Nilai: 1 Poin = Rp ${NumberFormat('#,###', 'id_ID').format(widget.pointRedeemRate)} (Maks Potongan: Rp ${NumberFormat('#,###', 'id_ID').format(widget.member!.points * widget.pointRedeemRate)})',
                                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _usePoints,
                          activeThumbColor: AppColors.warningFill,
                          onChanged: _toggleUsePoints,
                        ),
                      ],
                    ),
                    if (_usePoints) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _pointsInputController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Jumlah Poin Ditukar',
                                suffixText: 'Poin',
                                prefixIcon: const Icon(Icons.redeem_rounded, size: 18, color: AppColors.warningText),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                              ),
                              onChanged: _onPointsChanged,
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonal(
                            onPressed: () {
                              final maxMemberPoints = widget.member?.points ?? 0;
                              final rate = widget.pointRedeemRate > 0 ? widget.pointRedeemRate : 1.0;
                              final maxNeededPoints = (widget.totalAmount / rate).ceil();
                              final autoPts = maxMemberPoints < maxNeededPoints ? maxMemberPoints : maxNeededPoints;
                              _pointsInputController.text = autoPts.toString();
                              _onPointsChanged(autoPts.toString());
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.warningFill.withValues(alpha: 0.2),
                              foregroundColor: AppColors.warningText,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('max_points_btn'.tr(context: context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.successFill.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.successText),
                            const SizedBox(width: 6),
                            Text(
                              'bill_deduction_amount'.tr(context: context, args: [NumberFormat('#,###', 'id_ID').format(_pointRedeemAmount)]),
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.successText),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Total Tagihan Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (_pointRedeemAmount > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('total_before_points'.tr(context: context), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(currencyFormatter.format(widget.totalAmount), style: const TextStyle(color: Colors.white70, fontSize: 12, decoration: TextDecoration.lineThrough)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('redeem_points_title'.tr(context: context, args: [_pointsRedeemed.toString()]), style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('- ${currencyFormatter.format(_pointRedeemAmount)}', style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 12),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'total_tagihan_13'.tr(context: context),
                        style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        currencyFormatter.format(payable),
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Method Selector Tabs
            if (availableMethods.length > 1) ...[
              Row(
                children: availableMethods.map((m) {
                  final isSelected = _selectedMethod == m['id'];
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          setState(() {
                            _selectedMethod = m['id'];
                            if (_selectedMethod == 'cash') {
                              _cashReceived = payable;
                              _cashInputController.text = payable.toStringAsFixed(0);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(m['icon'] as IconData, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant, size: 24),
                              const SizedBox(height: 6),
                              Text(
                                m['label'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Payment Content based on selection
            if (_selectedMethod == 'cash') ...[
              // Quick Cash Chips
              Text('pilihan_uang_cepat_311'.tr(context: context), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _generateQuickAmounts().map((amount) {
                    final isUangPas = amount == payable;
                    final isSelected = _cashReceived == amount;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(
                          isUangPas ? 'Uang Pas (${currencyFormatter.format(amount)})' : currencyFormatter.format(amount),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: theme.colorScheme.primary,
                        onSelected: (selected) {
                          if (selected) _onQuickCashSelected(amount);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Cash Input Field
              TextFormField(
                controller: _cashInputController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Uang Diterima (Rp)',
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onChanged: (val) {
                  final parsed = double.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
                  setState(() {
                    _cashReceived = parsed;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Kembalian Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isCashValid
                      ? AppColors.successFill.withValues(alpha: 0.1)
                      : AppColors.dangerFill.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isCashValid ? AppColors.successFill.withValues(alpha: 0.4) : AppColors.dangerFill.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isCashValid ? 'Kembalian:' : 'Uang Kurang:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isCashValid ? AppColors.successText : AppColors.dangerText,
                      ),
                    ),
                    Text(
                      currencyFormatter.format(isCashValid ? (change >= 0 ? change : 0) : (payable - _cashReceived)),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isCashValid ? AppColors.successText : AppColors.dangerText,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_selectedMethod == 'qris') ...[
              // QRIS Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, size: 40, color: theme.colorScheme.primary),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('pembayaran_qris_digital_312'.tr(context: context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            'Minta pelanggan memindai QRIS toko. Pastikan notifikasi dana masuk telah terkonfirmasi.',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_selectedMethod == 'transfer') ...[
              // Transfer Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_rounded, size: 40, color: theme.colorScheme.primary),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('transfer_bank_314'.tr(context: context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            'Periksa bukti mutasi atau bukti transfer bank sebelum mengonfirmasi pesanan.',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Optional Staff/Kapster/Terapis Selector
            () {
              final otherStaff = widget.staffList.where((staff) {
                final staffId = staff['id'];
                return widget.currentUserId == null || staffId != widget.currentUserId;
              }).toList();

              if (otherStaff.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.badge_outlined, size: 16, color: theme.colorScheme.secondary),
                          const SizedBox(width: 6),
                          Text(
                            'Staf / Terapis / Kapster (Opsional)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int?>(
                        initialValue: _selectedStaffId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                        ),
                        hint: Text('pilih_staf_yang_melayani_317'.tr(context: context)),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text(
                              widget.currentUserName != null && widget.currentUserName!.isNotEmpty
                                  ? 'Saya Sendiri / Kasir (${widget.currentUserName})'
                                  : 'Dilayani Sendiri oleh Kasir',
                            ),
                          ),
                          ...otherStaff.map((staff) {
                            final title = staff['job_title'] ?? staff['role'] ?? 'karyawan_8'.tr(context: context);
                            return DropdownMenuItem<int?>(
                              value: staff['id'] as int?,
                              child: Text('${staff['name']} ($title)'),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedStaffId = val;
                            if (val != null) {
                              final match = otherStaff.firstWhere(
                                (s) => s['id'] == val,
                                orElse: () => {'name': ''},
                              );
                              _selectedStaffName = match['name'];
                            } else {
                              _selectedStaffName = null;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            }(),

            const SizedBox(height: 24),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_selectedMethod == 'cash' && !isCashValid)
                    ? null
                    : () {
                        Navigator.pop(context);
                        if (_selectedMethod == 'cash') {
                          widget.onConfirm(
                            'cash',
                            _cashReceived,
                            change >= 0 ? change : 0,
                            _selectedStaffId,
                            _selectedStaffName,
                            _pointsRedeemed,
                            _pointRedeemAmount,
                          );
                        } else {
                          widget.onConfirm(
                            _selectedMethod,
                            payable,
                            0,
                            _selectedStaffId,
                            _selectedStaffName,
                            _pointsRedeemed,
                            _pointRedeemAmount,
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                ),
                child: Text(
                  _selectedMethod == 'cash'
                      ? (isCashValid ? 'Selesaikan Pembayaran Tunai' : 'Nominal Masih Kurang')
                      : 'Konfirmasi Pembayaran ${_selectedMethod.toUpperCase()}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
