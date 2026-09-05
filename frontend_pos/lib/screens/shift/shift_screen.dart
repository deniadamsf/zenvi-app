import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../providers/shift_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ingredient_provider.dart';
import '../permission/employee_permission_screen.dart';
import '../../widgets/zenvi_header.dart';
import '../../theme/app_colors.dart';

class ShiftScreen extends StatefulWidget {
  const ShiftScreen({super.key});

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  final TextEditingController _openingBalanceController = TextEditingController();
  final TextEditingController _closingBalanceController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selfieImage;
  bool _isProcessingSelfie = false;
  bool _isLocationValid = false;
  bool _isCheckingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshShiftData();
      
      // Auto-validate for Owner
      final user = context.read<AuthProvider>().user;
      if (user?.role == 'owner_5'.tr(context: context)) {
        if (mounted) {
          setState(() {
            _isLocationValid = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _openingBalanceController.dispose();
    _closingBalanceController.dispose();
    super.dispose();
  }

  Future<void> _refreshShiftData() async {
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      await Future.wait([
        context.read<ShiftProvider>().fetchActiveShift(token),
        context.read<IngredientProvider>().fetchIngredients(),
      ]);
    }
  }

  Future<Position?> _getSafePosition() async {
    try {
      // 1. Coba ambil lokasi terakhir (instan tanpa menunggu GPS satellite lock)
      Position? lastKnown;
      try {
        lastKnown = await Geolocator.getLastKnownPosition();
      } catch (_) {}

      // 2. Ambil current position dengan timeout ketat 5 detik dan medium accuracy agar tidak hang platform channel
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      ).timeout(
        const Duration(seconds: 6),
        onTimeout: () {
          if (lastKnown != null) return lastKnown;
          throw Exception('Waktu pencarian sinyal GPS habis. Pastikan GPS aktif di area terbuka.');
        },
      );
    } catch (e) {
      debugPrint('Error getting safe position: $e');
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  void _showOutOfRadiusDialog(double currentDistance, double maxRadius) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 16,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_off_rounded,
                  color: theme.colorScheme.error,
                  size: 38,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'di_luar_radius_toko_title'.tr(context: context),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'di_luar_radius_toko_desc'.tr(context: context),
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Jarak Anda:',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                        ),
                        Text(
                          '${currentDistance.toStringAsFixed(0)} meter',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.error),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Batas Toko:',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                        ),
                        Text(
                          '${maxRadius.toStringAsFixed(0)} meter',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _checkLocation();
                  },
                  icon: const Icon(Icons.my_location_rounded, size: 18),
                  label: Text(
                    'cek_ulang_lokasi_btn'.tr(context: context),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EmployeePermissionScreen()),
                    );
                  },
                  icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                  label: Text(
                    'ajukan_izin_cuti_btn'.tr(context: context),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkLocation() async {
    if (_isCheckingLocation) return;
    setState(() {
      _isCheckingLocation = true;
    });

    final String errorGps = 'gps_tidak_aktif_harap_43'.tr(context: context);
    final String errorDenied = 'izin_lokasi_ditolak_19'.tr(context: context);
    final String errorDeniedForever = 'izin_lokasi_ditolak_secara_62'.tr(context: context);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception(errorGps);

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception(errorDenied);
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(errorDeniedForever);
      } 
      
      Position? position = await _getSafePosition();
      if (position == null) {
        throw Exception('Gagal mendapatkan sinyal GPS. Silakan coba beberapa saat lagi.');
      }
      
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      final company = authProvider.user?.company;
      final branch = authProvider.user?.branch;

      double branchLat = -6.200000;
      double branchLng = 106.816666;
      double radiusLimit = 50.0; // default 50 meter
      
      final locationSource = branch ?? company;
      if (locationSource != null) {
        if (locationSource['latitude'] != null) {
          branchLat = double.tryParse(locationSource['latitude'].toString()) ?? branchLat;
        }
        if (locationSource['longitude'] != null) {
          branchLng = double.tryParse(locationSource['longitude'].toString()) ?? branchLng;
        }
        if (locationSource['radius_meters'] != null) {
          radiusLimit = double.tryParse(locationSource['radius_meters'].toString()) ?? radiusLimit;
        }
      }

      double distance = Geolocator.distanceBetween(
        position.latitude, position.longitude,
        branchLat, branchLng,
      );

      if (mounted) {
        if (kDebugMode || distance <= radiusLimit) {
          setState(() {
            _isLocationValid = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(kDebugMode ? 'debug_mode_lokasi_bypass_32'.tr(context: context) : 'lokasi_valid_anda_berada_41'.tr(context: context)),
              backgroundColor: AppColors.successFill,
            ),
          );
        } else {
          setState(() {
            _isLocationValid = false;
          });
          _showOutOfRadiusDialog(distance, radiusLimit);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.dangerFill),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingLocation = false;
        });
      }
    }
  }

  Future<void> _takeSelfie() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image == null) return;

      setState(() {
        _isProcessingSelfie = true;
      });

      final rawFile = File(image.path);
      final tempDir = await getTemporaryDirectory();

      List<Face> faces = [];
      try {
        final inputImage = InputImage.fromFilePath(image.path);
        final faceDetector = FaceDetector(
          options: FaceDetectorOptions(
            enableClassification: false,
            enableLandmarks: false,
            enableTracking: false,
            performanceMode: FaceDetectorMode.fast,
          ),
        );
        faces = await faceDetector.processImage(inputImage);
        await faceDetector.close();
      } catch (e) {
        debugPrint('Face detection fallback: $e');
      }

      final bytes = await rawFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        // Direct fallback: use raw file
        if (mounted) {
          setState(() {
            _selfieImage = rawFile;
            _isProcessingSelfie = false;
          });
        }
        return;
      }

      // Pastikan orientasi EXIF di-bake tegak lurus
      originalImage = img.bakeOrientation(originalImage);

      img.Image croppedImage;

      if (faces.isNotEmpty) {
        // Ambil wajah terbesar/paling dominan di kamera
        faces.sort((a, b) {
          final areaA = a.boundingBox.width * a.boundingBox.height;
          final areaB = b.boundingBox.width * b.boundingBox.height;
          return areaB.compareTo(areaA);
        });

        final face = faces.first;
        final rect = face.boundingBox;

        // Auto-zoom dan crop di area wajah dengan margin potret proporsional
        final double centerX = rect.center.dx.clamp(0.0, originalImage.width.toDouble());
        final double centerY = rect.center.dy.clamp(0.0, originalImage.height.toDouble());
        final double faceSize = max(rect.width, rect.height);
        final double cropSize = max(faceSize * 1.8, 120.0);

        final int cropX = (centerX - cropSize / 2).round().clamp(0, originalImage.width - 1);
        final int cropY = (centerY - cropSize / 2).round().clamp(0, originalImage.height - 1);
        final int cropW = cropSize.round().clamp(1, originalImage.width - cropX);
        final int cropH = cropSize.round().clamp(1, originalImage.height - cropY);
        final int side = min(cropW, cropH);

        croppedImage = img.copyCrop(
          originalImage,
          x: cropX,
          y: cropY,
          width: side,
          height: side,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.face_retouching_natural_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('wajah_terdeteksi_terzoom_crop_433'.tr(context: context))),
                ],
              ),
              backgroundColor: AppColors.successFill,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Fallback: Crop bujur sangkar di tengah jika ML Kit tidak mendeteksi wajah dengan jelas
        final int side = min(originalImage.width, originalImage.height);
        final int cropX = ((originalImage.width - side) / 2).round().clamp(0, originalImage.width - 1);
        final int cropY = ((originalImage.height - side) / 2).round().clamp(0, originalImage.height - 1);

        croppedImage = img.copyCrop(
          originalImage,
          x: cropX,
          y: cropY,
          width: side,
          height: side,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.center_focus_strong, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('wajah_kurang_jelas_foto_434'.tr(context: context))),
                ],
              ),
              backgroundColor: AppColors.warningFill,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }

      // Resize ke resolusi compact 400x400 agar tajam & hemat server (< 40 KB)
      final img.Image resizedImage = img.copyResize(
        croppedImage,
        width: 400,
        height: 400,
        interpolation: img.Interpolation.linear,
      );

      final finalJpgBytes = img.encodeJpg(resizedImage, quality: 75);
      final finalPath = '${tempDir.path}/selfie_face_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final finalFile = File(finalPath);
      await finalFile.writeAsBytes(finalJpgBytes);

      if (mounted) {
        setState(() {
          _selfieImage = finalFile;
          _isProcessingSelfie = false;
        });
      }
    } catch (e) {
      debugPrint('Selfie processing error: $e');
      if (mounted) {
        setState(() {
          _isProcessingSelfie = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('failed_process_photo'.tr(context: context, args: [e.toString()])),
            backgroundColor: AppColors.dangerFill,
          ),
        );
      }
    }
  }

  Future<void> _openShift() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final isOwner = user?.role == 'owner_5'.tr(context: context);
    final isCashierOrOwner = isOwner || (user?.canAccessPos ?? false);
    final requireAttendance = user?.company?['require_attendance'] == 1 || user?.company?['require_attendance'] == true;
    final requireCashDrawer = (user?.company?['require_cash_drawer_balance'] == null 
        ? true 
        : (user?.company?['require_cash_drawer_balance'] == 1 || user?.company?['require_cash_drawer_balance'] == true)) && isCashierOrOwner;

    double openingBalance = 0.0;
    if (requireCashDrawer) {
      final cleanText = _openingBalanceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('harap_masukkan_saldo_awal_435'.tr(context: context))),
        );
        return;
      }
      openingBalance = double.tryParse(cleanText) ?? 0.0;
    }
    
    if (requireAttendance && !isOwner && _selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('selfie_wajib_diambil_untuk_436'.tr(context: context))),
      );
      return;
    }

    final token = auth.token;
    if (token == null) return;

    Position? position;
    if (requireAttendance && !isOwner) {
      if (!_isLocationValid) {
        await _checkLocation();
        if (!_isLocationValid) return;
      }
      position = await _getSafePosition();
    }

    if (!mounted) return;
    try {
      final success = await context.read<ShiftProvider>().startShift(
        token,
        openingBalance,
        _selfieImage,
        position?.latitude,
        position?.longitude,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Shift berhasil dibuka!'.tr()), backgroundColor: AppColors.successFill),
        );
        _openingBalanceController.clear();
        setState(() {
          _selfieImage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        if (errorMsg.contains('luar jangkauan')) {
          _checkLocation();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: AppColors.dangerFill),
          );
        }
      }
    }
  }

  void _showCloseShiftDialog() {
    final auth = context.read<AuthProvider>();
    final isOwner = auth.user?.role == 'owner_5'.tr(context: context);
    final isCashierOrOwner = isOwner || (auth.user?.canAccessPos ?? false);
    final requireCashDrawer = (auth.user?.company?['require_cash_drawer_balance'] == null 
        ? true 
        : (auth.user?.company?['require_cash_drawer_balance'] == 1 || auth.user?.company?['require_cash_drawer_balance'] == true)) && isCashierOrOwner;

    if (requireCashDrawer) {
      final cleanText = _closingBalanceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('harap_masukkan_saldo_akhir_437'.tr(context: context))),
        );
        return;
      }
    }

    final requireOpname = auth.user?.company?['require_opname_on_shift_close'] == 1 || 
                          auth.user?.company?['require_opname_on_shift_close'] == true;

    if (!requireOpname) {
      _processCloseShift([]);
      return;
    }

    final ingredients = context.read<IngredientProvider>().ingredients;
    if (ingredients.isEmpty) {
      _processCloseShift([]);
      return;
    }

    final List<TextEditingController> qtyControllers = List.generate(
      ingredients.length, 
      (index) => TextEditingController(),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: AppColors.infoFill),
              const SizedBox(width: 10),
              Expanded(child: Text('input_stok_akhir_dapur_438'.tr(context: context), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.5,
              maxWidth: 420,
            ),
            child: SizedBox(
              width: double.maxFinite,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: ingredients.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = ingredients[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('unit_label_prefix'.tr(context: context, args: [item.unit]), style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        SizedBox(
                          width: 110,
                          child: TextField(
                            controller: qtyControllers[index],
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Sisa (${item.unit})',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('batal_5'.tr(context: context)),
            ),
            ElevatedButton(
              onPressed: () {
                List<Map<String, dynamic>> opnameData = [];
                for (int i = 0; i < ingredients.length; i++) {
                  final text = qtyControllers[i].text.trim();
                  if (text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('harap_isi_semua_sisa_439'.tr(context: context))),
                    );
                    return;
                  }
                  final qty = double.tryParse(text);
                  if (qty == null || qty < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('format_angka_tidak_valid_440'.tr(context: context))),
                    );
                    return;
                  }
                  opnameData.add({
                    'ingredient_id': ingredients[i].id,
                    'actual_qty': qty,
                  });
                }
                Navigator.pop(dialogContext);
                _processCloseShift(opnameData);
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('simpan_tutup_shift_441'.tr(context: context)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processCloseShift(List<Map<String, dynamic>> opnameData) async {
    final provider = context.read<ShiftProvider>();
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null || provider.activeShift == null) return;

    final isOwner = auth.user?.role == 'owner_5'.tr(context: context);
    final isCashierOrOwner = isOwner || (auth.user?.canAccessPos ?? false);
    final requireCashDrawer = (auth.user?.company?['require_cash_drawer_balance'] == null 
        ? true 
        : (auth.user?.company?['require_cash_drawer_balance'] == 1 || auth.user?.company?['require_cash_drawer_balance'] == true)) && isCashierOrOwner;

    double closingBalance = 0.0;
    if (requireCashDrawer) {
      final cleanText = _closingBalanceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      closingBalance = double.tryParse(cleanText) ?? 0.0;
    } else {
      final shift = provider.activeShift!;
      closingBalance = isCashierOrOwner
          ? (shift.expectedCashBalance ?? ((shift.openingBalance) + (shift.cashRevenue ?? 0.0)))
          : shift.openingBalance;
    }

    try {
      final success = await provider.endShift(
        token,
        provider.activeShift!.id,
        closingBalance,
        opnameData,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Shift ditutup. Data kas & stok tersinkronisasi.'.tr()), backgroundColor: AppColors.successFill),
        );
        _closingBalanceController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.dangerFill),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final provider = context.watch<ShiftProvider>();
    final isShiftOpen = provider.activeShift != null;

    if (provider.isLoading && !isShiftOpen && _openingBalanceController.text.isEmpty) {
      return Scaffold(backgroundColor: theme.scaffoldBackgroundColor, body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      body: RefreshIndicator(
        onRefresh: _refreshShiftData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            ZenviHeader.sliver(
              title: 'manajemen_shift_title'.tr(context: context) == 'manajemen_shift_title' ? 'Manajemen Shift' : 'manajemen_shift_title'.tr(context: context),
              showBackButton: Navigator.of(context).canPop(),
              subtitleWidget: Text(
                isShiftOpen ? 'Sedang Bertugas' : 'Mulai Shift Anda',
                style: TextStyle(
                  color: isShiftOpen ? AppColors.successText : theme.colorScheme.onSurfaceVariant,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: (isShiftOpen ? AppColors.successFill : theme.colorScheme.primary).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isShiftOpen ? Icons.check_circle_rounded : Icons.access_time_filled_rounded,
                    color: isShiftOpen ? AppColors.successText : theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
              ],
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 120.0), // padding bottom for bottom nav
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: KeyedSubtree(
                        key: ValueKey<bool>(isShiftOpen),
                        child: isShiftOpen 
                          ? _buildActiveShift(theme, provider, authProvider) 
                          : _buildClosedShift(theme, provider, authProvider),
                      ),
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

  Widget _buildClosedShift(ThemeData theme, ShiftProvider provider, AuthProvider authProvider) {
    final user = authProvider.user;
    final isOwner = user?.role == 'owner_5'.tr(context: context);
    final isCashierOrOwner = isOwner || (user?.canAccessPos ?? false);
    final requireAttendance = user?.company?['require_attendance'] == 1 || user?.company?['require_attendance'] == true;
    final requireCashDrawer = (user?.company?['require_cash_drawer_balance'] == null 
        ? true 
        : (user?.company?['require_cash_drawer_balance'] == 1 || user?.company?['require_cash_drawer_balance'] == true)) && isCashierOrOwner;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_clock_rounded, size: 44, color: theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'shift_closed'.tr(),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4, fontSize: 18),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              requireCashDrawer
                  ? 'Buka shift kasir dengan memasukkan saldo awal laci'
                  : (isCashierOrOwner ? 'Buka shift kasir untuk memulai transaksi hari ini' : 'Buka shift untuk mulai bekerja & mencatat absensi'),
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 28),
          
          if (requireCashDrawer) ...[
            Text(
              'Saldo Awal Kasir (Uang Tunai di Laci):',
              style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
              ),
              child: TextField(
                controller: _openingBalanceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Rp 0',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          if (requireAttendance && !_isLocationValid) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.location_off, color: theme.colorScheme.error, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    'Lokasi Anda belum tervalidasi di area cabang.',
                    style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _isCheckingLocation ? null : _checkLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: _isCheckingLocation
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.my_location, size: 18),
                      label: Text(_isCheckingLocation ? 'Mengecek...' : 'Cek Lokasi GPS', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Selfie Section (Only for Employees if Required)
            if (requireAttendance && !isOwner) ...[
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isProcessingSelfie)
                          Container(
                            height: 140,
                            width: 140,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(strokeWidth: 2.5),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Deteksi wajah...',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (_selfieImage != null)
                          Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.successFill, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.successFill.withValues(alpha: 0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.file(_selfieImage!, height: 140, width: 140, fit: BoxFit.cover),
                                ),
                              ),
                              Positioned(
                                right: 6,
                                bottom: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.successFill,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                                ),
                              ),
                            ],
                          )
                        else
                          Container(
                            height: 140,
                            width: 140,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.face_retouching_natural_rounded, size: 44, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                                const SizedBox(height: 6),
                                Text(
                                  'Auto-Crop Wajah',
                                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isProcessingSelfie ? null : _takeSelfie,
                      icon: Icon(_selfieImage != null ? Icons.refresh_rounded : Icons.camera_alt_outlined, size: 18),
                      label: Text(_selfieImage != null ? 'Foto Ulang' : 'Ambil Selfie Presensi (Wajib)'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: provider.isLoading ? null : _openShift,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: provider.isLoading 
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text('open_shift'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmployeePermissionScreen()),
                );
              },
              icon: const Icon(Icons.edit_calendar_rounded, size: 18),
              label: const Text(
                'Ajukan Izin Libur / Telat Masuk',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveShift(ThemeData theme, ShiftProvider provider, AuthProvider authProvider) {
    final shift = provider.activeShift!;
    final user = authProvider.user;
    final isOwner = user?.role == 'owner_5'.tr(context: context);
    final isCashierOrOwner = isOwner || (user?.canAccessPos ?? false);
    final requireCashDrawer = (user?.company?['require_cash_drawer_balance'] == null 
        ? true 
        : (user?.company?['require_cash_drawer_balance'] == 1 || user?.company?['require_cash_drawer_balance'] == true)) && isCashierOrOwner;

    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'rp_3'.tr(context: context), decimalDigits: 0);

    final double enteredClosing = double.tryParse(_closingBalanceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
    final double expectedCash = shift.expectedCashBalance ?? ((shift.openingBalance) + (shift.cashRevenue ?? 0.0));
    final double diff = enteredClosing - expectedCash;
    final bool hasEnteredClosing = _closingBalanceController.text.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          )
        ],
        border: Border.all(color: AppColors.successFill.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.successFill.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, size: 28, color: AppColors.successFill),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'shift_active'.tr(),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        'shift_started_at'.tr(args: [DateFormat('hhmm_5'.tr(context: context)).format(shift.startTime)]),
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: _refreshShiftData,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'refresh_shift_data_tooltip'.tr(context: context),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (isCashierOrOwner) ...[
            // Ringkasan Keuangan Shift Card (Khusus Kasir & Owner)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('rincian_keuangan_shift_447'.tr(context: context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  
                  // Saldo Awal
                  if (requireCashDrawer) ...[
                    _buildShiftSummaryRow('Saldo Awal Kasir', currencyFormatter.format(shift.openingBalance), theme),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(height: 1),
                    ),
                  ],

                  // Penjualan Tunai
                  _buildShiftSummaryRow(
                    '💵 Penjualan Tunai (Cash)', 
                    currencyFormatter.format(shift.cashRevenue ?? 0), 
                    theme,
                    valueColor: AppColors.successText,
                  ),
                  const SizedBox(height: 6),

                  // Penjualan QRIS
                  _buildShiftSummaryRow(
                    '📱 Penjualan QRIS (Non-Tunai)',
                    currencyFormatter.format(shift.qrisRevenue ?? 0),
                    theme,
                    valueColor: AppColors.infoText,
                  ),
                  const SizedBox(height: 6),

                  // Penjualan Transfer
                  _buildShiftSummaryRow(
                    '🏦 Penjualan Transfer (Non-Tunai)', 
                    currencyFormatter.format(shift.transferRevenue ?? 0), 
                    theme,
                    valueColor: Colors.purple[700],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(height: 1),
                  ),

                  // Total Omzet
                  _buildShiftSummaryRow(
                    'Total Seluruh Penjualan', 
                    currencyFormatter.format(shift.totalRevenue ?? 0), 
                    theme,
                    isBold: true,
                  ),
                ],
              ),
            ),
            
            if (requireCashDrawer) ...[
              const SizedBox(height: 16),

              // Highlight Expected Physical Cash Drawer Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.point_of_sale_rounded, size: 16, color: theme.colorScheme.primary),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Kas Fisik di Laci Kasir',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '(Saldo Awal + Penjualan Tunai)',
                                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          currencyFormatter.format(expectedCash),
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '💡 QRIS & Transfer langsung masuk ke rekening bank/e-wallet, sehingga tidak dihitung di laci fisik kasir.',
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Input Closing Balance
              Text(
                'Hitung Uang Tunai di Laci & Masukkan Saldo Akhir:',
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                ),
                child: TextField(
                  controller: _closingBalanceController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Rp 0 (Uang Fisik Laci)',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                  ),
                ),
              ),
              
              if (hasEnteredClosing) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: diff == 0
                        ? AppColors.successFill.withValues(alpha: 0.1)
                        : (diff > 0 ? AppColors.warningFill.withValues(alpha: 0.1) : AppColors.dangerFill.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: diff == 0 ? AppColors.successFill.withValues(alpha: 0.35) : (diff > 0 ? AppColors.warningFill.withValues(alpha: 0.35) : AppColors.dangerFill.withValues(alpha: 0.35)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        diff == 0 ? '✅ Selisih Kas: Pas (Sesuai)' : (diff > 0 ? '⚠️ Selisih Kas (Lebih):' : '❌ Selisih Kas (Kurang):'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: diff == 0 ? AppColors.successText : (diff > 0 ? AppColors.warningText : AppColors.dangerText),
                        ),
                      ),
                      Text(
                        currencyFormatter.format(diff.abs()),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: diff == 0 ? AppColors.successText : (diff > 0 ? AppColors.warningText : AppColors.dangerText),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ] else ...[
            // Informasi Shift Kerja (Khusus Karyawan Non-Kasir)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.badge_outlined, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('informasi_shift_kerja_452'.tr(context: context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildShiftSummaryRow('Posisi / Jabatan', user?.jobTitle ?? 'karyawan_8'.tr(context: context), theme),
                  const SizedBox(height: 8),
                  _buildShiftSummaryRow('Cabang Penugasan', shift.branch?.name ?? 'Cabang Utama', theme),
                  const SizedBox(height: 8),
                  _buildShiftSummaryRow('Waktu Mulai Bertugas', DateFormat('dd MMM yyyy, HH:mm').format(shift.startTime), theme),
                  const SizedBox(height: 8),
                  _buildShiftSummaryRow('Status Kehadiran', '✅ Hadir & Aktif Bertugas', theme, valueColor: AppColors.successText),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          
          // Action Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: provider.isLoading ? null : _showCloseShiftDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              icon: provider.isLoading 
                ? const SizedBox.shrink()
                : const Icon(Icons.lock_rounded, size: 18),
              label: provider.isLoading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text('close_shift'.tr(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftSummaryRow(String label, String value, ThemeData theme, {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 13 : 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? (isBold ? theme.colorScheme.onSurface : theme.colorScheme.onSurface),
            fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
            fontSize: isBold ? 14 : 12,
          ),
        ),
      ],
    );
  }
}

