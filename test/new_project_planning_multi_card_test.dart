import 'package:dofluxo/presentation/projects/models/planning_status.dart';
import 'package:dofluxo/presentation/projects/models/project_category.dart';
import 'package:dofluxo/presentation/projects/widgets/new_project_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NewProjectResult planning multi-card', () {
    test('toPlanningFirestorePayloads shares groupId and title', () {
      final result = NewProjectResult(
        category: ProjectCategory.planejamento,
        title: 'Campanha Julho',
        description: '',
        clientId: 'client-1',
        clientName: 'Cliente A',
        tasks: const [],
        planningCards: [
          PlanningCardDraft(
            scheduledDate: DateTime(2026, 7, 10),
            format: 'Feed',
            description: 'Post 1',
            planningStatus: PlanningStatus.all.first,
          ),
          PlanningCardDraft(
            scheduledDate: DateTime(2026, 7, 12),
            format: 'Reels',
            description: 'Post 2',
            reference: 'https://drive.example',
            planningStatus: PlanningStatus.all[1],
          ),
        ],
      );

      final payloads = result.toPlanningFirestorePayloads(
        groupId: 'group-abc',
        projectIds: const ['p1', 'p2'],
      );

      expect(payloads, hasLength(2));
      expect(payloads[0]['groupId'], 'group-abc');
      expect(payloads[1]['groupId'], 'group-abc');
      expect(payloads[0]['groupTitle'], 'Campanha Julho');
      expect(payloads[1]['title'], 'Campanha Julho');
      expect(payloads[0]['category'], 'planejamento');
      expect(payloads[1]['category'], 'planejamento');
      expect(payloads[0]['clientId'], 'client-1');
      expect(payloads[1]['format'], 'Reels');
      expect(payloads[1]['reference'], 'https://drive.example');
      expect(payloads[0]['id'], 'p1');
      expect(payloads[1]['id'], 'p2');
      expect(payloads[0]['boardOrder'], lessThan(payloads[1]['boardOrder'] as num));
    });

    test('job payload remains single-doc shape', () {
      final result = NewProjectResult(
        category: ProjectCategory.job,
        title: 'Job X',
        description: 'Desc',
        clientId: 'c1',
        clientName: 'Cliente',
        tasks: const [],
      );

      final payload = result.toFirestorePayload('job-1');
      expect(payload['category'], 'job');
      expect(payload.containsKey('groupId'), isFalse);
      expect(payload['title'], 'Job X');
    });
  });
}
