import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

const _motionDuration = Duration(milliseconds: 650);

const _demoAccounts = <_DemoAccount>[
  _DemoAccount(
    label: 'Admin',
    email: 'demo.admin@fastcheck.app',
    password: 'Demo123!',
    icon: Icons.admin_panel_settings_outlined,
    accentColor: Color(0xFF8E44AD),
  ),
  _DemoAccount(
    label: 'Öğretmen',
    email: 'demo.ogretmen@fastcheck.app',
    password: 'Demo123!',
    icon: Icons.school_outlined,
    accentColor: Color(0xFF1F7A5C),
  ),
  _DemoAccount(
    label: 'Öğrenci 1',
    email: 'demo.ogrenci1@fastcheck.app',
    password: 'Demo123!',
    icon: Icons.person_outlined,
    accentColor: Color(0xFF2563EB),
  ),
  _DemoAccount(
    label: 'Öğrenci 2',
    email: 'demo.ogrenci2@fastcheck.app',
    password: 'Demo123!',
    icon: Icons.person_2_outlined,
    accentColor: Color(0xFF0F766E),
  ),
  _DemoAccount(
    label: 'Veli',
    email: 'demo.veli@fastcheck.app',
    password: 'Demo123!',
    icon: Icons.family_restroom_outlined,
    accentColor: Color(0xFFB45309),
  ),
];

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _pageVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _pageVisible = true);
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

  void _loginWithDemoAccount(_DemoAccount account) {
    _emailController.text = account.email;
    _passwordController.text = account.password;
    context.read<AuthBloc>().add(
          AuthLoginRequested(
            email: account.email,
            password: account.password,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
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
            const _LoginBackground(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Form(
                    key: _formKey,
                    child: AnimatedSlide(
                      duration: _motionDuration,
                      curve: Curves.easeOutCubic,
                      offset: _pageVisible ? Offset.zero : const Offset(0, 0.05),
                      child: AnimatedOpacity(
                        duration: _motionDuration,
                        opacity: _pageVisible ? 1 : 0,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 470),
                          child: Column(
                            children: [
                              const SizedBox(height: 14),
                              const _TopBrandMark(),
                              const SizedBox(height: 18),
                              Text(
                                'Tekrar hos geldin',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1.1,
                                      height: 1.05,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Hesabına giriş yap veya yeni bir hesap oluşturarak devam et.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: const Color(0xFF7B8498),
                                      height: 1.45,
                                    ),
                              ),
                              const SizedBox(height: 24),
                              _buildAuthTabs(),
                              const SizedBox(height: 24),
                              _buildFormCard(),
                            ],
                          ),
                        ),
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

  Widget _buildAuthTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EBF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F1729),
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _AuthTabButton(
              label: 'Giriş Yap',
              isSelected: true,
              onTap: () {},
            ),
          ),
          Expanded(
            child: _AuthTabButton(
              label: 'Kayıt Ol',
              isSelected: false,
              onTap: () => context.go('/auth/register'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F1729),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFormFields(),
          const SizedBox(height: 22),
          _buildLoginButton(),
          const SizedBox(height: 18),
          Center(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                Text(
                  'Hesabın yok mu?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF7B8498),
                      ),
                ),
                GestureDetector(
                  onTap: () => context.go('/auth/register'),
                  child: Text(
                    'Kayıt Ol',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 24),
            _buildDebugSection(context),
          ],
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        _AuthTextField(
          controller: _emailController,
          label: 'E-posta',
          hint: 'ornek@okul.com',
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
        _AuthTextField(
          controller: _passwordController,
          label: 'Şifre',
          hint: '******',
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
        final isLoading = state is AuthLoading;
        return SizedBox(
          height: 58,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: isLoading ? null : AppColors.primaryGradient,
              color: isLoading ? AppColors.textTertiary : null,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x333B4FD8),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: isLoading ? null : _onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Giriş Yap',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDebugSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(color: Color(0xFFE6EAF3)),
        const SizedBox(height: 12),
        Text(
          'Hızlı Giriş (Dev)',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tek dokunuşla gerçek demo hesabına giriş yap.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF98A1B3),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return Column(
              children: [
                for (final account in _demoAccounts) ...[
                  _demoLoginButton(
                    context,
                    account: account,
                    isLoading: isLoading,
                  ),
                  if (account != _demoAccounts.last) const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _demoLoginButton(
    BuildContext context, {
    required _DemoAccount account,
    required bool isLoading,
  }) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        side: BorderSide(color: account.accentColor.withOpacity(0.18)),
        backgroundColor: account.accentColor.withOpacity(0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      icon: Icon(account.icon, size: 18, color: account.accentColor),
      onPressed: isLoading ? null : () => _loginWithDemoAccount(account),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${account.label} olarak gir',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            account.email,
            style: const TextStyle(
              color: Color(0xFF7B8498),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoAccount {
  const _DemoAccount({
    required this.label,
    required this.email,
    required this.password,
    required this.icon,
    required this.accentColor,
  });

  final String label;
  final String email;
  final String password;
  final IconData icon;
  final Color accentColor;
}

class _TopBrandMark extends StatelessWidget {
  const _TopBrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x223B4FD8),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: const Icon(
        Icons.shield_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}

class _AuthTabButton extends StatelessWidget {
  const _AuthTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isSelected
                        ? AppColors.textPrimary
                        : const Color(0xFF8C94A7),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthTextField extends StatefulWidget {
  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.validator,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;

  @override
  State<_AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<_AuthTextField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF7A8295),
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          obscureText: widget.obscureText && _isObscured,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(color: Color(0xFFB1B8C9)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            suffixIcon: widget.obscureText
                ? IconButton(
                    onPressed: () =>
                        setState(() => _isObscured = !_isObscured),
                    icon: Icon(
                      _isObscured
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFFB1B8C9),
                    ),
                  )
                : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFE6EAF2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.4,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: const Color(0xFFF7F8FC)),
          Align(
            alignment: const Alignment(-1.05, -0.8),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Align(
            alignment: const Alignment(1.1, -0.55),
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFF111827).withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Positioned(
            top: 88,
            right: 28,
            child: _OutlineSquare(size: 74),
          ),
          const Positioned(
            top: 138,
            right: 118,
            child: _OutlineSquare(size: 58),
          ),
        ],
      ),
    );
  }
}

class _OutlineSquare extends StatelessWidget {
  const _OutlineSquare({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.14),
        ),
      ),
    );
  }
}
