import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/auth_roles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

const _motionDuration = Duration(milliseconds: 650);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _pageVisible = false;
  String _selectedRole = AuthRoles.student;

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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';

      context.read<AuthBloc>().add(
            AuthRegisterRequested(
              fullName: fullName.trim(),
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
            const _RegisterBackground(),
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
                                'Hesabını oluştur',
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
                                'Yeni hesabini olustur veya mevcut hesabinla giris yaparak devam et.',
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
              label: 'Kayıt Ol',
              isSelected: true,
              onTap: () {},
            ),
          ),
          Expanded(
            child: _AuthTabButton(
              label: 'Giriş Yap',
              isSelected: false,
              onTap: () => context.go('/auth/login'),
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
          LayoutBuilder(
            builder: (context, constraints) {
              final useTwoColumns = constraints.maxWidth >= 360;
              if (!useTwoColumns) {
                return Column(
                  children: [
                    _AuthTextField(
                      controller: _firstNameController,
                      label: 'Ad',
                      hint: 'Efe',
                      validator: _requiredNameValidator,
                    ),
                    const SizedBox(height: 18),
                    _AuthTextField(
                      controller: _lastNameController,
                      label: 'Soyad',
                      hint: 'Atas',
                      validator: _requiredNameValidator,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _AuthTextField(
                      controller: _firstNameController,
                      label: 'Ad',
                      hint: 'Efe',
                      validator: _requiredNameValidator,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _AuthTextField(
                      controller: _lastNameController,
                      label: 'Soyad',
                      hint: 'Atas',
                      validator: _requiredNameValidator,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          _AuthTextField(
            controller: _emailController,
            label: 'E-posta',
            hint: 'ornek@okul.com',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'E-posta adresi gerekli';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Geçerli bir e-posta adresi girin';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          _AuthTextField(
            controller: _passwordController,
            label: 'Şifre Belirle',
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
          const SizedBox(height: 18),
          Text(
            'Rol',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF7A8295),
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _RoleChip(
                label: 'Admin',
                isSelected: _selectedRole == AuthRoles.admin,
                onTap: () => setState(() => _selectedRole = AuthRoles.admin),
              ),
              _RoleChip(
                label: 'Öğretmen',
                isSelected: _selectedRole == AuthRoles.teacher,
                onTap: () => setState(() => _selectedRole = AuthRoles.teacher),
              ),
              _RoleChip(
                label: 'Öğrenci',
                isSelected: _selectedRole == AuthRoles.student,
                onTap: () => setState(() => _selectedRole = AuthRoles.student),
              ),
            ],
          ),
          const SizedBox(height: 26),
          _buildRegisterButton(),
          const SizedBox(height: 24),
          Text(
            'Kayıt olarak Hizmet Koşulları ve Veri İşleme Sözleşmesi’ni kabul etmiş olursunuz.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF7B8498),
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
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
              onPressed: isLoading ? null : _onRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
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
                      'Kayıt Ol',
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

  String? _requiredNameValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bu alan zorunlu';
    }
    if (value.trim().length < 2) {
      return 'En az 2 karakter girin';
    }
    return null;
  }
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

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isSelected ? AppColors.primary : const Color(0xFFE5EAF3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
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
    this.validator,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
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
          validator: widget.validator,
          keyboardType: widget.keyboardType,
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

class _RegisterBackground extends StatelessWidget {
  const _RegisterBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: const Color(0xFFF7F8FC)),
          Align(
            alignment: const Alignment(-1.15, -0.75),
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Positioned(
            top: 82,
            right: 24,
            child: _OutlineSquare(size: 76),
          ),
          const Positioned(
            top: 122,
            right: 118,
            child: _OutlineSquare(size: 92),
          ),
          const Positioned(
            top: 170,
            right: 36,
            child: _OutlineSquare(size: 60),
          ),
          const Positioned(
            top: 34,
            right: 150,
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
