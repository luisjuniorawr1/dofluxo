import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_update_logic.dart';
import 'app_version.dart';
import 'app_version_service.dart' as version_service;

const Duration _kCheckInterval = Duration(seconds: 5);

/// Notificação de atualização (somente web) — canto inferior direito, sem bloquear a UI.
class AppUpdateGate extends StatefulWidget {
  const AppUpdateGate({super.key, required this.child});

  final Widget? child;

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate> {
  Timer? _checkTimer;
  Timer? _countdownTimer;
  bool _checking = false;
  bool _updatePending = false;
  DateTime? _updateDetectedAt;
  String? _sessionVersion;
  String? _latestRemote;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb || !version_service.versionCheckSupported) return;

    version_service.registerUrlCleaningTriggers();

    if (kCompiledAppVersion.isNotEmpty) {
      _sessionVersion = kCompiledAppVersion.trim();
    }

    version_service.registerRevalidationTriggers(_checkForUpdate);
    _checkForUpdate();
    _checkTimer = Timer.periodic(_kCheckInterval, (_) => _checkForUpdate());
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Duration get _remainingGrace {
    final detectedAt = _updateDetectedAt;
    if (detectedAt == null) return kUpdateGracePeriod;
    return remainingGracePeriod(detectedAt: detectedAt, now: DateTime.now());
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_updatePending || !mounted) return;

      if (shouldAutoReload(
        detectedAt: _updateDetectedAt!,
        now: DateTime.now(),
      )) {
        _countdownTimer?.cancel();
        _onUpdatePressed();
        return;
      }

      setState(() {});
    });
  }

  void _showUpdateBanner() {
    if (_updatePending) return;
    setState(() {
      _updatePending = true;
      _updateDetectedAt = DateTime.now();
    });
    _startCountdownTimer();
  }

  Future<void> _checkForUpdate() async {
    if (_checking || _updatePending) return;
    _checking = true;
    try {
      final remote = await version_service.fetchRemoteAppVersion();
      if (remote == null || remote.isEmpty) return;

      _latestRemote = remote;

      if (version_service.shouldSkipUpdateOnce()) {
        version_service.clearSkipUpdateOnce();
        _sessionVersion = remote;
        version_service.clearAcceptedVersion();
        return;
      }

      final accepted = version_service.readAcceptedVersion();
      if (accepted != null && accepted == remote) {
        _sessionVersion = remote;
        version_service.clearAcceptedVersion();
        return;
      }

      _sessionVersion ??=
          kCompiledAppVersion.isNotEmpty ? kCompiledAppVersion : remote;

      final mustUpdate = isUpdateRequired(
        sessionVersion: _sessionVersion,
        remoteVersion: remote,
      );

      if (mustUpdate && mounted) {
        _showUpdateBanner();
      }
    } catch (_) {
      // Silencioso.
    } finally {
      _checking = false;
    }
  }

  void _onUpdatePressed() {
    _countdownTimer?.cancel();
    if (mounted) {
      setState(() => _updatePending = false);
    }
    version_service.reloadApp(acceptedVersion: _latestRemote ?? _sessionVersion);
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.child ?? const SizedBox.shrink();

    return Stack(
      fit: StackFit.expand,
      children: [
        content,
        if (_updatePending)
          Positioned(
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: _UpdateBanner(
                remaining: _remainingGrace,
                onUpdate: _onUpdatePressed,
              ),
            ),
          ),
      ],
    );
  }
}

class _UpdateBanner extends StatelessWidget {
  const _UpdateBanner({
    required this.remaining,
    required this.onUpdate,
  });

  final Duration remaining;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final countdown = formatGraceCountdown(remaining);

    return Material(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(12),
      color: colorScheme.inverseSurface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.system_update_alt_outlined,
                    color: ThemeUtils.contentAccent(
                      context,
                      background: colorScheme.inverseSurface,
                    ),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nova versão disponível',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onInverseSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Nos próximos 5 minutos você pode clicar em '
                          'Atualizar quando quiser. Depois disso, o app '
                          'será atualizado automaticamente.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onInverseSurface,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Atualização automática em $countdown',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: ThemeUtils.contentAccent(
                              context,
                              background: colorScheme.inverseSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Salve formulários abertos antes de atualizar.',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onInverseSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onUpdate,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Atualizar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
