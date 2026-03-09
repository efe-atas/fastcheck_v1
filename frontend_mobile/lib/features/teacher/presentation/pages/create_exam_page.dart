import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
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
  final _imagePicker = ImagePicker();
  final List<File> _selectedImages = [];
  int? _createdExamId;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<ExamBloc>(),
      child: BlocConsumer<ExamBloc, ExamState>(
        listener: (context, state) {
          if (state is ExamCreated) {
            _createdExamId = state.exam.examId;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sınav oluşturuldu. Şimdi fotoğraf ekleyin.'),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is ImagesUploaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fotoğraflar başarıyla yüklendi'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.of(context).pop(true);
          } else if (state is ExamError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isCreating = state is ExamCreating;
          final isUploading = state is ImagesUploading;
          final examCreated = _createdExamId != null;

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Yeni Sınav'),
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStepIndicator(examCreated),
                    const SizedBox(height: 24),
                    if (!examCreated) ...[
                      _buildCreateExamSection(context, isCreating),
                    ] else ...[
                      _buildImageUploadSection(context, isUploading),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepIndicator(bool examCreated) {
    return Row(
      children: [
        _buildStep(1, 'Sınav Bilgisi', true),
        Expanded(
          child: Container(
            height: 2,
            color: examCreated ? AppColors.primary : AppColors.border,
          ),
        ),
        _buildStep(2, 'Fotoğraflar', examCreated),
      ],
    );
  }

  Widget _buildStep(int number, String label, bool active) {
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor:
              active ? AppColors.primary : AppColors.surfaceVariant,
          child: Text(
            '$number',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.textTertiary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: active ? AppColors.primary : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildCreateExamSection(BuildContext context, bool isCreating) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(16),
          ),
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
                  'Sınav başlığını girin ve oluşturun.',
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

  Widget _buildImageUploadSection(BuildContext context, bool isUploading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sınav oluşturuldu! Şimdi sınav kağıtlarının fotoğraflarını yükleyin.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isUploading ? null : _pickFromCamera,
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Kamera'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isUploading ? null : _pickFromGallery,
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('Galeri'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_selectedImages.isNotEmpty) ...[
          Text(
            '${_selectedImages.length} fotoğraf seçildi',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _selectedImages[index],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImages.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          AppGradientButton(
            text: 'Fotoğrafları Yükle',
            isLoading: isUploading,
            onPressed: isUploading
                ? null
                : () {
                    context.read<ExamBloc>().add(UploadImagesEvent(
                          examId: _createdExamId!,
                          images: _selectedImages,
                        ));
                  },
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.border,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(14),
              color: AppColors.surfaceVariant,
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.add_photo_alternate_rounded,
                  size: 48,
                  color: AppColors.textTertiary,
                ),
                SizedBox(height: 12),
                Text(
                  'Henüz fotoğraf seçilmedi',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Fotoğraf yüklemeden devam et'),
        ),
      ],
    );
  }

  Future<void> _pickFromCamera() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _selectedImages.add(File(image.path)));
    }
  }

  Future<void> _pickFromGallery() async {
    final images = await _imagePicker.pickMultiImage(imageQuality: 85);
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((e) => File(e.path)));
      });
    }
  }
}
