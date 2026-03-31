import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/parent_entities.dart';
import '../../domain/usecases/parent_usecases.dart';

abstract class ParentDashboardState extends Equatable {
  const ParentDashboardState();

  @override
  List<Object?> get props => [];
}

class ParentDashboardInitial extends ParentDashboardState {
  const ParentDashboardInitial();
}

class ParentDashboardLoading extends ParentDashboardState {
  const ParentDashboardLoading();
}

class ParentDashboardLoaded extends ParentDashboardState {
  final ParentDashboardSummaryEntity summary;

  const ParentDashboardLoaded(this.summary);

  @override
  List<Object?> get props => [summary];
}

class ParentDashboardError extends ParentDashboardState {
  final String message;

  const ParentDashboardError(this.message);

  @override
  List<Object?> get props => [message];
}

class ParentDashboardCubit extends Cubit<ParentDashboardState> {
  final GetParentDashboardSummary getParentDashboardSummary;

  ParentDashboardCubit({required this.getParentDashboardSummary})
      : super(const ParentDashboardInitial());

  Future<void> loadDashboard() async {
    emit(const ParentDashboardLoading());
    final result = await getParentDashboardSummary(const NoParams());
    result.fold(
      (failure) => emit(ParentDashboardError(failure.message)),
      (summary) => emit(ParentDashboardLoaded(summary)),
    );
  }

  Future<void> refreshDashboard() async {
    final result = await getParentDashboardSummary(const NoParams());
    result.fold(
      (failure) => emit(ParentDashboardError(failure.message)),
      (summary) => emit(ParentDashboardLoaded(summary)),
    );
  }
}
