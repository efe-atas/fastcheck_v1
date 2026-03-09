import 'package:get_it/get_it.dart';

import '../network/api_client.dart';
import '../storage/secure_storage.dart';

// Auth
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

// Teacher
import '../../features/teacher/data/datasources/teacher_remote_datasource.dart';
import '../../features/teacher/data/repositories/teacher_repository_impl.dart';
import '../../features/teacher/domain/repositories/teacher_repository.dart';
import '../../features/teacher/domain/usecases/teacher_usecases.dart';
import '../../features/teacher/presentation/bloc/classes_bloc.dart';
import '../../features/teacher/presentation/bloc/class_detail_bloc.dart';
import '../../features/teacher/presentation/bloc/exam_bloc.dart';

// Student
import '../../features/student/data/datasources/student_remote_datasource.dart';
import '../../features/student/data/repositories/student_repository_impl.dart';
import '../../features/student/domain/repositories/student_repository.dart';
import '../../features/student/domain/usecases/student_usecases.dart';
import '../../features/student/presentation/bloc/student_exams_bloc.dart';
import '../../features/student/presentation/bloc/exam_questions_bloc.dart';

// Parent
import '../../features/parent/data/datasources/parent_remote_datasource.dart';
import '../../features/parent/data/repositories/parent_repository_impl.dart';
import '../../features/parent/domain/repositories/parent_repository.dart';
import '../../features/parent/domain/usecases/parent_usecases.dart';
import '../../features/parent/presentation/bloc/parent_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ── Core ─────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<SecureStorage>(() => SecureStorage());
  sl.registerLazySingleton<ApiClient>(() => ApiClient(storage: sl()));

  // ── Auth Feature ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      secureStorage: sl(),
    ),
  );
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      authRepository: sl(),
    ),
  );

  // ── Teacher Feature ──────────────────────────────────────────────────────
  sl.registerLazySingleton<TeacherRemoteDataSource>(
    () => TeacherRemoteDataSourceImpl(dio: sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<TeacherRepository>(
    () => TeacherRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetClasses(sl()));
  sl.registerLazySingleton(() => GetClassExams(sl()));
  sl.registerLazySingleton(() => GetClassStudents(sl()));
  sl.registerLazySingleton(() => CreateClass(sl()));
  sl.registerLazySingleton(() => CreateExam(sl()));
  sl.registerLazySingleton(() => UploadExamImages(sl()));
  sl.registerLazySingleton(() => GetExamStatus(sl()));
  sl.registerLazySingleton(() => AddStudentToClass(sl()));

  sl.registerFactory(() => ClassesBloc(getClasses: sl()));
  sl.registerFactory(
    () => ClassDetailBloc(getClassExams: sl(), getClassStudents: sl()),
  );
  sl.registerFactory(
    () => ExamBloc(
      createExam: sl(),
      uploadExamImages: sl(),
      getExamStatus: sl(),
    ),
  );

  // ── Student Feature ──────────────────────────────────────────────────────
  sl.registerLazySingleton<StudentRemoteDataSource>(
    () => StudentRemoteDataSourceImpl(dio: sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<StudentRepository>(
    () => StudentRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetStudentExams(sl()));
  sl.registerLazySingleton(() => GetExamQuestions(sl()));

  sl.registerFactory(() => StudentExamsBloc(getStudentExams: sl()));
  sl.registerFactory(() => ExamQuestionsBloc(getExamQuestions: sl()));

  // ── Parent Feature ───────────────────────────────────────────────────────
  sl.registerLazySingleton<ParentRemoteDataSource>(
    () => ParentRemoteDataSourceImpl(dio: sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<ParentRepository>(
    () => ParentRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetLinkedStudents(sl()));
  sl.registerLazySingleton(() => GetStudentExamQuestions(sl()));

  sl.registerFactory(
    () => ParentBloc(
      getLinkedStudents: sl(),
      getStudentExamQuestions: sl(),
    ),
  );
}
