import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/classes_bloc.dart';
import '../widgets/class_card.dart';

class TeacherDashboardPage extends StatelessWidget {
  const TeacherDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
            _buildSliverHeader(context),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              sliver: SliverToBoxAdapter(child: _buildOcrBanner(context)),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            BlocBuilder<ClassesBloc, ClassesState>(
              builder: (context, state) {
                if (state is ClassesLoading) {
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: ShimmerList(itemCount: 4, itemHeight: 160),
                    ),
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
                        onAction: () =>
                            _navigateToCreateClassAndReload(context),
                      ),
                    );
                  }

                  final totalExams = state.classes.fold<int>(
                    0,
                    (sum, c) => sum + c.examCount,
                  );

                  return SliverMainAxisGroup(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenHorizontal,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _StatsRow(
                            classCount: state.classes.length,
                            examCount: totalExams,
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                          child: SizedBox(height: AppSpacing.xxl)),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenHorizontal,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _SectionHeader(
                            title: 'Sınıflarım',
                            count: state.classes.length,
                            onAdd: () =>
                                _navigateToCreateClassAndReload(context),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                          child: SizedBox(height: AppSpacing.md)),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenHorizontal,
                          0,
                          AppSpacing.screenHorizontal,
                          120,
                        ),
                        sliver: SliverGrid(
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
                        ),
                      ),
                    ],
                  );
                }
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: SizedBox(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: _DashboardHeader(
        onAddClass: () => _navigateToCreateClassAndReload(context),
        onLogout: () =>
            context.read<AuthBloc>().add(const AuthLogoutRequested()),
      ),
    );
  }

  Widget _buildOcrBanner(BuildContext context) {
    return _OcrBanner(onTap: () => context.go('/teacher/ocr'));
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
    context.push(
        '/teacher/classes/$classId?name=${Uri.encodeComponent(className)}');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard Header — gradient hero with user greeting
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.onAddClass,
    required this.onLogout,
  });

  final VoidCallback onAddClass;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppSpacing.radiusSheet),
          bottomRight: Radius.circular(AppSpacing.radiusSheet),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          topPad + AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top action row
            Row(
              children: [
                // Avatar circle
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const Spacer(),
                // Add class button
                _HeaderIconButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Sınıf oluştur',
                  onTap: onAddClass,
                ),
                const SizedBox(width: AppSpacing.sm),
                // More menu
                _HeaderPopupMenu(onLogout: onLogout),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            // Greeting
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                final email = authState is AuthAuthenticated
                    ? authState.user.email
                    : null;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hoş geldiniz 👋',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email != null ? email.split('@').first : 'Öğretmen',
                      style: textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            // Tagline chip
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      size: 14, color: AppColors.accentLight),
                  const SizedBox(width: 6),
                  Text(
                    'Sınıf & sınav yönetim paneli',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
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
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _HeaderPopupMenu extends StatelessWidget {
  const _HeaderPopupMenu({required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'logout') onLogout();
      },
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child:
            const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 18),
              SizedBox(width: 10),
              Text('Çıkış yap'),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OCR Banner
// ─────────────────────────────────────────────────────────────────────────────

class _OcrBanner extends StatelessWidget {
  const _OcrBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'OCR Laboratuvarı',
              style: textTheme.titleMedium
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Row
// ─────────────────────────────────────────────────────────────────────────────

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
            label: 'Toplam Sınıf',
            value: '$classCount',
            accentColor: AppColors.primary,
            bgColor: AppColors.primarySurface,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            icon: Icons.assignment_turned_in_rounded,
            label: 'Toplam Sınav',
            value: '$examCount',
            accentColor: AppColors.accent,
            bgColor: AppColors.accentSurface,
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
    required this.accentColor,
    required this.bgColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.onAdd,
  });

  final String title;
  final int count;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count aktif sınıf',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Yeni Sınıf',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
