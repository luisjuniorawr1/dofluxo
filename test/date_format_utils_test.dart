import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dofluxo/core/utils/date_format_utils.dart';

void main() {
  group('DateFormatUtils delivery dates', () {
    test('parses dd/MM/yyyy like Kanban subtitle', () {
      final date = DateFormatUtils.fromFirestore('23/07/2026');
      expect(date, DateTime(2026, 7, 23));
    });

    test('parses ISO date string', () {
      final date = DateFormatUtils.fromFirestore('2026-07-23');
      expect(date, DateTime(2026, 7, 23));
    });

    test('Timestamp at local noon keeps calendar day', () {
      final ts = Timestamp.fromDate(DateTime(2026, 7, 23, 12));
      expect(DateFormatUtils.fromFirestore(ts), DateTime(2026, 7, 23));
    });

    test('Timestamp at UTC midnight still maps via local components', () {
      final ts = Timestamp.fromDate(DateTime.utc(2026, 7, 23));
      final parsed = DateFormatUtils.fromFirestore(ts);
      expect(parsed, isNotNull);
      // Must equal the local calendar day of that instant.
      final local = DateTime.utc(2026, 7, 23).toLocal();
      expect(parsed, DateTime(local.year, local.month, local.day));
    });

    test('projectDeliveryDate prefers expectedDeliveryDate', () {
      final date = DateFormatUtils.projectDeliveryDate({
        'expectedDeliveryDate': '23/07/2026',
        'scheduledDate': '01/01/2026',
      });
      expect(date, DateTime(2026, 7, 23));
    });

    test('toFirestoreTimestamp round-trips the same calendar day', () {
      final original = DateTime(2026, 7, 23);
      final ts = DateFormatUtils.toFirestoreTimestamp(original);
      expect(DateFormatUtils.fromFirestore(ts), original);
    });
  });
}
