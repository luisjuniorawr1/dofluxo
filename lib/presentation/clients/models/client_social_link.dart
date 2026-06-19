import 'package:flutter/material.dart';

/// Plataformas de rede social suportadas no cadastro de clientes.
enum SocialPlatform {
  instagram('Instagram', Color(0xFFE1306C), Icons.camera_alt_outlined),
  facebook('Facebook', Color(0xFF1877F2), Icons.facebook),
  linkedin('LinkedIn', Color(0xFF0A66C2), Icons.work_outline),
  tiktok('TikTok', Color(0xFF000000), Icons.music_note_outlined),
  youtube('YouTube', Color(0xFFFF0000), Icons.play_circle_outline),
  x('X (Twitter)', Color(0xFF000000), Icons.tag),
  whatsapp('WhatsApp', Color(0xFF25D366), Icons.chat_outlined),
  threads('Threads', Color(0xFF000000), Icons.alternate_email),
  pinterest('Pinterest', Color(0xFFE60023), Icons.push_pin_outlined),
  website('Site', Color(0xFF5C6BC0), Icons.language_outlined),
  other('Outro', Color(0xFF757575), Icons.link);

  const SocialPlatform(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;
}

/// Link de rede social com plataforma identificada automaticamente.
class ClientSocialLink {
  const ClientSocialLink({
    required this.platform,
    required this.value,
    this.handle,
  });

  final SocialPlatform platform;
  final String value;
  final String? handle;

  String get displayLabel => handle ?? value;

  Map<String, dynamic> toMap() => {
        'platform': platform.name,
        'value': value,
        if (handle != null && handle!.isNotEmpty) 'handle': handle,
      };

  factory ClientSocialLink.fromMap(Map<String, dynamic> map) {
    final platformName = map['platform'] as String? ?? 'other';
    final platform = SocialPlatform.values.firstWhere(
      (item) => item.name == platformName,
      orElse: () => SocialPlatform.other,
    );

    return ClientSocialLink(
      platform: platform,
      value: map['value'] as String? ?? '',
      handle: map['handle'] as String?,
    );
  }

  static ClientSocialLink parse(String raw) {
    final input = raw.trim();
    final detected = SocialLinkDetector.detect(input);

    return ClientSocialLink(
      platform: detected.platform,
      value: detected.normalizedValue,
      handle: detected.handle,
    );
  }
}

class SocialLinkDetection {
  const SocialLinkDetection({
    required this.platform,
    required this.normalizedValue,
    this.handle,
  });

  final SocialPlatform platform;
  final String normalizedValue;
  final String? handle;
}

/// Identifica a plataforma a partir de URL, @usuario ou número de telefone.
abstract final class SocialLinkDetector {
  static SocialLinkDetection detect(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const SocialLinkDetection(
        platform: SocialPlatform.other,
        normalizedValue: '',
      );
    }

    if (trimmed.startsWith('@')) {
      final handle = trimmed.replaceFirst('@', '');
      return SocialLinkDetection(
        platform: SocialPlatform.instagram,
        normalizedValue: 'https://instagram.com/$handle',
        handle: '@$handle',
      );
    }

    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (RegExp(r'^\d[\d\s().-]+$').hasMatch(trimmed) && digits.length >= 10 && digits.length <= 15) {
      return SocialLinkDetection(
        platform: SocialPlatform.whatsapp,
        normalizedValue: 'https://wa.me/$digits',
        handle: trimmed,
      );
    }

    final lower = trimmed.toLowerCase();
    final withProtocol = lower.startsWith('http') ? lower : 'https://$lower';

    Uri? uri;
    try {
      uri = Uri.parse(withProtocol);
    } catch (_) {
      uri = null;
    }

    if (uri != null && uri.host.isNotEmpty) {
      final host = uri.host.replaceFirst(RegExp(r'^www\.'), '');
      final path = uri.pathSegments.where((segment) => segment.isNotEmpty).toList();

      if (host.contains('instagram.com')) {
        return _profile(SocialPlatform.instagram, trimmed, path.isNotEmpty ? '@${path.first}' : null);
      }
      if (host.contains('facebook.com') || host == 'fb.com') {
        return _profile(SocialPlatform.facebook, trimmed, path.isNotEmpty ? path.last : null);
      }
      if (host.contains('linkedin.com')) {
        final handle = path.isNotEmpty ? path.last : null;
        return _profile(SocialPlatform.linkedin, trimmed, handle);
      }
      if (host.contains('tiktok.com')) {
        final handle = path.isNotEmpty ? (path.first.startsWith('@') ? path.first : '@${path.first}') : null;
        return _profile(SocialPlatform.tiktok, trimmed, handle);
      }
      if (host.contains('youtube.com') || host == 'youtu.be') {
        return _profile(SocialPlatform.youtube, trimmed, path.isNotEmpty ? path.last : null);
      }
      if (host.contains('twitter.com') || host == 'x.com') {
        final handle = path.isNotEmpty ? '@${path.first.replaceFirst('@', '')}' : null;
        return _profile(SocialPlatform.x, trimmed, handle);
      }
      if (host.contains('whatsapp.com') || host == 'wa.me') {
        return _profile(SocialPlatform.whatsapp, trimmed, uri.path.replaceAll('/', ''));
      }
      if (host.contains('threads.net')) {
        final handle = path.isNotEmpty ? '@${path.first.replaceFirst('@', '')}' : null;
        return _profile(SocialPlatform.threads, trimmed, handle);
      }
      if (host.contains('pinterest.')) {
        return _profile(SocialPlatform.pinterest, trimmed, path.isNotEmpty ? path.first : null);
      }

      return SocialLinkDetection(
        platform: SocialPlatform.website,
        normalizedValue: trimmed.startsWith('http') ? trimmed : 'https://$trimmed',
        handle: host,
      );
    }

    return SocialLinkDetection(
      platform: SocialPlatform.other,
      normalizedValue: trimmed,
      handle: trimmed,
    );
  }

  static SocialLinkDetection _profile(SocialPlatform platform, String value, String? handle) {
    return SocialLinkDetection(
      platform: platform,
      normalizedValue: value.startsWith('http') ? value : 'https://$value',
      handle: handle,
    );
  }
}
