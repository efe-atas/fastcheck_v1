import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/student_entities.dart';
import '../../domain/usecases/student_usecases.dart';

abstract class StudentDashboardState extends Equatable {
  const StudentDashboardState();

  @override
  List<Object?> get props => [];
}

class StudentDashboardInitial extends StudentDashboardState {
  const StudentDashboardInitial();
}

class StudentDashboardLoading extends StudentDashboardState {
  const StudentDashboardLoading();
}

class StudentDashboardLoaded extends StudentDashboardState {
  final StudentDashboardSummaryEntity summary;

  const StudentDashboardLoaded(this.summary);

  @override
  List<Object?> get props => [summary];
}

class StudentDashboardError extends StudentDashboardState {
  final String message;

  const StudentDashboardError(this.message);

  @override
  List<Object?> get props => [message];
}

class StudentDashboardCubit extends Cubit<StudentDashboardState> {
  final GetStudentDashboardSummary getStudentDashboardSummary;

  StudentDashboardCubit({required this.getStudentDashboardSummary})
      : super(const StudentDashboardInitial());

  Future<void> loadDashboard() async {
    emit(const StudentDashboardLoading());
    final result = await getStudentDashboardSummary(const NoParams());
    result.fold(
      (failure) => emit(StudentDashboardError(failure.message)),
      (summary) => emit(StudentDashboardLoaded(summary)),
    );
  }

  Future<void> refreshDashboard() async {
    final result = await getStudentDashboardSummary(const NoParams());
    result.fold(
      (failure) => emit(StudentDashboardError(failure.message)),
      (summary) => emit(StudentDashboardLoaded(summary)),
    );
  }
}
