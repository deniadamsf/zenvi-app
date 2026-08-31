import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../screens/subscription/plan_screen.dart';

/// Keterangan kenapa sesuatu terkunci — dari body 403 server, atau dirakit
/// lokal oleh [PremiumGate] sebelum permintaan sempat dikirim.
class PremiumLock {
  const PremiumLock({
    this.isLimit = false,
    this.feature,
    this.limitKey,
    this.current,
    this.max,
    this.requiredPlan,
    this.message,
  });

  final bool isLimit;
  final String? feature;
  final String? limitKey;
  final int? current;
  final int? max;
  final String? requiredPlan;
  final String? message;
}

/// Membungkus sesuatu yang hanya tersedia di paket berbayar.
///
/// Sengaja TIDAK menyembunyikan isinya: menu yang hilang tidak menjual apa pun,
/// sementara menu bergembok memberi tahu pengguna bahwa fiturnya ada dan bisa
/// dibuka. Ketukan mengarah ke tawaran upgrade, bukan ke pesan error.
class PremiumGate extends StatelessWidget {
  const PremiumGate({
    super.key,
    required this.locked,
    required this.child,
    this.feature,
    this.requiredPlan,
  });

  /// Kalau false, [child] ditampilkan apa adanya tanpa biaya tambahan.
  final bool locked;
  final Widget child;
  final String? feature;
  final String? requiredPlan;

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;

    final theme = Theme.of(context);

    return Stack(
      children: [
        // Isinya tetap terlihat tapi diredupkan, dan tidak bisa disentuh.
        Opacity(
          opacity: 0.45,
          child: IgnorePointer(child: child),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => showPremiumUpsellSheet(
                context,
                PremiumLock(feature: feature, requiredPlan: requiredPlan),
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, size: 12, color: theme.colorScheme.onPrimary),
                      const SizedBox(width: 4),
                      Text(
                        'premium_badge'.tr(context: context),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Lencana kecil untuk ditempel di judul menu yang terkunci.
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, size: 10, color: theme.colorScheme.primary),
          const SizedBox(width: 3),
          Text(
            'premium_badge'.tr(context: context),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

bool _upsellVisible = false;

/// Menampilkan tawaran upgrade. Dipanggil dari [PremiumGate] maupun dari
/// ApiClient saat server membalas 403 bertipe.
void showPremiumUpsellSheet(BuildContext context, PremiumLock lock) {
  // Satu permintaan pengguna bisa memicu beberapa panggilan API yang semuanya
  // terkunci; tanpa penjaga ini sheet-nya bertumpuk.
  if (_upsellVisible) return;
  _upsellVisible = true;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final theme = Theme.of(ctx);

      final title = lock.isLimit
          ? 'plan_limit_title'.tr(context: ctx)
          : 'feature_locked_title'.tr(context: ctx);

      final description = lock.isLimit && lock.max != null
          ? 'plan_limit_desc'.tr(context: ctx, namedArgs: {'max': '${lock.max}'})
          : (lock.message ?? 'feature_locked_desc'.tr(context: ctx));

      return Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                lock.isLimit ? Icons.trending_up_rounded : Icons.workspace_premium_rounded,
                color: theme.colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlanScreen()),
                  );
                },
                icon: const Icon(Icons.workspace_premium_rounded),
                label: Text('see_plans'.tr(context: ctx)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('later'.tr(context: ctx)),
              ),
            ),
          ],
        ),
      );
    },
  ).whenComplete(() => _upsellVisible = false);
}
