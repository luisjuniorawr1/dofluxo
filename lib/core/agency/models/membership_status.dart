enum MembershipStatus {
  active('active'),
  invited('invited'),
  suspended('suspended'),
  removed('removed');

  const MembershipStatus(this.firestoreValue);

  final String firestoreValue;

  static MembershipStatus fromFirestore(String? value) {
    return MembershipStatus.values.firstWhere(
      (status) => status.firestoreValue == value,
      orElse: () => MembershipStatus.active,
    );
  }
}
