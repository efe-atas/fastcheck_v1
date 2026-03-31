import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/entities/admin_entities.dart';
import '../cubit/admin_cubit.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _schoolNameCtrl = TextEditingController();
  final _newUserNameCtrl = TextEditingController();
  final _newUserEmailCtrl = TextEditingController();
  final _newUserPasswordCtrl = TextEditingController();
  final _newUserSchoolIdCtrl = TextEditingController();
  final _newUserClassIdCtrl = TextEditingController();
  final _assignUserSearchCtrl = TextEditingController();
  final _assignSchoolSearchCtrl = TextEditingController();
  final _parentSearchCtrl = TextEditingController();
  final _studentSearchCtrl = TextEditingController();
  final _listParentSearchCtrl = TextEditingController();
  String _newUserRole = 'ROLE_TEACHER';

  Timer? _assignUserDebounce;
  Timer? _assignSchoolDebounce;
  Timer? _parentDebounce;
  Timer? _studentDebounce;
  Timer? _listParentDebounce;

  @override
  void initState() {
    super.initState();
    _assignUserSearchCtrl.addListener(_onAssignUserSearchChanged);
    _assignSchoolSearchCtrl.addListener(_onAssignSchoolSearchChanged);
    _parentSearchCtrl.addListener(_onParentSearchChanged);
    _studentSearchCtrl.addListener(_onStudentSearchChanged);
    _listParentSearchCtrl.addListener(_onListParentSearchChanged);
  }

  @override
  void dispose() {
    _assignUserDebounce?.cancel();
    _assignSchoolDebounce?.cancel();
    _parentDebounce?.cancel();
    _studentDebounce?.cancel();
    _listParentDebounce?.cancel();
    _schoolNameCtrl.dispose();
    _newUserNameCtrl.dispose();
    _newUserEmailCtrl.dispose();
    _newUserPasswordCtrl.dispose();
    _newUserSchoolIdCtrl.dispose();
    _newUserClassIdCtrl.dispose();
    _assignUserSearchCtrl.dispose();
    _assignSchoolSearchCtrl.dispose();
    _parentSearchCtrl.dispose();
    _studentSearchCtrl.dispose();
    _listParentSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<AdminCubit, AdminState>(
        listenWhen: (prev, curr) =>
            curr.errorMessage != null && prev.errorMessage != curr.errorMessage,
        listener: (context, state) {
          showAppToast(
            context,
            message: state.errorMessage!,
            destructive: true,
          );
        },
        builder: (context, state) {
          return Stack(
            children: [
              ListView(
                padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, 110),
                children: [
                  Text(
                    'Yönetim',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 20),
                  if (state.lastSuccessMessage != null) ...[
                    _successBanner(
                      context,
                      message: state.lastSuccessMessage!,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildCreateSchoolSection(context, state),
                  const SizedBox(height: 20),
                  _buildCreateUserSection(context, state),
                  const SizedBox(height: 20),
                  _buildAssignUserSection(context, state),
                  const SizedBox(height: 20),
                  _buildLinkParentStudentSection(context, state),
                  const SizedBox(height: 20),
                  _buildListParentStudentsSection(context, state),
                  const SizedBox(height: 20),
                  _buildBulkAssignSection(context, state),
                  const SizedBox(height: 20),
                  _buildBulkLinkSection(context, state),
                ],
              ),
              if (state.isLoading) const LinearProgressIndicator(minHeight: 3),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCreateSchoolSection(BuildContext context, AdminState state) {
    return _section(
      title: 'Okul oluştur',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Okul adı',
            style: ShadTheme.of(context).textTheme.large,
          ),
          const SizedBox(height: 6),
          ShadInput(
            controller: _schoolNameCtrl,
            placeholder: const Text('Okul adı'),
          ),
          const SizedBox(height: 12),
          ShadButton(
            onPressed: state.isLoading
                ? null
                : () {
                    final name = _schoolNameCtrl.text.trim();
                    if (name.length < 2) {
                      showAppToast(
                        context,
                        message: 'Okul adı en az 2 karakter',
                      );
                      return;
                    }
                    context.read<AdminCubit>().onCreateSchool(name);
                  },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateUserSection(BuildContext context, AdminState state) {
    const roleOptions = <String, String>{
      'ROLE_TEACHER': 'Öğretmen',
      'ROLE_STUDENT': 'Öğrenci',
      'ROLE_PARENT': 'Veli',
      'ROLE_ADMIN': 'Admin',
    };

    return _section(
      title: 'Yeni kullanıcı oluştur',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Ad Soyad', style: ShadTheme.of(context).textTheme.large),
          const SizedBox(height: 6),
          ShadInput(
            controller: _newUserNameCtrl,
            placeholder: const Text('Örn. Ayşe Öğretmen'),
          ),
          const SizedBox(height: 12),
          Text('E-posta', style: ShadTheme.of(context).textTheme.large),
          const SizedBox(height: 6),
          ShadInput(
            controller: _newUserEmailCtrl,
            placeholder: const Text('ornek@fastcheck.app'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          Text('Rol', style: ShadTheme.of(context).textTheme.large),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            key: ValueKey(_newUserRole),
            initialValue: _newUserRole,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: roleOptions.entries
                .map(
                  (entry) => DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _newUserRole = value;
              });
            },
          ),
          const SizedBox(height: 12),
          Text('Opsiyonel: Şifre (boş bırakırsanız sistem üretir)',
              style: ShadTheme.of(context).textTheme.muted),
          const SizedBox(height: 6),
          ShadInput(
            controller: _newUserPasswordCtrl,
            placeholder: const Text('En az 8 karakter'),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          Text('Opsiyonel: Okul ID',
              style: ShadTheme.of(context).textTheme.muted),
          const SizedBox(height: 6),
          ShadInput(
            controller: _newUserSchoolIdCtrl,
            placeholder: const Text('Örn. 12'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          Text('Opsiyonel: Sınıf ID (öğrenci için)',
              style: ShadTheme.of(context).textTheme.muted),
          const SizedBox(height: 6),
          ShadInput(
            controller: _newUserClassIdCtrl,
            placeholder: const Text('Örn. 34'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          ShadButton(
            onPressed: state.isLoading ? null : () => _submitNewUser(context),
            child: const Text('Kullanıcı oluştur'),
          ),
          if (state.lastProvisionedUser != null) ...[
            const SizedBox(height: 12),
            _provisionedUserCard(context, state.lastProvisionedUser!),
          ],
        ],
      ),
    );
  }

  Widget _buildAssignUserSection(BuildContext context, AdminState state) {
    return _section(
      title: 'Kullanıcıyı okula ata (ID’siz)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Kullanıcı (e-posta/ad ile ara)',
            style: ShadTheme.of(context).textTheme.large,
          ),
          const SizedBox(height: 6),
          ShadInput(
            controller: _assignUserSearchCtrl,
            placeholder: const Text('ornek@email.com'),
          ),
          const SizedBox(height: 8),
          _resultList<AdminUserSummaryEntity>(
            items: state.assignableUsers,
            onTap: (item) =>
                context.read<AdminCubit>().selectAssignableUser(item),
            itemBuilder: (e) => '${e.fullName} · ${e.email} · ${e.role}',
          ),
          const SizedBox(height: 10),
          Text(
            state.selectedUser == null
                ? 'Seçili kullanıcı: -'
                : 'Seçili kullanıcı: ${state.selectedUser!.fullName} (${state.selectedUser!.email})',
            style: ShadTheme.of(context).textTheme.muted,
          ),
          const SizedBox(height: 12),
          Text(
            'Okul ara',
            style: ShadTheme.of(context).textTheme.large,
          ),
          const SizedBox(height: 6),
          ShadInput(
            controller: _assignSchoolSearchCtrl,
            placeholder: const Text('Okul adı'),
          ),
          const SizedBox(height: 8),
          _resultList<AdminSchoolSummaryEntity>(
            items: state.schoolOptions,
            onTap: (item) => context.read<AdminCubit>().selectSchool(item),
            itemBuilder: (e) => e.schoolName,
          ),
          const SizedBox(height: 10),
          Text(
            state.selectedSchool == null
                ? 'Seçili okul: -'
                : 'Seçili okul: ${state.selectedSchool!.schoolName}',
            style: ShadTheme.of(context).textTheme.muted,
          ),
          const SizedBox(height: 12),
          ShadButton(
            onPressed: state.isLoading
                ? null
                : () => context.read<AdminCubit>().onAssignSelectedUser(),
            child: const Text('Seçili kullanıcıyı ata'),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkParentStudentSection(
      BuildContext context, AdminState state) {
    return _section(
      title: 'Veli — öğrenci bağla (ID’siz)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Veli ara (e-posta/ad)',
            style: ShadTheme.of(context).textTheme.large,
          ),
          const SizedBox(height: 6),
          ShadInput(
            controller: _parentSearchCtrl,
            placeholder: const Text('veli@email.com'),
          ),
          const SizedBox(height: 8),
          _resultList<AdminUserSummaryEntity>(
            items: state.parentOptions,
            onTap: (item) => context.read<AdminCubit>().selectParent(item),
            itemBuilder: (e) => '${e.fullName} · ${e.email}',
          ),
          const SizedBox(height: 10),
          Text(
            state.selectedParent == null
                ? 'Seçili veli: -'
                : 'Seçili veli: ${state.selectedParent!.fullName}',
            style: ShadTheme.of(context).textTheme.muted,
          ),
          const SizedBox(height: 12),
          Text(
            'Öğrenci ara (e-posta/ad)',
            style: ShadTheme.of(context).textTheme.large,
          ),
          const SizedBox(height: 6),
          ShadInput(
            controller: _studentSearchCtrl,
            placeholder: const Text('ogrenci@email.com'),
          ),
          const SizedBox(height: 8),
          _resultList<AdminUserSummaryEntity>(
            items: state.studentOptions,
            onTap: (item) => context.read<AdminCubit>().selectStudent(item),
            itemBuilder: (e) => '${e.fullName} · ${e.email}',
          ),
          const SizedBox(height: 10),
          Text(
            state.selectedStudent == null
                ? 'Seçili öğrenci: -'
                : 'Seçili öğrenci: ${state.selectedStudent!.fullName}',
            style: ShadTheme.of(context).textTheme.muted,
          ),
          const SizedBox(height: 12),
          ShadButton(
            onPressed: state.isLoading
                ? null
                : () =>
                    context.read<AdminCubit>().onLinkSelectedParentStudent(),
            child: const Text('Seçili veli-öğrenciyi bağla'),
          ),
        ],
      ),
    );
  }

  Widget _buildListParentStudentsSection(
      BuildContext context, AdminState state) {
    return _section(
      title: 'Veliye bağlı öğrencileri listele',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Veli ara',
            style: ShadTheme.of(context).textTheme.large,
          ),
          const SizedBox(height: 6),
          ShadInput(
            controller: _listParentSearchCtrl,
            placeholder: const Text('veli@email.com'),
          ),
          const SizedBox(height: 8),
          _resultList<AdminUserSummaryEntity>(
            items: state.parentOptions,
            onTap: (item) => context.read<AdminCubit>().selectParent(item),
            itemBuilder: (e) => '${e.fullName} · ${e.email}',
          ),
          const SizedBox(height: 10),
          ShadButton(
            onPressed: state.isLoading || state.selectedParent == null
                ? null
                : () => context
                    .read<AdminCubit>()
                    .onListParentStudents(state.selectedParent!.userId),
            child: const Text('Listele'),
          ),
          if (state.listedStudents != null) ...[
            const SizedBox(height: 16),
            ...state.listedStudents!.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ShadCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.fullName,
                        style: ShadTheme.of(context).textTheme.h4,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${e.email}${e.classId != null ? ' · sınıf: ${e.classId}' : ''}',
                        style: ShadTheme.of(context).textTheme.muted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBulkAssignSection(BuildContext context, AdminState state) {
    return _section(
      title: 'Toplu kullanıcı-okul atama (CSV)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Format: userEmail,schoolName',
            style: ShadTheme.of(context).textTheme.muted,
          ),
          const SizedBox(height: 10),
          ShadButton.outline(
            onPressed: state.isLoading
                ? null
                : () => _pickCsvAndUpload(
                      onPicked: (bytes, name) => context
                          .read<AdminCubit>()
                          .onBulkAssignUsersToSchools(
                              fileBytes: bytes, fileName: name),
                    ),
            child: const Text('CSV seç ve yükle'),
          ),
          if (state.lastBulkResult != null) ...[
            const SizedBox(height: 12),
            _buildBulkResult(context, state.lastBulkResult!),
          ],
        ],
      ),
    );
  }

  Widget _buildBulkLinkSection(BuildContext context, AdminState state) {
    return _section(
      title: 'Toplu veli-öğrenci bağlama (CSV)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Format: parentEmail,studentEmail',
            style: ShadTheme.of(context).textTheme.muted,
          ),
          const SizedBox(height: 10),
          ShadButton.outline(
            onPressed: state.isLoading
                ? null
                : () => _pickCsvAndUpload(
                      onPicked: (bytes, name) => context
                          .read<AdminCubit>()
                          .onBulkLinkParentStudents(
                              fileBytes: bytes, fileName: name),
                    ),
            child: const Text('CSV seç ve yükle'),
          ),
          if (state.lastBulkResult != null) ...[
            const SizedBox(height: 12),
            _buildBulkResult(context, state.lastBulkResult!),
          ],
        ],
      ),
    );
  }

  Widget _successBanner(BuildContext context, {required String message}) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => context.read<AdminCubit>().dismissNotifications(),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildBulkResult(
      BuildContext context, AdminBulkOperationEntity result) {
    return ShadCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'İşlenen: ${result.processed} · Başarılı: ${result.success} · Hatalı: ${result.failed}',
            style: ShadTheme.of(context).textTheme.small,
          ),
          if (result.errors.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...result.errors.take(5).map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Satır ${e.rowNumber}: ${e.message}',
                      style: ShadTheme.of(context).textTheme.muted,
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _resultList<T>({
    required List<T> items,
    required void Function(T item) onTap,
    required String Function(T item) itemBuilder,
  }) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            dense: true,
            title: Text(itemBuilder(item)),
            onTap: () => onTap(item),
          );
        },
      ),
    );
  }

  Future<void> _pickCsvAndUpload({
    required Future<void> Function(List<int> bytes, String fileName) onPicked,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      withData: true,
    );
    if (!mounted || result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      showAppToast(context, message: 'Dosya okunamadı', destructive: true);
      return;
    }
    await onPicked(bytes, file.name);
  }

  void _onAssignUserSearchChanged() {
    _assignUserDebounce?.cancel();
    _assignUserDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context
          .read<AdminCubit>()
          .onSearchAssignableUsers(_assignUserSearchCtrl.text);
    });
  }

  void _onAssignSchoolSearchChanged() {
    _assignSchoolDebounce?.cancel();
    _assignSchoolDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.read<AdminCubit>().onSearchSchools(_assignSchoolSearchCtrl.text);
    });
  }

  void _onParentSearchChanged() {
    _parentDebounce?.cancel();
    _parentDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.read<AdminCubit>().onSearchParents(_parentSearchCtrl.text);
    });
  }

  void _onStudentSearchChanged() {
    _studentDebounce?.cancel();
    _studentDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.read<AdminCubit>().onSearchStudents(_studentSearchCtrl.text);
    });
  }

  void _onListParentSearchChanged() {
    _listParentDebounce?.cancel();
    _listParentDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.read<AdminCubit>().onSearchParents(_listParentSearchCtrl.text);
    });
  }

  void _submitNewUser(BuildContext context) {
    final fullName = _newUserNameCtrl.text.trim();
    final email = _newUserEmailCtrl.text.trim();
    if (fullName.length < 3) {
      showAppToast(context, message: 'Ad soyad en az 3 karakter olmalı');
      return;
    }
    if (!email.contains('@')) {
      showAppToast(context, message: 'Geçerli bir e-posta girin');
      return;
    }
    final password = _newUserPasswordCtrl.text.trim();
    final schoolText = _newUserSchoolIdCtrl.text.trim();
    final classText = _newUserClassIdCtrl.text.trim();
    int? schoolId;
    if (schoolText.isNotEmpty) {
      schoolId = int.tryParse(schoolText);
      if (schoolId == null) {
        showAppToast(context,
            message: 'Okul ID yalnızca sayı olmalıdır', destructive: true);
        return;
      }
    }
    int? classId;
    if (classText.isNotEmpty) {
      classId = int.tryParse(classText);
      if (classId == null) {
        showAppToast(context,
            message: 'Sınıf ID yalnızca sayı olmalıdır', destructive: true);
        return;
      }
    }
    context.read<AdminCubit>().onCreateUser(
          fullName: fullName,
          email: email,
          role: _newUserRole,
          password: password.isEmpty ? null : password,
          schoolId: schoolId,
          classId: classId,
        );
  }

  Widget _provisionedUserCard(
    BuildContext context,
    AdminProvisionedUserEntity user,
  ) {
    final roleLabel = user.role.replaceFirst('ROLE_', '');
    final theme = ShadTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${user.fullName} ($roleLabel)',
            style: theme.textTheme.large.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(user.email, style: theme.textTheme.muted),
          if (user.hasInitialPassword) ...[
            const SizedBox(height: 8),
            Text(
              'Geçici şifre: ${user.initialPassword}',
              style: theme.textTheme.small.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'İlk girişte değiştirmesini isteyin.',
              style: theme.textTheme.muted.copyWith(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: title),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
