import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'core/agency/agency_context.dart';
import 'core/theme/theme_provider.dart';
import 'core/update/app_update_gate.dart';
import 'presentation/shared/widgets/dofluxo_bootstrap_loading.dart';
import 'presentation/agency/agency_gate.dart';
import 'presentation/auth/manager/auth_service.dart';
import 'presentation/dashboard/pages/login_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _AppBootstrap());
}

/// Exibe loading escuro enquanto Firebase inicializa (evita flash branco).
class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  ThemeProvider? _themeProvider;
  AgencyContext? _agencyContext;
  Object? _initError;

  static ThemeData _bootstrapTheme({required Brightness brightness}) => ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor:
        brightness == Brightness.dark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFFD700),
      brightness: brightness,
    ),
  );

  ThemeData get _loadingTheme {
    final brightness = _themeProvider?.isDarkMode == true
        ? Brightness.dark
        : Brightness.light;
    return _bootstrapTheme(brightness: brightness);
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final themeProvider = await ThemeProvider.create();
      if (mounted) {
        setState(() => _themeProvider = themeProvider);
      }

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await AuthService.configure();

      if (!mounted) return;
      setState(() {
        _agencyContext = AgencyContext();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _initError = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return MaterialApp(
        theme: _loadingTheme,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Erro ao iniciar: $_initError',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    if (_themeProvider == null || _agencyContext == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _loadingTheme,
        home: const DofluxoBootstrapLoading(),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: _themeProvider!),
        ChangeNotifierProvider<AgencyContext>.value(value: _agencyContext!),
      ],
      child: const DofluxoApp(),
    );
  }
}

class DofluxoApp extends StatelessWidget {
  const DofluxoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'DOFLUXO',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          themeAnimationDuration: Duration.zero,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          builder: (context, nestedChild) => AppUpdateGate(child: nestedChild),
          home: child,
        );
      },
      // AuthGate estável: não recria a árvore ao trocar só ThemeMode.
      child: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();
  String? _sessionUid;
  String? _switchingToUid;
  bool _clearingAfterLogout = false;

  void _resetSessionState() {
    context.read<AgencyContext>().reset();
    context.read<ThemeProvider>().resetToDefaults();
  }

  Future<void> _clearSessionForNextUser() async {
    _resetSessionState();
  }

  Future<void> _handleAccountSwitch(User user) async {
    _switchingToUid = user.uid;
    await _clearSessionForNextUser();
    if (!mounted) return;
    setState(() {
      _sessionUid = user.uid;
      _switchingToUid = null;
    });
  }

  Future<void> _handleLogoutCleanup() async {
    if (_clearingAfterLogout) return;
    _clearingAfterLogout = true;
    _sessionUid = null;
    _switchingToUid = null;
    await _clearSessionForNextUser();
    if (mounted) {
      setState(() => _clearingAfterLogout = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const DofluxoBootstrapLoading();
        }

        final user = snapshot.data;

        if (user != null) {
          final uidChanged = _sessionUid != null && _sessionUid != user.uid;
          if (uidChanged && _switchingToUid != user.uid) {
            _handleAccountSwitch(user);
          }

          if (_switchingToUid != null) {
            return const DofluxoBootstrapLoading();
          }

          _sessionUid = user.uid;
          return AgencyGate(
            key: ValueKey(user.uid),
            user: user,
          );
        }

        if (_sessionUid != null && !_clearingAfterLogout) {
          _handleLogoutCleanup();
        }

        if (_clearingAfterLogout) {
          return const DofluxoBootstrapLoading();
        }

        return const LoginPage();
      },
    );
  }
}
