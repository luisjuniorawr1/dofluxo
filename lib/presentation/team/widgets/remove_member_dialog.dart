import 'package:flutter/material.dart';

import '../../../core/agency/models/membership.dart';
import '../../shared/widgets/app_modal.dart';

Future<bool?> showRemoveMemberDialog(
  BuildContext context, {
  required Membership membership,
  required String agencyName,
  required bool isCurrentUser,
}) {
  final displayName = membership.userDisplayName?.trim().isNotEmpty == true
      ? membership.userDisplayName!.trim()
      : membership.userEmail;

  return showAppConfirmModal(
    context: context,
    title: isCurrentUser ? 'Sair da agência' : 'Remover da equipe',
    message: isCurrentUser
        ? 'Você sairá da agência $agencyName e precisará ser adicionado novamente para voltar.'
        : 'Deseja remover $displayName da agência $agencyName? '
            'Essa pessoa perderá acesso a projetos e clientes desta agência.',
    cancelLabel: 'Cancelar',
    confirmLabel: isCurrentUser ? 'Sair' : 'Remover',
    isDestructive: true,
  );
}
