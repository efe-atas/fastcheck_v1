import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../domain/entities/student_entities.dart';

class QuestionCard extends StatefulWidget {
  final QuestionEntity question;
  final int displayIndex;

  const QuestionCard({
    super.key,
    required this.question,
    required this.displayIndex,
  });

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  QuestionEntity get q => widget.question;

  double get confidencePercent => (q.confidence ?? 0) * 100;

  Color get _confidenceColor {
    if (confidencePercent >= 80) return AppColors.success;
    if (confidencePercent >= 50) return AppColors.warning;
    return AppColors.error;
  }

  Color get _confidenceBgColor {
    if (confidencePercent >= 80) return AppColors.successLight;
    if (confidencePercent >= 50) return AppColors.warningLight;
    return AppColors.errorLight;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(16),
        child: AppSurfaceCard(
          padding: const EdgeInsets.all(16),
          radius: 16,
          borderColor: _expanded
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border,
          borderWidth: _expanded ? 1.5 : 1,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                if (_expanded) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 16),
                  _buildDetails(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            '${widget.displayIndex}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                q.questionText ?? 'Soru ${widget.displayIndex}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: _expanded ? null : 1,
                overflow: _expanded ? null : TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        AnimatedRotation(
          turns: _expanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 250),
          child: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailRow(
          'Öğrenci Cevabı',
          (q.studentAnswer == null || q.studentAnswer!.trim().isEmpty)
              ? 'Öğrenci cevabı bulunmuyor.'
              : q.studentAnswer!,
        ),
        const SizedBox(height: 12),
        _buildRow(
          'Sayfa',
          '${q.pageNumber}',
          Icons.description_outlined,
        ),
        const SizedBox(height: 8),
        _buildRow(
          'Soru Sırası',
          '${q.questionOrder}',
          Icons.format_list_numbered_rounded,
        ),
        if (q.confidence != null || q.sourceQuestionId != null) ...[
          const SizedBox(height: 16),
          _buildTechnicalDetails(),
        ],
      ],
    );
  }

  Widget _buildTechnicalDetails() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: const Text(
            'Teknik detaylar',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          children: [
            if (q.sourceQuestionId != null && q.sourceQuestionId!.isNotEmpty)
              _buildRow(
                'Kaynak ID',
                q.sourceQuestionId!,
                Icons.tag_rounded,
              ),
            if (q.sourceQuestionId != null && q.sourceQuestionId!.isNotEmpty)
              const SizedBox(height: 10),
            if (q.confidence != null) _buildConfidenceBar(),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textTertiary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Güven Skoru',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
              ),
            ),
            Text(
              '%${confidencePercent.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _confidenceColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (q.confidence ?? 0).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: _confidenceBgColor,
            valueColor: AlwaysStoppedAnimation<Color>(_confidenceColor),
          ),
        ),
      ],
    );
  }
}
