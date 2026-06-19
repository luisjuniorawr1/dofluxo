class ClientEntity {
  final String id;
  final String name;
  final String sector;
  final String initials;
  final int colorHex;
  final double progress;

  ClientEntity({
    required this.id,
    required this.name,
    required this.sector,
    required this.initials,
    required this.colorHex,
    this.progress = 0.0,
  });
}