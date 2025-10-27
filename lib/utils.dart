import 'package:intl/intl.dart';

extension DateOnlyFormatting on DateTime {
  /// Returns just the date portion (e.g. "2025-10-14")
  String get dateOnlyString => DateFormat('yyyy-MM-dd').format(this);

  /// Or a more readable version (e.g. "Oct 14, 2025")
  String get formattedDate => DateFormat('MMM d, y').format(this);
}

extension PriceString on double {
  String get asPrice =>
      NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(this);
}

extension Capitalize on String {
  String get capitalize => this[0].toUpperCase() + substring(1);
}
