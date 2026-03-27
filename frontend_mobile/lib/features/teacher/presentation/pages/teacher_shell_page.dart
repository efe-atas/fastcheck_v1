import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_google_bottom_nav.dart';

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
        ],
      ),
    );
  }
}
