import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/reservation_model.dart';
import '../../providers/reservation_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';

class ReservationSelectionModal extends StatefulWidget {
  const ReservationSelectionModal({super.key});

  @override
  State<ReservationSelectionModal> createState() => _ReservationSelectionModalState();
}

class _ReservationSelectionModalState extends State<ReservationSelectionModal> {
  final TextEditingController _searchController = TextEditingController();
  String _dateFilter = 'today'; // 'today', 'upcoming', 'all'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final branchId = auth.user?.branchId;
      Provider.of<ReservationProvider>(context, listen: false).fetchReservations(
        date: _dateFilter == 'all' ? null : _dateFilter,
        branchId: branchId,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onDateFilterChanged(String filter) {
    setState(() {
      _dateFilter = filter;
    });
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final branchId = auth.user?.branchId;
    Provider.of<ReservationProvider>(context, listen: false).fetchReservations(
      date: filter == 'all' ? null : filter,
      branchId: branchId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resProvider = Provider.of<ReservationProvider>(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.event_available_rounded, color: theme.colorScheme.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'select_reservation_title'.tr(context: context),
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => resProvider.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'cari_pesanan_pelanggan_215'.tr(context: context),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          resProvider.setSearchQuery('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),
          ),

          // Date Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'reservation_filter_today'.tr(context: context),
                  filterKey: 'today',
                  theme: theme,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'reservation_filter_upcoming'.tr(context: context),
                  filterKey: 'upcoming',
                  theme: theme,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'reservation_filter_all'.tr(context: context),
                  filterKey: 'all',
                  theme: theme,
                ),
              ],
            ),
          ),

          const Divider(height: 16),

          // Reservations List
          Expanded(
            child: resProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : resProvider.filteredReservations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy_rounded,
                              size: 64,
                              color: theme.colorScheme.outline.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'no_reservations_found'.tr(context: context),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: resProvider.filteredReservations.length,
                        itemBuilder: (context, index) {
                          final item = resProvider.filteredReservations[index];
                          return _buildReservationCard(context, theme, item);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String filterKey,
    required ThemeData theme,
  }) {
    final isSelected = _dateFilter == filterKey;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onDateFilterChanged(filterKey),
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: theme.colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildReservationCard(BuildContext context, ThemeData theme, ReservationModel item) {
    final isConfirmed = item.status == 'confirmed';
    final isPending = item.status == 'pending';
    Color statusFillColor = isConfirmed ? AppColors.successFill : (isPending ? AppColors.warningFill : theme.colorScheme.onSurfaceVariant);
    Color statusTextColor = isConfirmed ? AppColors.successText : (isPending ? AppColors.warningText : theme.colorScheme.onSurfaceVariant);
    String statusText = isConfirmed ? 'Dikonfirmasi' : (isPending ? 'Menunggu' : item.status.toUpperCase());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConfirmed ? AppColors.successFill.withValues(alpha: 0.3) : theme.colorScheme.outline.withValues(alpha: 0.15),
          width: isConfirmed ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Customer Name & Time Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                        child: Text(
                          item.customerName.isNotEmpty ? item.customerName[0].toUpperCase() : '?',
                          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.customerName,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              item.customerPhone,
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule_rounded, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${item.reservationDate} • ${item.reservationTime}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Details: People / Services / Notes / Staff
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                if (item.numberOfPeople > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.group_rounded, size: 14, color: theme.colorScheme.secondary),
                        const SizedBox(width: 4),
                        Text(
                          'guests_count_label'.tr(context: context, args: [item.numberOfPeople.toString()]),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
                        ),
                      ],
                    ),
                  ),
                if (item.serviceNames != null && item.serviceNames!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.spa_rounded, size: 14, color: theme.colorScheme.tertiary),
                        const SizedBox(width: 4),
                        Text(
                          'services_label'.tr(context: context, args: [item.serviceNames!]),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.tertiary),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusFillColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusTextColor),
                  ),
                ),
              ],
            ),

            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'notes_label_prefix'.tr(context: context, args: [item.notes!]),
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () {
                  Navigator.pop(context, item);
                },
                icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                label: Text(
                  'serve_reservation_btn'.tr(context: context),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
