import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/admin_entities.dart';
import '../../domain/usecases/admin_usecases.dart';

class AdminState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final String? lastSuccessMessage;
  final List<AdminParentStudentViewEntity>? listedStudents;
  final List<AdminUserSummaryEntity> assignableUsers;
  final List<AdminSchoolSummaryEntity> schoolOptions;
  final List<AdminUserSummaryEntity> parentOptions;
  final List<AdminUserSummaryEntity> studentOptions;
  final AdminUserSummaryEntity? selectedUser;
  final AdminSchoolSummaryEntity? selectedSchool;
  final AdminUserSummaryEntity? selectedParent;
  final AdminUserSummaryEntity? selectedStudent;
  final AdminBulkOperationEntity? lastBulkResult;

  const AdminState({
    this.isLoading = false,
    this.errorMessage,
    this.lastSuccessMessage,
    this.listedStudents,
    this.assignableUsers = const [],
    this.schoolOptions = const [],
    this.parentOptions = const [],
    this.studentOptions = const [],
    this.selectedUser,
    this.selectedSchool,
    this.selectedParent,
    this.selectedStudent,
    this.lastBulkResult,
  });

  AdminState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? lastSuccessMessage,
    List<AdminParentStudentViewEntity>? listedStudents,
    List<AdminUserSummaryEntity>? assignableUsers,
    List<AdminSchoolSummaryEntity>? schoolOptions,
    List<AdminUserSummaryEntity>? parentOptions,
    List<AdminUserSummaryEntity>? studentOptions,
    AdminUserSummaryEntity? selectedUser,
    AdminSchoolSummaryEntity? selectedSchool,
    AdminUserSummaryEntity? selectedParent,
    AdminUserSummaryEntity? selectedStudent,
    AdminBulkOperationEntity? lastBulkResult,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearList = false,
    bool clearBulkResult = false,
  }) {
    return AdminState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastSuccessMessage:
          clearSuccess ? null : (lastSuccessMessage ?? this.lastSuccessMessage),
      listedStudents:
          clearList ? null : (listedStudents ?? this.listedStudents),
      assignableUsers: assignableUsers ?? this.assignableUsers,
      schoolOptions: schoolOptions ?? this.schoolOptions,
      parentOptions: parentOptions ?? this.parentOptions,
      studentOptions: studentOptions ?? this.studentOptions,
      selectedUser: selectedUser ?? this.selectedUser,
      selectedSchool: selectedSchool ?? this.selectedSchool,
      selectedParent: selectedParent ?? this.selectedParent,
      selectedStudent: selectedStudent ?? this.selectedStudent,
      lastBulkResult:
          clearBulkResult ? null : (lastBulkResult ?? this.lastBulkResult),
    );
  }

  @override
  List<Object?> get props =>
      [
        isLoading,
        errorMessage,
        lastSuccessMessage,
        listedStudents,
        assignableUsers,
        schoolOptions,
        parentOptions,
        studentOptions,
        selectedUser,
        selectedSchool,
        selectedParent,
        selectedStudent,
        lastBulkResult,
      ];
}

class AdminCubit extends Cubit<AdminState> {
  final CreateSchool createSchool;
  final AssignUserToSchoolUc assignUserToSchool;
  final LinkParentStudentUc linkParentStudent;
  final ListParentStudentsAdmin listParentStudents;
  final SearchAdminUsers searchAdminUsers;
  final SearchAdminSchools searchAdminSchools;
  final BulkAssignUsersToSchoolsUc bulkAssignUsersToSchools;
  final BulkLinkParentStudentsUc bulkLinkParentStudents;

  AdminCubit({
    required this.createSchool,
    required this.assignUserToSchool,
    required this.linkParentStudent,
    required this.listParentStudents,
    required this.searchAdminUsers,
    required this.searchAdminSchools,
    required this.bulkAssignUsersToSchools,
    required this.bulkLinkParentStudents,
  }) : super(const AdminState());

