import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/settings/settings_service.dart';
import 'presentation/auth/manager/auth_service.dart';
import 'presentation/dashboard/pages/login_page.dart';
import 'presentation/shared/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final themeProvider = ThemeProvider();
  final settingsService = SettingsService();

  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      final settings = await settingsService.load(user.uid);
      themeProvider.applySettings(
        primaryColor: settings.primaryColor,
        agencyName: settings.agencyName,
      );
    } catch (e) {
      debugPrint('Erro ao carregar tema do Firestore: $e');
    }
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => themeProvider,
      child: const DofluxoApp(),
    ),
  );
}

class DofluxoApp extends StatelessWidget {
  const DofluxoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'DOFLUXO',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.build(
        primaryColor: themeProvider.primaryColor,
        brightness: Brightness.light,
      ),
      darkTheme: AppTheme.build(
        primaryColor: themeProvider.primaryColor,
        brightness: Brightness.dark,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const MainShell();
        }

        return const LoginPage();
      },
    );
  }
}
