import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_google_bottom_nav.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../bloc/student_exams_bloc.dart';

class StudentShellPage extends StatelessWidget {
  const StudentShellPage({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: AppGoogleBottomNav(
        selectedIndex: navigationShell.currentIndex,
        onSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: [
          AppGoogleNavItem(
            icon: Icons.quiz_rounded,
            label: 'Sınavlar',
            onTap: () {},
          ),
          AppGoogleNavItem(
            icon: Icons.refresh_rounded,
            label: 'Yenile',
            persistSelection: false,
            onTap: () => context
                .read<StudentExamsBloc>()
                .add(const RefreshStudentExams()),
          ),
          AppGoogleNavItem(
            icon: Icons.logout_rounded,
            label: 'Çıkış',
            persistSelection: false,
            onTap: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
        ],
      ),
    );
  }
}
