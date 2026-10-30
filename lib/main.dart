import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase_config.dart';
import 'services/auth_service.dart';
import 'services/user_session_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/create_edit_class_screen.dart';
import 'screens/my_reservations_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        publishableKey: SupabaseConfig.supabaseAnonKey,
      );
      if (AuthService.instance.currentUser != null) {
        await UserSessionService.instance.syncUserRole();
      }
    } catch (e) {
      debugPrint('Error al inicializar Supabase: $e');
    }
  }

  runApp(const IronPulseApp());
}

class IronPulseApp extends StatelessWidget {
  const IronPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = AuthService.instance.currentUser != null;
    final Widget initialHome = isLoggedIn
        ? (UserSessionService.instance.isAdmin
            ? const AdminDashboardScreen()
            : const HomeScreen())
        : const AuthScreen();

    return MaterialApp(
      title: 'IRON PULSE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: initialHome,
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
        '/admin': (context) => const AdminDashboardScreen(),
        '/create-class': (context) => const CreateEditClassScreen.create(),
        '/bookings': (context) => const MyReservationsScreen(),
      },
    );
  }
}
