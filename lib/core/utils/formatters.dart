import 'package:intl/intl.dart';

/// Utility functions for formatting values consistently across the app.
class AppFormatters {
  AppFormatters._();

  static final _naira = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 2,
  );

  static final _compact = NumberFormat.compact(locale: 'en');
  static final _dateTime = DateFormat('dd MMM yyyy, hh:mm a');
  static final _date = DateFormat('dd MMM yyyy');
  static final _time = DateFormat('hh:mm a');

  /// Formats a double as Nigerian Naira: ₦1,200.00
  static String naira(double amount) => _naira.format(amount);

  /// Compact large numbers: 1200000 → 1.2M
  static String compact(num value) => _compact.format(value);

  /// Full date + time: 12 Jan 2025, 03:45 PM
  static String dateTime(DateTime dt) => _dateTime.format(dt.toLocal());

  /// Date only: 12 Jan 2025
  static String date(DateTime dt) => _date.format(dt.toLocal());

  /// Time only: 03:45 PM
  static String time(DateTime dt) => _time.format(dt.toLocal());

  /// Parses an ISO 8601 string and formats it.
  static String fromIso(String iso) {
    try {
      return dateTime(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  /// Capitalises each word in a string.
  static String titleCase(String value) {
    return value
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  /// Returns a relative time label: "2 hours ago", "just now", etc.
  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return date(dt);
  }
}