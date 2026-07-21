import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_update_logic.dart';
import 'app_version_service.dart' as version_service;

/// Versão injetada no build via `--dart-define=APP_VERSION=x.y.z+build`.
const String _kCompiledAppVersion = String.fromEnvironment('APP_VERSION');

/// Reverificação periódica (~2,5 min).
const Duration _kCheckInterval = Duration(seconds: 150);

/// Tempo até auto-atualizar se o usuário não clicar.
const Duration _kAutoReloadDelay = Duration(minutes: 5);

/// Envolve todas as rotas e exibe notificação obrigatória de atualização (web).
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
  bool _updateRequired = false;
  String? _sessionVersion;
  String? _latestRemote;
  Duration _remaining = _kAutoReloadDelay;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb || !version_service.versionCheckSupported) return;

    if (_kCompiledAppVersion.isNotEmpty) {
      _sessionVersion = _kCompiledAppVersion.trim();
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

  Future<void> _checkForUpdate() async {
    if (_checking || _updateRequired) return;
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

      // Sem APP_VERSION (ex.: flutter run): congela a 1ª leitura remota.
      _sessionVersion ??= remote;

      final mustUpdate = isUpdateRequired(
        sessionVersion: _sessionVersion,
        remoteVersion: remote,
      );

      if (mustUpdate && mounted) {
        setState(() {
          _updateRequired = true;
          _remaining = _kAutoReloadDelay;
        });
        _checkTimer?.cancel();
        _startCountdown();
      }
    } catch (_) {
      // Silencioso.
    } finally {
      _checking = false;
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remaining.inSeconds <= 1) {
        timer.cancel();
        setState(() => _remaining = Duration.zero);
        _reload();
        return;
      }
      setState(() {
        _remaining = Duration(seconds: _remaining.inSeconds - 1);
      });
    });
  }

  void _reload() {
    _countdownTimer?.cancel();
    version_service.reloadApp(
      acceptedVersion: _latestRemote ?? _sessionVersion,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.child ?? const SizedBox.shrink();

    return Stack(
      fit: StackFit.expand,
      children: [
        content,
        if (_updateRequired)
          Positioned(
            right: 16,
            bottom: 16,
            child: _UpdateBanner(
              remaining: _remaining,
              onUpdate: _reload,
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
    final countdown = formatCountdown(remaining);

    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(12),
      color: const Color(0xFF1A1A1A),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.system_update,
                    color: Color(0xFFFFD700),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Atualização disponível',
                      style: TextStyle(
                        color: Color(0xFFEAEAEA),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    countdown,
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'O sistema atualizará automaticamente em $countdown. '
                'Você também pode atualizar agora.',
                style: const TextStyle(
                  color: Color(0xFFBDBDBD),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x33FFC107),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFC107)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFFFC107),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Se houver formulário aberto, dados não salvos '
                        'serão perdidos.',
                        style: TextStyle(
                          color: Color(0xFFFFE082),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: const Color(0xFF121212),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: onUpdate,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text(
                  'Atualizar agora',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
