import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/teacher_entities.dart';
import '../bloc/exam_bloc.dart';

class ExamDetailPage extends StatefulWidget {
  final int examId;
  final String examTitle;

  const ExamDetailPage({
    super.key,
    required this.examId,
    required this.examTitle,
  });

  @override
  State<ExamDetailPage> createState() => _ExamDetailPageState();
}

class _ExamDetailPageState extends State<ExamDetailPage> {
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        context.read<ExamBloc>().add(RefreshExamStatusEvent(widget.examId));
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: BlocConsumer<ExamBloc, ExamState>(
                listener: (context, state) {
                  if (state is ExamStatusLoaded) {
                    final s = state.examStatus.examStatus.toUpperCase();
                    if (s == 'PROCESSING' || s == 'IN_PROGRESS') {
                      _startPolling();
                    } else {
                      _stopPolling();
                    }
                  }
                },
                builder: (context, state) {
                  if (state is ExamStatusLoading) {
                    return const LoadingWidget(message: 'Yükleniyor...');
                  }
                  if (state is ExamError) {
                    return AppErrorWidget(
                      message: state.message,
                      onRetry: () => context
                          .read<ExamBloc>()
                          .add(LoadExamStatusEvent(widget.examId)),
                    );
                  }
                  if (state is ExamStatusLoaded) {
                    return _buildBody(context, state.examStatus);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => context
                .read<ExamBloc>()
                .add(LoadExamStatusEvent(widget.examId)),
            icon: const Icon(Icons.refresh_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ExamStatusEntity exam) {
    final status = exam.examStatus.toUpperCase();
    final clusters = exam.studentClusters;
    final isProcessing = status == 'PROCESSING' || status == 'IN_PROGRESS';
    final isFailed = status == 'FAILED' || status == 'ERROR';

    return Column(
      children: [
        // -- üst özet şeridi --
        _StatusBar(
          status: status,
          pageCount: exam.images.length,
          questionCount: exam.questionCount,
          studentCount: clusters.length,
          isProcessing: isProcessing,
          processedCount: exam.images
              .where((i) => i.status.toUpperCase() != 'PENDING')
              .length,
        ),

        if (isFailed)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => context
                    .read<ExamBloc>()
                    .add(ReprocessExamEvent(exam.examId)),
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('Yeniden işle'),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
              ),
            ),
          ),

        const SizedBox(height: 4),

        // -- öğrenci listesi --
        Expanded(
          child: clusters.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isProcessing
                              ? Icons.hourglass_top_rounded
                              : Icons.groups_2_outlined,
                          size: 48,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isProcessing
                              ? 'Kağıtlar işleniyor…'
                              : 'Henüz öğrenci grubu yok',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: clusters.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 2),
                  itemBuilder: (context, i) => _StudentRow(
                    exam: exam,
                    cluster: clusters[i],
                  ),
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Üst durum şeridi: tek satırda tüm bilgi
// ---------------------------------------------------------------------------
class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.status,
    required this.pageCount,
    required this.questionCount,
    required this.studentCount,
    required this.isProcessing,
    required this.processedCount,
  });

  final String status;
  final int pageCount;
  final int questionCount;
  final int studentCount;
  final bool isProcessing;
  final int processedCount;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Container(
      width: double.infinity,
      color: color.withAlpha(18),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withAlpha(35),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _miniStat(Icons.description_outlined, '$pageCount sayfa'),
              const SizedBox(width: 10),
              _miniStat(Icons.quiz_outlined, '$questionCount soru'),
              const SizedBox(width: 10),
              _miniStat(Icons.people_outline, '$studentCount öğrenci'),
            ],
          ),
          if (isProcessing) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pageCount > 0 ? processedCount / pageCount : 0,
                backgroundColor: color.withAlpha(30),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tek öğrenci satırı — ListTile kadar basit
// ---------------------------------------------------------------------------
class _StudentRow extends StatelessWidget {
  const _StudentRow({required this.exam, required this.cluster});

  final ExamStatusEntity exam;
  final TeacherStudentClusterEntity cluster;

  @override
  Widget build(BuildContext context) {
    final accent = cluster.needsAttention
        ? AppColors.warning
        : cluster.unmatched
            ? AppColors.error
            : AppColors.success;

    final pct = cluster.scorePercentage;
    final pctText = '%${pct.toStringAsFixed(pct % 1 == 0 ? 0 : 1)}';
    final scoreText =
        '${_fmt(cluster.awardedPoints)}/${_fmt(cluster.maxPoints)}';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: (cluster.hasQuestions || cluster.hasImages)
            ? () => _open(context)
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: accent.withAlpha(30),
                child: Text(
                  _initials(cluster.studentName),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // isim + durum
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cluster.studentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _matchLabel(cluster),
                      style: TextStyle(
                        fontSize: 12,
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // puan
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    pctText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                  Text(
                    scoreText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),

              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary.withAlpha(120),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    final params = <String, String>{'title': exam.title};
    if (cluster.unmatched) {
      params['unmatched'] = 'true';
    } else if (cluster.studentId != null) {
      params['studentId'] = cluster.studentId.toString();
      params['studentName'] = cluster.studentName;
    }
    final q = Uri(queryParameters: params).query;
    context.push('/teacher/exams/${exam.examId}/questions?$q');
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  static String _matchLabel(TeacherStudentClusterEntity c) {
    if (c.unmatched) return 'Atama bekliyor';
    switch (c.matchingStatus?.toUpperCase()) {
      case 'MANUAL':
        return 'Manuel eşleşti';
      case 'AMBIGUOUS':
        return 'Kontrol gerekli';
      case 'UNMATCHED':
        return 'Eşleştirilemedi';
      case 'MATCHED':
        return 'Eşleşti';
      default:
        return 'Hazır';
    }
  }
}

// ---------------------------------------------------------------------------
Color _statusColor(String s) => switch (s) {
      'READY' || 'COMPLETED' || 'DONE' => AppColors.success,
      'PROCESSING' || 'PENDING' || 'IN_PROGRESS' => AppColors.warning,
      'FAILED' || 'ERROR' => AppColors.error,
      _ => AppColors.textTertiary,
    };

String _statusLabel(String s) => switch (s) {
      'READY' || 'COMPLETED' || 'DONE' => 'Hazır',
      'PROCESSING' || 'IN_PROGRESS' => 'İşleniyor',
      'PENDING' => 'Bekliyor',
      'FAILED' || 'ERROR' => 'Hata',
      _ => 'Taslak',
    };
