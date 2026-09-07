import 'package:easy_localization/easy_localization.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/ingredient_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/product_model.dart';
import '../../widgets/zenvi_header.dart';
import '../../theme/app_colors.dart';

class AddProductScreen extends StatefulWidget {
  final ProductModel? product;

  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountNominalController = TextEditingController(text: '0');
  final _discountPercentController = TextEditingController(text: '0');
  bool _isActive = true;
  File? _imageFile;
  
  final List<Map<String, dynamic>> _selectedIngredients = [];
  final List<Map<String, dynamic>> _variants = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<IngredientProvider>(context, listen: false).fetchIngredients();
    });

    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _categoryController.text = widget.product!.category ?? '';
      _priceController.text = widget.product!.price.toStringAsFixed(0);
      _discountNominalController.text = widget.product!.discountNominal.toStringAsFixed(0);
      _discountPercentController.text = widget.product!.discountPercent.toStringAsFixed(0);
      _isActive = widget.product!.isActive;
      
      for (var ing in widget.product!.ingredients) {
        _selectedIngredients.add({
          'ingredient_id': ing.id,
          'amount_needed': ing.amountNeeded ?? 0.0,
          'controller': TextEditingController(text: (ing.amountNeeded ?? 0.0).toString()),
        });
      }

      for (var variant in widget.product!.variants) {
        _variants.add({
          'name_controller': TextEditingController(text: variant.name),
          'price_controller': TextEditingController(text: variant.price.toStringAsFixed(0)),
          'is_active': variant.isActive,
        });
      }
    }
  }

  Future<void> _pickImage() async {
    // Warna dan judul diambil sebelum await mana pun: sesudahnya BuildContext
    // sudah melintasi async gap dan tidak aman dipakai.
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cropTitle = 'product_crop_title'.tr(context: context);
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );

    if (pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 85,
        maxWidth: 600,
        maxHeight: 600,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: cropTitle,
            toolbarColor: primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: cropTitle,
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _imageFile = File(croppedFile.path);
        });
      }
    }
  }

  void _addIngredientRow() {
    setState(() {
      _selectedIngredients.add({
        'ingredient_id': null,
        'amount_needed': 0.0,
        'controller': TextEditingController(),
      });
    });
  }

  void _removeIngredientRow(int index) {
    setState(() {
      _selectedIngredients[index]['controller'].dispose();
      _selectedIngredients.removeAt(index);
    });
  }

  void _addVariantRow() {
    setState(() {
      _variants.add({
        'name_controller': TextEditingController(),
        'price_controller': TextEditingController(),
        'is_active': true,
      });
    });
  }

  void _removeVariantRow(int index) {
    setState(() {
      _variants[index]['name_controller'].dispose();
      _variants[index]['price_controller'].dispose();
      _variants.removeAt(index);
    });
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      bool validIngredients = true;
      List<Map<String, dynamic>> finalIngredients = [];
      
      for (var item in _selectedIngredients) {
        if (item['ingredient_id'] == null) {
          validIngredients = false;
          break;
        }
        final amount = double.tryParse(item['controller'].text) ?? 0.0;
        if (amount <= 0) {
          validIngredients = false;
          break;
        }
        finalIngredients.add({
          'ingredient_id': item['ingredient_id'],
          'amount_needed': amount,
        });
      }

      if (!validIngredients && _selectedIngredients.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('pastikan_semua_bahan_baku_40'.tr(context: context))),
        );
        return;
      }

      bool validVariants = true;
      List<Map<String, dynamic>> finalVariants = [];

      for (var v in _variants) {
        final name = v['name_controller'].text.trim();
        final price = double.tryParse(v['price_controller'].text) ?? -1;
        if (name.isEmpty || price < 0) {
          validVariants = false;
          break;
        }
        finalVariants.add({
          'name': name,
          'price': price,
          'is_active': v['is_active'],
        });
      }

      if (!validVariants && _variants.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('pastikan_nama_varian_tidak_41'.tr(context: context))),
        );
        return;
      }

      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      
      bool success = false;
      if (widget.product == null) {
        success = await productProvider.addProduct(
          name: _nameController.text,
          category: _categoryController.text.trim(),
          price: double.parse(_priceController.text),
          discountNominal: double.tryParse(_discountNominalController.text) ?? 0.0,
          discountPercent: double.tryParse(_discountPercentController.text) ?? 0.0,
          isActive: _isActive,
          imageFile: _imageFile,
          ingredients: finalIngredients,
          variants: finalVariants,
        );
      } else {
        success = await productProvider.updateProduct(
          id: widget.product!.id,
          name: _nameController.text,
          category: _categoryController.text.trim(),
          price: double.parse(_priceController.text),
          discountNominal: double.tryParse(_discountNominalController.text) ?? 0.0,
          discountPercent: double.tryParse(_discountPercentController.text) ?? 0.0,
          isActive: _isActive,
          imageFile: _imageFile,
          ingredients: finalIngredients,
          variants: finalVariants,
        );
      }

      
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.product == null
              ? 'product_added_success'.tr(context: context)
              : 'product_updated_success'.tr(context: context))),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('gagal_menyimpan_produk_42'.tr(context: context))),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _discountNominalController.dispose();
    _discountPercentController.dispose();
    for (var item in _selectedIngredients) {
      item['controller'].dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = Provider.of<ProductProvider>(context).isLoading;
    final existingCategories = Provider.of<ProductProvider>(context, listen: false).categories;
    final ingredientProvider = Provider.of<IngredientProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isProductImageEnabled = authProvider.isProductImageEnabled;
    final isEditing = widget.product != null;

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          ZenviHeader.sliver(
            title: isEditing
                ? 'product_edit_title'.tr(context: context)
                : 'product_add_title'.tr(context: context),
            showBackButton: true,
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isProductImageEnabled) ...[
                      // FOTO PRODUK
                      Text('foto_produk_43'.tr(context: context), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                          ),
                          child: _imageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity),
                                )
                              : (isEditing && widget.product!.imageUrl != null)
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: Image.network(widget.product!.imageUrl!, fit: BoxFit.cover, width: double.infinity),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.add_a_photo_rounded, size: 32, color: theme.colorScheme.primary),
                                        ),
                                        const SizedBox(height: 12),
                                        Text('unggah_foto_11_44'.tr(context: context), style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // INFORMASI DASAR
                    Text('informasi_dasar_45'.tr(context: context), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: inputDecoration.copyWith(
                        labelText: 'nama_produk_57'.tr(context: context),
                        prefixIcon: const Icon(Icons.fastfood_rounded),
                      ),
                      validator: (value) => value!.isEmpty ? 'product_name_required'.tr(context: context) : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _categoryController,
                      decoration: inputDecoration.copyWith(
                        labelText: 'product_category_label'.tr(context: context),
                        hintText: 'product_category_hint'.tr(context: context),
                        prefixIcon: const Icon(Icons.category_rounded),
                      ),
                    ),
                    if (existingCategories.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            Text('saran_46'.tr(context: context), style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                            ...existingCategories.map((cat) => Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: ActionChip(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                visualDensity: VisualDensity.compact,
                                label: Text(cat, style: const TextStyle(fontSize: 12)),
                                onPressed: () {
                                  setState(() {
                                    _categoryController.text = cat;
                                  });
                                },
                              ),
                            )),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: inputDecoration.copyWith(
                        labelText: 'product_price_label'.tr(context: context),
                        prefixIcon: const Icon(Icons.payments_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'product_price_required'.tr(context: context);
                        if (double.tryParse(value) == null) return 'product_price_numeric'.tr(context: context);
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    // DISKON
                    Text('diskon_opsional_47'.tr(context: context), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _discountNominalController,
                            keyboardType: TextInputType.number,
                            decoration: inputDecoration.copyWith(
                              labelText: 'product_amount_rp_label'.tr(context: context),
                              prefixIcon: const Icon(Icons.money_off_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _discountPercentController,
                            keyboardType: TextInputType.number,
                            decoration: inputDecoration.copyWith(
                              labelText: 'product_percent_label'.tr(context: context),
                              prefixIcon: const Icon(Icons.percent_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    // VARIAN PRODUK
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('varian_opsional_48'.tr(context: context), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        FilledButton.tonalIcon(
                          onPressed: _addVariantRow,
                          icon: const Icon(Icons.add, size: 16),
                          label: Text('tambah_49'.tr(context: context)),
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_variants.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                        ),
                        child: Text('tidak_ada_varian_ditambahkan_50'.tr(context: context), style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
                      ),
                    if (_variants.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          children: List.generate(_variants.length, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: _variants[index]['name_controller'],
                                      decoration: inputDecoration.copyWith(
                                        hintText: 'product_variant_name_hint'.tr(context: context),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: _variants[index]['price_controller'],
                                      keyboardType: TextInputType.number,
                                      decoration: inputDecoration.copyWith(
                                        hintText: 'product_variant_price_hint'.tr(context: context),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.dangerText),
                                    onPressed: () => _removeVariantRow(index),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),

                    const SizedBox(height: 32),
                    // RESEP / BAHAN BAKU
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('bahan_baku_resep_51'.tr(context: context), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        FilledButton.tonalIcon(
                          onPressed: _addIngredientRow,
                          icon: const Icon(Icons.add, size: 16),
                          label: Text('tambah_49'.tr(context: context)),
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('bahan_baku_akan_terpotong_52'.tr(context: context), style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 12),
                    if (ingredientProvider.isLoading)
                      Center(child: CircularProgressIndicator())
                    else if (_selectedIngredients.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                        ),
                        child: Text('belum_ada_bahan_baku_53'.tr(context: context), style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          children: List.generate(_selectedIngredients.length, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<int>(
                                      decoration: inputDecoration.copyWith(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      ),
                                      hint: Text('pilih_bahan_54'.tr(context: context), style: TextStyle(fontSize: 14)),
                                      isExpanded: true,
                                      initialValue: _selectedIngredients[index]['ingredient_id'],
                                      items: ingredientProvider.ingredients.map((ing) {
                                        return DropdownMenuItem<int>(
                                          value: ing.id,
                                          child: Text('${ing.name} (${ing.unit})', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedIngredients[index]['ingredient_id'] = val;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      controller: _selectedIngredients[index]['controller'],
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: inputDecoration.copyWith(
                                        hintText: 'product_portion_hint'.tr(context: context),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.dangerText),
                                    onPressed: () => _removeIngredientRow(index),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                      
                    const SizedBox(height: 32),
                    // STATUS
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                        boxShadow: [
                          BoxShadow(color: theme.shadowColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                        ]
                      ),
                      child: SwitchListTile(
                        title: Text('tampilkan_di_kasir_55'.tr(context: context), style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('produk_dapat_dibeli_jika_56'.tr(context: context)),
                        value: _isActive,
                        activeTrackColor: theme.colorScheme.primary,
                        onChanged: (bool value) => setState(() => _isActive = value),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // SIMPAN BUTTON
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: isLoading ? null : _submitForm,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: isLoading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                isEditing
                                    ? 'product_save_changes'.tr(context: context)
                                    : 'product_save_new'.tr(context: context),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
