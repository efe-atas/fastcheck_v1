import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/liquid_glass_bottom_bar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../cubit/admin_cubit.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _schoolNameCtrl = TextEditingController();
  final _assignUserIdCtrl = TextEditingController();
  final _assignSchoolIdCtrl = TextEditingController();
  final _linkParentCtrl = TextEditingController();
  final _linkStudentCtrl = TextEditingController();
  final _listParentCtrl = TextEditingController();

  @override
  void dispose() {
    _schoolNameCtrl.dispose();
    _assignUserIdCtrl.dispose();
    _assignSchoolIdCtrl.dispose();
    _linkParentCtrl.dispose();
    _linkStudentCtrl.dispose();
    _listParentCtrl.dispose();
    super.dispose();
  }

  int? _parseId(String s, String label) {
    final v = s.trim();
    if (v.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label gerekli')),
      );
      return null;
    }
    final n = int.tryParse(v);
    if (n == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label sayı olmalı')),
      );
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Yönetim'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: BlocConsumer<AdminCubit, AdminState>(
        listenWhen: (prev, curr) =>
            curr.errorMessage != null && prev.errorMessage != curr.errorMessage,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
        },
        builder: (context, state) {
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                children: [
                  if (state.lastSuccessMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.success),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              color: AppColors.success, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.lastSuccessMessage!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () =>
                                context.read<AdminCubit>().dismissNotifications(),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                  ],
                  _section(
                    title: 'Okul oluştur',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _schoolNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Okul adı',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: state.isLoading
                              ? null
                              : () {
                                  final name = _schoolNameCtrl.text.trim();
                                  if (name.length < 2) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Okul adı en az 2 karakter'),
                                      ),
                                    );
                                    return;
                                  }
                                  context
                                      .read<AdminCubit>()
                                      .onCreateSchool(name);
                                },
                          child: const Text('Oluştur'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _section(
                    title: 'Kullanıcıyı okula ata',
                    child: Column(
                      children: [
                        TextField(
                          controller: _assignUserIdCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Kullanıcı ID',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _assignSchoolIdCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Okul ID',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: state.isLoading
                              ? null
                              : () {
                                  final uid = _parseId(
                                    _assignUserIdCtrl.text,
                                    'Kullanıcı ID',
                                  );
                                  final sid = _parseId(
                                    _assignSchoolIdCtrl.text,
                                    'Okul ID',
                                  );
                                  if (uid == null || sid == null) return;
                                  context
                                      .read<AdminCubit>()
                                      .onAssignUser(uid, sid);
                                },
                          child: const Text('Ata'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _section(
                    title: 'Veli — öğrenci bağla',
                    child: Column(
                      children: [
                        TextField(
                          controller: _linkParentCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Veli kullanıcı ID',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _linkStudentCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Öğrenci kullanıcı ID',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: state.isLoading
                              ? null
                              : () {
                                  final p = _parseId(
                                    _linkParentCtrl.text,
                                    'Veli ID',
                                  );
                                  final s = _parseId(
                                    _linkStudentCtrl.text,
                                    'Öğrenci ID',
                                  );
                                  if (p == null || s == null) return;
                                  context
                                      .read<AdminCubit>()
                                      .onLinkParentStudent(p, s);
                                },
                          child: const Text('Bağla'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _section(
                    title: 'Veliye bağlı öğrencileri listele',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _listParentCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Veli kullanıcı ID',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: state.isLoading
                              ? null
                              : () {
                                  final id = _parseId(
                                    _listParentCtrl.text,
                                    'Veli ID',
                                  );
                                  if (id == null) return;
                                  context
                                      .read<AdminCubit>()
                                      .onListParentStudents(id);
                                },
                          child: const Text('Listele'),
                        ),
                        if (state.listedStudents != null) ...[
                          const SizedBox(height: 16),
                          ...state.listedStudents!.map(
                            (e) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(e.fullName),
                                subtitle: Text(
                                  '${e.email}${e.classId != null ? ' · sınıf: ${e.classId}' : ''}',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (state.isLoading)
                const LinearProgressIndicator(minHeight: 3),
            ],
          );
        },
      ),
      bottomNavigationBar: LiquidGlassBottomBar(
        items: [
          LiquidGlassBarItem(
            icon: Icons.admin_panel_settings_outlined,
            label: 'Yönetim',
            selected: true,
            onTap: () {},
          ),
          LiquidGlassBarItem(
            icon: Icons.document_scanner_outlined,
            label: 'OCR',
            onTap: () => context.push('/ocr'),
          ),
          LiquidGlassBarItem(
            icon: Icons.logout_rounded,
            label: 'Çıkış',
            onTap: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
