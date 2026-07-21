import 'package:flutter_test/flutter_test.dart';
import 'package:dofluxo/core/update/app_update_logic.dart';

void main() {
  group('normalizeVersionJson', () {
    test('combina version + build_number', () {
      final result = normalizeVersionJson({
        'app_name': 'dofluxo',
        'version': '1.0.0',
        'build_number': '2',
      });
      expect(result, '1.0.0+2');
    });

    test('usa apenas version quando build_number ausente', () {
      final result = normalizeVersionJson({'version': '1.2.3'});
      expect(result, '1.2.3');
    });

    test('retorna null quando version ausente', () {
      final result = normalizeVersionJson({'build_number': '5'});
      expect(result, isNull);
    });

    test('retorna null quando version vazia', () {
      final result = normalizeVersionJson({'version': '   '});
      expect(result, isNull);
    });
  });

  group('grace period', () {
    final detectedAt = DateTime(2026, 6, 19, 12, 0, 0);

    test('remainingGracePeriod diminui com o tempo', () {
      expect(
        remainingGracePeriod(
          detectedAt: detectedAt,
          now: detectedAt.add(const Duration(minutes: 2)),
        ),
        const Duration(minutes: 3),
      );
    });

    test('remainingGracePeriod não fica negativo', () {
      expect(
        remainingGracePeriod(
          detectedAt: detectedAt,
          now: detectedAt.add(const Duration(minutes: 10)),
        ),
        Duration.zero,
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
      expect(
        shouldAutoReload(
          detectedAt: detectedAt,
          now: detectedAt.add(const Duration(minutes: 4, seconds: 59)),
        ),
        isFalse,
      );
    });

    test('formatGraceCountdown', () {
      expect(formatGraceCountdown(const Duration(minutes: 4, seconds: 32)), '4:32');
      expect(formatGraceCountdown(const Duration(seconds: 8)), '0:08');
    });
  });

  group('isUpdateRequired', () {
    test('força quando versões diferem', () {
      expect(
        isUpdateRequired(sessionVersion: '1.0.0+1', remoteVersion: '1.0.0+2'),
        isTrue,
      );
    });

    test('não força quando versões iguais', () {
      expect(
        isUpdateRequired(sessionVersion: '1.0.0+2', remoteVersion: '1.0.0+2'),
        isFalse,
      );
    });

    test('não força quando remota é nula (falha de rede)', () {
      expect(
        isUpdateRequired(sessionVersion: '1.0.0+1', remoteVersion: null),
        isFalse,
      );
    });

    test('não força quando remota é vazia', () {
      expect(
        isUpdateRequired(sessionVersion: '1.0.0+1', remoteVersion: ''),
        isFalse,
      );
    });

    test('não força quando sessão é desconhecida (baseline indefinida)', () {
      expect(
        isUpdateRequired(sessionVersion: null, remoteVersion: '1.0.0+2'),
        isFalse,
      );
    });

    test('ignora espaços ao redor', () {
      expect(
        isUpdateRequired(sessionVersion: ' 1.0.0+2 ', remoteVersion: '1.0.0+2'),
        isFalse,
      );
    });
  });
}
