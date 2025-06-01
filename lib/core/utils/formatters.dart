import 'package:intl/intl.dart';

class Formatters {
  // ============================================================================
  // DATE FORMATTERS
  // ============================================================================

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');

  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatTime(DateTime date) => _timeFormat.format(date);
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);
  static String formatApiDate(DateTime date) => _apiDateFormat.format(date);

  static DateTime? parseApiDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return _apiDateFormat.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // ============================================================================
  // TEXT FORMATTERS
  // ============================================================================

  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ')
        .map((word) => word.isEmpty ? word : capitalize(word))
        .join(' ');
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // ============================================================================
  // WORKOUT FORMATTERS
  // ============================================================================

  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  static String formatWeight(double weight) {
    if (weight == weight.toInt()) {
      return '${weight.toInt()} kg';
    } else {
      return '${weight.toStringAsFixed(1)} kg';
    }
  }

  static String formatReps(int reps) {
    return '$reps rep${reps != 1 ? 's' : ''}';
  }

  static String formatSets(int sets) {
    return '$sets set${sets != 1 ? 's' : ''}';
  }

  // ============================================================================
  // NUMBER FORMATTERS
  // ============================================================================

  static String formatNumber(num number) {
    final formatter = NumberFormat('#,##0', 'it_IT');
    return formatter.format(number);
  }

  static String formatDecimal(double number, {int decimals = 1}) {
    return number.toStringAsFixed(decimals);
  }

  static String formatPercentage(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }
}