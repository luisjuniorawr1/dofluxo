import 'package:flutter/material.dart';

import '../../../core/agency/models/agency_role.dart';

class AddMemberDialog extends StatefulWidget {
  const AddMemberDialog({super.key});

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  AgencyRole _role = AgencyRole.member;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar membro'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return 'Informe o e-mail.';
                  if (!email.contains('@')) return 'E-mail inválido.';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                'A pessoa precisa já ter feito login no DOFLUXO. Convites por e-mail em breve.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Cargo',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              RadioListTile<AgencyRole>(
                value: AgencyRole.member,
                groupValue: _role,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _role = value);
                },
                title: const Text('Membro'),
                subtitle: const Text('Clientes e projetos'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<AgencyRole>(
                value: AgencyRole.admin,
                groupValue: _role,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _role = value);
                },
                title: const Text('Admin'),
                subtitle: const Text('Configurações e equipe'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ],
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
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, (_emailController.text.trim(), _role));
          },
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}
