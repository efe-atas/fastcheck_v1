import 'dart:convert';
import '../../domain/entities/user_entity.dart';

class AuthResponseModel {
  final int userId;
  final String email;
  final String accessToken;
  final String refreshToken;

  const AuthResponseModel({
    required this.userId,
    required this.email,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      userId: json['userId'] as int,
      email: json['email'] as String,
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }

  UserEntity toEntity() {
    final role = _extractRoleFromToken(accessToken);
    return UserEntity(
      id: userId,
      email: email,
      role: role,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  static String _extractRoleFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return 'ROLE_USER';

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(decoded) as Map<String, dynamic>;

      return map['role'] as String? ?? 'ROLE_USER';
    } catch (_) {
      return 'ROLE_USER';
    }
  }
}
