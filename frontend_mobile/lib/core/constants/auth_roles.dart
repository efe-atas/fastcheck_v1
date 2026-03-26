/// API ve [UserEntity.role] ile uyumlu rol sabitleri.
abstract final class AuthRoles {
  AuthRoles._();

  static const student = 'ROLE_STUDENT';
  static const teacher = 'ROLE_TEACHER';
  static const admin = 'ROLE_ADMIN';
}
