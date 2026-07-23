import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/agency/agency_context.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/theme_utils.dart';
import '../../agency/pages/agency_onboarding_page.dart';
import '../../agency/pages/join_agency_page.dart';
import '../../shared/widgets/app_modal.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _agencyNameController = TextEditingController();
  Color _tempColor = const Color(0xFFFFD700);
  bool _isSaving = false;
  bool _loadedFromContext = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedFromContext) return;

    final agencyContext = context.read<AgencyContext>();
    _agencyNameController.text = agencyContext.activeAgencyName;
    _tempColor = agencyContext.activePrimaryColor;
    _loadedFromContext = true;
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      await context.read<AgencyContext>().updateActiveAgencyBranding(
            name: _agencyNameController.text.trim(),
            primaryColor: _tempColor,
          );

      if (!mounted) return;

      context.read<ThemeProvider>().applyAgencyBranding(
            name: _agencyNameController.text.trim(),
            color: _tempColor,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Configurações salvas com sucesso!',
            style: TextStyle(color: ThemeUtils.getContrastColor(AppTheme.success)),
          ),
          backgroundColor: AppTheme.success,
        ),
      );
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

  @override
  void dispose() {
    _agencyNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações da Agência')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _agencyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Agência',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Cor Principal da Marca',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Selecionar cor',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                  subtitle: Text(
                    'Alterações são salvas em agencies/{activeAgencyId}',
                    style: ThemeUtils.bodyMuted(context),
                  ),
                  trailing: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _tempColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onTap: () async {
                    final color = await showAppColorPickerModal(
                      context: context,
                      initialColor: _tempColor,
                    );
                    if (color != null && mounted) {
                      setState(() => _tempColor = color);
                    }
                  },
                ),
                const SizedBox(height: 40),
                Text(
                  'Minhas agências',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Entre em um cliente com código de convite ou crie outro workspace.',
                  style: ThemeUtils.bodyMuted(context),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    showAppModalPage(
                      context: context,
                      size: AppModalSize.medium,
                      child: const JoinAgencyPage(),
                    );
                  },
                  icon: const Icon(Icons.vpn_key_outlined),
                  label: const Text('Entrar em uma agência'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    showAppModalPage(
                      context: context,
                      size: AppModalSize.medium,
                      child: const AgencyOnboardingPage(isAdditional: true),
                    );
                  },
                  icon: const Icon(Icons.add_business_outlined),
                  label: const Text('Criar nova agência'),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveSettings,
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Salvar Alterações', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
