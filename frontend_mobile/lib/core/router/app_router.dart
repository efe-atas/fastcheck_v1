import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../di/injection_container.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/teacher/presentation/pages/teacher_dashboard_page.dart';
import '../../features/teacher/presentation/pages/teacher_exams_page.dart';
import '../../features/teacher/presentation/pages/teacher_shell_page.dart';
import '../../features/teacher/presentation/pages/class_detail_page.dart';
import '../../features/teacher/presentation/pages/create_class_page.dart';
import '../../features/teacher/presentation/pages/create_exam_page.dart';
import '../../features/teacher/presentation/pages/exam_detail_page.dart';
import '../../features/teacher/presentation/pages/add_student_page.dart';
import '../../features/teacher/presentation/bloc/classes_bloc.dart';
import '../../features/teacher/presentation/bloc/class_detail_bloc.dart';
import '../../features/teacher/presentation/bloc/exam_bloc.dart';
import '../../features/student/presentation/pages/student_dashboard_page.dart';
import '../../features/student/presentation/pages/student_shell_page.dart';
import '../../features/student/presentation/pages/exam_questions_page.dart';
import '../../features/student/presentation/bloc/student_exams_bloc.dart';
import '../../features/student/presentation/bloc/exam_questions_bloc.dart';
import '../../features/parent/presentation/pages/parent_dashboard_page.dart';
import '../../features/parent/presentation/pages/parent_shell_page.dart';
import '../../features/parent/presentation/pages/student_exam_view_page.dart';
import '../../features/parent/presentation/bloc/parent_bloc.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/admin_shell_page.dart';
import '../../features/admin/presentation/cubit/admin_cubit.dart';
import '../../features/ocr/presentation/pages/ocr_lab_page.dart';
import '../../features/ocr/presentation/cubit/ocr_cubit.dart';

class AppRouter {
  final AuthBloc authBloc;

  AppRouter({required this.authBloc});

  late final GoRouter router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isOnSplash = state.matchedLocation == '/splash';
      final isOnAuth = state.matchedLocation.startsWith('/auth');

      if (authState is AuthLoading && isOnSplash) return null;

      if (authState is AuthUnauthenticated || authState is AuthError) {
        if (isOnAuth) return null;
        return '/auth/login';
      }

      if (authState is AuthAuthenticated) {
        if (isOnSplash || isOnAuth) {
          return _homeRouteForRole(authState.user.role);
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterPage(),
      ),

      // Teacher shell (Ana Sayfa + Sınavlar + OCR sekmeleri)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => BlocProvider(
          create: (_) => sl<ClassesBloc>()..add(const LoadClasses()),
          child: TeacherShellPage(navigationShell: navigationShell),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/teacher',
                builder: (context, state) => const TeacherDashboardPage(),
                routes: [
                  GoRoute(
                    path: 'classes/create',
                    builder: (context, state) => BlocProvider(
                      create: (_) => sl<ExamBloc>(),
                      child: const CreateClassPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'classes/:classId',
                    builder: (context, state) {
                      final classId =
                          int.parse(state.pathParameters['classId'] ?? '0');
                      final className =
                          state.uri.queryParameters['name'] ?? 'Sınıf';
                      return BlocProvider(
                        create: (_) => sl<ClassDetailBloc>()
                          ..add(LoadClassDetail(classId)),
                        child: ClassDetailPage(
                            classId: classId, className: className),
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'exams/create',
                        builder: (context, state) {
                          final classId =
                              int.parse(state.pathParameters['classId'] ?? '0');
                          return BlocProvider(
                            create: (_) => sl<ExamBloc>(),
                            child: CreateExamPage(classId: classId),
                          );
                        },
                      ),
                      GoRoute(
                        path: 'students/add',
                        builder: (context, state) {
                          final classId =
                              int.parse(state.pathParameters['classId'] ?? '0');
                          return BlocProvider(
                            create: (_) => sl<ExamBloc>(),
                            child: AddStudentPage(classId: classId),
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'exams/:examId',
                    builder: (context, state) {
                      final examId =
                          int.parse(state.pathParameters['examId'] ?? '0');
                      final title =
                          state.uri.queryParameters['title'] ?? 'Sınav';
                      return BlocProvider(
                        create: (_) =>
                            sl<ExamBloc>()..add(LoadExamStatusEvent(examId)),
                        child: ExamDetailPage(examId: examId, examTitle: title),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/teacher/exams',
                builder: (context, state) => const TeacherExamsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/teacher/ocr',
                builder: (context, state) => BlocProvider(
                  create: (_) => sl<OcrCubit>(),
                  child: const OcrLabPage(requireExamSelection: true),
                ),
              ),
            ],
          ),
        ],
      ),

      // Student shell (Sınavlar sekmesi)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => BlocProvider(
          create: (_) => sl<StudentExamsBloc>()..add(const LoadStudentExams()),
          child: StudentShellPage(navigationShell: navigationShell),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student',
                builder: (context, state) => const StudentDashboardPage(),
                routes: [
                  GoRoute(
                    path: 'exams/:examId/questions',
                    builder: (context, state) {
                      final examId =
                          int.parse(state.pathParameters['examId'] ?? '0');
                      final title =
                          state.uri.queryParameters['title'] ?? 'Sınav';
                      return BlocProvider(
                        create: (_) => sl<ExamQuestionsBloc>()
                          ..add(LoadExamQuestions(examId: examId)),
                        child:
                            ExamQuestionsPage(examId: examId, examTitle: title),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Parent shell (Öğrenciler sekmesi)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => BlocProvider(
          create: (_) => sl<ParentBloc>(),
          child: ParentShellPage(navigationShell: navigationShell),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/parent',
                builder: (context, state) => const ParentDashboardPage(),
                routes: [
                  GoRoute(
                    path: 'students/:studentId/exams/:examId',
                    builder: (context, state) {
                      final studentId =
                          int.parse(state.pathParameters['studentId'] ?? '0');
                      final examId =
                          int.parse(state.pathParameters['examId'] ?? '0');
                      final studentName =
                          state.uri.queryParameters['name'] ?? 'Öğrenci';
                      return BlocProvider(
                        create: (_) => sl<ParentBloc>()
                          ..add(LoadStudentExamQuestions(
                            studentId: studentId,
                            examId: examId,
                          )),
                        child: StudentExamViewPage(
                          studentId: studentId,
                          examId: examId,
                          studentName: studentName,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Admin shell (Yönetim + OCR sekmeleri)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => BlocProvider(
          create: (_) => sl<AdminCubit>(),
          child: AdminShellPage(navigationShell: navigationShell),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin',
                builder: (context, state) => const AdminDashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/ocr',
                builder: (context, state) => BlocProvider(
                  create: (_) => sl<OcrCubit>(),
                  child: const OcrLabPage(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  String _homeRouteForRole(String role) {
    switch (role) {
      case 'ROLE_TEACHER':
        return '/teacher';
      case 'ROLE_STUDENT':
        return '/student';
      case 'ROLE_PARENT':
        return '/parent';
      case 'ROLE_ADMIN':
        return '/admin';
      default:
        return '/student';
    }
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
