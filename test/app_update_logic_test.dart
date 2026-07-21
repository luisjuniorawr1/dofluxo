import 'package:flutter_test/flutter_test.dart';
import 'package:dofluxo/core/update/app_update_logic.dart';

void main() {
  group('normalizeVersionJson', () {
    test('combina version + build_number', () {
      expect(
        normalizeVersionJson({
          'version': '1.0.0',
          'build_number': '2',
        }),
        '1.0.0+2',
      );
    });

    test('usa apenas version quando build_number ausente', () {
      expect(normalizeVersionJson({'version': '1.2.3'}), '1.2.3');
    });

    test('retorna null quando version ausente', () {
      expect(normalizeVersionJson({'build_number': '5'}), isNull);
    });
  });

  group('isUpdateRequired', () {
    test('força quando versões diferem', () {
      expect(
        isUpdateRequired(sessionVersion: '1.0.0+1', remoteVersion: '1.0.0+2'),
        isTrue,
      );
    });

    test('não força quando iguais', () {
      expect(
        isUpdateRequired(sessionVersion: '1.0.0+2', remoteVersion: '1.0.0+2'),
        isFalse,
      );
    });

    test('não força em falha de rede', () {
      expect(
        isUpdateRequired(sessionVersion: '1.0.0+1', remoteVersion: null),
        isFalse,
      );
    });

    test('não força sem baseline de sessão', () {
      expect(
        isUpdateRequired(sessionVersion: null, remoteVersion: '1.0.0+2'),
        isFalse,
      );
    });
  });

  group('formatCountdown', () {
    test('formata minutos e segundos', () {
      expect(formatCountdown(const Duration(minutes: 5)), '5:00');
      expect(formatCountdown(const Duration(minutes: 4, seconds: 59)), '4:59');
      expect(formatCountdown(const Duration(seconds: 9)), '0:09');
      expect(formatCountdown(Duration.zero), '0:00');
    });
  });

  group('grace period', () {
    final detectedAt = DateTime(2026, 7, 21, 12, 0, 0);

    test('remainingGracePeriod diminui com o tempo', () {
      expect(
        remainingGracePeriod(
          detectedAt: detectedAt,
          now: detectedAt.add(const Duration(minutes: 2)),
        ),
        const Duration(minutes: 3),
      );
    });

    test('shouldAutoReload após 5 minutos', () {
      expect(
        shouldAutoReload(
          detectedAt: detectedAt,
          now: detectedAt.add(const Duration(minutes: 5)),
        ),
        isTrue,
      );
    });

    test('formatGraceCountdown delega para formatCountdown', () {
      expect(formatGraceCountdown(const Duration(minutes: 4, seconds: 32)), '4:32');
    });
  });
}
