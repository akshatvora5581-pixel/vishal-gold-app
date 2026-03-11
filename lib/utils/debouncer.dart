import 'dart:async';
import 'package:flutter/foundation.dart';

/// Reusable debouncer for search-as-you-type or any delayed callback.
///
/// Usage:
/// ```dart
/// final _debouncer = Debouncer(milliseconds: 500);
/// _debouncer.run(() => performSearch(query));
/// ```
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({this.milliseconds = 500});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
