import 'dart:math';

import 'package:dofluxo/core/agency/utils/invite_code_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InviteCodeGenerator', () {
    test('generate returns DFX format', () {
      final generator = InviteCodeGenerator(random: _FakeRandom([0, 1, 2, 3, 4, 5, 6, 7]));
      final code = generator.generate();
      expect(code, startsWith('DFX-'));
      expect(isValidInviteCodeFormat(code), isTrue);
    });
  });

  group('normalizeInviteCode', () {
    test('normalizes spacing and case', () {
      expect(normalizeInviteCode(' dfx-abcd-efgh '), 'DFX-ABCD-EFGH');
    });
  });

  group('isValidInviteCodeFormat', () {
    test('accepts valid code', () {
      expect(isValidInviteCodeFormat('DFX-ABCD-2345'), isTrue);
    });

    test('rejects invalid code', () {
      expect(isValidInviteCodeFormat('ABC-123'), isFalse);
      expect(isValidInviteCodeFormat('DFX-ABCD'), isFalse);
    });
  });
}

class _FakeRandom implements Random {
  _FakeRandom(this._values);

  final List<int> _values;
  var _index = 0;

  @override
  int nextInt(int max) => _values[_index++ % _values.length];

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}
