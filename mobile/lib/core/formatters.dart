import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String currency(num value, {String currency = 'PEN'}) {
    final locale = currency.toUpperCase() == 'USD' ? 'en_US' : 'es_PE';
    return NumberFormat.simpleCurrency(name: currency.toUpperCase(), locale: locale).format(value);
  }

  static String date(DateTime? date) {
    if (date == null) return '-';
    return DateFormat.yMMMMd('es_PE').format(date);
  }

  static String shortDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMM').format(date);
  }
}
