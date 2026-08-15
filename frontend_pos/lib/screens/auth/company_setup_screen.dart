import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../dashboard/owner_dashboard_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CompanySetupScreen extends StatefulWidget {
  const CompanySetupScreen({super.key});

  @override
  State<CompanySetupScreen> createState() => _CompanySetupScreenState();
}

class _CompanySetupScreenState extends State<CompanySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isKdsEnabled = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.createCompany(_nameController.text.trim(), isKdsEnabled: _isKdsEnabled);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('perusahaan_berhasil_dibuat_0'.tr(context: context))),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OwnerDashboardScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('gagal_membuat_perusahaan_silakan_1'.tr(context: context))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('setup_perusahaan_2'.tr(context: context), style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              Navigator.pop(context); // Go back to login screen
            },
            tooltip: 'logout_6'.tr(context: context),
          )
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      ),
                      child: Icon(Icons.storefront_rounded, size: 32, color: theme.colorScheme.primary),
                    ).animate().scale().fade(),
                    const SizedBox(height: 16),
                    Text(
                      'satu_langkah_lagi_18'.tr(context: context),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ).animate().slideY().fade(),
                    const SizedBox(height: 6),
                    Text(
                      'buat_nama_perusahaantoko_anda_117'.tr(context: context),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                    ).animate().slideY(delay: 100.ms).fade(),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'nama_perusahaan_15'.tr(context: context),
                        prefixIcon: const Icon(Icons.business_rounded, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'nama_perusahaan_tidak_boleh_34'.tr(context: context);
                        }
                        return null;
                      },
                    ).animate().slideY(delay: 200.ms).fade(),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                      ),
                      child: SwitchListTile(
                        title: Text('aktifkan_kitchen_display_system_5'.tr(context: context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        subtitle: Text('tampilkan_layar_khusus_dapur_6'.tr(context: context), style: const TextStyle(fontSize: 12)),
                        value: _isKdsEnabled,
                        activeThumbColor: theme.colorScheme.primary,
                        secondary: Icon(Icons.kitchen_rounded, color: _isKdsEnabled ? theme.colorScheme.primary : Colors.grey, size: 22),
                        onChanged: (val) {
                          setState(() {
                            _isKdsEnabled = val;
                          });
                        },
                      ),
                    ).animate().slideY(delay: 250.ms).fade(),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: authProvider.isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text('buat_perusahaan_7'.tr(context: context), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ).animate().slideY(delay: 300.ms).fade(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
