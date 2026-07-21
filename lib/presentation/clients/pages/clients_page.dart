import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../manager/client_service.dart';
import '../../agency/agency_service_scope.dart';
import '../models/client_social_link.dart';
import '../pages/client_form_page.dart';
import '../widgets/client_social_links_field.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  Future<void> _openClientForm({
    String? docId,
    Map<String, dynamic>? initialData,
  }) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (routeContext) => AgencyServiceScope.wrapRoute(
          context,
          ClientFormPage(docId: docId, initialData: initialData),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String docId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir cliente'),
        content: Text('Deseja excluir "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await context.read<ClientService>().deleteClient(docId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  List<ClientSocialLink> _parseSocialLinks(Map<String, dynamic> data) {
    final rawLinks = data['socialLinks'];
    if (rawLinks is! List) return [];

    return rawLinks
        .whereType<Map>()
        .map(
          (item) => ClientSocialLink.fromMap(Map<String, dynamic>.from(item)),
        )
        .where((link) => link.value.isNotEmpty)
        .toList();
  }

  String _buildSubtitle(Map<String, dynamic> data) {
    final parts = <String>[];

    final sector = data['sector'] as String?;
    if (sector != null && sector.trim().isNotEmpty) parts.add(sector.trim());

    final phone = data['phone'] as String?;
    if (phone != null && phone.trim().isNotEmpty) parts.add(phone.trim());

    final email = data['email'] as String?;
    if (email != null && email.trim().isNotEmpty) parts.add(email.trim());

    return parts.isEmpty ? 'Sem informações adicionais' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Clientes',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () => _openClientForm(),
                icon: const Icon(Icons.add),
                label: const Text('Novo Cliente'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: context.read<ClientService>().getClientsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro ao carregar clientes: ${snapshot.error}',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Nenhum cliente cadastrado.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final name = data['name'] as String? ?? 'Sem nome';
                    final responsible = data['responsible'] as String?;
                    final socialLinks = _parseSocialLinks(data);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                          ),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _buildSubtitle(data),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (responsible != null &&
                                responsible.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Resp.: $responsible',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ClientSocialIconsRow(links: socialLinks),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Editar',
                              onPressed: () => _openClientForm(
                                docId: doc.id,
                                initialData: data,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: theme.colorScheme.error,
                              ),
                              tooltip: 'Excluir',
                              onPressed: () => _confirmDelete(doc.id, name),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
