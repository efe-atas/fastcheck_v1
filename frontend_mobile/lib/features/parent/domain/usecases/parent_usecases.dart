import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/parent_entities.dart';
import '../repositories/parent_repository.dart';

class GetLinkedStudents extends UseCase<List<LinkedStudentEntity>, int> {
  final ParentRepository repository;

  GetLinkedStudents(this.repository);

  @override
  Future<Either<Failure, List<LinkedStudentEntity>>> call(int parentUserId) {
    return repository.getLinkedStudents(parentUserId);
  }
}

class GetStudentExamQuestions
    extends UseCase<List<ParentQuestionEntity>, StudentExamParams> {
  final ParentRepository repository;

  GetStudentExamQuestions(this.repository);

  @override
  Future<Either<Failure, List<ParentQuestionEntity>>> call(
      StudentExamParams params) {
    return repository.getStudentExamQuestions(params.studentId, params.examId);
  }
}

class StudentExamParams extends Equatable {
  final int studentId;
  final int examId;

  const StudentExamParams({required this.studentId, required this.examId});

  @override
  List<Object?> get props => [studentId, examId];
}
