import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_google_bottom_nav.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../bloc/classes_bloc.dart';

class TeacherShellPage extends StatelessWidget {
  const TeacherShellPage({
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
            icon: Icons.grid_view_rounded,
            label: 'Sınıflar',
            onTap: () {},
          ),
          AppGoogleNavItem(
            icon: Icons.document_scanner_outlined,
            label: 'OCR',
            onTap: () {},
          ),
          AppGoogleNavItem(
            icon: Icons.add_rounded,
            label: 'Ekle',
            persistSelection: false,
            onTap: () => _navigateToCreateClass(context),
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

  Future<void> _navigateToCreateClass(BuildContext context) async {
    final created = await context.push<bool>('/teacher/classes/create');
    if (!context.mounted) return;
    if (created == true) {
      context.read<ClassesBloc>().add(const LoadClasses());
    }
  }
}
