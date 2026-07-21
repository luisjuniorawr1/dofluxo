enum InviteCodeStatus {
  active('active'),
  used('used'),
  revoked('revoked');

  const InviteCodeStatus(this.firestoreValue);

  final String firestoreValue;

  static InviteCodeStatus fromFirestore(String? value) {
    return InviteCodeStatus.values.firstWhere(
      (status) => status.firestoreValue == value,
      orElse: () => InviteCodeStatus.active,
    );
  }
}
