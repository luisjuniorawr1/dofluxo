import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_format_utils.dart';
import '../../dashboard/config/dashboard_stages.dart';
import '../../dashboard/utils/dashboard_board_mapper.dart';
import '../../../core/utils/theme_utils.dart';
import '../../projects/models/planning_status.dart';
import '../../projects/models/project_category.dart';
import '../manager/project_service.dart';
import '../models/project_production_task.dart';
import '../widgets/expected_delivery_date_field.dart';
import '../widgets/planning_status_chip.dart';

class ProjectDetailPage extends StatefulWidget {
  const ProjectDetailPage({super.key, required this.projectId});

  final String projectId;

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _additionalInfoController = TextEditingController();

  DashboardStageId? _selectedStage;
  late final List<TextEditingController> _taskControllers;
  List<ProjectProductionTask> _tasks = List.generate(
    5,
    (_) => const ProjectProductionTask(label: ''),
  );
  String _clientName = '';
  DateTime? _expectedDeliveryDate;
  ProjectCategory _category = ProjectCategory.job;
  String _format = PlanningFormat.options.first;
  final _referenceController = TextEditingController();
  final _customFormatController = TextEditingController();
  PlanningStatus _planningStatus = PlanningStatus.all.first;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _taskControllers = List.generate(5, (_) => TextEditingController());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _additionalInfoController.dispose();
    _referenceController.dispose();
    _customFormatController.dispose();
    for (final controller in _taskControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncFromData(Map<String, dynamic> data) {
    _category = projectCategoryFromFirestore(data['category'] as String?);
    _titleController.text = data['title'] as String? ?? '';
    _descriptionController.text = data['description'] as String? ?? '';
    _additionalInfoController.text = data['additionalInfo'] as String? ?? '';
    _referenceController.text = data['reference'] as String? ?? '';
    _clientName = data['clientName'] as String? ?? '';
    _expectedDeliveryDate =
        DateFormatUtils.fromFirestore(data['expectedDeliveryDate']) ??
        DateFormatUtils.fromFirestore(data['scheduledDate']);
    _planningStatus = PlanningStatus.fromFirestore(
      data['planningStatus'] as String?,
    );

    final format =
        (data['format'] as String?)?.trim() ?? PlanningFormat.options.first;
    if (PlanningFormat.options.contains(format)) {
      _format = format;
    } else {
      _format = 'Outro';
      _customFormatController.text = format;
    }

    final status = data['status'] as String?;
    _selectedStage = DashboardBoardMapper.stageIdForStatus(status);

    final loadedTasks = ProjectProductionTask.listFromFirestore(
      data['productionTasks'],
    );
    _tasks = List<ProjectProductionTask>.generate(5, (index) {
      if (index < loadedTasks.length) return loadedTasks[index];
      return const ProjectProductionTask(label: '');
    });
    for (var i = 0; i < 5; i++) {
      _taskControllers[i].text = _tasks[i].label;
    }
  }

  String get _resolvedFormat {
    if (_format == 'Outro') {
      final custom = _customFormatController.text.trim();
      return custom.isEmpty ? 'Outro' : custom;
    }
    return _format;
  }

  bool get _isPlanejamento => _category == ProjectCategory.planejamento;

  Future<void> _save({
    bool closeOnSuccess = true,
    bool showSnackBar = true,
  }) async {
    if (_isSaving) return;
    if (!_isPlanejamento && _selectedStage == null) return;

    final trimmedTitle = _titleController.text.trim();
    if (trimmedTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Informe o nome do projeto.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final deliveryTimestamp = DateFormatUtils.toFirestoreTimestamp(
      _expectedDeliveryDate,
    );

    try {
      if (_isPlanejamento) {
        await context.read<ProjectService>().updateProject(widget.projectId, {
          'title': trimmedTitle,
          'description': _descriptionController.text.trim(),
          'format': _resolvedFormat,
          'reference': _referenceController.text.trim(),
          'planningStatus': _planningStatus.firestoreValue,
          'scheduledDate': deliveryTimestamp ?? FieldValue.delete(),
          'expectedDeliveryDate': deliveryTimestamp ?? FieldValue.delete(),
        });
      } else {
        final status = DashboardBoardMapper.firestoreStatusForStage(
          _selectedStage!,
        );
        final progress = ProjectProductionTask.progressFromTasks(_tasks);

        await context.read<ProjectService>().updateProject(widget.projectId, {
          'title': trimmedTitle,
          'description': _descriptionController.text.trim(),
          'additionalInfo': _additionalInfoController.text.trim(),
          'status': status,
          'productionTasks': ProjectProductionTask.serializeList(_tasks),
          if (progress != null) 'progress': progress,
          'expectedDeliveryDate': deliveryTimestamp ?? FieldValue.delete(),
        });
      }

      if (!mounted) return;

      if (showSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Projeto salvo com sucesso!')),
        );
      }

      if (closeOnSuccess) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _updatePlanningStatus(PlanningStatus status) async {
    setState(() => _planningStatus = status);

    try {
      await context.read<ProjectService>().updateProject(widget.projectId, {
        'planningStatus': status.firestoreValue,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar status: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _updateStage(DashboardStageId stage) async {
    setState(() => _selectedStage = stage);

    try {
      final planningStatus = DashboardBoardMapper.planningStatusForStage(stage);
      await context.read<ProjectService>().updateProject(widget.projectId, {
        'status': DashboardBoardMapper.firestoreStatusForStage(stage),
        if (_isPlanejamento && planningStatus != null)
          'planningStatus': planningStatus,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar fase: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleTask(int index, bool? value) async {
    if (value == null) return;

    setState(() {
      _tasks[index] = _tasks[index].copyWith(completed: value);
    });

    final progress = ProjectProductionTask.progressFromTasks(_tasks);

    try {
      await context.read<ProjectService>().updateProject(widget.projectId, {
        'productionTasks': ProjectProductionTask.serializeList(_tasks),
        if (progress != null) 'progress': progress,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar atividade: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _updateTaskLabel(int index, String label) {
    setState(() {
      _tasks[index] = _tasks[index].copyWith(
        label: label,
        completed: label.trim().isEmpty ? false : _tasks[index].completed,
      );
    });
  }

  Future<void> _saveTasksToFirestore() async {
    final progress = ProjectProductionTask.progressFromTasks(_tasks);
    await context.read<ProjectService>().updateProject(widget.projectId, {
      'productionTasks': ProjectProductionTask.serializeList(_tasks),
      if (progress != null) 'progress': progress,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Projeto'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => _save(closeOnSuccess: true),
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar'),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: context.read<ProjectService>().getProjectStream(
          widget.projectId,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final doc = snapshot.data!;
          if (!doc.exists) {
            return const Center(child: Text('Projeto não encontrado.'));
          }

          final data = doc.data() ?? {};
          if (!_initialized) {
            _syncFromData(data);
            _initialized = true;
          }

          final progress = ProjectProductionTask.progressFromTasks(_tasks);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCategoryBadge(context),
                    const SizedBox(height: 16),
                    if (_isPlanejamento)
                      ..._buildPlanejamentoFields(context)
                    else
                      ..._buildJobFields(context, progress),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isSaving
                          ? null
                          : () => _save(
                              closeOnSuccess: false,
                              showSnackBar: true,
                            ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Salvar alterações'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryBadge(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        label: Text(_category.label),
        avatar: Icon(
          _isPlanejamento ? Icons.calendar_month_outlined : Icons.work_outline,
          size: 18,
        ),
      ),
    );
  }

  List<Widget> _buildPlanejamentoFields(BuildContext context) {
    return [
      TextField(
        controller: _titleController,
        decoration: const InputDecoration(
          labelText: 'Nome do projeto',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 16),
      TextFormField(
        initialValue: _clientName.isNotEmpty
            ? _clientName
            : 'Nenhum cliente vinculado',
        readOnly: true,
        decoration: const InputDecoration(
          labelText: 'Cliente',
          border: OutlineInputBorder(),
          filled: true,
        ),
      ),
      const SizedBox(height: 16),
      ExpectedDeliveryDateField(
        value: _expectedDeliveryDate,
        required: true,
        labelText: 'Data',
        helpText: 'Data do post',
        onChanged: (date) => setState(() => _expectedDeliveryDate = date),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        initialValue: _format,
        decoration: const InputDecoration(
          labelText: 'Formato',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.view_carousel_outlined),
        ),
        items: PlanningFormat.options
            .map((f) => DropdownMenuItem(value: f, child: Text(f)))
            .toList(),
        onChanged: (value) {
          if (value != null) setState(() => _format = value);
        },
      ),
      if (_format == 'Outro') ...[
        const SizedBox(height: 16),
        TextField(
          controller: _customFormatController,
          decoration: const InputDecoration(
            labelText: 'Formato personalizado',
            border: OutlineInputBorder(),
          ),
        ),
      ],
      const SizedBox(height: 16),
      TextField(
        controller: _descriptionController,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: 'Descrição',
          border: OutlineInputBorder(),
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _referenceController,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Referência',
          hintText: 'Link do Drive, Pinterest, inspiração...',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.link),
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: 24),
      Text('Status', style: ThemeUtils.sectionTitle(context)),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: PlanningStatus.all.map((status) {
          return PlanningStatusChip(
            status: status,
            selected: _planningStatus.id == status.id,
            onTap: () => _updatePlanningStatus(status),
          );
        }).toList(),
      ),
    ];
  }

  List<Widget> _buildJobFields(BuildContext context, double? progress) {
    return [
      TextField(
        controller: _titleController,
        decoration: const InputDecoration(
          labelText: 'Nome do projeto',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _descriptionController,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: 'Descrição do projeto',
          border: OutlineInputBorder(),
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: 16),
      TextFormField(
        initialValue: _clientName.isNotEmpty
            ? _clientName
            : 'Nenhum cliente vinculado',
        readOnly: true,
        decoration: const InputDecoration(
          labelText: 'Cliente',
          border: OutlineInputBorder(),
          filled: true,
        ),
      ),
      const SizedBox(height: 16),
      ExpectedDeliveryDateField(
        value: _expectedDeliveryDate,
        onChanged: (date) => setState(() => _expectedDeliveryDate = date),
      ),
      const SizedBox(height: 24),
      Text('Etapa no Kanban', style: ThemeUtils.sectionTitle(context)),
      const SizedBox(height: 8),
      ...DashboardStage.workflow.map((stage) {
        return RadioListTile<DashboardStageId>(
          value: stage.id,
          groupValue: _selectedStage,
          onChanged: (value) {
            if (value == null) return;
            _updateStage(value);
          },
          title: Text(
            stage.title,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          dense: true,
          contentPadding: EdgeInsets.zero,
        );
      }),
      const SizedBox(height: 24),
      Text(
        'Atividades de produção (até 5)',
        style: ThemeUtils.sectionTitle(context),
      ),
      const SizedBox(height: 4),
      Text(
        'Marque as atividades concluídas para acompanhar o progresso do job.',
        style: ThemeUtils.bodyMuted(context),
      ),
      if (progress != null) ...[
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.12),
            color: ThemeUtils.successColor(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(progress * 100).round()}% concluído',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: ThemeUtils.successColor(context),
          ),
        ),
      ],
      const SizedBox(height: 12),
      ...List.generate(5, (index) {
        final task = _tasks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: task.completed,
                onChanged: task.label.trim().isEmpty
                    ? null
                    : (value) => _toggleTask(index, value),
              ),
              Expanded(
                child: TextField(
                  controller: _taskControllers[index],
                  decoration: InputDecoration(
                    labelText: 'Atividade ${index + 1}',
                    border: const OutlineInputBorder(),
                    hintText: 'Ex: Roteiro, gravação, edição...',
                  ),
                  onChanged: (value) => _updateTaskLabel(index, value),
                  onEditingComplete: _saveTasksToFirestore,
                  onTapOutside: (_) => _saveTasksToFirestore(),
                ),
              ),
            ],
          ),
        );
      }),
      const SizedBox(height: 16),
      TextField(
        controller: _additionalInfoController,
        maxLines: 5,
        decoration: const InputDecoration(
          labelText: 'Informações adicionais',
          hintText: 'Links do Drive, referências, observações...',
          border: OutlineInputBorder(),
          alignLabelWithHint: true,
        ),
      ),
    ];
  }
}
