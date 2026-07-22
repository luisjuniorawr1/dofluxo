import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_format_utils.dart';
import '../../../core/utils/theme_utils.dart';
import '../../clients/manager/client_service.dart';
import '../models/planning_status.dart';
import '../models/project_category.dart';
import '../models/project_production_task.dart';
import 'expected_delivery_date_field.dart';
import 'new_project_delivery_calendar.dart';
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

  DateTime? get _calendarSelectedDay =>
      _isPlanejamento ? _scheduledDate : _expectedDeliveryDate;

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
        .map((controller) => ProjectProductionTask(label: controller.text.trim()))
        .toList();
  }

  String get _resolvedFormat {
    if (_selectedFormat == 'Outro') {
      final custom = _customFormatController.text.trim();
      return custom.isEmpty ? 'Outro' : custom;
    }
    return _selectedFormat;
  }

  void _onCalendarDaySelected(DateTime day) {
    setState(() {
      if (_isPlanejamento) {
        _scheduledDate = day;
      } else {
        _expectedDeliveryDate = day;
      }
    });
  }

  void _submit() {
    final theme = Theme.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;

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
        expectedDeliveryDate: _isPlanejamento ? _scheduledDate : _expectedDeliveryDate,
        format: _isPlanejamento ? _resolvedFormat : null,
        reference: _isPlanejamento ? _referenceController.text.trim() : null,
        planningStatus: _isPlanejamento ? _planningStatus : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final media = MediaQuery.sizeOf(context);
    final isWide = media.width >= 900;
    final maxHeight = media.height * 0.94;
    // Quase full-bleed: células do calendário ficam mais largas p/ o nome do card.
    final dialogWidth = isWide
        ? (media.width - 24).clamp(1100.0, 1680.0)
        : 560.0;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isWide ? 12 : 16,
        vertical: 12,
      ),
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: maxHeight,
          minWidth: isWide ? dialogWidth : 0,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: scheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 7,
                                child: NewProjectDeliveryCalendar(
                                  selectedDay: _calendarSelectedDay,
                                  onDaySelected: _onCalendarDaySelected,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 4,
                                child: _buildFormPanel(theme, scheme),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: media.height * 0.42,
                                child: NewProjectDeliveryCalendar(
                                  selectedDay: _calendarSelectedDay,
                                  onDaySelected: _onCalendarDaySelected,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(child: _buildFormPanel(theme, scheme)),
                            ],
                          ),
                  ),
                ),
                _buildFooter(theme, scheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormPanel(ThemeData theme, ColorScheme scheme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Text(
                'Novo Projeto',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Categoria',
                      style: ThemeUtils.sectionTitle(context),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<ProjectCategory>(
                      segments: ProjectCategory.values
                          .map(
                            (c) => ButtonSegment(
                              value: c,
                              label: Text(c.label),
                              icon: Icon(
                                c == ProjectCategory.job
                                    ? Icons.work_outline
                                    : Icons.calendar_month_outlined,
                                size: 18,
                              ),
                            ),
                          )
                          .toList(),
                      selected: {_category},
                      onSelectionChanged: (values) =>
                          setState(() => _category = values.first),
                    ),
                    const SizedBox(height: 20),
                    _buildClientField(),
                    const SizedBox(height: 16),
                    if (_isPlanejamento) ...[
                      ..._buildPlanejamentoFields(theme),
                    ] else ...[
                      ..._buildJobFields(theme, scheme),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, ColorScheme scheme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            Tooltip(
              message: 'Em breve — rascunhos ainda não estão no backend',
              child: TextButton(
                onPressed: null,
                child: Text(
                  'Salvar rascunho',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: _submit,
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
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

  List<Widget> _buildJobFields(ThemeData theme, ColorScheme scheme) {
    final isWideForm = MediaQuery.sizeOf(context).width >= 900;

    final mainFields = <Widget>[
      TextFormField(
        controller: _titleController,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Nome do projeto',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Informe o nome do projeto';
          }
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
    ];

    final activities = _buildActivitiesBlock(theme, scheme);

    if (!isWideForm) {
      return [...mainFields, const SizedBox(height: 20), activities];
    }

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Column(children: mainFields)),
          const SizedBox(width: 16),
          Expanded(child: activities),
        ],
      ),
    ];
  }

  Widget _buildActivitiesBlock(ThemeData theme, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Atividades de produção',
          style: ThemeUtils.sectionTitle(context),
        ),
        const SizedBox(height: 10),
        ...List.generate(5, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: scheme.outline),
              ),
              child: TextFormField(
                controller: _taskControllers[index],
                decoration: InputDecoration(
                  labelText: 'Atividade ${index + 1}',
                  hintText: 'Opcional',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  List<Widget> _buildPlanejamentoFields(ThemeData theme) {
    return [
      TextFormField(
        controller: _titleController,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Nome do projeto',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Informe o nome do projeto';
          }
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
          if (value == null || value.trim().isEmpty) {
            return 'Informe a descrição';
          }
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
      Text('Status', style: ThemeUtils.sectionTitle(context)),
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
    final deliveryTimestamp = DateFormatUtils.toFirestoreTimestamp(expectedDeliveryDate);

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
            planningStatus?.firestoreValue ?? PlanningStatus.all.first.firestoreValue,
        'status': 'Planejamento',
        if (deliveryTimestamp != null) 'scheduledDate': deliveryTimestamp,
        if (deliveryTimestamp != null) 'expectedDeliveryDate': deliveryTimestamp,
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
