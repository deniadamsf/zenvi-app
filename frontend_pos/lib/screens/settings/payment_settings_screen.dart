import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/qris_image.dart';
import '../../widgets/zenvi_header.dart';

class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

/// Satu baris rekening yang sedang diedit. Controller-nya dipegang di sini
/// supaya menghapus satu baris tidak mengacaukan isian baris lain.
class _BankAccountDraft {
  _BankAccountDraft({String bank = '', String number = '', String holder = ''})
      : bankController = TextEditingController(text: bank),
        numberController = TextEditingController(text: number),
        holderController = TextEditingController(text: holder);

  final TextEditingController bankController;
  final TextEditingController numberController;
  final TextEditingController holderController;

  bool get isEmpty =>
      bankController.text.trim().isEmpty &&
      numberController.text.trim().isEmpty &&
      holderController.text.trim().isEmpty;

  bool get isComplete =>
      bankController.text.trim().isNotEmpty && numberController.text.trim().isNotEmpty;

  Map<String, String> toMap() => {
        'bank': bankController.text.trim(),
        'number': numberController.text.trim(),
        'holder': holderController.text.trim(),
      };

  void dispose() {
    bankController.dispose();
    numberController.dispose();
    holderController.dispose();
  }
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  static const int _maxBankAccounts = 5;

  final TextEditingController _merchantController = TextEditingController();
  final List<_BankAccountDraft> _accounts = [];

  bool _savingQris = false;
  bool _savingBank = false;
  bool _uploadingQris = false;

  @override
  void initState() {
    super.initState();
    final company = context.read<AuthProvider>().user?.company;
    _merchantController.text = (company?['qris_merchant_name'] ?? '').toString();
    for (final account in _readAccounts(company)) {
      _accounts.add(_BankAccountDraft(
        bank: account['bank'] ?? '',
        number: account['number'] ?? '',
        holder: account['holder'] ?? '',
      ));
    }
  }

  @override
  void dispose() {
    _merchantController.dispose();
    for (final account in _accounts) {
      account.dispose();
    }
    super.dispose();
  }

  bool _parseBool(dynamic val) {
    if (val == null) return false;
    if (val == 1 || val == true || val == '1' || val == 'true') return true;
    return false;
  }

  /// `bank_accounts` bisa datang sebagai list (dari server) atau null (toko
  /// yang belum pernah mengisinya).
  List<Map<String, String>> _readAccounts(Map<String, dynamic>? company) {
    final raw = company?['bank_accounts'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((item) {
      return {
        'bank': (item['bank'] ?? '').toString(),
        'number': (item['number'] ?? '').toString(),
        'holder': (item['holder'] ?? '').toString(),
      };
    }).toList();
  }

  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickQris(AuthProvider authProvider) async {
    try {
      final picker = ImagePicker();
      // QRIS TIDAK dipotong jadi kotak seperti logo: memotong kode QR berarti
      // merusaknya. Cukup dibatasi ukurannya supaya unggahan tidak berat.
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1400,
        maxHeight: 1400,
        imageQuality: 92,
      );
      if (picked == null) return;

      setState(() => _uploadingQris = true);
      final ok = await authProvider.uploadQrisImage(File(picked.path));
      if (!mounted) return;
      setState(() => _uploadingQris = false);
      _snack(
        ok
            ? 'payment_qris_uploaded'.tr(context: context)
            : 'payment_qris_upload_failed'.tr(context: context),
        isError: !ok,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingQris = false);
      _snack('payment_qris_upload_failed'.tr(context: context), isError: true);
    }
  }

