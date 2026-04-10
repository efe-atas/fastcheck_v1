import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/authenticated_image.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../ocr/domain/entities/ocr_entities.dart';
import '../../domain/entities/teacher_entities.dart';
import '../bloc/classes_bloc.dart';
import '../bloc/teacher_dashboard_cubit.dart';

class TeacherDashboardPage extends StatelessWidget {
  const TeacherDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FB),
      body: RefreshIndicator(
        color: const Color(0xFF3B4FD8),
        onRefresh: () async {
          final classesBloc = context.read<ClassesBloc>();
          final dashboardCubit = context.read<TeacherDashboardCubit>();
          classesBloc.add(const LoadClasses());
          await Future.wait([
            classesBloc.stream.firstWhere((s) => s is! ClassesLoading),
            dashboardCubit.refreshDashboard(),
          ]);
        },
        child: BlocBuilder<TeacherDashboardCubit, TeacherDashboardState>(
          builder: (context, dashboardState) {
            return BlocBuilder<ClassesBloc, ClassesState>(
              builder: (context, classesState) {
                final classes = classesState is ClassesLoaded
                    ? classesState.classes
                    : <ClassEntity>[];
                final summary = dashboardState is TeacherDashboardLoaded
                    ? dashboardState.summary
                    : null;
                final isDashboardLoading =
                    dashboardState is TeacherDashboardLoading ||
                        dashboardState is TeacherDashboardInitial;
                final dashboardError = dashboardState is TeacherDashboardError
                    ? dashboardState.message
                    : null;
                final latestExams =
                    summary?.latestExams ?? const <ExamEntity>[];
                final recentJobs =
                    summary?.recentOcrJobs ?? const <OcrJobEntity>[];
                final recentResults = dashboardState is TeacherDashboardLoaded
                    ? dashboardState.recentOcrResults
                    : const <OcrResultEntity>[];
                final visibleExams = latestExams.take(3).toList();
                final visibleJobs = recentJobs.take(5).toList();
                final visibleResults = recentResults.take(5).toList();

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    _DashboardHero(
                      classesValue: summary != null
                          ? '${summary.totalClasses}'
                          : (isDashboardLoading ? '—' : '0'),
                      processingValue: summary != null
                          ? '${summary.processingExams}'
                          : (isDashboardLoading ? '—' : '0'),
                      readyValue: summary != null
                          ? '${summary.readyExams}'
                          : (isDashboardLoading ? '—' : '0'),
                      onLogout: () => context
                          .read<AuthBloc>()
                          .add(const AuthLogoutRequested()),
                    ),
                    if (dashboardError != null)
                      _DashboardErrorCard(
                        message: dashboardError,
                        onRetry: () => context
                            .read<TeacherDashboardCubit>()
                            .loadDashboard(),
                      ),
                    if (classesState is ClassesError)
                      _DashboardErrorCard(
                        message: classesState.message,
                        onRetry: () => context
                            .read<ClassesBloc>()
                            .add(const LoadClasses()),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _SectionTitle(
                        title: 'Yaklaşan Sınavlar',
                        onTapAll: () => context.go('/teacher/exams'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (isDashboardLoading)
                      const _SectionLoadingIndicator()
                    else if (visibleExams.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: _DashboardEmptyCard(
                          message: 'Henüz planlanmış sınav bulunmuyor.',
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: visibleExams.map(
                            (exam) {
                              final statusUi = _mapExamStatus(exam.status);
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
                                child: _UpcomingExamTile(
                                  title: exam.title,
                                  classCode: 'Sınıf #${exam.classId}',
                                  dateLabel: DateFormat('d MMMM y', 'tr_TR')
                                      .format(exam.createdAt),
                                  badgeText: statusUi.label,
                                  badgeColor: statusUi.color,
                                  badgeBgColor: statusUi.background,
                                  iconColor: statusUi.iconColor,
                                ),
                              );
                            },
                          ).toList(),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                      child: _SectionTitle(
                        title: 'Son OCR İşlemleri',
                        onTapAll: () => context.go('/teacher/ocr'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (isDashboardLoading)
                      const SizedBox(
                        height: 120,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (visibleResults.isEmpty && visibleJobs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: _DashboardEmptyCard(
                          message:
                              'Hiç OCR kaydı yok. İlk sınavını yüklemeyi deneyebilirsin.',
                        ),
                      )
                    else
                      SizedBox(
                        height: 198,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            if (visibleResults.isNotEmpty) {
                              final result = visibleResults[index];
                              final statusUi = _mapOcrStatus(result.status);
                              return _OcrPreviewCard(
                                title: _ocrResultTitle(result),
                                subtitle: _ocrResultSubtitle(result),
                                progress: statusUi.progress,
                                progressText: statusUi.progressLabel,
                                status: statusUi.label,
                                statusColor: statusUi.color,
                                imageUrl: result.imageUrl,
                                useAuthenticatedImage: true,
                              );
                            }

                            final job = visibleJobs[index];
                            final statusUi = _mapOcrStatus(job.status);
                            final subtitle = job.createdAt != null
                                ? 'Oluşturma: ${DateFormat('d MMM HH:mm', 'tr_TR').format(job.createdAt!.toLocal())}'
                                : 'Tekrar sayısı: ${job.retryCount}';
                            return _OcrPreviewCard(
                              title: _ocrJobTitle(job),
                              subtitle: subtitle,
                              progress: statusUi.progress,
                              progressText: statusUi.progressLabel,
                              status: statusUi.label,
                              statusColor: statusUi.color,
                            );
                          },
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemCount: visibleResults.isNotEmpty
                              ? visibleResults.length
                              : visibleJobs.length,
                        ),
                      ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 18, 16, 0),
                      child: Text(
                        'Hızlı İşlemler',
                        style: TextStyle(
                          color: Color(0xFF0F1729),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _QuickActionButton(
                            icon: Icons.apartment_rounded,
                            label: 'Sınıf Oluştur',
                            onTap: () =>
                                _navigateToCreateClassAndReload(context),
                          ),
                          _QuickActionButton(
                            icon: Icons.note_alt_outlined,
                            label: 'Sınav Ekle',
                            onTap: () {
                              if (classes.isNotEmpty) {
                                context.push(
                                    '/teacher/classes/${classes.first.classId}/exams/create');
                                return;
                              }
                              _navigateToCreateClassAndReload(context);
                            },
                          ),
                          _QuickActionButton(
                            icon: Icons.upload_rounded,
                            label: 'Kağıt Yükle',
                            selected: true,
                            onTap: () => context.go('/teacher/ocr'),
                          ),
                          _QuickActionButton(
                            icon: Icons.person_add_alt_1_rounded,
                            label: 'Öğrenci Ekle',
                            onTap: () {
                              if (classes.isNotEmpty) {
                                context.push(
                                    '/teacher/classes/${classes.first.classId}/students/add');
                                return;
                              }
                              _navigateToCreateClassAndReload(context);
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 96 + MediaQuery.paddingOf(context).bottom),
                  ],
                );
              },
            );
          },
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
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.classesValue,
    required this.processingValue,
    required this.readyValue,
    required this.onLogout,
  });

  final String classesValue;
  final String processingValue;
  final String readyValue;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final formatted =
        DateFormat('EEEE, d MMMM y', 'tr_TR').format(DateTime.now());
    final top = MediaQuery.paddingOf(context).top;

    const metricCardHeight = 131.5;
    const overlapAmount = 65.5;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF3B4FD8),
                    Color(0xFF2D3DB8),
                    Color(0xFF1A2A9E)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding:
                    EdgeInsets.fromLTRB(16, top + 12, 16, overlapAmount + 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 80.5,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            top: 5.5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Merhaba, Ayşe',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    height: 1.02,
                                  ),
                                ),
                                const Text(
                                  'Öğretmen 👋',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    height: 1.02,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _capitalizeFirst(formatted),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Column(
                              children: [
                                InkWell(
                                  onTap: onLogout,
                                  borderRadius: BorderRadius.circular(18),
                                  child: Ink(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.16),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.notifications_none_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 30,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 11),
                                  decoration: BoxDecoration(
                                    color: const Color(0x400BBFB0),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'OGRETMEN',
                                    style: TextStyle(
                                      color: Color(0xFF0BBFB0),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      height: 112,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox.expand(
                              child: Image.asset(
                                'lib/mascot/dashboard_ai_banner.png',
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.medium,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFF4B5EDC),
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.black.withValues(alpha: 0.10),
                            ),
                          ),
                          const Positioned(
                            left: 12,
                            bottom: 28,
                            child: Text(
                              'FastCheck AI ile',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Positioned(
                            left: 12,
                            bottom: 12,
                            child: Text(
                              'Kağıtları saniyeler içinde dijitalleştir',
                              style: TextStyle(
                                color: Color(0xC9FFFFFF),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: -overlapAmount,
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: metricCardHeight,
                      child: _HeroMetric(
                        icon: Icons.apartment_rounded,
                        value: classesValue,
                        label: 'Aktif Sınıflar',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: metricCardHeight,
                      child: _HeroMetric(
                        icon: Icons.timelapse_rounded,
                        value: processingValue,
                        label: 'Bekleyen OCR',
                        badgeDot: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: metricCardHeight,
                      child: _HeroMetric(
                        icon: Icons.calendar_month_rounded,
                        value: readyValue,
                        label: 'Bu Hafta Sınavlar',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: overlapAmount + 12),
      ],
    );
  }

  static String _capitalizeFirst(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.icon,
    required this.value,
    required this.label,
    this.badgeDot = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool badgeDot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9DFF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F1729),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF5068F3), size: 18),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF0F1729),
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 0.95,
                ),
              ),
              if (badgeDot) ...[
                const SizedBox(width: 2),
                const Icon(Icons.circle, size: 8, color: Color(0xFF0BBFB0)),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
                color: Color(0xFF6B7A99), fontSize: 11, height: 1.2),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.onTapAll});
  final String title;
  final VoidCallback onTapAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0F1729),
            fontSize: 15,
            fontWeight: FontWeight.w700,
            height: 1.02,
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: onTapAll,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Row(
              children: [
                Text('Tümü',
                    style: TextStyle(color: Color(0xFF3B4FD8), fontSize: 14)),
                SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    color: Color(0xFF3B4FD8), size: 16),
              ],
            ),
          ),
        )
      ],
    );
  }
}

