import 'package:intl/intl.dart';

class TimeUtils {
  static String formatRelativeTime(int timestampMs) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - timestampMs;

    if (diff < 60000) return 'agora mesmo';
    if (diff < 3600000) {
      final mins = (diff / 60000).floor();
      return 'há $mins min';
    }
    if (diff < 86400000) {
      final hours = (diff / 3600000).floor();
      return 'há $hours h';
    }
    if (diff < 604800000) {
      final days = (diff / 86400000).floor();
      return 'há $days ${days == 1 ? 'dia' : 'dias'}';
    }
    
    final date = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
