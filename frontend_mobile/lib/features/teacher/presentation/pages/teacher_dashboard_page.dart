import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/app_google_bottom_nav.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../bloc/classes_bloc.dart';
import '../widgets/class_card.dart';

class TeacherDashboardPage extends StatelessWidget {
  const TeacherDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            final bloc = context.read<ClassesBloc>();
            bloc.add(const LoadClasses());
            await bloc.stream.firstWhere((s) => s is! ClassesLoading);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: topInset > 0 ? AppSpacing.sm : AppSpacing.lg),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                sliver: SliverToBoxAdapter(child: _buildHeroCard(context)),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                sliver: SliverToBoxAdapter(child: _buildQuickActions(context)),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.xl,
                  AppSpacing.screenHorizontal,
                  120,
                ),
                sliver: BlocBuilder<ClassesBloc, ClassesState>(
                  builder: (context, state) {
                    if (state is ClassesLoading) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: ShimmerList(itemCount: 4, itemHeight: 160),
                      );
                    }
                    if (state is ClassesError) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: AppErrorWidget(
                          message: state.message,
                          onRetry: () =>
                              context.read<ClassesBloc>().add(const LoadClasses()),
                        ),
                      );
                    }
                    if (state is ClassesLoaded) {
                      if (state.classes.isEmpty) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyStateWidget(
                            icon: Icons.school_rounded,
                            title: 'Henüz sınıf yok',
                            subtitle: 'İlk sınıfınızı oluşturarak başlayın.',
                            actionLabel: 'Sınıf Oluştur',
                            onAction: () => _navigateToCreateClassAndReload(context),
                          ),
                        );
                      }

                      final totalExams = state.classes.fold<int>(
                        0,
                        (sum, classItem) => sum + classItem.examCount,
                      );

                      return SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            _StatsRow(
                              classCount: state.classes.length,
                              examCount: totalExams,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            _SectionTitle(
                              title: 'Sınıflarım',
                              subtitle: 'Toplam ${state.classes.length} aktif sınıf',
                            ),
                            const SizedBox(height: AppSpacing.md),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: AppSpacing.md,
                                crossAxisSpacing: AppSpacing.md,
                                childAspectRatio: 0.88,
                              ),
                              itemCount: state.classes.length,
                              itemBuilder: (context, index) {
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
                            ),
                          ],
                        ),
                      );
                    }
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: SizedBox(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppGoogleBottomNav(
        items: [
          AppGoogleNavItem(
            icon: Icons.grid_view_rounded,
            label: 'Sınıflar',
            onTap: () {},
          ),
          AppGoogleNavItem(
            icon: Icons.document_scanner_outlined,
            label: 'OCR',
            persistSelection: false,
            onTap: () => context.push('/ocr'),
          ),
          AppGoogleNavItem(
            icon: Icons.add_rounded,
            label: 'Ekle',
            persistSelection: false,
            onTap: () => _navigateToCreateClassAndReload(context),
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

  Widget _buildHeroCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Merhaba, Öğretmen',
                  style: textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sınıflarınızı, sınavlarınızı ve OCR işlemlerinizi tek ekrandan yönetin.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.add_rounded,
            title: 'Sınıf Ekle',
            subtitle: 'Hızlıca yeni sınıf oluştur',
            onTap: () => _navigateToCreateClassAndReload(context),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.document_scanner_outlined,
            title: 'OCR Laboratuvarı',
            subtitle: 'Tarama akışına hızlı geçiş',
            onTap: () => context.push('/ocr'),
          ),
        ),
      ],
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.classCount,
    required this.examCount,
  });

  final int classCount;
  final int examCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.grid_view_rounded,
            label: 'Sınıf',
            value: '$classCount',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            icon: Icons.assignment_rounded,
            label: 'Toplam Sınav',
            value: '$examCount',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
