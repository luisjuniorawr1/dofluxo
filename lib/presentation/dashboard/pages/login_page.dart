import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dofluxo/presentation/auth/manager/auth_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../shared/theme_toggle_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      final user = await _authService.signInWithGoogle();
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login disponível apenas na Web no momento.')),
          );
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao fazer login: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final agencyName = context.select<ThemeProvider, String>((p) => p.agencyName);

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              if (size.width > 800)
                Expanded(
                  flex: 1,
                  child: Container(
                    color: theme.primaryColor,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            agencyName,
                            style: TextStyle(
                              fontSize: 80,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              letterSpacing: -4,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                          Text(
                            'ORGANIZER',
                            style: TextStyle(
                              letterSpacing: 8,
                              fontWeight: FontWeight.w300,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(
                flex: 1,
                child: Container(
                  color: theme.colorScheme.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Agência Conectada',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gerencie seus projetos e clientes em um só lugar.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (_authService.requiresFreshSignIn) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Escolha a conta Google na janela que abrir. '
                          'Para trocar de usuário, selecione outro e-mail.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: theme.colorScheme.outlineVariant),
                          ),
                          onPressed: _isLoading ? null : _handleGoogleLogin,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  'G',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFDB4437),
                                  ),
                                ),
                          label: Text(
                            _isLoading ? 'Entrando...' : 'Continuar com Google',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 4,
            right: 4,
            child: ThemeToggleButton(iconColor: theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}
