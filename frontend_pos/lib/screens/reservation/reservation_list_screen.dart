import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/reservation_model.dart';
import '../../providers/reservation_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/branch_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/member_provider.dart';
import '../../widgets/zenvi_header.dart';

class ReservationListScreen extends StatefulWidget {
  const ReservationListScreen({super.key});

  @override
  State<ReservationListScreen> createState() => _ReservationListScreenState();
}

class _ReservationListScreenState extends State<ReservationListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    final resProvider = Provider.of<ReservationProvider>(context, listen: false);
    resProvider.fetchReservations();
    Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      Provider.of<BranchProvider>(context, listen: false).fetchBranches(token);
    }
  }

  String _formatDateDisplay(BuildContext context, String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final checkDate = DateTime(date.year, date.month, date.day);
      final lang = context.locale.languageCode;

      if (checkDate == today) {
        return 'date_today_fmt'.tr(context: context, args: [DateFormat('d MMM yyyy', lang).format(date)]);
      } else if (checkDate == today.add(const Duration(days: 1))) {
        return 'date_tomorrow_fmt'.tr(context: context, args: [DateFormat('d MMM yyyy', lang).format(date)]);
      } else {
        return DateFormat('EEEE, d MMMM yyyy', lang).format(date);
      }
    } catch (_) {
      return dateStr;
    }
  }

  String _formatTimeDisplay(String timeStr) {
    try {
      if (timeStr.length >= 5) {
        return timeStr.substring(0, 5); // HH:mm
      }
      return timeStr;
    } catch (_) {
      return timeStr;
    }
  }

  Future<void> _openWhatsApp(ReservationModel res, String storeName) async {
    String phone = res.customerPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.startsWith('0')) {
      phone = '62${phone.substring(1)}';
    } else if (phone.startsWith('8')) {
      phone = '62$phone';
    }

    final message = Uri.encodeComponent(
      'Halo Kak ${res.customerName}, kami dari *$storeName*.\n'
      'Mengenai reservasi Anda pada:\n'
      '📅 Tanggal: ${res.reservationDate}\n'
      '⏰ Jam: ${_formatTimeDisplay(res.reservationTime)} WIB\n'
      '👥 Jumlah: ${res.numberOfPeople} orang\n'
      '${res.serviceNames != null && res.serviceNames!.isNotEmpty ? "✂️ Layanan: ${res.serviceNames}\n" : ""}'
      'Status reservasi Anda: *${res.status.toUpperCase()}*.\n\n'
      'Apakah ada yang ingin dikonfirmasi atau ditanyakan kembali? Terima kasih! 🙏',
    );

    // Prioritize direct WhatsApp scheme then web links
    final List<Uri> uris = [
      Uri.parse('whatsapp://send?phone=$phone&text=$message'),
      Uri.parse('https://wa.me/$phone?text=$message'),
      Uri.parse('https://api.whatsapp.com/send?phone=$phone&text=$message'),
    ];

    bool launched = false;
    for (final uri in uris) {
      try {
        if (await canLaunchUrl(uri)) {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (launched) break;
        } else {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (launched) break;
        }
      } catch (e) {
        debugPrint('WhatsApp launch attempt failed for $uri: $e');
      }
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('cannot_open_wa'.tr(context: context, args: [res.customerPhone])),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanNumber');
    bool launched = false;
    try {
      if (await canLaunchUrl(uri)) {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Phone call launch failed: $e');
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('cannot_make_call'.tr(context: context, args: [phoneNumber])),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _serveInPos(BuildContext context, ReservationModel res) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.setSelectedReservation(res);

    // Auto select member if matches
    final memberProv = Provider.of<MemberProvider>(context, listen: false);
    final matchingMember = memberProv.members.where((m) =>
      (m.phone.isNotEmpty && m.phone == res.customerPhone) ||
      (m.name.isNotEmpty && m.name.toLowerCase() == res.customerName.toLowerCase())
    ).firstOrNull;

    if (matchingMember != null) {
      cart.setSelectedMember(matchingMember);
    }

    // Auto add matching services
    if (res.serviceNames != null && res.serviceNames!.isNotEmpty) {
      final prodProv = Provider.of<ProductProvider>(context, listen: false);
      final services = res.serviceNames!.split(RegExp(r'[,;|\n]')).map((s) => s.trim().toLowerCase()).where((s) => s.isNotEmpty);
      for (final serviceName in services) {
        final matchingProduct = prodProv.products.where((p) => p.name.toLowerCase().contains(serviceName) || serviceName.contains(p.name.toLowerCase())).firstOrNull;
        if (matchingProduct != null) {
          cart.addToCart(matchingProduct);
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('reservation_loaded_msg'.tr(context: context, args: [res.customerName])),
        backgroundColor: Colors.teal.shade700,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resProvider = Provider.of<ReservationProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final company = authProvider.user?.company;
    final storeName = company?['name']?.toString() ?? 'Zenvi';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      body: RefreshIndicator(
        onRefresh: () => resProvider.fetchReservations(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            ZenviHeader.sliver(
              showBackButton: true,
              title: _isSearchExpanded ? null : 'reservation_list_title'.tr(context: context),
              titleWidget: _isSearchExpanded
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'search_reservation_hint'.tr(context: context),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 14),
                      ),
                      onChanged: (val) => resProvider.setSearchQuery(val),
                    )
                  : null,
              actions: [
                IconButton(
                  icon: Icon(_isSearchExpanded ? Icons.close_rounded : Icons.search_rounded),
                  onPressed: () {
                    setState(() {
                      _isSearchExpanded = !_isSearchExpanded;
                      if (!_isSearchExpanded) {
                        _searchController.clear();
                        resProvider.setSearchQuery('');
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'segarkan_data_13'.tr(context: context),
                  onPressed: () => resProvider.fetchReservations(),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildStatusTabs(theme, resProvider),
                  _buildDateFilterRow(theme, resProvider),
                ],
              ),
            ),
            if (resProvider.isLoading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (resProvider.filteredReservations.isEmpty)
              SliverFillRemaining(child: _buildEmptyState(theme, resProvider))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final res = resProvider.filteredReservations[index];
                      return _buildReservationCard(context, theme, res, resProvider, storeName)
                          .animate(delay: (index * 40).ms)
                          .fade(duration: 350.ms)
                          .slideY(begin: 0.1, end: 0);
                    },
                    childCount: resProvider.filteredReservations.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReservationModal(context),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('tambah_reservasi_333'.tr(context: context), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatusTabs(ThemeData theme, ReservationProvider resProvider) {
    final tabs = [
      {'key': 'all', 'label': 'semua_5'.tr(context: context), 'count': resProvider.allReservations.length},
      {'key': 'pending', 'label': 'status_pending'.tr(context: context), 'count': resProvider.pendingCount},
      {'key': 'confirmed', 'label': 'status_confirmed'.tr(context: context), 'count': resProvider.confirmedCount},
      {'key': 'completed', 'label': 'status_completed'.tr(context: context), 'count': resProvider.completedCount},
      {'key': 'cancelled', 'label': 'status_cancelled'.tr(context: context), 'count': resProvider.cancelledCount},
    ];

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.08))),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isSelected = resProvider.selectedStatusFilter == tab['key'];
          final count = tab['count'] as int;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => resProvider.setStatusFilter(tab['key'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? theme.colorScheme.primary : theme.dividerColor.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      tab['label'] as String,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateFilterRow(ThemeData theme, ReservationProvider resProvider) {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final tomorrowStr = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // All Dates
            _buildDateChip(
              context: context,
              theme: theme,
              label: 'semua_tanggal_334'.tr(context: context),
              isSelected: resProvider.selectedDateFilter == null,
              onTap: () => resProvider.setDateFilter(null),
            ),
            const SizedBox(width: 8),
            // Today
            _buildDateChip(
              context: context,
              theme: theme,
              label: 'filter_today'.tr(context: context),
              isSelected: resProvider.selectedDateFilter == todayStr,
              onTap: () => resProvider.setDateFilter(resProvider.selectedDateFilter == todayStr ? null : todayStr),
            ),
            const SizedBox(width: 8),
            // Tomorrow
            _buildDateChip(
              context: context,
              theme: theme,
              label: 'besok_335'.tr(context: context),
              isSelected: resProvider.selectedDateFilter == tomorrowStr,
              onTap: () => resProvider.setDateFilter(resProvider.selectedDateFilter == tomorrowStr ? null : tomorrowStr),
            ),
            const SizedBox(width: 8),
            // Custom Date
            _buildDateChip(
              context: context,
              theme: theme,
              icon: Icons.calendar_month_rounded,
              label: (resProvider.selectedDateFilter != null &&
                      resProvider.selectedDateFilter != todayStr &&
                      resProvider.selectedDateFilter != tomorrowStr)
                  ? DateFormat('d MMM yyyy', context.locale.languageCode).format(DateTime.parse(resProvider.selectedDateFilter!))
                  : 'pick_date_hint'.tr(context: context),
              isSelected: (resProvider.selectedDateFilter != null &&
                  resProvider.selectedDateFilter != todayStr &&
                  resProvider.selectedDateFilter != tomorrowStr),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 180)),
                );
                if (picked != null) {
                  resProvider.setDateFilter(DateFormat('yyyy-MM-dd').format(picked));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip({
    required BuildContext context,
    required ThemeData theme,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.4)
                  : theme.dividerColor.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReservationCard(
    BuildContext context,
    ThemeData theme,
    ReservationModel res,
    ReservationProvider resProvider,
    String storeName,
  ) {
    Color statusColor;
    Color statusBg;
    String statusLabel;
    IconData statusIcon;

    final isDark = theme.brightness == Brightness.dark;

    switch (res.status) {
      case 'confirmed':
        statusColor = const Color(0xFF2563EB); // Soft Slate Blue
        statusBg = isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF);
        statusLabel = 'status_confirmed'.tr(context: context);
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'completed':
        statusColor = const Color(0xFF059669); // Soft Emerald
        statusBg = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5);
        statusLabel = 'status_completed'.tr(context: context);
        statusIcon = Icons.task_alt_rounded;
        break;
      case 'cancelled':
        statusColor = const Color(0xFFDC2626); // Soft Rose Red
        statusBg = isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : const Color(0xFFFEF2F2);
        statusLabel = 'status_cancelled'.tr(context: context);
        statusIcon = Icons.cancel_rounded;
        break;
      case 'pending':
      default:
        statusColor = const Color(0xFFD97706); // Soft Amber
        statusBg = isDark ? const Color(0xFF78350F).withValues(alpha: 0.3) : const Color(0xFFFEF3C7);
        statusLabel = 'status_pending'.tr(context: context);
        statusIcon = Icons.hourglass_top_rounded;
        break;
    }

    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final isToday = res.reservationDate == todayStr;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isToday
              ? theme.colorScheme.primary.withValues(alpha: 0.35)
              : theme.dividerColor.withValues(alpha: 0.08),
          width: isToday ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name & Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    res.customerName.isNotEmpty ? res.customerName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                      fontSize: 17,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        res.customerName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone_rounded, size: 13, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            res.customerPhone,
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withValues(alpha: 0.25), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 13, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.08)),
            const SizedBox(height: 12),

            // Time & Guest Details - UNIFIED CLEAN TONAL CHIPS
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                // Date Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: isToday
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: isToday ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _formatDateDisplay(context, res.reservationDate),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                          color: isToday ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                // Time Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time_rounded, size: 13, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 5),
                      Text(
                        '${_formatTimeDisplay(res.reservationTime)} WIB',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                // Guests Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline_rounded, size: 13, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 5),
                      Text(
                        'guests_count_badge'.tr(context: context, args: [res.numberOfPeople.toString()]),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Service Names
            if (res.serviceNames != null && res.serviceNames!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.spa_rounded, size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      res.serviceNames!,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Notes
            if (res.notes != null && res.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes_rounded, size: 13, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        res.notes!,
                        style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Branch if present
            if (res.branch != null && res.branch!['name'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.store_rounded, size: 13, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'branch_label_prefix'.tr(context: context, args: [res.branch!['name']]),
                    style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                // WhatsApp Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openWhatsApp(res, storeName),
                    borderRadius: BorderRadius.circular(10),
                    child: Ink(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
                      ),
                      child: Icon(Icons.chat_bubble_outline_rounded, size: 16, color: theme.colorScheme.onSurface),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Phone Call Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _makePhoneCall(res.customerPhone),
                    borderRadius: BorderRadius.circular(10),
                    child: Ink(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
                      ),
                      child: Icon(Icons.phone_in_talk_rounded, size: 16, color: theme.colorScheme.onSurface),
                    ),
                  ),
                ),
                const Spacer(),

                // Status Change Action Buttons
                if (res.status == 'pending') ...[
                  OutlinedButton(
                    onPressed: () => _confirmChangeStatus(context, res, 'cancelled', resProvider),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.withValues(alpha: 0.25)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 36),
                    ),
                    child: Text('tolak_85'.tr(context: context), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _changeStatus(res.id, 'confirmed', resProvider),
                    icon: const Icon(Icons.check_rounded, size: 15),
                    label: Text('konfirmasi_336'.tr(context: context), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                ] else if (res.status == 'confirmed') ...[
                  ElevatedButton.icon(
                    onPressed: () => _serveInPos(context, res),
                    icon: const Icon(Icons.point_of_sale_rounded, size: 15),
                    label: Text('serve_reservation_btn'.tr(context: context), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _confirmChangeStatus(context, res, 'cancelled', resProvider),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.withValues(alpha: 0.25)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 36),
                    ),
                    child: Text('batal_5'.tr(context: context), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _changeStatus(res.id, 'completed', resProvider),
                    icon: const Icon(Icons.task_alt_rounded, size: 15),
                    label: Text('selesai_301'.tr(context: context), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                ] else ...[
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz_rounded),
                    onSelected: (val) {
                      if (val == 'delete') {
                        _confirmDelete(context, res.id, resProvider);
                      } else {
                        _changeStatus(res.id, val, resProvider);
                      }
                    },
                    itemBuilder: (ctx) => [
                      if (res.status != 'confirmed')
                        PopupMenuItem(value: 'confirmed', child: Text('ubah_ke_dikonfirmasi_337'.tr(context: context))),
                      if (res.status != 'pending')
                        PopupMenuItem(value: 'pending', child: Text('kembalikan_ke_menunggu_338'.tr(context: context))),
                      if (res.status != 'completed')
                        PopupMenuItem(value: 'completed', child: Text('tandai_selesai_339'.tr(context: context))),
                      const PopupMenuDivider(),
                      PopupMenuItem(value: 'delete', child: Text('hapus_data_340'.tr(context: context), style: const TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _changeStatus(int id, String status, ReservationProvider resProvider) async {
    final success = await resProvider.updateReservationStatus(id, status);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('reservation_status_updated'.tr(context: context, args: [status.toUpperCase()])),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _confirmChangeStatus(BuildContext context, ReservationModel res, String targetStatus, ReservationProvider resProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('konfirmasi_pembatalan_341'.tr(context: context)),
        content: Text('cancel_reservation_confirm'.tr(context: context, args: [res.customerName])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('kembali_24'.tr(context: context))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _changeStatus(res.id, targetStatus, resProvider);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: Text('ya_batalkan_25'.tr(context: context)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id, ReservationProvider resProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('hapus_data_reservasi_342'.tr(context: context)),
        content: Text('data_reservasi_ini_akan_343'.tr(context: context)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('batal_5'.tr(context: context))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await resProvider.deleteReservation(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: Text('hapus_88'.tr(context: context)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ReservationProvider resProvider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.event_seat_rounded, size: 64, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'no_reservations_yet'.tr(context: context),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'reservations_empty_desc'.tr(context: context),
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddReservationModal(context),
              icon: const Icon(Icons.add_rounded),
              label: Text('tambah_reservasi_manual_346'.tr(context: context)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddReservationModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AddReservationBottomSheet(),
    );
  }
}

class _AddReservationBottomSheet extends StatefulWidget {
  const _AddReservationBottomSheet();

  @override
  State<_AddReservationBottomSheet> createState() => _AddReservationBottomSheetState();
}

class _AddReservationBottomSheetState extends State<_AddReservationBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _serviceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _numberOfPeople = 1;
  int? _selectedBranchId;
  final List<String> _selectedProductServices = [];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _serviceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resProvider = Provider.of<ReservationProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context);
    final branchProvider = Provider.of<BranchProvider>(context);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.bookmark_add_rounded, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'add_manual_reservation_title'.tr(context: context),
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Scrollable Form
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'customer_name_required'.tr(context: context),
                        prefixIcon: const Icon(Icons.person_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'customer_name_validation'.tr(context: context) : null,
                    ),
                    const SizedBox(height: 14),

                    // Customer Phone
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'customer_phone_required'.tr(context: context),
                        prefixIcon: const Icon(Icons.phone_rounded),
                        hintText: 'customer_phone_hint'.tr(context: context),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'customer_phone_validation'.tr(context: context) : null,
                    ),
                    const SizedBox(height: 14),

                    // Date & Time Row
                    Row(
                      children: [
                        // Date Picker
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                                lastDate: DateTime.now().add(const Duration(days: 180)),
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'date_required_label'.tr(context: context),
                                prefixIcon: const Icon(Icons.calendar_today_rounded),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(
                                DateFormat('d MMM yyyy', context.locale.languageCode).format(_selectedDate),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Time Picker
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _selectedTime,
                              );
                              if (picked != null) {
                                setState(() => _selectedTime = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'time_required_label'.tr(context: context),
                                prefixIcon: const Icon(Icons.access_time_rounded),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(
                                '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Number of Guests Stepper
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.people_outline_rounded, color: theme.colorScheme.primary),
                              const SizedBox(width: 10),
                              Text('jumlah_tamu_orang_347'.tr(context: context), style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline_rounded),
                                onPressed: _numberOfPeople > 1
                                    ? () => setState(() => _numberOfPeople--)
                                    : null,
                              ),
                              Text(
                                '$_numberOfPeople',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline_rounded),
                                onPressed: () => setState(() => _numberOfPeople++),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Branch Selection (if available)
                    if (branchProvider.branches.isNotEmpty) ...[
                      DropdownButtonFormField<int>(
                        initialValue: _selectedBranchId,
                        decoration: InputDecoration(
                          labelText: 'branch_store_label'.tr(context: context),
                          prefixIcon: const Icon(Icons.store_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        items: [
                          DropdownMenuItem<int>(
                            value: null,
                            child: Text('semua_cabang_pusat_348'.tr(context: context)),
                          ),
                          ...branchProvider.branches.map((b) {
                            return DropdownMenuItem<int>(
                              value: b.id,
                              child: Text(b.name),
                            );
                          }),
                        ],
                        onChanged: (val) => setState(() => _selectedBranchId = val),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Service Picker Chips (from Product List)
                    if (productProvider.products.isNotEmpty) ...[
                      Text(
                        'select_service_menu_optional'.tr(context: context),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: productProvider.products.take(12).map((prod) {
                          final isSelected = _selectedProductServices.contains(prod.name);
                          return FilterChip(
                            label: Text(prod.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedProductServices.add(prod.name);
                                } else {
                                  _selectedProductServices.remove(prod.name);
                                }
                                _serviceController.text = _selectedProductServices.join(', ');
                              });
                            },
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Service input manual
                    TextFormField(
                      controller: _serviceController,
                      decoration: InputDecoration(
                        labelText: 'service_menu_ordered_label'.tr(context: context),
                        prefixIcon: const Icon(Icons.spa_rounded),
                        hintText: 'service_menu_ordered_hint'.tr(context: context),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'additional_notes_optional'.tr(context: context),
                        prefixIcon: const Icon(Icons.notes_rounded),
                        hintText: 'additional_notes_hint'.tr(context: context),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
                            final timeStr = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

                            final success = await resProvider.createReservation(
                              customerName: _nameController.text.trim(),
                              customerPhone: _phoneController.text.trim(),
                              reservationDate: dateStr,
                              reservationTime: timeStr,
                              numberOfPeople: _numberOfPeople,
                              serviceNames: _serviceController.text.trim().isNotEmpty ? _serviceController.text.trim() : null,
                              notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
                              branchId: _selectedBranchId,
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('reservasi_berhasil_ditambahkan_350'.tr(context: context))),
                                );
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text('simpan_reservasi_351'.tr(context: context), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


