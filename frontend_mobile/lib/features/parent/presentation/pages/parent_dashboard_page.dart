import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_dashboard_header.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/liquid_glass_bottom_bar.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/parent_bloc.dart';

class ParentDashboardPage extends StatefulWidget {
  const ParentDashboardPage({super.key});

  @override
  State<ParentDashboardPage> createState() => _ParentDashboardPageState();
}

class _ParentDashboardPageState extends State<ParentDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStudents());
  }

  void _loadStudents() {
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) {
      context.read<ParentBloc>().add(LoadLinkedStudents(auth.user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: DashboardGradientBoxHeader(
              headline: 'Merhaba, Veli 👋',
              subtitle: 'Öğrenci durumlarını takip edin',
            ),
          ),
          _buildStudentList(),
        ],
      ),
      bottomNavigationBar: LiquidGlassBottomBar(
        items: [
          LiquidGlassBarItem(
            icon: Icons.family_restroom_rounded,
            label: 'Öğrenciler',
            selected: true,
            onTap: () {},
          ),
          LiquidGlassBarItem(
            icon: Icons.refresh_rounded,
            label: 'Yenile',
            onTap: _loadStudents,
          ),
          LiquidGlassBarItem(
            icon: Icons.logout_rounded,
            label: 'Çıkış',
            onTap: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      sliver: BlocBuilder<ParentBloc, ParentState>(
        builder: (context, state) {
          if (state is ParentLoading) {
            return const SliverFillRemaining(child: ShimmerList(itemCount: 3));
          }
          if (state is ParentError) {
            return SliverFillRemaining(
              child: AppErrorWidget(
                message: state.message,
                onRetry: _loadStudents,
              ),
            );
          }
          if (state is LinkedStudentsLoaded) {
            if (state.students.isEmpty) {
              return const SliverFillRemaining(
                child: EmptyStateWidget(
                  icon: Icons.people_outline_rounded,
                  title: 'Bağlı Öğrenci Yok',
                  subtitle: 'Henüz bir öğrenci bağlantınız bulunmuyor.',
                ),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final student = state.students[index];
                  return _StudentCard(student: student);
                },
                childCount: state.students.length,
              ),
            );
          }
          return const SliverFillRemaining(child: SizedBox());
        },
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final dynamic student;

  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Navigate to student exam view
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    student.initials,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      student.email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
