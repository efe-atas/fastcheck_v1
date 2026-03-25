import 'dart:convert';
import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorage secureStorage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorage,
  });

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await remoteDataSource.login(
        email: email,
        password: password,
      );
      final entity = response.toEntity();
      await _persistAuth(entity);
      return Right(entity);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return const Left(ServerFailure('Giriş yapılırken bir hata oluştu'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await remoteDataSource.register(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
      );
      final entity = response.toEntity();
      await _persistAuth(entity);
      return Right(entity);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return const Left(ServerFailure('Kayıt olurken bir hata oluştu'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> refreshToken() async {
    try {
      final storedRefreshToken = await secureStorage.refreshToken;
      if (storedRefreshToken == null) {
        return const Left(UnauthorizedFailure());
      }
      final response =
          await remoteDataSource.refreshToken(storedRefreshToken);
      final entity = response.toEntity();
      await _persistAuth(entity);
      return Right(entity);
    } on ServerException catch (e) {
      await secureStorage.clearAll();
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return const Left(UnauthorizedFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> tryAutoLogin() async {
    try {
      final hasTokens = await secureStorage.hasTokens;
      if (!hasTokens) return const Left(AuthFailure('Oturum bulunamadı'));

      final token = await secureStorage.accessToken;
      final refreshTokenVal = await secureStorage.refreshToken;
      final email = await secureStorage.userEmail;
      final role = await secureStorage.userRole;
      final userId = await secureStorage.userId;

      if (token == null || refreshTokenVal == null || email == null ||
          role == null || userId == null) {
        return const Left(AuthFailure('Oturum bilgileri eksik'));
      }

      if (_isTokenExpired(token)) {
        return refreshToken();
      }

      return Right(UserEntity(
        id: userId,
        email: email,
        role: role,
        accessToken: token,
        refreshToken: refreshTokenVal,
      ));
    } catch (e) {
      return const Left(AuthFailure('Otomatik giriş başarısız'));
    }
  }

  @override
  Future<void> logout() async {
    await secureStorage.clearAll();
  }

  Future<void> _persistAuth(UserEntity entity) async {
    await Future.wait([
      secureStorage.saveTokens(
        accessToken: entity.accessToken,
        refreshToken: entity.refreshToken,
      ),
      secureStorage.saveUserInfo(
        userId: entity.id,
        email: entity.email,
        role: entity.role,
      ),
    ]);
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final exp = map['exp'] as int?;
      if (exp == null) return true;
      final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expDate.subtract(const Duration(minutes: 1)));
    } catch (_) {
      return true;
    }
  }
}
