import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final int id;
  final String email;
  final String role;
  final String accessToken;
  final String refreshToken;

  const UserEntity({
    required this.id,
    required this.email,
    required this.role,
    required this.accessToken,
    required this.refreshToken,
  });

  bool get isTeacher => role == 'ROLE_TEACHER';
  bool get isStudent => role == 'ROLE_STUDENT';
  bool get isParent => role == 'ROLE_PARENT';
  bool get isAdmin => role == 'ROLE_ADMIN';

  @override
  List<Object?> get props => [id, email, role, accessToken, refreshToken];
}
