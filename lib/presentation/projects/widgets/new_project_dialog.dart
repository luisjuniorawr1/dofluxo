import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_format_utils.dart';
import '../../clients/manager/client_service.dart';
import '../models/planning_status.dart';
import '../models/project_category.dart';
import '../models/project_production_task.dart';
import 'expected_delivery_date_field.dart';
import 'planning_status_chip.dart';

class NewProjectDialog extends StatefulWidget {
  const NewProjectDialog({super.key});

  @override
  State<NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<NewProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _referenceController = TextEditingController();
  final _customFormatController = TextEditingController();
  final _taskControllers = List.generate(5, (_) => TextEditingController());

  ProjectCategory _category = ProjectCategory.job;
  String? _selectedClientId;
  String? _selectedClientName;
  DateTime? _expectedDeliveryDate;
  DateTime? _scheduledDate;
  String _selectedFormat = PlanningFormat.options.first;
  PlanningStatus _planningStatus = PlanningStatus.all.first;

  bool get _isPlanejamento => _category == ProjectCategory.planejamento;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _referenceController.dispose();
    _customFormatController.dispose();
    for (final controller in _taskControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<ProjectProductionTask> get _tasks {
    return _taskControllers
        .map(
          (controller) => ProjectProductionTask(label: controller.text.trim()),
        )
        .toList();
  }

  String get _resolvedFormat {
    if (_selectedFormat == 'Outro') {
      final custom = _customFormatController.text.trim();
      return custom.isEmpty ? 'Outro' : custom;
    }
    return _selectedFormat;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Novo Projeto'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Categoria',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<ProjectCategory>(
                  segments: ProjectCategory.values
                      .map((c) => ButtonSegment(value: c, label: Text(c.label)))
                      .toList(),
                  selected: {_category},
                  onSelectionChanged: (values) =>
                      setState(() => _category = values.first),
                ),
                const SizedBox(height: 20),
                _buildClientField(),
                const SizedBox(height: 16),
                if (_isPlanejamento) ...[
                  ..._buildPlanejamentoFields(),
                ] else ...[
                  ..._buildJobFields(theme),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              if (_isPlanejamento && _scheduledDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Selecione a data do post.'),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
                return;
              }

              Navigator.pop(
                context,
                NewProjectResult(
                  category: _category,
                  title: _titleController.text.trim(),
                  description: _descriptionController.text.trim(),
                  clientId: _selectedClientId!,
                  clientName: _selectedClientName ?? '',
                  tasks: _isPlanejamento ? const [] : _tasks,
                  expectedDeliveryDate: _isPlanejamento
                      ? _scheduledDate
                      : _expectedDeliveryDate,
                  format: _isPlanejamento ? _resolvedFormat : null,
                  reference: _isPlanejamento
                      ? _referenceController.text.trim()
                      : null,
                  planningStatus: _isPlanejamento ? _planningStatus : null,
                ),
              );
            }
          },
          child: const Text('Criar'),
        ),
      ],
    );
  }

  Widget _buildClientField() {
    return StreamBuilder<QuerySnapshot>(
      stream: context.read<ClientService>().getClientsStream(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        return DropdownButtonFormField<String>(
          initialValue: _selectedClientId,
          decoration: const InputDecoration(
            labelText: 'Cliente',
            border: OutlineInputBorder(),
          ),
          items: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final name = data['name'] as String? ?? 'Sem nome';
            return DropdownMenuItem(value: doc.id, child: Text(name));
          }).toList(),
          onChanged: docs.isEmpty
              ? null
              : (value) {
                  final doc = docs.firstWhere((d) => d.id == value);
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  setState(() {
                    _selectedClientId = value;
                    _selectedClientName = data['name'] as String? ?? '';
                  });
                },
          validator: (value) {
            if (value == null || value.isEmpty) return 'Selecione um cliente';
            return null;
          },
        );
      },
    );
  }

  List<Widget> _buildJobFields(ThemeData theme) {
    return [
      TextFormField(
        controller: _titleController,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Nome do projeto',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty)
            return 'Informe o nome do projeto';
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _descriptionController,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Descrição (opcional)',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 16),
      ExpectedDeliveryDateField(
        value: _expectedDeliveryDate,
        onChanged: (date) => setState(() => _expectedDeliveryDate = date),
      ),
      const SizedBox(height: 20),
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Atividades de produção (até 5)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(height: 8),
      ...List.generate(5, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextFormField(
            controller: _taskControllers[index],
            decoration: InputDecoration(
              labelText: 'Atividade ${index + 1}',
              border: const OutlineInputBorder(),
              hintText: 'Opcional',
            ),
          ),
        );
      }),
    ];
  }

  List<Widget> _buildPlanejamentoFields() {
    return [
      TextFormField(
        controller: _titleController,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Nome do projeto',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty)
            return 'Informe o nome do projeto';
          return null;
        },
      ),
      const SizedBox(height: 16),
      ExpectedDeliveryDateField(
        value: _scheduledDate,
        required: true,
        labelText: 'Data',
        helpText: 'Data do post',
        onChanged: (date) => setState(() => _scheduledDate = date),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        initialValue: _selectedFormat,
        decoration: const InputDecoration(
          labelText: 'Formato',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.view_carousel_outlined),
        ),
        items: PlanningFormat.options
            .map((f) => DropdownMenuItem(value: f, child: Text(f)))
            .toList(),
        onChanged: (value) {
          if (value != null) setState(() => _selectedFormat = value);
        },
      ),
      if (_selectedFormat == 'Outro') ...[
        const SizedBox(height: 16),
        TextFormField(
          controller: _customFormatController,
          decoration: const InputDecoration(
            labelText: 'Formato personalizado',
            border: OutlineInputBorder(),
          ),
        ),
      ],
      const SizedBox(height: 16),
      TextFormField(
        controller: _descriptionController,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: 'Descrição',
          hintText: 'Tema, copy, briefing do post...',
          border: OutlineInputBorder(),
          alignLabelWithHint: true,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty)
            return 'Informe a descrição';
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _referenceController,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Referência (opcional)',
          hintText: 'Link do Drive, Pinterest, inspiração...',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.link),
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: 20),
      Text(
        'Status',
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: PlanningStatus.all.map((status) {
          return PlanningStatusChip(
            status: status,
            selected: _planningStatus.id == status.id,
            onTap: () => setState(() => _planningStatus = status),
          );
        }).toList(),
      ),
    ];
  }
}

