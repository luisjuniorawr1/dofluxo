import 'dart:ui';

import 'package:flutter/material.dart';

/// Tamanhos da família visual da janela de Novo Projeto.
enum AppModalSize {
  /// Confirmações e forms curtos (~420).
  compact,

  /// Forms médios / mobile Novo Projeto (~560).
  medium,

  /// Detalhe de projeto / cliente (~720).
  large,

  /// Novo Projeto wide (calendário + form).
  wide,
}

/// Abre conteúdo interno como JANELA modal com fundo desfocado.
///
/// Menu da sidebar (Dashboard, Clientes, Equipe, Conta) continua em páginas.
/// Envolva o conteúdo com [AppModalShell] para o painel arredondado.
Future<T?> showAppModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _AppModalRouteBody(
        animation: animation,
        barrierDismissible: barrierDismissible,
        child: builder(dialogContext),
      );
    },
  );
}

/// Confirmação no mesmo shell (substitui AlertDialog solto).
Future<bool?> showAppConfirmModal({
  required BuildContext context,
  required String title,
  required String message,
  String cancelLabel = 'Cancelar',
  String confirmLabel = 'Confirmar',
  bool isDestructive = false,
}) {
  return showAppModal<bool>(
    context: context,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      return AppModalShell(
        size: AppModalSize.compact,
        shrinkWrap: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppModalHeader(title: title),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                message,
                style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                    ),
              ),
            ),
            AppModalFooter(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(cancelLabel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: isDestructive
                      ? FilledButton.styleFrom(backgroundColor: scheme.error)
                      : null,
                  child: Text(confirmLabel),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class _AppModalRouteBody extends StatelessWidget {
  const _AppModalRouteBody({
    required this.animation,
    required this.barrierDismissible,
    required this.child,
  });

  final Animation<double> animation;
  final bool barrierDismissible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barrierTint = isDark
        ? Colors.black.withValues(alpha: 0.55)
        : Colors.black.withValues(alpha: 0.32);

    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);

    return Stack(
      fit: StackFit.expand,
      children: [
        FadeTransition(
          opacity: curved,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: barrierDismissible
                ? () => Navigator.of(context).maybePop()
                : null,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: ColoredBox(color: barrierTint),
            ),
          ),
        ),
        SafeArea(
          child: AnimatedBuilder(
            animation: curved,
            builder: (context, _) {
              final t = curved.value;
              return Opacity(
                opacity: t,
                child: Transform.scale(
                  scale: 0.98 + (0.02 * t),
                  child: Align(
                    alignment: Alignment.center,
                    child: child,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Painel arredondado — mesma família visual do Novo Projeto.
class AppModalShell extends StatelessWidget {
  const AppModalShell({
    super.key,
    required this.child,
    this.size = AppModalSize.medium,
    this.shrinkWrap = false,
    this.maxHeightFactor = 0.94,
    this.contentPadding,
  });

  final Widget child;
  final AppModalSize size;
  final bool shrinkWrap;
  final double maxHeightFactor;
  final EdgeInsetsGeometry? contentPadding;

  static double maxWidthFor(AppModalSize size, Size media, {required bool isWideScreen}) {
    switch (size) {
      case AppModalSize.compact:
        return 440;
      case AppModalSize.medium:
        return 560;
      case AppModalSize.large:
        return 720;
      case AppModalSize.wide:
        return isWideScreen
            ? (media.width - 24).clamp(1100.0, 1680.0)
            : 560.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final media = MediaQuery.sizeOf(context);
    final isWideScreen = media.width >= 900;
    final maxWidth = maxWidthFor(size, media, isWideScreen: isWideScreen);
    final maxHeight = media.height * maxHeightFactor;
    final horizontalInset = size == AppModalSize.wide
        ? (isWideScreen ? 12.0 : 16.0)
        : 16.0;

    final panel = Material(
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: contentPadding == null
          ? child
          : Padding(padding: contentPadding!, child: child),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalInset, vertical: 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          minWidth: size == AppModalSize.wide && isWideScreen ? maxWidth : 0,
        ),
        child: shrinkWrap
            ? panel
            : SizedBox(
                width: maxWidth,
                height: maxHeight,
                child: panel,
              ),
      ),
    );
  }
}

class AppModalHeader extends StatelessWidget {
  const AppModalHeader({
    super.key,
    required this.title,
    this.actions,
    this.showClose = true,
  });

  final String title;
  final List<Widget>? actions;
  final bool showClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
          ),
          if (actions != null) ...actions!,
          if (showClose)
            IconButton(
              tooltip: 'Fechar',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(Icons.close_rounded, color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

class AppModalFooter extends StatelessWidget {
  const AppModalFooter({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            const Spacer(),
            ..._withGaps(children),
          ],
        ),
      ),
    );
  }

  List<Widget> _withGaps(List<Widget> items) {
    if (items.isEmpty) return const [];
    final out = <Widget>[items.first];
    for (var i = 1; i < items.length; i++) {
      out.add(const SizedBox(width: 8));
      out.add(items[i]);
    }
    return out;
  }
}
