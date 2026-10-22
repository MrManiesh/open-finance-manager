import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, {String symbol = '₹'}) {
    final formatter = NumberFormat.currency(
      symbol: symbol.isNotEmpty ? '$symbol ' : '',
      decimalDigits: amount.truncateToDouble() == amount ? 0 : 2,
    );
    return formatter.format(amount);
  }

  static String formatCompact(double amount, {String symbol = '₹'}) {
    final formatter = NumberFormat.compact();
    final formatted = formatter.format(amount);
    return symbol.isNotEmpty ? '$symbol$formatted' : formatted;
  }
}