class _UpcomingExamTile extends StatelessWidget {
  const _UpcomingExamTile({
    required this.title,
    required this.classCode,
    required this.dateLabel,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeBgColor,
    required this.iconColor,
  });

  final String title;
  final String classCode;
  final String dateLabel;
  final String badgeText;
  final Color badgeColor;
  final Color badgeBgColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE3F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F1729),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.note_alt_outlined, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0F1729),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EDF6),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(classCode,
                          style: const TextStyle(
                              color: Color(0xFF8A96B2), fontSize: 10)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 12, color: Color(0xFF8A96B2)),
                    const SizedBox(width: 6),
                    Text(dateLabel,
                        style: const TextStyle(
                            color: Color(0xFF6B7A99), fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: badgeBgColor, borderRadius: BorderRadius.circular(999)),
            child: Text(
              badgeText,
              style: TextStyle(
                  color: badgeColor, fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _OcrPreviewCard extends StatelessWidget {
  const _OcrPreviewCard({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.progressText,
    required this.status,
    required this.statusColor,
    this.imageUrl,
    this.useAuthenticatedImage = false,
  });

  final String title;
  final String subtitle;
  final double progress;
  final String progressText;
  final String status;
  final Color statusColor;
  final String? imageUrl;
  final bool useAuthenticatedImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 178,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE3F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F1729),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                SizedBox(
                  width: 178,
                  height: 95,
                  child: imageUrl != null && imageUrl!.trim().isNotEmpty
                      ? (useAuthenticatedImage
                          ? AuthenticatedImage(
                              url: imageUrl!.trim(),
                              width: 178,
                              height: 95,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              imageUrl!.trim(),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _imageFallback(),
                            ))
                      : _imageFallback(),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xFF0F1729),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1)),
                const SizedBox(height: 4),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xFF6B7A99), fontSize: 11)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFDCE2EE),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF0BBFB0)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(progressText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xFF6B7A99), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: const Color(0xFFE9EEF8),
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Color(0xFF8A96B2),
          size: 20,
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 78,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFDFF6F5) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD9DFF2)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x100F1729),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon,
                  color: selected
                      ? const Color(0xFF0BBFB0)
                      : const Color(0xFF3B4FD8),
                  size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B7A99),
                fontSize: 10,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardErrorCard extends StatelessWidget {
  const _DashboardErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Yenile')),
        ],
      ),
    );
  }
}

