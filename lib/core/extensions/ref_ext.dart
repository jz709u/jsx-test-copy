import 'package:flutter_riverpod/flutter_riverpod.dart';

extension WidgetRefX on WidgetRef {
  /// Invalidates [provider] and awaits the fresh fetch in one call.
  ///
  /// ```dart
  /// onRefresh: () => ref.invalidateAndAwait(bookingsProvider),
  /// ```
  Future<T> invalidateAndAwait<T>(FutureProvider<T> provider) {
    invalidate(provider);
    return read(provider.future);
  }
}
