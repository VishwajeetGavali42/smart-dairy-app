class FormatUtils {
  /// Format milk/liquid quantity preserving decimal places if present (e.g. 1.5 Ltr, 2 Ltr, 12.25 Ltr)
  static String formatQty(dynamic qty, [String unit = 'Ltr']) {
    if (qty == null) return unit.isEmpty ? '0' : '0 $unit';
    final double val = (qty is num) ? qty.toDouble() : (double.tryParse(qty.toString()) ?? 0.0);
    String str;
    if (val % 1 == 0) {
      str = val.toInt().toString();
    } else {
      str = val.toStringAsFixed(2);
      if (str.endsWith('0')) {
        str = str.substring(0, str.length - 1);
      }
    }
    return unit.isEmpty ? str : '$str $unit';
  }

  /// Format currency with rupee symbol (e.g. ₹150, ₹150.50)
  static String formatCurrency(dynamic amount, {bool showDecimalsForZero = false}) {
    if (amount == null) return '₹0';
    final double val = (amount is num) ? amount.toDouble() : (double.tryParse(amount.toString()) ?? 0.0);
    if (val % 1 == 0 && !showDecimalsForZero) {
      return '₹${val.toInt()}';
    }
    return '₹${val.toStringAsFixed(2)}';
  }

  /// Format rate per litre (e.g. ₹42.50/L or ₹40/L)
  static String formatRate(dynamic rate) {
    if (rate == null) return '₹0/L';
    final double val = (rate is num) ? rate.toDouble() : (double.tryParse(rate.toString()) ?? 0.0);
    if (val % 1 == 0) {
      return '₹${val.toInt()}/L';
    }
    return '₹${val.toStringAsFixed(2)}/L';
  }
}
