import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import 'screens/auth/login_screen.dart';
import 'widgets/zenvi_logo_widgets.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/auth/pending_approval_screen.dart';
import 'screens/dashboard/owner_dashboard_screen.dart';
import 'screens/dashboard/employee_dashboard_screen.dart';
import 'screens/notifications/notification_center_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/shift/shift_screen.dart';
import 'screens/stock/stock_management_screen.dart';
import 'screens/permission/owner_permission_management_screen.dart';
import 'screens/reservation/reservation_list_screen.dart';

import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'providers/ingredient_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/shift_provider.dart';
import 'providers/branch_provider.dart';
import 'providers/stock_management_provider.dart';
import 'providers/order_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/printer_provider.dart';
import 'providers/employee_performance_provider.dart';
import 'providers/employee_permission_provider.dart';
import 'providers/reservation_provider.dart';
import 'providers/member_provider.dart';
import 'providers/member_promo_provider.dart';
import 'providers/notification_provider.dart';
import 'services/sync_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Inisialisasi Layanan Notifikasi & FCM
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Notification service init failed: $e');
  }

  // Memulai pemantauan sinyal internet secara background
  SyncService().startMonitoringConnectivity();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('id')],
      path: 'assets/translations',
      fallbackLocale: const Locale('id'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()..checkLoginStatus()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => ProductProvider()),
          ChangeNotifierProvider(create: (_) => IngredientProvider()),
          ChangeNotifierProvider(create: (_) => ExpenseProvider()),
          ChangeNotifierProvider(create: (_) => ShiftProvider()),
          ChangeNotifierProvider(create: (_) => BranchProvider()),
          ChangeNotifierProvider(create: (_) => StockManagementProvider()),
          ChangeNotifierProvider(create: (_) => OrderProvider()),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
          ChangeNotifierProvider(create: (_) => PrinterProvider()),
          ChangeNotifierProvider(create: (_) => EmployeePerformanceProvider()),
          ChangeNotifierProvider(create: (_) => EmployeePermissionProvider()),
          ChangeNotifierProvider(create: (_) => ReservationProvider()),
          ChangeNotifierProvider(create: (_) => MemberProvider()),
          ChangeNotifierProvider(create: (_) => MemberPromoProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ],
        child: const ZenviApp(),
      ),
    ),
  );
}

class ZenviApp extends StatelessWidget {
  const ZenviApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      title: 'Zenvi',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      themeMode: themeProvider.themeMode,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        // Clamp text scaler antara 0.85x dan 1.15x agar UI presisi di semua setting font HP fisik
        final clampedTextScaler = mediaQuery.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.15,
        );
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clampedTextScaler),
          child: child ?? const SizedBox.shrink(),
        );
      },
      routes: {
        '/notifications': (context) => const NotificationCenterScreen(),
        '/chat': (context) => const ChatListScreen(),
        '/shifts': (context) => const ShiftScreen(),
        '/stock': (context) => const StockManagementScreen(),
        '/permissions': (context) => const OwnerPermissionManagementScreen(),
        '/reservations': (context) => const ReservationListScreen(),
      },
      home: const AuthGate(),
    );
  }
}

/// Gerbang Autentikasi Cerdas
/// Mengarahkan pengguna langsung ke Dashboard / POS tanpa perlu login berulang kali saat restart.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Saat pembacaan cache lokal dari disk sedang berjalan
        if (auth.isInitializing) {
          return const Scaffold(
            body: Center(
              child: ZenviLoadingAnimation(),
            ),
          );
        }

        // Jika belum ada session login tersimpan
        if (!auth.isAuthenticated || auth.user == null) {
          return const LoginScreen();
        }

        final user = auth.user!;

        // 1. Akun baru belum memilih peran / toko
        if (user.companyId == null) {
          return RoleSelectionScreen();
        }

        // 2. Karyawan menunggu approval Owner
        if (!user.isApproved) {
          return PendingApprovalScreen();
        }

        // 3. Owner Toko
        if (user.isOwner) {
          return const OwnerDashboardScreen();
        }

        // 4. Karyawan / Kasir Toko
        return const EmployeeDashboardScreen();
      },
    );
  }
}
