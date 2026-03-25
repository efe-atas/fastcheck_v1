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

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  _buildHeader(),
                  const SizedBox(height: 48),
                  _buildForm(),
                  const SizedBox(height: 32),
                  _buildLoginButton(),
                  const SizedBox(height: 24),
                  _buildRegisterLink(),
                  if (kDebugMode) ...[
                    const SizedBox(height: 24),
                    _buildDevBypassButton(context),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Hoş Geldiniz',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Hesabınıza giriş yapın',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        AppTextField(
          controller: _emailController,
          label: 'E-posta',
          hint: 'ornek@email.com',
          prefixIcon: Icons.email_outlined,
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
        const SizedBox(height: 20),
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
          'Hesabınız yok mu? ',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        ShadButton.link(
          onPressed: () => context.push('/auth/register'),
          child: const Text('Kayıt Olun'),
        ),
      ],
    );
  }

  /// Debug: API olmadan ana sayfaya (varsayılan öğretmen paneli).
  Widget _buildDevBypassButton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Geliştirici testi',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
        ),
        const SizedBox(height: 8),
        ShadButton.outline(
          leading: const Icon(Icons.home_outlined, size: 20),
          onPressed: () => context.read<AuthBloc>().add(
                const AuthDevBypassRequested(),
              ),
          child: const Text('Ana sayfaya geç (test)'),
        ),
      ],
    );
  }
}
