import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/agency/agency_branding_sync.dart';
import '../../core/agency/agency_context.dart';
import '../../core/theme/theme_provider.dart';
import '../clients/manager/client_service.dart';
import '../projects/manager/project_service.dart';
import '../shared/main_shell.dart';
import '../shared/widgets/dofluxo_bootstrap_loading.dart';
import 'pages/agency_selection_page.dart';
import 'pages/agency_welcome_page.dart';

/// Bootstrap multi-agência pós-login. Subetapas 3A–3D.
class AgencyGate extends StatefulWidget {
  const AgencyGate({super.key, required this.user});

  final User user;

  @override
  State<AgencyGate> createState() => _AgencyGateState();
}

class _AgencyGateState extends State<AgencyGate> {
  bool _bootstrapping = false;
  bool _kickScheduled = false;
  int _retryAttempt = 0;

  @override
  void initState() {
    super.initState();
    _scheduleBootstrap();
  }

  @override
  void didUpdateWidget(covariant AgencyGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      _retryAttempt = 0;
      _kickScheduled = false;
      context.read<AgencyContext>().reset();
      context.read<ThemeProvider>().resetToDefaults();
      _scheduleBootstrap();
    }
  }

  void _scheduleBootstrap({Duration delay = Duration.zero}) {
    if (_kickScheduled && delay == Duration.zero) return;
    _kickScheduled = true;
    Future<void>.delayed(delay, () {
      _kickScheduled = false;
      if (mounted) _runBootstrap();
    });
  }

  bool _isUsable(AgencyContext agencyContext, String uid) {
    if (agencyContext.sessionUserId != uid) return false;
    if (agencyContext.isReady) return true;
    if (agencyContext.errorMessage != null) return true;
    if (agencyContext.needsOnboarding) return true;
    return false;
  }

  Future<void> _runBootstrap() async {
    if (!mounted || _bootstrapping) return;

    final uid = widget.user.uid;
    final agencyContext = context.read<AgencyContext>();

    if (_isUsable(agencyContext, uid)) {
      _retryAttempt = 0;
      return;
    }

    final authUid = FirebaseAuth.instance.currentUser?.uid;
    if (authUid != uid) {
      if (_retryAttempt < 40) {
        _retryAttempt++;
        _scheduleBootstrap(delay: const Duration(milliseconds: 100));
      }
      return;
    }

    _bootstrapping = true;
    try {
      await agencyContext.initialize(widget.user);
      if (!mounted) return;

      if (_isUsable(agencyContext, uid)) {
        _retryAttempt = 0;
        return;
      }

      if (_retryAttempt < 40) {
        _retryAttempt++;
        _scheduleBootstrap(delay: const Duration(milliseconds: 150));
      }
    } finally {
      _bootstrapping = false;
    }
  }

  Future<void> _retryBootstrap() async {
    _retryAttempt = 0;
    _kickScheduled = false;
    await context.read<AgencyContext>().initialize(widget.user);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser?.uid != widget.user.uid) {
      _scheduleBootstrap(delay: const Duration(milliseconds: 50));
      return const DofluxoBootstrapLoading();
    }

    return Consumer<AgencyContext>(
      builder: (context, agencyContext, _) {
        if (agencyContext.sessionUserId != null &&
            agencyContext.sessionUserId != widget.user.uid) {
          return const DofluxoBootstrapLoading();
        }

        final isBootstrapLoading =
            agencyContext.isLoading && !agencyContext.needsOnboarding;

        final idleNotReady = !isBootstrapLoading &&
            !agencyContext.isReady &&
            agencyContext.errorMessage == null &&
            !agencyContext.needsOnboarding;

        if (idleNotReady) {
          _scheduleBootstrap(delay: const Duration(milliseconds: 50));
          return const DofluxoBootstrapLoading();
        }

        if (isBootstrapLoading ||
            (!agencyContext.isReady && agencyContext.errorMessage == null)) {
          return const DofluxoBootstrapLoading();
        }

        if (agencyContext.errorMessage != null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        agencyContext.errorMessage!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed:
                            agencyContext.isLoading ? null : _retryBootstrap,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        if (agencyContext.needsOnboarding) {
          return const AgencyWelcomePage();
        }

        if (agencyContext.needsAgencySelection) {
          return const AgencySelectionPage();
        }

        if (agencyContext.hasActiveAgency) {
          final agencyId = agencyContext.activeAgencyId!;
          final sessionKey = '${widget.user.uid}/$agencyId';

          return AgencyBrandingSync(
            key: ValueKey('branding-$sessionKey'),
            child: MultiProvider(
              key: ValueKey('services-$sessionKey'),
              providers: [
                Provider<ProjectService>(
                  create: (_) => ProjectService(agencyId: agencyId),
                  dispose: (_, service) => service.dispose(),
                ),
                Provider<ClientService>(
                  create: (_) => ClientService(agencyId: agencyId),
                ),
              ],
              child: const MainShell(),
            ),
          );
        }

        return Scaffold(
          body: Center(
            child: Text(
              'Não foi possível carregar a agência ativa.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        );
      },
    );
  }
}
