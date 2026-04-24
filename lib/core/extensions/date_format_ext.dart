import 'package:intl/intl.dart';

extension DateTimeFormat on DateTime {
  /// `9:45 AM`
  String get timeFormat => DateFormat('h:mm a').format(this);

  /// `Monday, January 6, 2025`
  String get longDate => DateFormat('EEEE, MMMM d, yyyy').format(this);

  /// `Monday, January 6`  (no year — used for "today" labels)
  String get longDateNoYear => DateFormat('EEEE, MMMM d').format(this);

  /// `Mon, Jan 6, 2025`
  String get mediumDate => DateFormat('EEE, MMM d, yyyy').format(this);

  /// `Jan 6, 2025`
  String get shortDate => DateFormat('MMM d, yyyy').format(this);

  /// `Jan 6`
  String get shortMonthDay => DateFormat('MMM d').format(this);

  /// `Mon, Jan 6 · 9:45 AM`  (boarding-pass / confirmation style)
  String get compactDateTime => DateFormat('EEE, MMM d · h:mm a').format(this);
}
