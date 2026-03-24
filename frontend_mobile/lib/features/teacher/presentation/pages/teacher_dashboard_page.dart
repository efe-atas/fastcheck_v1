import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/gradient_dashboard_header.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/liquid_glass_bottom_bar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../bloc/classes_bloc.dart';
import '../widgets/class_card.dart';

class TeacherDashboardPage extends StatelessWidget {
  const TeacherDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          final bloc = context.read<ClassesBloc>();
          bloc.add(const LoadClasses());
          await bloc.stream.firstWhere((s) => s is! ClassesLoading);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          _buildHeader(context),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.sm,
              AppSpacing.screenHorizontal,
              120,
            ),
            sliver: BlocBuilder<ClassesBloc, ClassesState>(
              builder: (context, state) {
                if (state is ClassesLoading) {
                  return const SliverFillRemaining(
                    child: ShimmerList(itemCount: 4, itemHeight: 160),
                  );
                }
                if (state is ClassesError) {
                  return SliverFillRemaining(
                    child: AppErrorWidget(
                      message: state.message,
                      onRetry: () => context
                          .read<ClassesBloc>()
                          .add(const LoadClasses()),
                    ),
                  );
                }
                if (state is ClassesLoaded) {
                  if (state.classes.isEmpty) {
                    return SliverFillRemaining(
                      child: EmptyStateWidget(
                        icon: Icons.school_rounded,
                        title: 'Henüz sınıf yok',
                        subtitle:
                            'Yeni bir sınıf oluşturarak başlayın.',
                        actionLabel: 'Sınıf Oluştur',
                        onAction: () => _navigateToCreateClassAndReload(context),
                      ),
                    );
                  }
                  return SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.88,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final classEntity = state.classes[index];
                        return ClassCard(
                          classEntity: classEntity,
                          onTap: () => _navigateToClassDetail(
                            context,
                            classEntity.classId,
                            classEntity.className,
                          ),
                        );
                      },
                      childCount: state.classes.length,
                    ),
                  );
                }
                return const SliverFillRemaining(child: SizedBox());
              },
            ),
          ),
        ],
        ),
      ),
      bottomNavigationBar: _buildLiquidNavBar(context),
    );
  }

  Widget _buildLiquidNavBar(BuildContext context) {
    return LiquidGlassBottomBar(
      items: [
        LiquidGlassBarItem(
          icon: Icons.grid_view_rounded,
          label: 'Sınıflar',
          selected: true,
          onTap: () {},
        ),
        LiquidGlassBarItem(
          icon: Icons.document_scanner_outlined,
          label: 'OCR',
          onTap: () => context.push('/ocr'),
        ),
        LiquidGlassBarItem(
          icon: Icons.add_rounded,
          emphasized: true,
          onTap: () => _navigateToCreateClassAndReload(context),
        ),
        LiquidGlassBarItem(
          icon: Icons.logout_rounded,
          label: 'Çıkış',
          onTap: () =>
              context.read<AuthBloc>().add(const AuthLogoutRequested()),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return DashboardGradientSliverAppBar(
      expandedHeight: 140,
      pinned: true,
      stretch: true,
      title: 'Sınıflarım',
      titlePadding: const EdgeInsets.only(left: AppSpacing.xl, bottom: 14),
      expandedChild: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          0,
        ),
        child: Row(
          children: [
            const DashboardGradientIconBadge(icon: Icons.school_rounded),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Merhaba, Öğretmen',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sınıflarınızı yönetin',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToCreateClassAndReload(BuildContext context) async {
    final created = await context.push<bool>('/teacher/classes/create');
    if (!context.mounted) return;
    if (created == true) {
      context.read<ClassesBloc>().add(const LoadClasses());
    }
  }

  void _navigateToClassDetail(
    BuildContext context,
    int classId,
    String className,
  ) {
    context.push('/teacher/classes/$classId?name=${Uri.encodeComponent(className)}');
  }
}
