import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/teacher_entities.dart';
import '../../domain/usecases/teacher_usecases.dart';

// --- Events ---

abstract class ClassesEvent extends Equatable {
  const ClassesEvent();

  @override
  List<Object?> get props => [];
}

class LoadClasses extends ClassesEvent {
  const LoadClasses();
}

class ClassCreated extends ClassesEvent {
  final ClassEntity newClass;

  const ClassCreated(this.newClass);

  @override
  List<Object?> get props => [newClass];
}

// --- States ---

abstract class ClassesState extends Equatable {
  const ClassesState();

  @override
  List<Object?> get props => [];
}

class ClassesInitial extends ClassesState {
  const ClassesInitial();
}

class ClassesLoading extends ClassesState {
  const ClassesLoading();
}

class ClassesLoaded extends ClassesState {
  final List<ClassEntity> classes;

  const ClassesLoaded(this.classes);

  @override
  List<Object?> get props => [classes];
}

class ClassesError extends ClassesState {
  final String message;

  const ClassesError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Bloc ---

class ClassesBloc extends Bloc<ClassesEvent, ClassesState> {
  final GetClasses getClasses;

  ClassesBloc({required this.getClasses}) : super(const ClassesInitial()) {
    on<LoadClasses>(_onLoadClasses);
    on<ClassCreated>(_onClassCreated);
  }

  Future<void> _onLoadClasses(
    LoadClasses event,
    Emitter<ClassesState> emit,
  ) async {
    emit(const ClassesLoading());
    final result = await getClasses(const NoParams());
    result.fold(
      (failure) => emit(ClassesError(failure.message)),
      (classes) => emit(ClassesLoaded(classes)),
    );
  }

  void _onClassCreated(ClassCreated event, Emitter<ClassesState> emit) {
    final currentState = state;
    if (currentState is ClassesLoaded) {
      emit(ClassesLoaded([event.newClass, ...currentState.classes]));
    }
  }
}
