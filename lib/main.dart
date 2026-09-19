import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'providers/bidang_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/roadmap_provider.dart';
import 'providers/task_provider.dart';
import 'providers/user_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/username_setup_screen.dart';
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
  bool isNewGoogleUser = false;

  if (session != null) {
    try {
      currentUser = await AuthService.getCurrentUser();
      if (currentUser == null) {
        // Ada session tapi tidak ada profile row → Google user baru
        isNewGoogleUser = true;
      }
    } catch (_) {
      // Session corrupt → sign out
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
    }
  }

  runApp(CodePathApp(
    initialUser: currentUser,
    isNewGoogleUser: isNewGoogleUser,
  ));
}

class CodePathApp extends StatelessWidget {
  final AuthResult? initialUser;
  final bool isNewGoogleUser;

  const CodePathApp({
    super.key,
    this.initialUser,
    this.isNewGoogleUser = false,
  });

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
        ChangeNotifierProvider(create: (_) => BidangProvider()),
      ],
      child: MaterialApp(
        title: 'CodePath',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: isNewGoogleUser
            ? const UsernameSetupScreen()
            : SplashScreen(currentUser: initialUser),
      ),
    );
  }
}
