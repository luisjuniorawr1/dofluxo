import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../manager/client_service.dart';
import '../models/client_social_link.dart';
import '../widgets/client_social_links_field.dart';
import '../../../core/utils/theme_utils.dart';
import '../../shared/widgets/app_modal.dart';

class ClientFormPage extends StatefulWidget {
  const ClientFormPage({
    super.key,
    this.docId,
    this.initialData,
  });

  final String? docId;
  final Map<String, dynamic>? initialData;

  bool get isEditing => docId != null;

  @override
  State<ClientFormPage> createState() => _ClientFormPageState();
}

class _ClientFormPageState extends State<ClientFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _sectorController;
  late final TextEditingController _responsibleController;
  late final TextEditingController _addressController;

  List<ClientSocialLink> _socialLinks = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData ?? {};

    _nameController = TextEditingController(text: data['name'] as String? ?? '');
    _emailController = TextEditingController(text: data['email'] as String? ?? '');
    _phoneController = TextEditingController(text: data['phone'] as String? ?? '');
    _sectorController = TextEditingController(text: data['sector'] as String? ?? '');
    _responsibleController = TextEditingController(text: data['responsible'] as String? ?? '');
    _addressController = TextEditingController(text: data['address'] as String? ?? '');

    final rawLinks = data['socialLinks'];
    if (rawLinks is List) {
      _socialLinks = rawLinks
          .whereType<Map>()
          .map((item) => ClientSocialLink.fromMap(Map<String, dynamic>.from(item)))
          .where((link) => link.value.isNotEmpty)
          .toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _sectorController.dispose();
    _responsibleController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildPayload() {
    return {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'sector': _sectorController.text.trim(),
      'responsible': _responsibleController.text.trim(),
      'address': _addressController.text.trim(),
      'socialLinks': _socialLinks.map((link) => link.toMap()).toList(),
    };
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    try {
      final payload = _buildPayload();

      if (widget.isEditing) {
        await context.read<ClientService>().updateClient(widget.docId!, payload);
      } else {
        await context.read<ClientService>().addClient(payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? 'Cliente atualizado!' : 'Cliente criado!'),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar cliente: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inModal = AppModalScope.isOf(context);
    final title = widget.isEditing ? 'Editar Cliente' : 'Novo Cliente';

    final form = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Dados do cliente', style: ThemeUtils.sectionTitle(context)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            autofocus: !widget.isEditing,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nome *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Informe o nome do cliente';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-mail',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Telefone',
              hintText: '(11) 99999-9999',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 28),
          Text('Empresa', style: ThemeUtils.sectionTitle(context)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _sectorController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Ramo de trabalho',
              hintText: 'Ex.: Moda, Alimentação, Saúde',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _responsibleController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Responsável',
              hintText: 'Nome do contato principal',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Endereço',
              hintText: 'Rua, número, bairro, cidade',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 28),
          ClientSocialLinksField(
            links: _socialLinks,
            onChanged: (links) => setState(() => _socialLinks = links),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.isEditing ? 'Salvar alterações' : 'Criar cliente'),
          ),
        ],
      ),
    );

    if (inModal) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppModalHeader(title: title),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: form,
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: form,
          ),
        ),
      ),
    );
  }
}
