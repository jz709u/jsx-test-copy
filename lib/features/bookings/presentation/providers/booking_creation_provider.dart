import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../flights/domain/entities/flight.dart';
import '../../domain/use_cases/create_booking.dart';
import 'bookings_provider.dart';

enum BookingCreationStatus { idle, loading, success, failure }

@immutable
class BookingCreationState {
  final BookingCreationStatus status;
  final String? confirmationCode;
  final String? errorMessage;

  const BookingCreationState({
    this.status = BookingCreationStatus.idle,
    this.confirmationCode,
    this.errorMessage,
  });

  BookingCreationState copyWith({
    BookingCreationStatus? status,
    String? confirmationCode,
    String? errorMessage,
  }) =>
      BookingCreationState(
        status: status ?? this.status,
        confirmationCode: confirmationCode ?? this.confirmationCode,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class BookingCreationNotifier extends StateNotifier<BookingCreationState> {
  final CreateBooking _useCase;

  BookingCreationNotifier(this._useCase) : super(const BookingCreationState());

  Future<void> confirm(Flight flight, int passengers) async {
    state = state.copyWith(status: BookingCreationStatus.loading);
    try {
      final code = await _useCase.execute(flight, passengers);
      state = state.copyWith(
        status: BookingCreationStatus.success,
        confirmationCode: code,
      );
    } catch (e) {
      state = state.copyWith(
        status: BookingCreationStatus.failure,
        errorMessage: e.toString(),
      );
    }
  }
}

final createBookingUseCaseProvider = Provider<CreateBooking>(
  (ref) => CreateBooking(ref.watch(bookingRepositoryProvider)),
);

final bookingCreationProvider = StateNotifierProvider.autoDispose<
    BookingCreationNotifier, BookingCreationState>(
  (ref) => BookingCreationNotifier(ref.watch(createBookingUseCaseProvider)),
);