class _DashboardEmptyCard extends StatelessWidget {
  const _DashboardEmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE3F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF6B7A99)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF6B7A99),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLoadingIndicator extends StatelessWidget {
  const _SectionLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 90,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Color(0xFF3B4FD8),
        ),
      ),
    );
  }
}

_ExamStatusUi _mapExamStatus(String? raw) {
  final status = raw?.toUpperCase() ?? '';
  switch (status) {
    case 'READY':
      return const _ExamStatusUi(
        label: 'Hazır',
        color: Color(0xFF19A56E),
        background: Color(0xFFE7F7EF),
        iconColor: Color(0xFF31B580),
      );
    case 'PROCESSING':
      return const _ExamStatusUi(
        label: 'OCR Sürüyor',
        color: Color(0xFF0BBFB0),
        background: Color(0xFFE3F8F5),
        iconColor: Color(0xFF14C6B7),
      );
    case 'FAILED':
      return const _ExamStatusUi(
        label: 'Hata',
        color: AppColors.error,
        background: AppColors.errorLight,
        iconColor: AppColors.error,
      );
    case 'DRAFT':
    default:
      return const _ExamStatusUi(
        label: 'Planlandı',
        color: Color(0xFF3B4FD8),
        background: Color(0xFFE9EEFF),
        iconColor: Color(0xFF5168F5),
      );
  }
}

