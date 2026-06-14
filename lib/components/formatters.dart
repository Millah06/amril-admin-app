
import 'package:intl/intl.dart';

class MyFormatManager {

  static String formatMyDate(DateTime myDate, String formatterString) {
    String rowDate = DateFormat(formatterString).format(myDate);
    String req = rowDate.split(' ')[1].split(',').first;
    String formatted = '';
    if (req.endsWith('11') || req.endsWith('12') || req.endsWith('13')) {
      formatted = '${req}th';
    }
    else if (req.endsWith('1')) {
      formatted = '${req}st';
    }
    else if (req.endsWith('2')) {
      formatted = '${req}nd';
    }
    else if (req.endsWith('3')) {
      formatted = '${req}rd';
    }
    else {
      formatted = '${req}th';
    }
    return DateFormat(formatterString).format(myDate).replaceFirst(req, formatted);
  }

  static List<String> getUnavailableServices(Map<String, bool> services) {
    return services.entries
        .where((e) => e.value == false) // pick only false ones
        .map((e) => e.key)              // keep the keys
        .toList();
  }

  static String formatUnavailable(List<String> items, String provider) {
    if (items.isEmpty) return '';

    if (items.length == 1) return '${items[0]} $provider';

    // join all except the last with commas
    final allButLast = items.sublist(0, items.length - 1).join(', ');
    final last = items.last;

    return '$allButLast and $last $provider';
  }


}