import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branch_provider.dart';
import '../../models/branch_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/zenvi_header.dart';

class BranchFormScreen extends StatefulWidget {
  final BranchModel? branch;
  const BranchFormScreen({super.key, this.branch});

  @override
  State<BranchFormScreen> createState() => _BranchFormScreenState();
}

class _BranchFormScreenState extends State<BranchFormScreen> {
  final _nameController = TextEditingController();
  final _radiusController = TextEditingController(text: '100');
  LatLng _selectedLocation = const LatLng(-6.200000, 106.816666); // Jakarta Default
  final MapController _mapController = MapController();
  bool _isLoading = false;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.branch != null) {
      _nameController.text = widget.branch!.name;
      _radiusController.text = widget.branch!.radiusMeters.toString();
      _selectedLocation = LatLng(widget.branch!.latitude, widget.branch!.longitude);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getCurrentLocation();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('layanan_lokasi_gps_tidak_363'.tr(context: context))),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 6),
        ),
      );

      if (!mounted) return;

      final newLocation = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _selectedLocation = newLocation;
      });

      if (_isMapReady) {
        try {
          _mapController.move(newLocation, 15.0);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _saveBranch() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('silakan_masukkan_nama_cabang_364'.tr(context: context))),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }

    final provider = context.read<BranchProvider>();
    final radius = int.tryParse(_radiusController.text.trim()) ?? 100;
    
    bool success;
    if (widget.branch == null) {
      success = await provider.addBranch(token, name, _selectedLocation.latitude, _selectedLocation.longitude, radius);
    } else {
      success = await provider.updateBranch(token, widget.branch!.id, name, _selectedLocation.latitude, _selectedLocation.longitude, radius);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.branch == null ? 'Cabang berhasil ditambahkan' : 'Cabang berhasil diperbarui'),
          backgroundColor: AppColors.successText,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Gagal menyimpan cabang. Silakan periksa koneksi.'),
          backgroundColor: AppColors.dangerText,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: ZenviHeader(
        title: widget.branch == null ? 'Tambah Cabang Baru' : 'Edit Cabang',
        showBackButton: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Cabang',
                      hintText: 'Contoh: Cabang Kemang, Cabang 2',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      prefixIcon: const Icon(Icons.storefront_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _radiusController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Radius Absensi Karyawan (Meter)',
                      hintText: '50 - 500',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      prefixIcon: const Icon(Icons.radar_rounded),
                      suffixText: 'Meter',
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('tentukan_titik_lokasi_cabang_365'.tr(context: context), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_selectedLocation.latitude.toStringAsFixed(4)}, ${_selectedLocation.longitude.toStringAsFixed(4)}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onPrimaryContainer),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('geser_atau_sentuh_peta_366'.tr(context: context), style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                  const SizedBox(height: 16),
                  
                  Container(
                    height: 320,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _selectedLocation,
                            initialZoom: 15.0,
                            onMapReady: () {
                              _isMapReady = true;
                              try {
                                _mapController.move(_selectedLocation, 15.0);
                              } catch (_) {}
                            },
                            onTap: (tapPosition, point) {
                              setState(() {
                                _selectedLocation = point;
                              });
                            },
                            onPositionChanged: (camera, hasGesture) {
                              if (hasGesture) {
                                _selectedLocation = camera.center;
                              }
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.zenvi',
                            ),
                          ],
                        ),
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 38.0),
                            child: Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 48,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: FloatingActionButton.small(
                            backgroundColor: theme.colorScheme.surface,
                            elevation: 4,
                            onPressed: () async {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('mencari_lokasi_perangkat_367'.tr(context: context)), duration: const Duration(seconds: 1)),
                              );
                              await _getCurrentLocation();
                            },
                            child: Icon(Icons.my_location, color: theme.colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveBranch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) 
                      : Text('simpan_cabang_368'.tr(context: context), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
