import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/tmdb_service.dart';
import '../../../shared/models/person_model.dart';

abstract class PersonState {}

class PersonInitial extends PersonState {}

class PersonLoading extends PersonState {}

class PersonLoaded extends PersonState {
  final Map<String, dynamic> person;
  final List<Map<String, dynamic>> credits;

  PersonLoaded({required this.person, required this.credits});
}

class PersonError extends PersonState {
  final String message;
  PersonError(this.message);
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

      emit(PersonLoaded(
        person: results[0],
        credits: List<Map<String, dynamic>>.from(results[1]['cast'] ?? []),
      ));
    } catch (e) {
      emit(PersonError(e.toString()));
    }
  }
}
