import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dofluxo/presentation/dashboard/config/dashboard_stages.dart';
import 'package:dofluxo/presentation/dashboard/models/project_board_item.dart';
import 'package:dofluxo/presentation/dashboard/utils/dashboard_board_mapper.dart';
import 'package:dofluxo/presentation/projects/models/project_production_task.dart';
import 'package:flutter_test/flutter_test.dart';

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
  group('DashboardBoardMapper', () {
    test('maps legacy Postagens status to postagens do dia column', () {
      expect(
        DashboardBoardMapper.stageIdForStatus('Postagens'),
        DashboardStageId.postagensDoDia,
      );
    });

    test('maps workflow statuses to expected columns', () {
      expect(DashboardBoardMapper.stageIdForStatus('Criação'), DashboardStageId.criacao);
      expect(DashboardBoardMapper.stageIdForStatus('INCÊNDIOS'), DashboardStageId.incendios);
      expect(DashboardBoardMapper.stageIdForStatus('Captação'), DashboardStageId.captacao);
      expect(DashboardBoardMapper.stageIdForStatus('Edição'), DashboardStageId.edicao);
      expect(DashboardBoardMapper.stageIdForStatus('Aprovação'), DashboardStageId.aprovacao);
    });

    test('groups snapshot docs into board columns', () {
      final snapshot = _FakeSnapshot([
        _FakeDoc('1', {
          'title': 'Campanha verão',
          'status': 'Postagens',
          'description': 'Feed instagram',
        }),
        _FakeDoc('2', {
          'title': 'Reels marca',
          'status': 'Edição',
          'clientName': 'Cliente X',
          'progress': 75,
        }),
        _FakeDoc('3', {
          'title': 'Urgente',
          'status': 'INCÊNDIOS',
        }),
      ]);

      final board = DashboardBoardMapper.groupSnapshot(snapshot);

      expect(board[DashboardStageId.postagensDoDia.name], hasLength(1));
      expect(board[DashboardStageId.edicao.name], hasLength(1));
      expect(board[DashboardStageId.incendios.name], hasLength(1));
      expect(board[DashboardStageId.edicao.name]!.first.clientName, 'Cliente X');
      expect(board[DashboardStageId.edicao.name]!.first.progress, 0.75);
    });

    test('builds display title with client name', () {
      final item = ProjectBoardItem.fromFirestore('1', {
        'title': 'Nome Projeto',
        'clientName': 'Cliente',
        'status': 'Aprovação',
      });

      expect(item.displayTitle, 'Cliente - Nome Projeto');
      expect(item.statusLabel, 'Aguardando aprovação');
    });

    test('production task helpers compute progress', () {
      final progress = ProjectProductionTask.progressFromTasks(const [
        ProjectProductionTask(label: 'A', completed: true),
        ProjectProductionTask(label: 'B', completed: true),
        ProjectProductionTask(label: 'C', completed: false),
      ]);

      expect(progress, closeTo(2 / 3, 0.001));
    });

    test('reads expected delivery date on board item', () {
      final delivery = Timestamp.fromDate(DateTime(2025, 6, 15));
      final item = ProjectBoardItem.fromFirestore('1', {
        'title': 'Projeto',
        'status': 'Postagens',
        'expectedDeliveryDate': delivery,
      });

      expect(item.expectedDeliveryDate, '15/06/2025');
    });

    test('reads progress from production tasks in firestore data', () {
      final item = ProjectBoardItem.fromFirestore('1', {
        'title': 'Projeto',
        'status': 'Criação',
        'productionTasks': [
          {'label': 'Roteiro', 'completed': true},
          {'label': 'Gravação', 'completed': false},
        ],
      });

      expect(item.progress, 0.5);
      expect(item.hasProgress, isTrue);
    });
  });
}
