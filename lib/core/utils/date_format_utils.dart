import 'package:cloud_firestore/cloud_firestore.dart';

/// Formatação e leitura de datas usadas nos projetos.
abstract final class DateFormatUtils {
  static const _monthNames = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  static const weekdayLabelsShort = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

  static String formatMonthYear(DateTime date) {
    return '${_monthNames[date.month - 1]} ${date.year}';
  }

  static String formatDayMonth(DateTime date) {
    return '${date.day} de ${_monthNames[date.month - 1].toLowerCase()}';
  }

  static DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  static bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  static String formatDayMonthYear(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  static DateTime? fromFirestore(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return tryParseDayMonthYear(value.trim());
    }
    return null;
  }

  /// Data de entrega/agendamento do projeto (mesma prioridade do card e do Kanban).
  static DateTime? projectDeliveryDate(Map<String, dynamic> data) {
    final parsed = fromFirestore(data['expectedDeliveryDate']) ??
        fromFirestore(data['scheduledDate']);
    return parsed != null ? dateOnly(parsed) : null;
  }

  static DateTime? tryParseDayMonthYear(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;

    return DateTime(year, month, day);
  }

  static Timestamp? toFirestoreTimestamp(DateTime? date) {
    if (date == null) return null;
    return Timestamp.fromDate(DateTime(date.year, date.month, date.day));
  }
}