  Future<void> _removeQris(AuthProvider authProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('payment_qris_remove_confirm_title'.tr(context: context)),
        content: Text('payment_qris_remove_confirm_body'.tr(context: context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('batal_5'.tr(context: context)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'hapus_88'.tr(context: context),
              style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await authProvider.removeQrisImage();
    if (!mounted) return;
    _snack(
      ok
          ? 'payment_qris_removed'.tr(context: context)
          : 'payment_qris_upload_failed'.tr(context: context),
      isError: !ok,
    );
  }

  Future<void> _saveMerchantName(AuthProvider authProvider) async {
    setState(() => _savingQris = true);
    final ok = await authProvider.updateCompanySetting(
      qrisMerchantName: _merchantController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _savingQris = false);
    _snack(
      ok
          ? 'payment_settings_saved'.tr(context: context)
          : 'payment_settings_save_failed'.tr(context: context),
      isError: !ok,
    );
  }

  Future<void> _saveAccounts(AuthProvider authProvider) async {
    // Baris yang benar-benar kosong dianggap belum diisi, bukan kesalahan -
    // biar owner bisa menekan "Tambah" lalu berubah pikiran.
    final filled = _accounts.where((a) => !a.isEmpty).toList();
    if (filled.any((a) => !a.isComplete)) {
      _snack('payment_bank_incomplete'.tr(context: context), isError: true);
      return;
    }

    setState(() => _savingBank = true);
    final ok = await authProvider.updateCompanySetting(
      bankAccounts: filled.map((a) => a.toMap()).toList(),
    );
    if (!mounted) return;
    setState(() => _savingBank = false);
    _snack(
      ok
          ? 'payment_bank_saved'.tr(context: context)
          : 'payment_bank_save_failed'.tr(context: context),
      isError: !ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final company = authProvider.user?.company;
    final isQrisEnabled = _parseBool(company?['is_qris_enabled'] ?? 1);
    final isTransferEnabled = _parseBool(company?['is_transfer_enabled'] ?? 1);
    final qrisUrl = (company?['qris_image_url'] ?? '').toString();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            ZenviHeader.sliver(
              title: 'pembayaran_kasir_16'.tr(context: context),
              showBackButton: true,
            ),
            SliverPadding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0, bottom: 120.0),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'metode_pembayaran_17'.tr(context: context),
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _card(
                          theme,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'tunai_cash_selalu_aktif_89'.tr(context: context),
                                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                              ),
                              const SizedBox(height: 16),
                              _toggleTile(
                                theme: theme,
                                icon: Icons.qr_code_2_rounded,
                                title: 'qris_digital_405'.tr(context: context),
                                subtitle: 'terima_pembayaran_kode_qris_406'.tr(context: context),
                                value: isQrisEnabled,
                                onChanged: (val) => authProvider.updateCompanySetting(isQrisEnabled: val),
                              ),
                              const SizedBox(height: 12),
                              _toggleTile(
                                theme: theme,
                                icon: Icons.account_balance_rounded,
                                title: 'transfer_bank_314'.tr(context: context),
                                subtitle: 'terima_transfer_rekening_bank_407'.tr(context: context),
                                value: isTransferEnabled,
                                onChanged: (val) => authProvider.updateCompanySetting(isTransferEnabled: val),
                              ),
                            ],
                          ),
                        ).animate().fade(delay: 200.ms).slideY(begin: 0.1, end: 0),

                        if (isQrisEnabled) ...[
                          const SizedBox(height: 28),
                          _sectionLabel(theme, 'payment_qris_section_title'.tr(context: context)),
                          const SizedBox(height: 16),
                          _card(
                            theme,
                            child: _qrisEditor(theme, authProvider, qrisUrl),
                          ).animate().fade(delay: 250.ms).slideY(begin: 0.1, end: 0),
                        ],

                        if (isTransferEnabled) ...[
                          const SizedBox(height: 28),
                          _sectionLabel(theme, 'payment_bank_section_title'.tr(context: context)),
                          const SizedBox(height: 16),
                          _card(
                            theme,
                            child: _bankEditor(theme, authProvider),
                          ).animate().fade(delay: 300.ms).slideY(begin: 0.1, end: 0),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(ThemeData theme, String text) => Text(
        text,
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      );

  Widget _card(ThemeData theme, {required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: theme.shadowColor.withValues(alpha: 0.05), blurRadius: 30, offset: const Offset(0, 10))
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    );
  }

  Widget _toggleTile({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  subtitle,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _qrisEditor(ThemeData theme, AuthProvider authProvider, String qrisUrl) {
    final hasQris = qrisUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'payment_qris_section_desc'.tr(context: context),
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
            ),
            clipBehavior: Clip.antiAlias,
            child: _uploadingQris
                ? const Center(child: CircularProgressIndicator())
                : hasQris
                    ? Padding(
                        padding: const EdgeInsets.all(8),
                        child: QrisImage(
                          imageUrl: qrisUrl,
                          fallback: _qrisPlaceholder(theme),
                        ),
                      )
                    : _qrisPlaceholder(theme),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: _uploadingQris ? null : () => _pickQris(authProvider),
              icon: const Icon(Icons.upload_rounded, size: 18),
              label: Text(
                hasQris
                    ? 'payment_qris_change'.tr(context: context)
                    : 'payment_qris_upload'.tr(context: context),
              ),
            ),
            if (hasQris) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _uploadingQris ? null : () => _removeQris(authProvider),
                icon: Icon(Icons.delete_outline_rounded, size: 18, color: theme.colorScheme.error),
                label: Text(
                  'payment_qris_remove'.tr(context: context),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _merchantController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'payment_qris_merchant_label'.tr(context: context),
            hintText: 'payment_qris_merchant_hint'.tr(context: context),
            helperText: 'payment_qris_merchant_help'.tr(context: context),
            helperMaxLines: 3,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: _savingQris ? null : () => _saveMerchantName(authProvider),
            child: _savingQris
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('simpan_6'.tr(context: context)),
          ),
        ),
      ],
    );
  }

  Widget _qrisPlaceholder(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.qr_code_2_rounded, size: 56, color: Colors.grey.shade400),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'payment_qris_empty'.tr(context: context),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _bankEditor(ThemeData theme, AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'payment_bank_section_desc'.tr(context: context),
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 16),
        if (_accounts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'payment_bank_empty'.tr(context: context),
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else
          for (int i = 0; i < _accounts.length; i++) _bankRow(theme, i),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: _accounts.length >= _maxBankAccounts
                  ? null
                  : () => setState(() => _accounts.add(_BankAccountDraft())),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('payment_bank_add'.tr(context: context)),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _savingBank ? null : () => _saveAccounts(authProvider),
              child: _savingBank
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('simpan_6'.tr(context: context)),
            ),
          ],
        ),
        if (_accounts.length >= _maxBankAccounts)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'payment_bank_max'.tr(context: context),
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget _bankRow(ThemeData theme, int index) {
    final account = _accounts[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: account.bankController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'payment_bank_name_label'.tr(context: context),
                    hintText: 'payment_bank_name_hint'.tr(context: context),
                    isDense: true,
                    border: const UnderlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'payment_remove_account'.tr(context: context),
                onPressed: () {
                  setState(() {
                    final removed = _accounts.removeAt(index);
                    removed.dispose();
                  });
                },
                icon: Icon(Icons.close_rounded, size: 20, color: theme.colorScheme.error),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: account.numberController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\- ]'))],
            decoration: InputDecoration(
              labelText: 'payment_bank_number_label'.tr(context: context),
              isDense: true,
              border: const UnderlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: account.holderController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'payment_bank_holder_label'.tr(context: context),
              isDense: true,
              border: const UnderlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
