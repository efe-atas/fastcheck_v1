import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../bloc/exam_bloc.dart';

class CreateExamPage extends StatefulWidget {
  final int classId;

  const CreateExamPage({super.key, required this.classId});

  @override
  State<CreateExamPage> createState() => _CreateExamPageState();
}

class _CreateExamPageState extends State<CreateExamPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExamBloc, ExamState>(
      listener: (context, state) {
        if (state is ExamCreated) {
          showAppToast(
            context,
            message: 'Sınav oluşturuldu. Tarama için OCR sekmesini kullanın.',
          );
          Navigator.of(context).pop(true);
        } else if (state is ExamError) {
          showAppToast(
            context,
            message: state.message,
            destructive: true,
          );
        }
      },
      builder: (context, state) {
        final isCreating = state is ExamCreating;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(context),
                    const SizedBox(height: 8),
                    _buildCreateExamSection(context, isCreating),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return IconButton(
      onPressed: () => Navigator.of(context).maybePop(),
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildCreateExamSection(BuildContext context, bool isCreating) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSurfaceCard(
          padding: const EdgeInsets.all(20),
          backgroundColor: AppColors.primarySurface,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Sınavı oluşturduktan sonra OCR sekmesinden tarama yapabilirsiniz.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AppTextField(
          controller: _titleController,
          label: 'Sınav Başlığı',
          hint: 'Örn: 1. Dönem Matematik Sınavı',
          prefixIcon: Icons.title_rounded,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Sınav başlığı gereklidir';
            }
            return null;
          },
        ),
        const SizedBox(height: 32),
        AppGradientButton(
          text: 'Sınavı Oluştur',
          isLoading: isCreating,
          onPressed: isCreating
              ? null
              : () {
                  if (_formKey.currentState!.validate()) {
                    context.read<ExamBloc>().add(CreateExamEvent(
                          classId: widget.classId,
                          title: _titleController.text.trim(),
                        ));
                  }
                },
        ),
      ],
    );
  }
}
