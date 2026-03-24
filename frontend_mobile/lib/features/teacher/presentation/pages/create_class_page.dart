import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/usecases/teacher_usecases.dart';

class CreateClassPage extends StatefulWidget {
  const CreateClassPage({super.key});

  @override
  State<CreateClassPage> createState() => _CreateClassPageState();
}

class _CreateClassPageState extends State<CreateClassPage> {
  final _formKey = GlobalKey<FormState>();
  final _schoolIdController = TextEditingController();
  final _classNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _prefillSchoolIdFromExistingClasses();
  }

  /// Backend’de öğretmen yalnızca kendi okulunda sınıf açabilir; mevcut sınıflardan okul ID önerilir.
  Future<void> _prefillSchoolIdFromExistingClasses() async {
    final getClasses = GetIt.I<GetClasses>();
    final result = await getClasses(const NoParams());
    if (!mounted) return;
    result.fold((_) {}, (classes) {
      if (classes.isEmpty) return;
      final sid = classes.first.schoolId;
      if (_schoolIdController.text.trim().isEmpty) {
        _schoolIdController.text = '$sid';
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _schoolIdController.dispose();
    _classNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Yeni Sınıf Oluştur'),
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'Okul ID, yöneticinin sizi bir okula atadığı kayıttaki numaradır. '
                  'Zaten sınıfınız varsa aşağıdaki alan genelde otomatik dolar; '
                  'ilk kez oluşturuyorsanız yöneticiden öğrenin.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              AppTextField(
                controller: _schoolIdController,
                label: 'Okul ID',
                hint: 'Örn: 1',
                prefixIcon: Icons.business_rounded,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Okul ID gereklidir';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Geçerli bir sayı girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
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
    );
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final createClass = GetIt.I<CreateClass>();
    final result = await createClass(
      CreateClassParams(
        schoolId: int.parse(_schoolIdController.text.trim()),
        className: _classNameController.text.trim(),
      ),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.error,
          ),
        );
      },
      (classEntity) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sınıf başarıyla oluşturuldu'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      },
    );
  }
}
