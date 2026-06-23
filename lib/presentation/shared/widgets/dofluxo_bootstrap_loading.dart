import 'dart:async';

import 'package:flutter/material.dart';

import '../config/bootstrap_loading_messages.dart';

/// Tela de carregamento do bootstrap — fundo escuro, detalhes brancos, mensagens em loop.
class DofluxoBootstrapLoading extends StatefulWidget {
  const DofluxoBootstrapLoading({
    super.key,
    this.messages = BootstrapLoadingMessages.messages,
    this.rotateMessages = true,
  });

  final List<({IconData icon, String text})> messages;
  final bool rotateMessages;

  @override
  State<DofluxoBootstrapLoading> createState() => _DofluxoBootstrapLoadingState();
}

class _DofluxoBootstrapLoadingState extends State<DofluxoBootstrapLoading>
    with TickerProviderStateMixin {
  late final AnimationController _iconController;
  late final AnimationController _progressController;
  late final Animation<double> _iconScale;

  Timer? _messageTimer;
  int _messageIndex = 0;

  static const Color _backgroundTop = Color(0xFF0D0D0D);
  static const Color _backgroundBottom = Color(0xFF121212);
  static const Color _detailColor = Color(0xFFFFFFFF);
  static const Color _trackColor = Color(0xFF383838);

  @override
  void initState() {
    super.initState();

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _iconScale = Tween<double>(begin: 0.88, end: 1.08).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );

    if (widget.rotateMessages && widget.messages.length > 1) {
      _messageTimer = Timer.periodic(BootstrapLoadingMessages.rotationInterval, (_) {
        if (!mounted) return;
        setState(() {
          _messageIndex = (_messageIndex + 1) % widget.messages.length;
        });
      });
    }
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _iconController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 480;
    final maxWidth = isCompact ? 320.0 : 420.0;
    final message = widget.messages[_messageIndex];

    return Scaffold(
      backgroundColor: _backgroundBottom,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_backgroundTop, _backgroundBottom],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: isCompact ? 48 : 52,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 450),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          final slide = Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(position: slide, child: child),
                          );
                        },
                        child: _LoadingMessageRow(
                          key: ValueKey('${message.icon.codePoint}-${message.text}'),
                          icon: message.icon,
                          text: message.text,
                          iconScale: _iconScale,
                          iconController: _iconController,
                          isCompact: isCompact,
                        ),
                      ),
                    ),
                    SizedBox(height: isCompact ? 20 : 24),
                    _AnimatedProgressBar(
                      controller: _progressController,
                      highlightColor: _detailColor,
                      trackColor: _trackColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingMessageRow extends StatelessWidget {
  const _LoadingMessageRow({
    super.key,
    required this.icon,
    required this.text,
    required this.iconScale,
    required this.iconController,
    required this.isCompact,
  });

  final IconData icon;
  final String text;
  final Animation<double> iconScale;
  final AnimationController iconController;
  final bool isCompact;

  static const Color _detailColor = Color(0xFFFFFFFF);
  static const Color _textColor = Color(0xFFEAEAEA);

  @override
  Widget build(BuildContext context) {
    final iconSize = isCompact ? 28.0 : 32.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: iconSize + 4,
          height: iconSize + 4,
          child: AnimatedBuilder(
            animation: iconController,
            builder: (context, child) {
              return Transform.scale(
                scale: iconScale.value,
                child: Icon(icon, size: iconSize, color: _detailColor),
              );
            },
          ),
        ),
        SizedBox(width: isCompact ? 10 : 12),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.start,
            style: TextStyle(
              fontSize: isCompact ? 15 : 16,
              fontWeight: FontWeight.w600,
              height: 1.35,
              color: _textColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedProgressBar extends StatelessWidget {
  const _AnimatedProgressBar({
    required this.controller,
    required this.highlightColor,
    required this.trackColor,
  });

  final AnimationController controller;
  final Color highlightColor;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 4,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: trackColor),
                Align(
                  alignment: Alignment(-1 + (2 * t), 0),
                  child: FractionallySizedBox(
                    widthFactor: 0.38,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          colors: [
                            highlightColor.withValues(alpha: 0.15),
                            highlightColor,
                            highlightColor.withValues(alpha: 0.15),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
