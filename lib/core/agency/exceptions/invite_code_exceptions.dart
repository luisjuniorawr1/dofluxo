class InviteCodeNotFoundException implements Exception {
  const InviteCodeNotFoundException();

  @override
  String toString() => 'Código inválido. Verifique e tente novamente.';
}

class InviteCodeExpiredException implements Exception {
  const InviteCodeExpiredException();

  @override
  String toString() => 'Este código expirou. Peça um novo convite à agência.';
}

class InviteCodeAlreadyUsedException implements Exception {
  const InviteCodeAlreadyUsedException();

  @override
  String toString() => 'Este código já foi utilizado.';
}

class InviteCodeRevokedException implements Exception {
  const InviteCodeRevokedException();

  @override
  String toString() => 'Este código foi revogado. Peça um novo convite à agência.';
}

class InviteCodeInvalidRoleException implements Exception {
  const InviteCodeInvalidRoleException();

  @override
  String toString() => 'Código de convite com função inválida.';
}

class AlreadyAgencyMemberException implements Exception {
  const AlreadyAgencyMemberException();

  @override
  String toString() => 'Você já faz parte desta agência.';
}
