import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../domain/entities/teacher_entities.dart';
import '../bloc/classes_bloc.dart';

class TeacherDashboardPage extends StatelessWidget {
  const TeacherDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FB),
      body: RefreshIndicator(
        color: const Color(0xFF3B4FD8),
        onRefresh: () async {
          final bloc = context.read<ClassesBloc>();
          bloc.add(const LoadClasses());
          await bloc.stream.firstWhere((s) => s is! ClassesLoading);
        },
        child: BlocBuilder<ClassesBloc, ClassesState>(
          builder: (context, state) {
            final classes =
                state is ClassesLoaded ? state.classes : <ClassEntity>[];
            final classCount = classes.length;
            final examCount =
                classes.fold<int>(0, (sum, item) => sum + item.examCount);

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                _DashboardHero(
                  classes: classCount,
                  exams: examCount,
                  onLogout: () =>
                      context.read<AuthBloc>().add(const AuthLogoutRequested()),
                ),
                if (state is ClassesError)
                  _DashboardErrorCard(
                    message: state.message,
                    onRetry: () =>
                        context.read<ClassesBloc>().add(const LoadClasses()),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _SectionTitle(
                    title: 'Yaklaşan Sınavlar',
                    onTapAll: () => context.go('/teacher/exams'),
                  ),
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _UpcomingExamTile(
                        title: 'Matematik Yazılı',
                        classCode: '9-A',
                        dateLabel: '15 Ocak 2024',
                        badgeText: 'Planlandı',
                        badgeColor: Color(0xFF3B4FD8),
                        badgeBgColor: Color(0xFFE9EEFF),
                        iconColor: Color(0xFF5168F5),
                      ),
                      SizedBox(height: 10),
                      _UpcomingExamTile(
                        title: 'Türkçe Yazılı',
                        classCode: '10-B',
                        dateLabel: '17 Ocak 2024',
                        badgeText: 'OCR Bekleniyor',
                        badgeColor: Color(0xFF0BBFB0),
                        badgeBgColor: Color(0xFFE3F8F5),
                        iconColor: Color(0xFF14C6B7),
                      ),
                      SizedBox(height: 10),
                      _UpcomingExamTile(
                        title: 'Fen Bilimleri',
                        classCode: '8-C',
                        dateLabel: '18 Ocak 2024',
                        badgeText: 'Tamamlandı',
                        badgeColor: Color(0xFF19A56E),
                        badgeBgColor: Color(0xFFE7F7EF),
                        iconColor: Color(0xFF31B580),
                      ),
                    ],
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
                SizedBox(
                  height: 205,
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    children: [
                      _OcrPreviewCard(
                        title: 'Matematik 9-A',
                        students: '28 öğrenci',
                        progress: 0.67,
                        progressText: '%67 tamamlandı',
                        status: 'İşleniyor',
                        statusColor: Color(0xFF0BBFB0),
                        imageUrl:
                            'https://www.figma.com/api/mcp/asset/e7c9e96d-f0a2-4878-b694-6d46113b9171',
                      ),
                      SizedBox(width: 12),
                      _OcrPreviewCard(
                        title: 'Türkçe 10-B',
                        students: '32 öğrenci',
                        progress: 0.20,
                        progressText: '%20 tamamlandı',
                        status: 'Kuyrukta',
                        statusColor: Color(0xFF3D50DA),
                        imageUrl:
                            'https://www.figma.com/api/mcp/asset/b041ebc8-6cfc-4b5f-9a6d-9210f18baf92',
                      ),
                    ],
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
                        onTap: () => _navigateToCreateClassAndReload(context),
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
    required this.classes,
    required this.exams,
    required this.onLogout,
  });

  final int classes;
  final int exams;
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
                              child: Image.network(
                                'https://www.figma.com/api/mcp/asset/577ed5ac-0be7-4457-aae3-aa419800500a',
                                fit: BoxFit.cover,
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
                        value: '$classes',
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
                        value: '${(exams / 2).ceil()}',
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
                        value: '${(exams / 3).ceil()}',
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
    required this.students,
    required this.progress,
    required this.progressText,
    required this.status,
    required this.statusColor,
    required this.imageUrl,
  });

  final String title;
  final String students;
  final double progress;
  final String progressText;
  final String status;
  final Color statusColor;
  final String imageUrl;

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
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFE9EEF8),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Color(0xFF8A96B2),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
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
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Color(0xFF0F1729),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1)),
                const SizedBox(height: 6),
                Text(students,
                    style: const TextStyle(
                        color: Color(0xFF6B7A99), fontSize: 11)),
                const SizedBox(height: 10),
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
                const SizedBox(height: 8),
                Text(progressText,
                    style: const TextStyle(
                        color: Color(0xFF6B7A99), fontSize: 11)),
              ],
            ),
          ),
        ],
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
