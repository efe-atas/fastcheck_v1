import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/teacher_entities.dart';

abstract class TeacherRepository {
  Future<Either<Failure, List<ClassEntity>>> getClasses();

  Future<Either<Failure, List<ExamEntity>>> getClassExams(int classId);

  Future<Either<Failure, PagedResult<StudentEntity>>> getClassStudents(
    int classId, {
    int page = 0,
    int size = 20,
  });

  Future<Either<Failure, ClassEntity>> createClass({
    required int schoolId,
    required String className,
  });

  Future<Either<Failure, ExamEntity>> createExam({
    required int classId,
    required String title,
  });

  Future<Either<Failure, List<ExamImageEntity>>> uploadExamImages({
    required int examId,
    required List<File> images,
  });

  Future<Either<Failure, ExamStatusEntity>> getExamStatus(int examId);

  Future<Either<Failure, StudentEntity>> addStudentToClass({
    required int classId,
    required String fullName,
    required String email,
    required String password,
  });
}
