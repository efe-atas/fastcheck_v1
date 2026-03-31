import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_google_bottom_nav.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../cubit/parent_dashboard_cubit.dart';

class ParentShellPage extends StatelessWidget {
  const ParentShellPage({
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
            icon: Icons.family_restroom_rounded,
            label: 'Öğrenciler',
            onTap: () {},
          ),
          AppGoogleNavItem(
            icon: Icons.refresh_rounded,
            label: 'Yenile',
            persistSelection: false,
            onTap: () =>
                context.read<ParentDashboardCubit>().refreshDashboard(),
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
