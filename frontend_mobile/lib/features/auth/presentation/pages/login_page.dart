import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Giriş ekranı maskot görseli (`lib/mascot/`).
const _loginMascotAsset = 'lib/mascot/5.png';

const _heroHighlights = [
  'Gerçek zamanlı sınav akışı',
  'AI destekli OCR laboratuvarı',
  'Veli & öğrenci panoraması',
];

const _motionDuration = Duration(milliseconds: 700);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            AuthLoginRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
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
            const _AuthAtmosphere(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Form(
                    key: _formKey,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: LayoutBuilder(
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
                                  constraints:
                                      const BoxConstraints(maxWidth: 460),
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

  /// Visual thesis: aurora benzeri okul kontrol odası, cam yüzeyler ve maskot spotu.
  /// Content plan: marka rozeti, iddialı hero mesajı, kanıt pill'leri ve ürün vignette'i.
  /// Interaction thesis: kayarak açılan hero + form, parlak atmosfer orb'ları ve link hover.
  Widget _buildHeroSection(bool isWide) {
    final textTheme = Theme.of(context).textTheme;
    return AnimatedSlide(
      duration: _motionDuration,
      curve: Curves.easeOutCubic,
      offset: _heroVisible ? Offset.zero : const Offset(0, 0.15),
      child: AnimatedOpacity(
        duration: _motionDuration,
        opacity: _heroVisible ? 1 : 0,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 48 : 24,
            vertical: isWide ? 48 : 28,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isWide ? 40 : 28),
            border: Border.all(color: AppColors.border.withOpacity(0.3)),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.32),
                Colors.white.withOpacity(0.16),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accentSurface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.blur_on_rounded,
                        size: 16, color: AppColors.accentDark),
                    SizedBox(width: 8),
                    Text(
                      'Fastcheck Platformu',
                      style: TextStyle(
                        color: AppColors.accentDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Okul ekosistemini tek ekranda yönetin',
                style: textTheme.displayMedium?.copyWith(
                  height: 1.05,
                  fontSize: isWide ? 56 : 44,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Sınav operasyonları, OCR laboratuvarı ve veli iletişimi için modern kontrol merkezi.',
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _heroHighlights
                    .map(
                      (item) => _HeroPill(text: item),
                    )
                    .toList(),
              ),
              const SizedBox(height: 32),
              AspectRatio(
                aspectRatio: isWide ? 16 / 9 : 4 / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Image.asset(
                            _loginMascotAsset,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 20,
                        top: 20,
                        child: _FloatingStat(
                          label: 'Aktif kurum',
                          value: '320+',
                        ),
                      ),
                      const Positioned(
                        left: 20,
                        bottom: 20,
                        child: _FloatingStat(
                          label: 'Günlük analiz',
                          value: '58K',
                        ),
                      ),
                    ],
                  ),
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
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.border.withOpacity(0.7)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A0F1729),
                blurRadius: 28,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Hesabınıza giriş yapın',
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Fastcheck kimlik bilgilerinizle devam edin.',
                style: textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 28),
              _buildFormFields(),
              const SizedBox(height: 18),
              _buildLoginButton(),
              const SizedBox(height: 18),
              _buildRegisterLink(),
              if (kDebugMode) ...[
                const SizedBox(height: 20),
                _buildDevBypassButton(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
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
          hint: '••••••••',
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
      ],
    );
  }

  Widget _buildLoginButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return AppGradientButton(
          text: 'Giriş Yap',
          isLoading: state is AuthLoading,
          onPressed: _onLogin,
        );
      },
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Hesabınız yok mu?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(width: 8),
        ShadButton.link(
          onPressed: () => context.push('/auth/register'),
          child: const Text('Fastcheck’e katılın'),
        ),
      ],
    );
  }

  /// Debug: API olmadan seçilen rolle direkt panele gir.
  Widget _buildDevBypassButton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        const SizedBox(height: 4),
        Text(
          'Hızlı Giriş (Dev)',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
        ),
        const SizedBox(height: 8),
        _devRoleButton(
          context,
          label: 'Admin',
          role: 'ROLE_ADMIN',
          icon: Icons.admin_panel_settings_outlined,
        ),
        const SizedBox(height: 8),
        _devRoleButton(
          context,
          label: 'Öğretmen',
          role: 'ROLE_TEACHER',
          icon: Icons.school_outlined,
        ),
        const SizedBox(height: 8),
        _devRoleButton(
          context,
          label: 'Öğrenci',
          role: 'ROLE_STUDENT',
          icon: Icons.person_outlined,
        ),
        const SizedBox(height: 8),
        _devRoleButton(
          context,
          label: 'Veli',
          role: 'ROLE_PARENT',
          icon: Icons.family_restroom_outlined,
        ),
      ],
    );
  }

  Widget _devRoleButton(
    BuildContext context, {
    required String label,
    required String role,
    required IconData icon,
  }) {
    return ShadButton.outline(
      leading: Icon(icon, size: 18),
      onPressed: () => context.read<AuthBloc>().add(
            AuthDevBypassRequested(role: role),
          ),
      child: Text('$label olarak gir'),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.75),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withOpacity(0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              size: 16, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingStat extends StatelessWidget {
  const _FloatingStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthAtmosphere extends StatelessWidget {
  const _AuthAtmosphere();

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final diameter = media.shortestSide * 0.8;
    return Positioned.fill(
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.surfaceWarm,
                  AppColors.background,
                  Color(0xFFE8ECFF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Align(
            alignment: const Alignment(-0.9, -1.1),
            child: _GlowOrb(
              size: diameter,
              color: AppColors.primary.withOpacity(0.25),
            ),
          ),
          Align(
            alignment: const Alignment(1.1, -0.6),
            child: _GlowOrb(
              size: diameter * 0.7,
              color: AppColors.accent.withOpacity(0.22),
            ),
          ),
          Align(
            alignment: const Alignment(0.6, 1.0),
            child: _GlowOrb(
              size: diameter * 0.9,
              color: AppColors.primaryLight.withOpacity(0.18),
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
