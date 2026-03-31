import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/teacher_entities.dart';
import '../../domain/usecases/teacher_usecases.dart';

abstract class TeacherDashboardState extends Equatable {
  const TeacherDashboardState();

  @override
  List<Object?> get props => [];
}

class TeacherDashboardInitial extends TeacherDashboardState {
  const TeacherDashboardInitial();
}

class TeacherDashboardLoading extends TeacherDashboardState {
  const TeacherDashboardLoading();
}

class TeacherDashboardLoaded extends TeacherDashboardState {
  final TeacherDashboardSummaryEntity summary;

  const TeacherDashboardLoaded(this.summary);

  @override
  List<Object?> get props => [summary];
}

class TeacherDashboardError extends TeacherDashboardState {
  final String message;

  const TeacherDashboardError(this.message);

  @override
  List<Object?> get props => [message];
}

class TeacherDashboardCubit extends Cubit<TeacherDashboardState> {
  final GetTeacherDashboardSummary getTeacherDashboardSummary;

  TeacherDashboardCubit({required this.getTeacherDashboardSummary})
      : super(const TeacherDashboardInitial());

  Future<void> loadDashboard() async {
    emit(const TeacherDashboardLoading());
    final result = await getTeacherDashboardSummary(const NoParams());
    result.fold(
      (failure) => emit(TeacherDashboardError(failure.message)),
      (summary) => emit(TeacherDashboardLoaded(summary)),
    );
  }

  Future<void> refreshDashboard() async {
    final result = await getTeacherDashboardSummary(const NoParams());
    result.fold(
      (failure) => emit(TeacherDashboardError(failure.message)),
      (summary) => emit(TeacherDashboardLoaded(summary)),
    );
  }
}
