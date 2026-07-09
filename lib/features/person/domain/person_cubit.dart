import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/tmdb_service.dart';

abstract class PersonState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PersonInitial extends PersonState {}

class PersonLoading extends PersonState {}

class PersonLoaded extends PersonState {
  final Map<String, dynamic> person;
  final List<Map<String, dynamic>> credits;

  PersonLoaded({required this.person, required this.credits});

  @override
  List<Object?> get props => [person, credits];
}

class PersonError extends PersonState {
  final String message;
  PersonError(this.message);

  @override
  List<Object?> get props => [message];
}

class PersonCubit extends Cubit<PersonState> {
  final TmdbService _tmdbService;
  final int personId;

  PersonCubit(this._tmdbService, this.personId) : super(PersonInitial()) {
    loadPerson();
  }

  Future<void> loadPerson() async {
    emit(PersonLoading());
    try {
      final results = await Future.wait([
        _tmdbService.getPersonDetails(personId),
        _tmdbService.getPersonCredits(personId),
      ]);

      if (isClosed) return;
      emit(PersonLoaded(
        person: results[0],
        credits: List<Map<String, dynamic>>.from(results[1]['cast'] ?? []),
      ));
    } catch (e) {
      if (isClosed) return;
      emit(PersonError('Something went wrong. Please try again.'));
    }
  }
}