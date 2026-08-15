import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/printer_provider.dart';
import '../../widgets/zenvi_header.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PrinterProvider>(context, listen: false).scanDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final printerProvider = Provider.of<PrinterProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: ZenviHeader(
        title: 'pengaturan_printer_303'.tr(context: context),
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              printerProvider.scanDevices();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: printerProvider.isConnected ? Colors.green.shade50 : Colors.red.shade50,
            child: Row(
              children: [
                Icon(
                  printerProvider.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                  color: printerProvider.isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        printerProvider.isConnected ? 'terhubung_9'.tr(context: context) : 'terputus_8'.tr(context: context),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: printerProvider.isConnected ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                      ),
                      if (printerProvider.selectedDevice != null)
                        Text(printerProvider.selectedDevice!.name ?? 'unknown_device_14'.tr(context: context)),
                    ],
                  ),
                ),
                if (printerProvider.isConnected)
                  TextButton(
                    onPressed: () => printerProvider.disconnect(),
                    child: Text('putuskan_304'.tr(context: context), style: const TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ),
          
          Expanded(
            child: printerProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : printerProvider.devices.isEmpty
                    ? Center(
                        child: Text('tidak_ada_perangkat_bluetooth_305'.tr(context: context)),
                      )
                    : ListView.builder(
                        itemCount: printerProvider.devices.length,
                        itemBuilder: (context, index) {
                          final device = printerProvider.devices[index];
                          final isSelected = printerProvider.selectedDevice?.address == device.address;
                          
                          return ListTile(
                            leading: Icon(
                              Icons.print,
                              color: isSelected ? theme.colorScheme.primary : Colors.grey,
                            ),
                            title: Text(device.name ?? 'unknown_device_14'.tr(context: context)),
                            subtitle: Text(device.address ?? ''),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : ElevatedButton(
                                    onPressed: () async {
                                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                                      scaffoldMessenger.showSnackBar(
                                        SnackBar(content: Text('connecting_to_device'.tr(context: context, args: [device.name ?? 'unknown_device_14'.tr(context: context)]))),
                                      );
                                      
                                      // Get translated strings before async gap
                                      final successText = 'berhasil_terhubung_306'.tr(context: context);
                                      final failureText = 'gagal_terhubung_ke_printer_307'.tr(context: context);
                                      
                                      final success = await printerProvider.connect(device);
                                      
                                      if (mounted) {
                                        if (success) {
                                          scaffoldMessenger.showSnackBar(
                                            SnackBar(content: Text(successText)),
                                          );
                                        } else {
                                          scaffoldMessenger.showSnackBar(
                                            SnackBar(content: Text(failureText)),
                                          );
                                        }
                                      }
                                    },
                                    child: Text('connect_308'.tr(context: context)),
                                  ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
