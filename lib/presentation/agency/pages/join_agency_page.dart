import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/agency/agency_context.dart';
import '../../../core/agency/utils/invite_code_generator.dart';

/// Resgata código de convite para entrar em uma agência.
class JoinAgencyPage extends StatefulWidget {
  const JoinAgencyPage({super.key, this.isFirstAgency = false});

  /// Quando true, não exibe botão voltar (fluxo de primeiro acesso).
  final bool isFirstAgency;

  @override
  State<JoinAgencyPage> createState() => _JoinAgencyPageState();
}

class _JoinAgencyPageState extends State<JoinAgencyPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final agencyContext = context.read<AgencyContext>();
    final hadAgencyBefore = agencyContext.hasActiveAgency;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final invite = await agencyContext.redeemInviteCode(_codeController.text);
      if (!mounted) return;

      if (!widget.isFirstAgency && hadAgencyBefore) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Você entrou em ${invite.agencyName}. Agência ativa atualizada.',
            ),
          ),
        );
        Navigator.pop(context);
        return;
      }

      if (widget.isFirstAgency) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bem-vindo à ${invite.agencyName}!')),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSubmitting = _isSubmitting;

    return Scaffold(
      appBar: widget.isFirstAgency
          ? null
          : AppBar(title: const Text('Entrar em uma agência')),
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
                  if (widget.isFirstAgency) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        tooltip: 'Voltar',
                      ),
                    ),
                  ],
                  Icon(
                    Icons.vpn_key_outlined,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Código de convite',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Cole o código que você recebeu da agência. '
                    'Sua função (membro ou admin) já vem definida no convite.',
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
                    controller: _codeController,
                    enabled: !isSubmitting,
                    decoration: const InputDecoration(
                      labelText: 'Código',
                      hintText: 'DFX-XXXX-XXXX',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      final code = value?.trim() ?? '';
                      if (code.isEmpty) return 'Informe o código de convite.';
                      if (!isValidInviteCodeFormat(code)) {
                        return 'Formato inválido. Use DFX-XXXX-XXXX.';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: isSubmitting ? null : _submit,
                    child: isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Entrar na agência'),
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

/// Copia texto para a área de transferência com feedback.
Future<void> copyInviteCode(BuildContext context, String code) async {
  await Clipboard.setData(ClipboardData(text: code));
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Código copiado!')));
}
