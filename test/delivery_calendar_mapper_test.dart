// Fake Firestore snapshots for unit tests (sealed in cloud_firestore).
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dofluxo/presentation/shared/utils/delivery_calendar_mapper.dart';

class _FakeDoc implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _FakeDoc(this.id, this._data);

  @override
  final String id;
  final Map<String, dynamic> _data;

  @override
  Map<String, dynamic> data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSnapshot implements QuerySnapshot<Map<String, dynamic>> {
  _FakeSnapshot(this.docs);

  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('agrupa projetos por data de entrega prevista', () {
    final snapshot = _FakeSnapshot([
      _FakeDoc('p1', {
        'title': 'Campanha Verão',
        'clientName': 'Cliente A',
        'expectedDeliveryDate': Timestamp.fromDate(DateTime(2026, 6, 17)),
        'status': 'Edição',
      }),
      _FakeDoc('p2', {
        'title': 'Reel Junho',
        'clientName': 'Cliente B',
        'expectedDeliveryDate': Timestamp.fromDate(DateTime(2026, 6, 17)),
        'status': 'Aprovação',
      }),
      _FakeDoc('p3', {
        'title': 'Sem data',
        'expectedDeliveryDate': null,
      }),
    ]);

    final grouped = DeliveryCalendarMapper.fromSnapshot(snapshot);
    final day = DateTime(2026, 6, 17);

    expect(grouped.length, 1);
    expect(grouped[day]?.length, 2);
    expect(DeliveryCalendarMapper.countInMonth(grouped, DateTime(2026, 6)), 2);
    expect(DeliveryCalendarMapper.entriesForDay(grouped, day).first.projectId, 'p1');
  });
}
