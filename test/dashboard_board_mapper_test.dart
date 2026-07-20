import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dofluxo/presentation/dashboard/config/dashboard_stages.dart';
import 'package:dofluxo/presentation/dashboard/config/dashboard_zones.dart';
import 'package:dofluxo/presentation/dashboard/models/project_board_item.dart';
import 'package:dofluxo/presentation/dashboard/utils/dashboard_board_mapper.dart';
import 'package:dofluxo/presentation/projects/models/project_category.dart';
import 'package:dofluxo/presentation/projects/models/project_production_task.dart';
import 'package:flutter/material.dart';
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
    test('maps legacy Postagens status to planejamento column', () {
      expect(
        DashboardBoardMapper.stageIdForStatus('Postagens'),
        DashboardStageId.planejamento,
      );
    });

    test('maps workflow statuses to expected columns', () {
      expect(DashboardBoardMapper.stageIdForStatus('Incêndios'), DashboardStageId.incendios);
      expect(DashboardBoardMapper.stageIdForStatus('Planejamento'), DashboardStageId.planejamento);
      expect(DashboardBoardMapper.stageIdForStatus('Criação'), DashboardStageId.producao);
      expect(DashboardBoardMapper.stageIdForStatus('Captação'), DashboardStageId.producao);
      expect(DashboardBoardMapper.stageIdForStatus('Edição'), DashboardStageId.producao);
      expect(DashboardBoardMapper.stageIdForStatus('Aprovação'), DashboardStageId.aprovacao);
      expect(DashboardBoardMapper.stageIdForStatus('Concluído'), DashboardStageId.concluido);
    });

    test('groups snapshot docs into dashboard zones', () {
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
          'status': 'Incêndios',
        }),
        _FakeDoc('4', {
          'title': 'Post feed',
          'category': 'planejamento',
          'status': 'Planejamento',
          'format': 'Feed',
          'planningStatus': 'pendente',
        }),
      ]);

      final board = DashboardBoardMapper.groupSnapshot(snapshot);

      expect(board[DashboardZoneId.jobs.name], hasLength(2));
      expect(board[DashboardZoneId.producao.name], hasLength(1));
      expect(board[DashboardZoneId.statusPlanejamento.name], hasLength(1));
      expect(board[DashboardZoneId.producao.name]!.first.clientName, 'Cliente X');
      expect(board[DashboardZoneId.producao.name]!.first.progress, 0.75);
    });

    test('workflowZoneForItem keeps cards in workflow; mirrors by date', () {
      final today = DateTime(2026, 6, 23);
      final yesterday = Timestamp.fromDate(DateTime(2026, 6, 22));
      final tomorrow = Timestamp.fromDate(DateTime(2026, 6, 24));
      final todayTs = Timestamp.fromDate(DateTime(2026, 6, 23));

      final overdueData = {'title': 'Atrasado', 'status': 'Produção', 'scheduledDate': yesterday};
      final overdueItem = ProjectBoardItem.fromFirestore('1', overdueData);
      expect(DashboardBoardMapper.workflowZoneForItem(overdueData, overdueItem),
          DashboardZoneId.producao);
      expect(DashboardBoardMapper.shouldMirrorInIncendio(overdueData, overdueItem, today),
          isTrue);
      expect(DashboardBoardMapper.shouldMirrorInPostagensDoDia(overdueData, overdueItem, today),
          isFalse);

      final todayData = {'title': 'Hoje', 'status': 'Produção', 'scheduledDate': todayTs};
      final todayItem = ProjectBoardItem.fromFirestore('2', todayData);
      expect(DashboardBoardMapper.workflowZoneForItem(todayData, todayItem),
          DashboardZoneId.producao);
      expect(DashboardBoardMapper.shouldMirrorInPostagensDoDia(todayData, todayItem, today),
          isTrue);

      final futureData = {'title': 'Futuro', 'status': 'Produção', 'scheduledDate': tomorrow};
      final futureItem = ProjectBoardItem.fromFirestore('3', futureData);
      expect(DashboardBoardMapper.workflowZoneForItem(futureData, futureItem),
          DashboardZoneId.producao);
      expect(DashboardBoardMapper.shouldMirrorInPostagensDoDia(futureData, futureItem, today),
          isFalse);
    });

    test('groupSnapshot mirrors without removing workflow card', () {
      final today = DateTime.now();
      final todayTs = Timestamp.fromDate(
        DateTime(today.year, today.month, today.day),
      );
      final snapshot = _FakeSnapshot([
        _FakeDoc('1', {
          'title': 'Post hoje em produção',
          'status': 'Produção',
          'scheduledDate': todayTs,
        }),
      ]);

      final board = DashboardBoardMapper.groupSnapshot(snapshot);

      expect(board[DashboardZoneId.producao.name], hasLength(1));
      expect(board[DashboardZoneId.postagensDoDia.name], hasLength(1));
      expect(
        board[DashboardZoneId.producao.name]!.first.id,
        board[DashboardZoneId.postagensDoDia.name]!.first.id,
      );
    });

    test('concluded card with today date stays in concluidos only', () {
      final today = DateTime(2026, 6, 24);
      final todayTs = Timestamp.fromDate(DateTime(2026, 6, 24));
      final data = {
        'title': 'Finalizado',
        'status': 'Concluído',
        'scheduledDate': todayTs,
        'expectedDeliveryDate': todayTs,
      };
      final item = ProjectBoardItem.fromFirestore('1', data);

      expect(
        DashboardBoardMapper.workflowZoneForItem(data, item),
        DashboardZoneId.concluidos,
      );
      expect(
        DashboardBoardMapper.shouldMirrorInPostagensDoDia(data, item, today),
        isFalse,
      );
    });

    test('mirror uses expectedDeliveryDate when scheduledDate diverges', () {
      final today = DateTime(2026, 6, 24);
      final overdue = Timestamp.fromDate(DateTime(2026, 6, 22));
      final todayTs = Timestamp.fromDate(DateTime(2026, 6, 24));

      final item = ProjectBoardItem.fromFirestore('1', {
        'title': 'Divergente',
        'status': 'Postagens',
        'expectedDeliveryDate': overdue,
        'scheduledDate': todayTs,
      });

      expect(
        DashboardBoardMapper.shouldMirrorInIncendio(
          {
            'status': 'Postagens',
            'expectedDeliveryDate': overdue,
            'scheduledDate': todayTs,
          },
          item,
          today,
        ),
        isTrue,
      );
      expect(item.expectedDeliveryDate, '22/06/2026');
    });

    test('filters jobs and planning by category', () {
      final snapshot = _FakeSnapshot([
        _FakeDoc('1', {
          'title': 'Job item',
          'status': 'Produção',
        }),
        _FakeDoc('2', {
          'title': 'Planning item',
          'category': 'planejamento',
          'status': 'Planejamento',
        }),
      ]);

      final jobsOnly = DashboardBoardMapper.groupSnapshot(snapshot, includePlanning: false);
      final planningOnly = DashboardBoardMapper.groupSnapshot(snapshot, includeJobs: false);

      expect(jobsOnly.values.expand((items) => items), hasLength(1));
      expect(jobsOnly.values.expand((items) => items).first.title, 'Job item');

      expect(planningOnly.values.expand((items) => items), hasLength(1));
      expect(planningOnly.values.expand((items) => items).first.isPlanejamento, isTrue);
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

    test('board stripe color follows project category', () {
      expect(ProjectCategory.job.boardStripeColor, const Color(0xFF9C27B0));
      expect(ProjectCategory.planejamento.boardStripeColor, const Color(0xFFE74C4C));
    });

    test('card subtitle shows delivery date and client', () {
      final item = ProjectBoardItem.fromFirestore('1', {
        'title': 'Campanha verão',
        'clientName': 'Cliente X',
        'status': 'Produção',
        'expectedDeliveryDate': Timestamp.fromDate(DateTime(2025, 6, 15)),
      });

      expect(item.cardPrimaryTitle, 'Campanha verão');
      expect(item.cardSubtitle, '15/06/2025 · Cliente X');
    });

    test('reads planejamento fields on board item', () {
      final item = ProjectBoardItem.fromFirestore('1', {
        'title': 'Post',
        'category': 'planejamento',
        'status': 'Planejamento',
        'format': 'Reels',
        'planningStatus': 'emProducao',
        'scheduledDate': Timestamp.fromDate(DateTime(2025, 6, 15)),
      });

      expect(item.isPlanejamento, isTrue);
      expect(item.format, 'Reels');
      expect(item.expectedDeliveryDate, '15/06/2025');
      expect(item.planningStatusLabel, 'Em produção');
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
        'status': 'Planejamento',
        'expectedDeliveryDate': delivery,
      });

      expect(item.expectedDeliveryDate, '15/06/2025');
    });

    test('reads progress from production tasks in firestore data', () {
      final item = ProjectBoardItem.fromFirestore('1', {
        'title': 'Projeto',
        'status': 'Produção',
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
