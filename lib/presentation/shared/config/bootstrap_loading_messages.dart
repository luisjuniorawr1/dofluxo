import 'package:flutter/material.dart';

typedef BootstrapLoadingMessage = ({IconData icon, String text});

/// Mensagens exibidas durante o bootstrap (rotacionam e repetem em loop).
class BootstrapLoadingMessages {
  BootstrapLoadingMessages._();

  static const Duration rotationInterval = Duration(milliseconds: 1750);

  static const List<BootstrapLoadingMessage> messages = [
    (icon: Icons.groups_outlined, text: 'Reunindo a equipe...'),
    (icon: Icons.assignment_outlined, text: 'Organizando os briefings...'),
    (icon: Icons.palette_outlined, text: 'Preparando a mesa criativa...'),
    (icon: Icons.rocket_launch_outlined, text: 'Colocando os projetos em movimento...'),
    (icon: Icons.inventory_2_outlined, text: 'Conferindo as próximas entregas...'),
    (icon: Icons.waves, text: 'Organizando o fluxo da agência...'),
  ];
}
