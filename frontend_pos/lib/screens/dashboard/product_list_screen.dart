import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product_model.dart';
import 'add_product_screen.dart';
import '../../widgets/zenvi_header.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          ZenviHeader.sliver(
            title: 'daftar_produk_13'.tr(context: context),
            showBackButton: true,
          ),
          if (productProvider.isLoading && productProvider.products.isEmpty)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (productProvider.products.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.inventory_2_rounded, size: 64, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'belum_ada_produk_16'.tr(context: context),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'tambahkan_produk_untuk_mulai_38'.tr(context: context),
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = productProvider.products[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddProductScreen(product: product),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
                                    ),
                                    child: (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: Image.network(
                                              product.imageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Icon(_getProductCategoryIcon(product), color: theme.colorScheme.primary.withValues(alpha: 0.6), size: 30),
                                            ),
                                          )
                                        : Icon(_getProductCategoryIcon(product), color: theme.colorScheme.primary.withValues(alpha: 0.6), size: 30),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                product.name,
                                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            PopupMenuButton<String>(
                                              icon: Icon(Icons.more_horiz_rounded, color: theme.colorScheme.onSurfaceVariant),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onSelected: (value) {
                                                if (value == 'edit') {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => AddProductScreen(product: product),
                                                    ),
                                                  );
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.edit_rounded, size: 20, color: theme.colorScheme.primary),
                                                      const SizedBox(width: 12),
                                                      Text('edit_produk_171'.tr(context: context)),
                                                    ],
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                                                      const SizedBox(width: 12),
                                                      Text('hapus_88'.tr(context: context), style: const TextStyle(color: Colors.red)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          product.category ?? 'tanpa_kategori_14'.tr(context: context),
                                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Rp ${product.price.toStringAsFixed(0)}',
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                color: theme.colorScheme.primary,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: product.isActive ? Colors.green.withValues(alpha: 0.1) : theme.colorScheme.error.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                product.isActive ? 'Tersedia' : 'Habis/Nonaktif',
                                                style: TextStyle(
                                                  color: product.isActive ? Colors.green.shade700 : theme.colorScheme.error,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: productProvider.products.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );
        },
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded),
        label: Text('tambah_produk_172'.tr(context: context), style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  IconData _getProductCategoryIcon(ProductModel product) {
    final cat = (product.category ?? '').toLowerCase();
    final name = product.name.toLowerCase();
    final combined = '$cat $name';

    if (combined.contains('kopi') ||
        combined.contains('coffee') ||
        combined.contains('tea') ||
        combined.contains('teh') ||
        combined.contains('minum') ||
        combined.contains('drink') ||
        combined.contains('jus') ||
        combined.contains('juice') ||
        combined.contains('latte') ||
        combined.contains('boba')) {
      return Icons.local_cafe_rounded;
    }
    if (combined.contains('potong') ||
        combined.contains('cukur') ||
        combined.contains('rambut') ||
        combined.contains('hair') ||
        combined.contains('barber') ||
        combined.contains('salon') ||
        combined.contains('creambath') ||
        combined.contains('shampoo') ||
        combined.contains('facial') ||
        combined.contains('massage') ||
        combined.contains('pijat') ||
        combined.contains('spa') ||
        combined.contains('treatment') ||
        combined.contains('service') ||
        combined.contains('jasa') ||
        combined.contains('cuci')) {
      return Icons.content_cut_rounded;
    }
    if (combined.contains('baju') ||
        combined.contains('kaos') ||
        combined.contains('pakaian') ||
        combined.contains('cloth') ||
        combined.contains('retail') ||
        combined.contains('barang')) {
      return Icons.shopping_bag_rounded;
    }
    return Icons.restaurant_rounded;
  }
}

