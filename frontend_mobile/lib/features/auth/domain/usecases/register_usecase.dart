import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase extends UseCase<UserEntity, RegisterParams> {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(RegisterParams params) {
    return repository.register(
      fullName: params.fullName,
      email: params.email,
      password: params.password,
      role: params.role,
    );
  }
}

class RegisterParams extends Equatable {
  final String fullName;
  final String email;
  final String password;
  final String role;

  const RegisterParams({
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
  });

  @override
  List<Object?> get props => [fullName, email, password, role];
}
