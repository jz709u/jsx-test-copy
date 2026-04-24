import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import 'jsx_text.dart';

/// Wraps [AsyncValue.when] with app-standard loading and error states so
/// call sites only need to handle the [data] case.
///
/// ```dart
/// body: AsyncBuilder(
///   value: bookingsAsync,
///   data: (bookings) => BookingList(bookings),
/// )
/// ```
class AsyncBuilder<T> extends StatelessWidget {
  const AsyncBuilder({super.key, required this.value, required this.data});

  final AsyncValue<T> value;
  final Widget Function(T) data;

  @override
  Widget build(BuildContext context) => value.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(
            child: JsxText('$e', JsxTextVariant.bodyMedium, color: AppColors.error)),
        data: data,
      );
}