class NewProjectResult {
  const NewProjectResult({
    required this.category,
    required this.title,
    required this.description,
    required this.clientId,
    required this.clientName,
    required this.tasks,
    this.expectedDeliveryDate,
    this.format,
    this.reference,
    this.planningStatus,
  });

  final ProjectCategory category;
  final String title;
  final String description;
  final String clientId;
  final String clientName;
  final List<ProjectProductionTask> tasks;
  final DateTime? expectedDeliveryDate;
  final String? format;
  final String? reference;
  final PlanningStatus? planningStatus;

  Map<String, dynamic> toFirestorePayload(String projectUuid) {
    final deliveryTimestamp = DateFormatUtils.toFirestoreTimestamp(
      expectedDeliveryDate,
    );

    if (category == ProjectCategory.planejamento) {
      return {
        'id': projectUuid,
        'category': category.firestoreValue,
        'title': title.trim(),
        'description': description,
        'clientId': clientId,
        'clientName': clientName,
        if (format != null) 'format': format,
        if (reference != null && reference!.isNotEmpty) 'reference': reference,
        'planningStatus':
            planningStatus?.firestoreValue ??
            PlanningStatus.all.first.firestoreValue,
        'status': 'Planejamento',
        if (deliveryTimestamp != null) 'scheduledDate': deliveryTimestamp,
        if (deliveryTimestamp != null)
          'expectedDeliveryDate': deliveryTimestamp,
      };
    }

    final progress = ProjectProductionTask.progressFromTasks(tasks);

    return {
      'id': projectUuid,
      'category': category.firestoreValue,
      'title': title,
      'description': description,
      'clientId': clientId,
      'clientName': clientName,
      'status': 'Planejamento',
      'productionTasks': ProjectProductionTask.serializeList(tasks),
      if (progress != null) 'progress': progress,
      if (deliveryTimestamp != null) 'expectedDeliveryDate': deliveryTimestamp,
    };
  }
}
