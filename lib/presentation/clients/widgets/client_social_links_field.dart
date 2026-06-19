import 'package:flutter/material.dart';

import '../../../core/theme/agency_theme_colors.dart';
import '../../../core/utils/theme_utils.dart';
import '../models/client_social_link.dart';
class ClientSocialLinksField extends StatefulWidget {
  const ClientSocialLinksField({
    super.key,
    required this.links,
    required this.onChanged,
  });

  final List<ClientSocialLink> links;
  final ValueChanged<List<ClientSocialLink>> onChanged;

  @override
  State<ClientSocialLinksField> createState() => _ClientSocialLinksFieldState();
}

class _ClientSocialLinksFieldState extends State<ClientSocialLinksField> {
  final _inputController = TextEditingController();
  SocialPlatform? _previewPlatform;
  String? _previewHandle;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _updatePreview(String value) {
    if (value.trim().isEmpty) {
      setState(() {
        _previewPlatform = null;
        _previewHandle = null;
      });
      return;
    }

    final detected = SocialLinkDetector.detect(value);
    setState(() {
      _previewPlatform = detected.platform;
      _previewHandle = detected.handle ?? detected.normalizedValue;
    });
  }

  void _addLink() {
    final raw = _inputController.text.trim();
    if (raw.isEmpty) return;

    final link = ClientSocialLink.parse(raw);
    widget.onChanged([...widget.links, link]);
    _inputController.clear();
    setState(() {
      _previewPlatform = null;
      _previewHandle = null;
    });
  }

  void _removeLink(int index) {
    final updated = [...widget.links]..removeAt(index);
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Redes sociais',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Cole um link, @usuario ou telefone — identificamos a rede automaticamente.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                decoration: InputDecoration(
                  labelText: 'Link ou @usuario',
                  hintText: 'instagram.com/cliente, @cliente ou 11999999999',
                  border: const OutlineInputBorder(),
                  prefixIcon: _previewPlatform != null
                      ? Padding(
                          padding: const EdgeInsets.only(left: 12, right: 8),
                          child: _PlatformBadge(platform: _previewPlatform!, compact: true),
                        )
                      : const Icon(Icons.link),
                  suffixIcon: _previewPlatform != null
                      ? Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              _previewPlatform!.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: ThemeUtils.brandColor(context, _previewPlatform!.color),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
                onChanged: _updatePreview,
                onSubmitted: (_) => _addLink(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _addLink,
              child: const Icon(Icons.add),
            ),
          ],
        ),
        if (_previewHandle != null) ...[
          const SizedBox(height: 8),
          Text(
            'Detectado: $_previewHandle',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AgencyThemeColors.of(context).contentAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (widget.links.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(widget.links.length, (index) {
              final link = widget.links[index];
              return InputChip(
                avatar: _PlatformBadge(platform: link.platform, compact: true),
                label: Text(link.displayLabel, overflow: TextOverflow.ellipsis),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _removeLink(index),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _PlatformBadge extends StatelessWidget {
  const _PlatformBadge({required this.platform, this.compact = false});

  final SocialPlatform platform;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconColor = ThemeUtils.brandColor(context, platform.color);

    return Container(
      width: compact ? 28 : 36,
      height: compact ? 28 : 36,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(platform.icon, size: compact ? 16 : 20, color: iconColor),
    );
  }
}

/// Ícones compactos para exibir na listagem de clientes.
class ClientSocialIconsRow extends StatelessWidget {
  const ClientSocialIconsRow({super.key, required this.links});

  final List<ClientSocialLink> links;

  @override
  Widget build(BuildContext context) {
    if (links.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        children: links.take(5).map((link) {
          return Tooltip(
            message: '${link.platform.label}: ${link.displayLabel}',
            child: Icon(
              link.platform.icon,
              size: 16,
              color: ThemeUtils.brandColor(context, link.platform.color),
            ),
          );
        }).toList(),
      ),
    );
  }
}
