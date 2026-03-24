import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/teacher_entities.dart';
import '../../domain/usecases/teacher_usecases.dart';

// --- Events ---

abstract class ClassDetailEvent extends Equatable {
  const ClassDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadClassDetail extends ClassDetailEvent {
  final int classId;

  const LoadClassDetail(this.classId);

  @override
  List<Object?> get props => [classId];
}

class RefreshExams extends ClassDetailEvent {
  final int classId;

  const RefreshExams(this.classId);

  @override
  List<Object?> get props => [classId];
}

class RefreshStudents extends ClassDetailEvent {
  final int classId;
  final int page;
  final String? name;

  const RefreshStudents(this.classId, {this.page = 0, this.name});

  @override
  List<Object?> get props => [classId, page, name];
}

class ExamCreatedInClass extends ClassDetailEvent {
  final ExamEntity exam;

  const ExamCreatedInClass(this.exam);

  @override
  List<Object?> get props => [exam];
}

class StudentAddedToClass extends ClassDetailEvent {
  final StudentEntity student;

  const StudentAddedToClass(this.student);

  @override
  List<Object?> get props => [student];
}

// --- States ---

abstract class ClassDetailState extends Equatable {
  const ClassDetailState();

  @override
  List<Object?> get props => [];
}

class ClassDetailInitial extends ClassDetailState {
  const ClassDetailInitial();
}

class ClassDetailLoading extends ClassDetailState {
  const ClassDetailLoading();
}

class ClassDetailLoaded extends ClassDetailState {
  final List<ExamEntity> exams;
  final List<StudentEntity> students;
  final int totalStudents;
  final bool hasMoreStudents;
  final String? studentNameFilter;

  const ClassDetailLoaded({
    required this.exams,
    required this.students,
    required this.totalStudents,
    this.hasMoreStudents = false,
    this.studentNameFilter,
  });

  ClassDetailLoaded copyWith({
    List<ExamEntity>? exams,
    List<StudentEntity>? students,
    int? totalStudents,
    bool? hasMoreStudents,
    String? studentNameFilter,
    bool clearStudentNameFilter = false,
  }) {
    return ClassDetailLoaded(
      exams: exams ?? this.exams,
      students: students ?? this.students,
      totalStudents: totalStudents ?? this.totalStudents,
      hasMoreStudents: hasMoreStudents ?? this.hasMoreStudents,
      studentNameFilter: clearStudentNameFilter
          ? null
          : (studentNameFilter ?? this.studentNameFilter),
    );
  }

  @override
  List<Object?> get props =>
      [exams, students, totalStudents, hasMoreStudents, studentNameFilter];
}

class ClassDetailError extends ClassDetailState {
  final String message;

  const ClassDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Bloc ---

class ClassDetailBloc extends Bloc<ClassDetailEvent, ClassDetailState> {
  final GetClassExams getClassExams;
  final GetClassStudents getClassStudents;

  ClassDetailBloc({
    required this.getClassExams,
    required this.getClassStudents,
  }) : super(const ClassDetailInitial()) {
    on<LoadClassDetail>(_onLoadClassDetail);
    on<RefreshExams>(_onRefreshExams);
    on<RefreshStudents>(_onRefreshStudents);
    on<ExamCreatedInClass>(_onExamCreated);
    on<StudentAddedToClass>(_onStudentAdded);
  }

  Future<void> _onLoadClassDetail(
    LoadClassDetail event,
    Emitter<ClassDetailState> emit,
  ) async {
    emit(const ClassDetailLoading());

    final examsResult = await getClassExams(event.classId);
    final studentsResult = await getClassStudents(
      GetClassStudentsParams(classId: event.classId),
    );

    final exams = examsResult.fold(
      (_) => <ExamEntity>[],
      (list) => list,
    );

    studentsResult.fold(
      (failure) => emit(ClassDetailError(failure.message)),
      (paged) => emit(ClassDetailLoaded(
        exams: exams,
        students: paged.content,
        totalStudents: paged.totalElements,
        hasMoreStudents: paged.hasNext,
        studentNameFilter: null,
      )),
    );

    if (examsResult.isLeft() && studentsResult.isLeft()) {
      examsResult.fold(
        (failure) => emit(ClassDetailError(failure.message)),
        (_) {},
      );
    }
  }

  Future<void> _onRefreshExams(
    RefreshExams event,
    Emitter<ClassDetailState> emit,
  ) async {
    final result = await getClassExams(event.classId);
    final currentState = state;
    result.fold(
      (failure) => emit(ClassDetailError(failure.message)),
      (exams) {
        if (currentState is ClassDetailLoaded) {
          emit(currentState.copyWith(exams: exams));
        } else {
          emit(ClassDetailLoaded(
            exams: exams,
            students: const [],
            totalStudents: 0,
          ));
        }
      },
    );
  }

  Future<void> _onRefreshStudents(
    RefreshStudents event,
    Emitter<ClassDetailState> emit,
  ) async {
    final result = await getClassStudents(
      GetClassStudentsParams(
        classId: event.classId,
        page: event.page,
        name: event.name,
      ),
    );
    final currentState = state;
    result.fold(
      (failure) => emit(ClassDetailError(failure.message)),
      (paged) {
        if (currentState is ClassDetailLoaded) {
          emit(currentState.copyWith(
            students: paged.content,
            totalStudents: paged.totalElements,
            hasMoreStudents: paged.hasNext,
            studentNameFilter: event.name,
          ));
        }
      },
    );
  }

  void _onExamCreated(
    ExamCreatedInClass event,
    Emitter<ClassDetailState> emit,
  ) {
    final currentState = state;
    if (currentState is ClassDetailLoaded) {
      emit(currentState.copyWith(
        exams: [event.exam, ...currentState.exams],
      ));
    }
  }

  void _onStudentAdded(
    StudentAddedToClass event,
    Emitter<ClassDetailState> emit,
  ) {
    final currentState = state;
    if (currentState is ClassDetailLoaded) {
      emit(currentState.copyWith(
        students: [...currentState.students, event.student],
        totalStudents: currentState.totalStudents + 1,
      ));
    }
  }
}
