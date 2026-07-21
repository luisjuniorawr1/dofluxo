import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../clients/manager/client_service.dart';
import '../projects/manager/project_service.dart';

/// Repassa [ProjectService] e [ClientService] para rotas/dialogs fora da árvore do [MainShell].
class AgencyServiceScope {
  AgencyServiceScope._();

  static Widget wrapRoute(BuildContext parentContext, Widget child) {
    return MultiProvider(
      providers: [
        Provider<ProjectService>.value(
          value: parentContext.read<ProjectService>(),
        ),
        Provider<ClientService>.value(
          value: parentContext.read<ClientService>(),
        ),
      ],
      child: child,
    );
  }
}