class _ExamStatusUi {
  final String label;
  final Color color;
  final Color background;
  final Color iconColor;

  const _ExamStatusUi({
    required this.label,
    required this.color,
    required this.background,
    required this.iconColor,
  });
}

_OcrStatusUi _mapOcrStatus(String? raw) {
  final status = raw?.toUpperCase() ?? '';
  switch (status) {
    case 'COMPLETED':
      return const _OcrStatusUi(
        label: 'Tamamlandı',
        color: Color(0xFF19A56E),
        progress: 1,
        progressLabel: '%100 tamamlandı',
      );
    case 'PROCESSING':
      return const _OcrStatusUi(
        label: 'İşleniyor',
        color: Color(0xFF0BBFB0),
        progress: 0.65,
        progressLabel: '%65 tamamlandı',
      );
    case 'FAILED':
      return const _OcrStatusUi(
        label: 'Hata',
        color: AppColors.error,
        progress: 1,
        progressLabel: 'İşleme hatası',
      );
    case 'PENDING':
    default:
      return const _OcrStatusUi(
        label: 'Kuyrukta',
        color: Color(0xFF3B4FD8),
        progress: 0.15,
        progressLabel: '%15 sırada',
      );
  }
}

class _OcrStatusUi {
  final String label;
  final Color color;
  final double progress;
  final String progressLabel;

  const _OcrStatusUi({
    required this.label,
    required this.color,
    required this.progress,
    required this.progressLabel,
  });
}

String _shortenId(String value) {
  if (value.isEmpty) return '---';
  return value.length <= 8 ? value : value.substring(0, 8);
}

String _ocrResultTitle(OcrResultEntity result) {
  final studentName = _extractStudentName(result.result);
  if (studentName != null) return studentName;

  final source = _sourceLabel(result.sourceId);
  if (source != null) return source;

  return 'İş ${_shortenId(result.jobId)}';
}

String _ocrResultSubtitle(OcrResultEntity result) {
  final parts = <String>[];
  final source = _sourceLabel(result.sourceId);
  if (source != null) {
    parts.add(source);
  }
  parts.add(DateFormat('d MMM HH:mm', 'tr_TR').format(result.createdAt.toLocal()));
  return parts.join(' • ');
}

String _ocrJobTitle(OcrJobEntity job) {
  final source = _sourceLabel(job.requestId);
  if (source != null) return source;
  return 'İş ${_shortenId(job.jobId)}';
}

String? _sourceLabel(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final value = raw.trim();
  if (value.startsWith('exam-') && value.length > 5) {
    return 'Sınav #${value.substring(5)}';
  }
  if (value.startsWith('class-') && value.length > 6) {
    return 'Sınıf #${value.substring(6)}';
  }
  if (value.startsWith('student-') && value.length > 8) {
    return 'Öğrenci #${value.substring(8)}';
  }
  return null;
}

String? _extractStudentName(dynamic raw) {
  if (raw is! Map) return null;
  final data = raw.map((key, value) => MapEntry(key.toString(), value));

  for (final key in const ['studentName', 'student', 'name', 'owner']) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }

  final metadata = data['metadata'];
  if (metadata is Map) {
    final normalized =
        metadata.map((key, value) => MapEntry(key.toString(), value));
    for (final key in const ['studentName', 'student', 'name']) {
      final value = normalized[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
  }

  return null;
}
