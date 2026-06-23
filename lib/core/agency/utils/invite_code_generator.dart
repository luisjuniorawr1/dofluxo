import 'dart:math';

/// Gera códigos legíveis no formato DFX-XXXX-XXXX.
class InviteCodeGenerator {
  InviteCodeGenerator({Random? random}) : _random = random ?? Random.secure();

  static const _prefix = 'DFX';
  static const _chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  static const _segmentLength = 4;

  final Random _random;

  String generate() {
    final first = _randomSegment();
    final second = _randomSegment();
    return '$_prefix-$first-$second';
  }

  String _randomSegment() {
    final buffer = StringBuffer();
    for (var i = 0; i < _segmentLength; i++) {
      buffer.write(_chars[_random.nextInt(_chars.length)]);
    }
    return buffer.toString();
  }
}

/// Normaliza entrada do usuário (remove espaços, uppercase, hífens extras).
String normalizeInviteCode(String raw) {
  return raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
}

bool isValidInviteCodeFormat(String code) {
  final normalized = normalizeInviteCode(code);
  return RegExp(r'^DFX-[A-Z2-9]{4}-[A-Z2-9]{4}$').hasMatch(normalized);
}
