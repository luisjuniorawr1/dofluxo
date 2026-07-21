import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';

import '../../../core/agency/agency_context.dart';
import '../../../core/agency/models/agency.dart';
import '../../../core/utils/theme_utils.dart';

/// Wizard de criação da primeira agência (usuário sem membership).
class AgencyOnboardingPage extends StatefulWidget {
  const AgencyOnboardingPage({super.key, this.isAdditional = false});

  /// Quando true, cria agência extra e volta à tela anterior ao concluir.
  final bool isAdditional;

  @override
  State<AgencyOnboardingPage> createState() => _AgencyOnboardingPageState();
}

class _AgencyOnboardingPageState extends State<AgencyOnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  Color _primaryColor = Agency.defaultPrimaryColor;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _closeAfterSuccess() {
    if (widget.isAdditional) {
      Navigator.pop(context);
      return;
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final agencyContext = context.read<AgencyContext>();

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      if (widget.isAdditional) {
        await agencyContext.createAgency(
          name: _nameController.text.trim(),
          primaryColor: _primaryColor,
        );
      } else {
        await agencyContext.createFirstAgency(
          name: _nameController.text.trim(),
          primaryColor: _primaryColor,
        );
      }

      if (!mounted) return;

      _closeAfterSuccess();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isAdditional
                ? 'Nova agência criada e ativada.'
                : 'Agência criada com sucesso!',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = _friendlyError(e);
      setState(() => _errorMessage = message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('permission-denied')) {
      return 'Permissão negada no Firestore. Publique as regras atualizadas '
          '(firebase deploy --only firestore) e tente novamente.';
    }
    return text
        .replaceFirst('Exception: ', '')
        .replaceFirst('StateError: ', '');
  }

  Future<void> _pickColor() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cor da agência'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _primaryColor,
            onColorChanged: (color) => setState(() => _primaryColor = color),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: widget.isAdditional
          ? AppBar(title: const Text('Criar agência'))
          : null,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.storefront_outlined,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.isAdditional
                        ? 'Nova agência'
                        : 'Configure sua agência',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.isAdditional
                        ? 'Crie outro workspace para um cliente ou operação separada.'
                        : 'Crie sua primeira agência para começar a gerenciar projetos e clientes.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _nameController,
                    enabled: !_isSubmitting,
                    decoration: const InputDecoration(
                      labelText: 'Nome da agência',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o nome da agência';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 20),
                  Text('Cor principal', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Selecionar cor'),
                    subtitle: Text(
                      'Usada na sidebar e no tema do app',
                      style: ThemeUtils.bodyMuted(context),
                    ),
                    trailing: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    onTap: _isSubmitting ? null : _pickColor,
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Criar agência'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