  void dismissNotifications() {
    emit(state.copyWith(
      clearError: true,
      clearSuccess: true,
      clearBulkResult: true,
    ));
  }

  void selectAssignableUser(AdminUserSummaryEntity? user) {
    emit(state.copyWith(selectedUser: user));
  }

  void selectSchool(AdminSchoolSummaryEntity? school) {
    emit(state.copyWith(selectedSchool: school));
  }

  void selectParent(AdminUserSummaryEntity? parent) {
    emit(state.copyWith(selectedParent: parent));
  }

  void selectStudent(AdminUserSummaryEntity? student) {
    emit(state.copyWith(selectedStudent: student));
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

  Future<void> onSearchAssignableUsers(String query) async {
    final result = await searchAdminUsers(
      SearchAdminUsersParams(query: query.trim(), page: 0, size: 20),
    );
    result.fold(
      (f) => emit(state.copyWith(errorMessage: f.message)),
      (r) => emit(state.copyWith(assignableUsers: r.content)),
    );
  }

  Future<void> onSearchSchools(String query) async {
    final result = await searchAdminSchools(
      SearchAdminSchoolsParams(query: query.trim(), page: 0, size: 20),
    );
    result.fold(
      (f) => emit(state.copyWith(errorMessage: f.message)),
      (r) => emit(state.copyWith(schoolOptions: r.content)),
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

  Future<void> onAssignSelectedUser() async {
    final user = state.selectedUser;
    final school = state.selectedSchool;
    if (user == null || school == null) {
      emit(state.copyWith(errorMessage: 'Kullanıcı ve okul seçimi gerekli'));
      return;
    }
    await onAssignUser(user.userId, school.schoolId);
  }

  Future<void> onSearchParents(String query) async {
    final result = await searchAdminUsers(
      SearchAdminUsersParams(
        role: 'ROLE_PARENT',
        query: query.trim(),
        page: 0,
        size: 20,
      ),
    );
    result.fold(
      (f) => emit(state.copyWith(errorMessage: f.message)),
      (r) => emit(state.copyWith(parentOptions: r.content)),
    );
  }

  Future<void> onSearchStudents(String query) async {
    final result = await searchAdminUsers(
      SearchAdminUsersParams(
        role: 'ROLE_STUDENT',
        query: query.trim(),
        page: 0,
        size: 20,
      ),
    );
    result.fold(
      (f) => emit(state.copyWith(errorMessage: f.message)),
      (r) => emit(state.copyWith(studentOptions: r.content)),
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

  Future<void> onLinkSelectedParentStudent() async {
    final parent = state.selectedParent;
    final student = state.selectedStudent;
    if (parent == null || student == null) {
      emit(state.copyWith(errorMessage: 'Veli ve öğrenci seçimi gerekli'));
      return;
    }
    await onLinkParentStudent(parent.userId, student.userId);
  }

  Future<void> onBulkAssignUsersToSchools({
    required List<int> fileBytes,
    required String fileName,
  }) async {
    emit(state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
      clearBulkResult: true,
    ));
    final result = await bulkAssignUsersToSchools(
      BulkCsvUploadParams(fileBytes: fileBytes, fileName: fileName),
    );
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, errorMessage: f.message)),
      (bulk) => emit(state.copyWith(
        isLoading: false,
        lastBulkResult: bulk,
        lastSuccessMessage:
            'Toplu atama tamamlandı: ${bulk.success}/${bulk.processed} başarılı',
      )),
    );
  }

  Future<void> onBulkLinkParentStudents({
    required List<int> fileBytes,
    required String fileName,
  }) async {
    emit(state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
      clearBulkResult: true,
    ));
    final result = await bulkLinkParentStudents(
      BulkCsvUploadParams(fileBytes: fileBytes, fileName: fileName),
    );
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, errorMessage: f.message)),
      (bulk) => emit(state.copyWith(
        isLoading: false,
        lastBulkResult: bulk,
        lastSuccessMessage:
            'Toplu veli-öğrenci bağlama: ${bulk.success}/${bulk.processed} başarılı',
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
