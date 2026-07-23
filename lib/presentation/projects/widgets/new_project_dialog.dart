import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_format_utils.dart';
import '../../../core/utils/theme_utils.dart';
import '../../agency/agency_service_scope.dart';
import '../../clients/manager/client_service.dart';
import '../../shared/models/calendar_delivery_entry.dart';
import '../../shared/widgets/app_modal.dart';
import '../models/planning_draft_card.dart';
import '../models/planning_status.dart';
import '../models/project_category.dart';
import '../models/project_production_task.dart';
import '../pages/project_detail_page.dart';
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

  /// Cards do grupo de planejamento (estado local até Criar).
  final List<PlanningDraftCard> _draftCards = [];
  String? _editingLocalId;
  int _draftSeq = 0;

  bool get _isPlanejamento => _category == ProjectCategory.planejamento;

  DateTime? get _calendarSelectedDay =>
      _isPlanejamento ? _scheduledDate : _expectedDeliveryDate;

  List<CalendarDeliveryEntry> get _previewEntries =>
      _isPlanejamento ? _draftCards.map((c) => c.toPreviewEntry()).toList() : const [];

  bool get _isEditingDraft => _editingLocalId != null;

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

  Future<void> _openProjectFromCalendar(String projectId) async {
    if (projectId.startsWith('draft:')) return;
    await showAppModalPage(
      context: context,
      size: AppModalSize.large,
      child: AgencyServiceScope.wrapRoute(
        context,
        ProjectDetailPage(projectId: projectId),
      ),
    );
  }

  void _onCategoryChanged(ProjectCategory category) {
    setState(() {
      _category = category;
      if (category != ProjectCategory.planejamento) {
        _draftCards.clear();
        _editingLocalId = null;
        _clearCardForm(keepClient: true);
      }
    });
  }

  void _clearCardForm({bool keepClient = false}) {
    if (!keepClient) {
      _selectedClientId = null;
      _selectedClientName = null;
    }
    _scheduledDate = null;
    _selectedFormat = PlanningFormat.options.first;
    _customFormatController.clear();
    _descriptionController.clear();
    _referenceController.clear();
    _planningStatus = PlanningStatus.all.first;
    _editingLocalId = null;
  }

  void _addOrUpdateDraftCard() {
    final theme = Theme.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_scheduledDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecione a data do post.'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return;
    }
    if (_selectedClientId == null || _selectedClientId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecione um cliente.'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return;
    }

    final card = PlanningDraftCard(
      localId: _editingLocalId ?? 'd${++_draftSeq}',
      clientId: _selectedClientId!,
      clientName: _selectedClientName ?? '',
      scheduledDate: DateFormatUtils.dateOnly(_scheduledDate!),
      format: _resolvedFormat,
      description: _descriptionController.text.trim(),
      reference: _referenceController.text.trim(),
      planningStatus: _planningStatus,
    );

    setState(() {
      final index = _draftCards.indexWhere((c) => c.localId == card.localId);
      if (index >= 0) {
        _draftCards[index] = card;
      } else {
        _draftCards.add(card);
      }
      _clearCardForm(keepClient: true);
    });
  }

  void _editDraftCard(PlanningDraftCard card) {
    setState(() {
      _editingLocalId = card.localId;
      _selectedClientId = card.clientId;
      _selectedClientName = card.clientName;
      _scheduledDate = card.scheduledDate;
      final known = PlanningFormat.options.contains(card.format);
      _selectedFormat = known ? card.format : 'Outro';
      _customFormatController.text = known ? '' : card.format;
      _descriptionController.text = card.description;
      _referenceController.text = card.reference ?? '';
      _planningStatus = card.planningStatus;
    });
  }

  void _removeDraftCard(String localId) {
    setState(() {
      _draftCards.removeWhere((c) => c.localId == localId);
      if (_editingLocalId == localId) {
        _clearCardForm(keepClient: true);
      }
    });
  }

  void _submit() {
    final theme = Theme.of(context);

    if (_isPlanejamento) {
      final groupTitle = _titleController.text.trim();
      if (groupTitle.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Informe o nome do grupo (ex.: Planejamento Maio).'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
        return;
      }
      if (_draftCards.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Adicione ao menos um card no resumo (botão Adicionar).'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
        return;
      }

      Navigator.pop(
        context,
        NewProjectResult.planejamentoBatch(
          groupTitle: groupTitle,
          cards: List<PlanningDraftCard>.unmodifiable(_draftCards),
        ),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.pop(
      context,
      NewProjectResult.job(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        clientId: _selectedClientId!,
        clientName: _selectedClientName ?? '',
        tasks: _tasks,
        expectedDeliveryDate: _expectedDeliveryDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final media = MediaQuery.sizeOf(context);
    final isWide = media.width >= 900;

    return AppModalShell(
      size: AppModalSize.wide,
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
                            onProjectTap: _openProjectFromCalendar,
                            previewEntries: _previewEntries,
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
                            onProjectTap: _openProjectFromCalendar,
                            previewEntries: _previewEntries,
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
                          _onCategoryChanged(values.first),
                    ),
                    const SizedBox(height: 20),
                    if (_isPlanejamento) ...[
                      ..._buildPlanejamentoFields(theme, scheme),
                    ] else ...[
                      _buildClientField(),
                      const SizedBox(height: 16),
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
    final canCreate = _isPlanejamento
        ? _draftCards.isNotEmpty && _titleController.text.trim().isNotEmpty
        : true;

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
              onPressed: canCreate ? _submit : null,
              child: Text(
                _isPlanejamento
                    ? 'Criar (${_draftCards.length})'
                    : 'Criar',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientField({Key? key}) {
    return StreamBuilder<QuerySnapshot>(
      stream: context.read<ClientService>().getClientsStream(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final hasSelected =
            _selectedClientId != null && docs.any((d) => d.id == _selectedClientId);

        return DropdownButtonFormField<String>(
          key: key,
          initialValue: hasSelected ? _selectedClientId : null,
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
            if (!_isPlanejamento && (value == null || value.isEmpty)) {
              return 'Selecione um cliente';
            }
            if (_isPlanejamento && (value == null || value.isEmpty)) {
              return 'Selecione um cliente';
            }
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

  List<Widget> _buildPlanejamentoFields(ThemeData theme, ColorScheme scheme) {
    final formEpoch = _editingLocalId ?? 'new-$_draftSeq';

    return [
      TextFormField(
        controller: _titleController,
        autofocus: true,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          labelText: 'Nome do grupo',
          hintText: 'Ex.: Planejamento Maio',
          helperText: 'Reúne vários posts/cards neste planejamento',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          // Validado no Criar; no Adicionar o grupo pode já estar preenchido.
          return null;
        },
      ),
      const SizedBox(height: 20),
      Text(
        _isEditingDraft ? 'Editar card' : 'Novo card',
        style: ThemeUtils.sectionTitle(context),
      ),
      const SizedBox(height: 10),
      _buildClientField(key: ValueKey('client-$formEpoch')),
      const SizedBox(height: 16),
      ExpectedDeliveryDateField(
        key: ValueKey('date-$formEpoch'),
        value: _scheduledDate,
        required: true,
        labelText: 'Data',
        helpText: 'Data do post',
        onChanged: (date) => setState(() => _scheduledDate = date),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        key: ValueKey('format-$formEpoch'),
        initialValue: PlanningFormat.options.contains(_selectedFormat)
            ? _selectedFormat
            : 'Outro',
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
          if (!_isPlanejamento) return null;
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
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: FilledButton.tonalIcon(
          onPressed: _addOrUpdateDraftCard,
          icon: Icon(_isEditingDraft ? Icons.check_rounded : Icons.add_rounded),
          label: Text(_isEditingDraft ? 'Atualizar card' : 'Adicionar'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
      if (_isEditingDraft) ...[
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _clearCardForm(keepClient: true)),
          child: const Text('Cancelar edição'),
        ),
      ],
      const SizedBox(height: 24),
      _buildResumo(theme, scheme),
    ];
  }

  Widget _buildResumo(ThemeData theme, ColorScheme scheme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'RESUMO',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: scheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  _draftCards.isEmpty
                      ? 'Nenhum card'
                      : '${_draftCards.length} card${_draftCards.length == 1 ? '' : 's'}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_draftCards.isEmpty)
              Text(
                'Preencha o card e toque em Adicionar. Ele entra aqui e no calendário.',
                style: ThemeUtils.bodyMuted(context),
              )
            else
              ..._draftCards.map((card) => _ResumoItem(
                    card: card,
                    onEdit: () => _editDraftCard(card),
                    onRemove: () => _removeDraftCard(card.localId),
                  )),
          ],
        ),
      ),
    );
  }
}

class _ResumoItem extends StatelessWidget {
  const _ResumoItem({
    required this.card,
    required this.onEdit,
    required this.onRemove,
  });

  final PlanningDraftCard card;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 40,
                margin: const EdgeInsets.only(right: 10, top: 2),
                decoration: BoxDecoration(
                  color: card.planningStatus.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.shortTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        DateFormatUtils.formatDayMonthYear(card.scheduledDate),
                        card.format,
                        card.planningStatus.label,
                        if (card.clientName.trim().isNotEmpty) card.clientName.trim(),
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Editar',
                onPressed: onEdit,
                icon: Icon(Icons.edit_outlined, color: scheme.onSurfaceVariant),
              ),
              IconButton(
                tooltip: 'Remover',
                onPressed: onRemove,
                icon: Icon(Icons.delete_outline, color: scheme.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NewProjectResult {
  const NewProjectResult._({
    required this.category,
    required this.title,
    required this.description,
    required this.clientId,
    required this.clientName,
    required this.tasks,
    required this.planningCards,
    this.expectedDeliveryDate,
  });

  factory NewProjectResult.job({
    required String title,
    required String description,
    required String clientId,
    required String clientName,
    required List<ProjectProductionTask> tasks,
    DateTime? expectedDeliveryDate,
  }) {
    return NewProjectResult._(
      category: ProjectCategory.job,
      title: title,
      description: description,
      clientId: clientId,
      clientName: clientName,
      tasks: tasks,
      expectedDeliveryDate: expectedDeliveryDate,
      planningCards: const [],
    );
  }

  factory NewProjectResult.planejamentoBatch({
    required String groupTitle,
    required List<PlanningDraftCard> cards,
  }) {
    return NewProjectResult._(
      category: ProjectCategory.planejamento,
      title: groupTitle,
      description: '',
      clientId: '',
      clientName: '',
      tasks: const [],
      planningCards: cards,
    );
  }

  final ProjectCategory category;
  final String title;
  final String description;
  final String clientId;
  final String clientName;
  final List<ProjectProductionTask> tasks;
  final DateTime? expectedDeliveryDate;

  /// Cards do grupo (Planejamento). Vazio no modo Job.
  final List<PlanningDraftCard> planningCards;

  bool get isPlanningBatch =>
      category == ProjectCategory.planejamento && planningCards.isNotEmpty;

  Map<String, dynamic> toFirestorePayload(String projectUuid) {
    final deliveryTimestamp = DateFormatUtils.toFirestoreTimestamp(expectedDeliveryDate);
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
