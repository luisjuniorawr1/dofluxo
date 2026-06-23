import 'package:flutter/material.dart';

import '../../../core/agency/models/membership.dart';

Future<bool?> showRemoveMemberDialog(
  BuildContext context, {
  required Membership membership,
  required String agencyName,
  required bool isCurrentUser,
}) {
  final displayName = membership.userDisplayName?.trim().isNotEmpty == true
      ? membership.userDisplayName!.trim()
      : membership.userEmail;

  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(isCurrentUser ? 'Sair da agência' : 'Remover da equipe'),
      content: Text(
        isCurrentUser
            ? 'Você sairá da agência $agencyName e precisará ser adicionado novamente para voltar.'
            : 'Deseja remover $displayName da agência $agencyName? '
                'Essa pessoa perderá acesso a projetos e clientes desta agência.',
      ),
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
          child: Text(isCurrentUser ? 'Sair' : 'Remover'),
        ),
      ],
    ),
  );
}
