// Fake Firestore snapshots for unit tests (sealed in cloud_firestore).
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dofluxo/presentation/dashboard/config/dashboard_stages.dart';
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
      expect(
        DashboardBoardMapper.stageIdForStatus('Incêndios'),
        DashboardStageId.incendios,
      );
      expect(
        DashboardBoardMapper.stageIdForStatus('Planejamento'),
        DashboardStageId.planejamento,
      );
      expect(
        DashboardBoardMapper.stageIdForStatus('Criação'),
        DashboardStageId.producao,
      );
      expect(
        DashboardBoardMapper.stageIdForStatus('Captação'),
        DashboardStageId.producao,
      );
      expect(
        DashboardBoardMapper.stageIdForStatus('Edição'),
        DashboardStageId.producao,
      );
      expect(
        DashboardBoardMapper.stageIdForStatus('Aprovação'),
        DashboardStageId.aprovacao,
      );
      expect(
        DashboardBoardMapper.stageIdForStatus('Concluído'),
        DashboardStageId.concluido,
      );
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
        _FakeDoc('3', {'title': 'Urgente', 'status': 'Incêndios'}),
        _FakeDoc('4', {
          'title': 'Post feed',
          'category': 'planejamento',
          'status': 'Planejamento',
          'format': 'Feed',
          'planningStatus': 'pendente',
        }),
      ]);

      final board = DashboardBoardMapper.groupSnapshot(snapshot);

      expect(board[DashboardStageId.planejamento.name], hasLength(2));
      expect(board[DashboardStageId.producao.name], hasLength(1));
      expect(board[DashboardStageId.incendios.name], hasLength(1));
      expect(
        board[DashboardStageId.producao.name]!.first.clientName,
        'Cliente X',
      );
      expect(board[DashboardStageId.producao.name]!.first.progress, 0.75);
    });

    test('filters jobs and planning by category', () {
      final snapshot = _FakeSnapshot([
        _FakeDoc('1', {'title': 'Job item', 'status': 'Produção'}),
        _FakeDoc('2', {
          'title': 'Planning item',
          'category': 'planejamento',
          'status': 'Planejamento',
        }),
      ]);

      final jobsOnly = DashboardBoardMapper.groupSnapshot(
        snapshot,
        includePlanning: false,
      );
      final planningOnly = DashboardBoardMapper.groupSnapshot(
        snapshot,
        includeJobs: false,
      );

      expect(jobsOnly.values.expand((items) => items), hasLength(1));
      expect(jobsOnly.values.expand((items) => items).first.title, 'Job item');

      expect(planningOnly.values.expand((items) => items), hasLength(1));
      expect(
        planningOnly.values.expand((items) => items).first.isPlanejamento,
        isTrue,
      );
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
      expect(
        ProjectCategory.planejamento.boardStripeColor,
        const Color(0xFFE74C4C),
      );
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
