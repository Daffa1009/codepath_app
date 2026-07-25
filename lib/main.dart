import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'providers/progress_provider.dart';
import 'providers/roadmap_provider.dart';
import 'providers/task_provider.dart';
import 'providers/user_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_nav_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'services/auth_result.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseAnonKey,
  );

  final session = Supabase.instance.client.auth.currentSession;
  AuthResult? currentUser;

  if (session != null) {
    try {
      currentUser = await AuthService.getCurrentUser();
    } catch (_) {
      // Gagal ambil detail user, log out untuk membersihkan session corrupt
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
    }
  }

  runApp(CodePathApp(initialUser: currentUser));
}

class CodePathApp extends StatelessWidget {
  final AuthResult? initialUser;
  const CodePathApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserProvider()..setUser(initialUser),
        ),
        ChangeNotifierProvider(create: (_) => RoadmapProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
      ],
      child: MaterialApp(
        title: 'CodePath',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: _getInitialScreen(initialUser),
      ),
    );
  }

  Widget _getInitialScreen(AuthResult? user) {
    if (user == null) {
      return const LoginScreen();
    }
    if (user.isAdmin) {
      return const AdminHomeScreen();
    }
    return MainNavScreen(user: user);
  }
}
