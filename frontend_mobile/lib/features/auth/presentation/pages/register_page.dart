import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/auth_roles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

const _motionDuration = Duration(milliseconds: 700);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = AuthRoles.student;
  bool _heroVisible = false;
  bool _formVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _heroVisible = true;
        _formVisible = true;
      });
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            AuthRegisterRequested(
              fullName: _fullNameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
              role: _selectedRole,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            showAppToast(
              context,
              message: state.message,
              destructive: true,
            );
          }
        },
        child: Stack(
          children: [
            const _RegisterAtmosphere(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Form(
                    key: _formKey,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ShadButton.ghost(
                              leading: const Icon(Icons.chevron_left_rounded),
                              onPressed: () => Navigator.of(context).maybePop(),
                              child: const Text('Geri dön'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 960;
                              final heroSection = _buildHeroSection(isWide);
                              final formSection = _buildFormSection();

                              if (isWide) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: heroSection),
                                    const SizedBox(width: 32),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 520,
                                      ),
                                      child: formSection,
                                    ),
                                  ],
                                );
                              }

                              return Column(
                                children: [
                                  heroSection,
                                  const SizedBox(height: 28),
                                  formSection,
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Visual thesis: kayıt ekranı için cam yüzeyli onboarding paneli + ritmik hatlı zaman çizelgesi.
  /// Content plan: hero sözü, adım adım rehber, rol seçimi, form alanları, CTA ve geri dönüş linki.
  /// Interaction thesis: rol kartlarında ışıklı seçim durumu, hero/form için paralel slide-fade, arkada nefes alan orb'lar.
  Widget _buildHeroSection(bool isWide) {
    final textTheme = Theme.of(context).textTheme;
    final steps = const [
      _OnboardingStepData(
        title: 'Rolünü belirle',
        subtitle: 'Admin, öğretmen veya öğrenci için ayrı izin setleri',
      ),
      _OnboardingStepData(
        title: 'Bilgilerini doğrula',
        subtitle: 'Kurumsal e-posta ve güçlü şifre ile güvence',
      ),
      _OnboardingStepData(
        title: 'Ekibini davet et',
        subtitle: 'Fastcheck paneline anında geçiş yapın',
      ),
    ];

    return AnimatedSlide(
      duration: _motionDuration,
      curve: Curves.easeOutCubic,
      offset: _heroVisible ? Offset.zero : const Offset(0, 0.15),
      child: AnimatedOpacity(
        duration: _motionDuration,
        opacity: _heroVisible ? 1 : 0,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 44 : 24,
            vertical: isWide ? 44 : 28,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isWide ? 40 : 28),
            border: Border.all(color: AppColors.border.withOpacity(0.35)),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.12),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x330F1729),
                blurRadius: 24,
                offset: Offset(0, 24),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.auto_awesome_rounded,
                      color: AppColors.primaryLight, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Yeni nesil kayıt deneyimi',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Fastcheck ekosistemine katılın',
                style: textTheme.displayMedium?.copyWith(
                  fontSize: isWide ? 52 : 44,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Sınav, veli ve kampüs operasyonlarını aynı oturum açma ile yönetin.',
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Column(
                children: [
                  for (var i = 0; i < steps.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                          bottom: i == steps.length - 1 ? 0 : 18),
                      child: _OnboardingStep(
                        index: i + 1,
                        data: steps[i],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 26),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: AppColors.primarySurface.withOpacity(0.9),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_clock_rounded,
                        color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Kayıtlar ortalama 2 dakikada tamamlanır. İstediğiniz zaman destek ekibine ulaşabilirsiniz.',
                        style: textTheme.bodyMedium
                            ?.copyWith(color: AppColors.secondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    final textTheme = Theme.of(context).textTheme;
    return AnimatedSlide(
      duration: _motionDuration,
      curve: Curves.easeOut,
      offset: _formVisible ? Offset.zero : const Offset(0, 0.12),
      child: AnimatedOpacity(
        duration: _motionDuration,
        opacity: _formVisible ? 1 : 0,
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.border.withOpacity(0.7)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A0F1729),
                blurRadius: 30,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Hesap oluşturun',
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Rolünüzü seçin ve kurumsal bilgilerinizle devam edin.',
                style: textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              _buildRolePicker(),
              const SizedBox(height: 28),
              _buildFormFields(),
              const SizedBox(height: 22),
              _buildRegisterButton(),
              const SizedBox(height: 18),
              _buildLoginLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRolePicker() {
    const roleOptions = [
      _RoleOptionData(
        value: AuthRoles.admin,
        title: 'Admin',
        subtitle: 'Kurum ayarları, sınav akışları ve raporlar',
        icon: Icons.auto_awesome_mosaic_rounded,
      ),
      _RoleOptionData(
        value: AuthRoles.teacher,
        title: 'Öğretmen',
        subtitle: 'Sınıf içerikleri, yoklamalar ve değerlendirme',
        icon: Icons.menu_book_rounded,
      ),
      _RoleOptionData(
        value: AuthRoles.student,
        title: 'Öğrenci',
        subtitle: 'Sonuçlar, takvim ve bildirimler',
        icon: Icons.school_rounded,
      ),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: roleOptions
          .map(
            (option) => _RoleCard(
              data: option,
              isSelected: option.value == _selectedRole,
              onTap: () => setState(() => _selectedRole = option.value),
            ),
          )
          .toList(),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        AppTextField(
          controller: _fullNameController,
          label: 'Ad Soyad',
          hint: 'Adınız Soyadınız',
          prefixIcon: Icons.person_outline_rounded,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ad soyad gerekli';
            }
            if (value.trim().length < 2) {
              return 'Ad soyad en az 2 karakter olmalı';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        AppTextField(
          controller: _emailController,
          label: 'Kurumsal e-posta',
          hint: 'ornek@okul.edu.tr',
          prefixIcon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'E-posta adresi gerekli';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Geçerli bir e-posta adresi girin';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        AppTextField(
          controller: _passwordController,
          label: 'Şifre',
          hint: 'En az 8 karakter',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Şifre gerekli';
            }
            if (value.length < 8) {
              return 'Şifre en az 8 karakter olmalı';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        AppTextField(
          controller: _confirmPasswordController,
          label: 'Şifre Tekrar',
          hint: 'Şifrenizi tekrar girin',
          prefixIcon: Icons.lock_person_outlined,
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Şifre tekrarı gerekli';
            }
            if (value != _passwordController.text) {
              return 'Şifreler eşleşmiyor';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return AppGradientButton(
          text: 'Kayıt Ol',
          isLoading: state is AuthLoading,
          onPressed: _onRegister,
        );
      },
    );
  }

  Widget _buildLoginLink() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Zaten hesabınız var mı?',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(width: 8),
            ShadButton.link(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Giriş yapın'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ShadButton.ghost(
          onPressed: () => showAppToast(
            context,
            message: 'Destek ekibi kısa sürede sizinle iletişime geçecek.',
          ),
          child: const Text('Destek ile konuş'),
        ),
      ],
    );
  }
}

class _RoleOptionData {
  const _RoleOptionData({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String value;
  final String title;
  final String subtitle;
  final IconData icon;
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  final _RoleOptionData data;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : AppColors.border.withOpacity(0.7),
          width: isSelected ? 1.6 : 1,
        ),
        color: isSelected ? AppColors.primarySurface : Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F1729),
            blurRadius: 18,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  data.icon,
                  color: isSelected ? AppColors.primary : AppColors.secondary,
                ),
                const SizedBox(height: 12),
                Text(
                  data.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingStepData {
  const _OnboardingStepData({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}

class _OnboardingStep extends StatelessWidget {
  const _OnboardingStep({
    required this.index,
    required this.data,
  });

  final int index;
  final _OnboardingStepData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(0.12),
            border: Border.all(color: AppColors.primary.withOpacity(0.4)),
          ),
          child: Text(
            index.toString().padLeft(2, '0'),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                data.subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RegisterAtmosphere extends StatelessWidget {
  const _RegisterAtmosphere();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final diameter = size.shortestSide * 0.8;
    return Positioned.fill(
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.surfaceWarm,
                  Color(0xFFF1F4FF),
                  Color(0xFFEAF6FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Align(
            alignment: const Alignment(-1, -0.8),
            child: _GlowOrb(
              size: diameter,
              color: AppColors.primary.withOpacity(0.18),
            ),
          ),
          Align(
            alignment: const Alignment(0.8, -1),
            child: _GlowOrb(
              size: diameter * 0.7,
              color: AppColors.accent.withOpacity(0.2),
            ),
          ),
          Align(
            alignment: const Alignment(0.6, 1.1),
            child: _GlowOrb(
              size: diameter * 0.9,
              color: AppColors.primaryLight.withOpacity(0.16),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: size * 0.04, sigmaY: size * 0.04),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
