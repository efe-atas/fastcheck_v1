import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/usecases/teacher_usecases.dart';

class CreateClassPage extends StatefulWidget {
  const CreateClassPage({super.key});

  @override
  State<CreateClassPage> createState() => _CreateClassPageState();
}

class _CreateClassPageState extends State<CreateClassPage> {
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _classNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                          Icons.class_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yeni Sınıf',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Sınıf bilgilerini girerek yeni bir sınıf oluşturun.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                AppSurfaceCard(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  backgroundColor: AppColors.surfaceVariant,
                  child: const Text(
                    'Sınıf, bağlı olduğunuz okulda otomatik olarak oluşturulur. '
                    'Başka bir okul seçmeniz gerekmez.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                AppTextField(
                  controller: _classNameController,
                  label: 'Sınıf Adı',
                  hint: 'Örn: 10-A Matematik',
                  prefixIcon: Icons.edit_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Sınıf adı gereklidir';
                    }
                    if (value.trim().length < 2) {
                      return 'Sınıf adı en az 2 karakter olmalıdır';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 36),
                AppGradientButton(
                  text: 'Sınıf Oluştur',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _handleCreate,
                ),
              ],
            ),
          ),
        ),
      ),
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

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final createClass = GetIt.I<CreateClass>();
    final result = await createClass(
      CreateClassParams(
        className: _classNameController.text.trim(),
      ),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        showAppToast(
          context,
          message: failure.message,
          destructive: true,
        );
      },
      (classEntity) {
        showAppToast(
          context,
          message: 'Sınıf başarıyla oluşturuldu',
        );
        Navigator.of(context).pop(true);
      },
    );
  }
}
