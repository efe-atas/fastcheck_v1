import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/admin_entities.dart';
import '../../domain/usecases/admin_usecases.dart';

class AdminState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final String? lastSuccessMessage;
  final List<AdminParentStudentViewEntity>? listedStudents;

  const AdminState({
    this.isLoading = false,
    this.errorMessage,
    this.lastSuccessMessage,
    this.listedStudents,
  });

  AdminState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? lastSuccessMessage,
    List<AdminParentStudentViewEntity>? listedStudents,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearList = false,
  }) {
    return AdminState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastSuccessMessage:
          clearSuccess ? null : (lastSuccessMessage ?? this.lastSuccessMessage),
      listedStudents:
          clearList ? null : (listedStudents ?? this.listedStudents),
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, errorMessage, lastSuccessMessage, listedStudents];
}

class AdminCubit extends Cubit<AdminState> {
  final CreateSchool createSchool;
  final AssignUserToSchoolUc assignUserToSchool;
  final LinkParentStudentUc linkParentStudent;
  final ListParentStudentsAdmin listParentStudents;

  AdminCubit({
    required this.createSchool,
    required this.assignUserToSchool,
    required this.linkParentStudent,
    required this.listParentStudents,
  }) : super(const AdminState());

  void dismissNotifications() {
    emit(state.copyWith(clearError: true, clearSuccess: true));
  }

  Future<void> onCreateSchool(String schoolName) async {
    emit(state.copyWith(isLoading: true, clearError: true, clearSuccess: true));
    final result = await createSchool(CreateSchoolParams(schoolName: schoolName));
    result.fold(
      (f) => emit(state.copyWith(
        isLoading: false,
        errorMessage: f.message,
      )),
      (school) => emit(state.copyWith(
        isLoading: false,
        lastSuccessMessage:
            'Okul oluşturuldu: ${school.schoolName} (id: ${school.schoolId})',
      )),
    );
  }

  Future<void> onAssignUser(int userId, int schoolId) async {
    emit(state.copyWith(isLoading: true, clearError: true, clearSuccess: true));
    final result = await assignUserToSchool(
      AssignUserToSchoolParams(userId: userId, schoolId: schoolId),
    );
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, errorMessage: f.message)),
      (r) => emit(state.copyWith(
        isLoading: false,
        lastSuccessMessage:
            'Kullanıcı okula atandı: ${r.fullName} (${r.email})',
      )),
    );
  }

  Future<void> onLinkParentStudent(int parentUserId, int studentUserId) async {
    emit(state.copyWith(isLoading: true, clearError: true, clearSuccess: true));
    final result = await linkParentStudent(
      LinkParentStudentParams(
        parentUserId: parentUserId,
        studentUserId: studentUserId,
      ),
    );
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, errorMessage: f.message)),
      (link) => emit(state.copyWith(
        isLoading: false,
        lastSuccessMessage:
            'Bağlantı oluşturuldu (linkId: ${link.linkId})',
      )),
    );
  }

  Future<void> onListParentStudents(int parentUserId) async {
    emit(state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
      clearList: true,
    ));
    final result = await listParentStudents(parentUserId);
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, errorMessage: f.message)),
      (list) => emit(state.copyWith(
        isLoading: false,
        listedStudents: list,
        lastSuccessMessage: '${list.length} öğrenci listelendi',
      )),
    );
  }
}
