import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/date_format_utils.dart';
import '../../clients/manager/client_service.dart';
import '../../projects/models/project_production_task.dart';
import 'expected_delivery_date_field.dart';
class NewProjectDialog extends StatefulWidget {
  const NewProjectDialog({super.key});

  @override
  State<NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<NewProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _taskControllers = List.generate(5, (_) => TextEditingController());
  final ClientService _clientService = ClientService();

  String? _selectedClientId;
  String? _selectedClientName;
  DateTime? _expectedDeliveryDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo Projeto'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: _clientService.getClientsStream(),
                  builder: (context, snapshot) {
                    final docs = snapshot.data?.docs ?? [];

                    return DropdownButtonFormField<String>(
                      value: _selectedClientId,
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
                        if (value == null || value.isEmpty) {
                          return 'Selecione um cliente';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Atividades de produção (até 5)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
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
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(
                context,
                NewProjectResult(
                  title: _titleController.text.trim(),
                  description: _descriptionController.text.trim(),
                  clientId: _selectedClientId!,
                  clientName: _selectedClientName ?? '',
                  tasks: _tasks,
                  expectedDeliveryDate: _expectedDeliveryDate,
                ),
              );
            }
          },
          child: const Text('Criar'),
        ),
      ],
    );
  }
}

class NewProjectResult {
  const NewProjectResult({
    required this.title,
    required this.description,
    required this.clientId,
    required this.clientName,
    required this.tasks,
    this.expectedDeliveryDate,
  });

  final String title;
  final String description;
  final String clientId;
  final String clientName;
  final List<ProjectProductionTask> tasks;
  final DateTime? expectedDeliveryDate;

  Map<String, dynamic> toFirestorePayload(String projectUuid) {
    final progress = ProjectProductionTask.progressFromTasks(tasks);
    final deliveryTimestamp = DateFormatUtils.toFirestoreTimestamp(expectedDeliveryDate);

    return {
      'id': projectUuid,
      'title': title,
      'description': description,
      'clientId': clientId,
      'clientName': clientName,
      'productionTasks': ProjectProductionTask.serializeList(tasks),
      if (progress != null) 'progress': progress,
      if (deliveryTimestamp != null) 'expectedDeliveryDate': deliveryTimestamp,
    };
  }
}
