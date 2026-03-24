import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/domain/paged_result.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/teacher_entities.dart';
import '../repositories/teacher_repository.dart';

class GetClasses implements UseCase<List<ClassEntity>, NoParams> {
  final TeacherRepository repository;

  const GetClasses(this.repository);

  @override
  Future<Either<Failure, List<ClassEntity>>> call(NoParams params) {
    return repository.getClasses();
  }
}

class GetClassExams implements UseCase<List<ExamEntity>, int> {
  final TeacherRepository repository;

  const GetClassExams(this.repository);

  @override
  Future<Either<Failure, List<ExamEntity>>> call(int classId) {
    return repository.getClassExams(classId);
  }
}

class GetClassStudentsParams extends Equatable {
  final int classId;
  final int page;
  final int size;
  final String? name;

  const GetClassStudentsParams({
    required this.classId,
    this.page = 0,
    this.size = 20,
    this.name,
  });

  @override
  List<Object?> get props => [classId, page, size, name];
}

class GetClassStudents
    implements UseCase<PagedResult<StudentEntity>, GetClassStudentsParams> {
  final TeacherRepository repository;

  const GetClassStudents(this.repository);

  @override
  Future<Either<Failure, PagedResult<StudentEntity>>> call(
    GetClassStudentsParams params,
  ) {
    return repository.getClassStudents(
      params.classId,
      page: params.page,
      size: params.size,
      name: params.name,
    );
  }
}

class CreateClassParams extends Equatable {
  final int schoolId;
  final String className;

  const CreateClassParams({required this.schoolId, required this.className});

  @override
  List<Object?> get props => [schoolId, className];
}

class CreateClass implements UseCase<ClassEntity, CreateClassParams> {
  final TeacherRepository repository;

  const CreateClass(this.repository);

  @override
  Future<Either<Failure, ClassEntity>> call(CreateClassParams params) {
    return repository.createClass(
      schoolId: params.schoolId,
      className: params.className,
    );
  }
}

class CreateExamParams extends Equatable {
  final int classId;
  final String title;

  const CreateExamParams({required this.classId, required this.title});

  @override
  List<Object?> get props => [classId, title];
}

class CreateExam implements UseCase<ExamEntity, CreateExamParams> {
  final TeacherRepository repository;

  const CreateExam(this.repository);

  @override
  Future<Either<Failure, ExamEntity>> call(CreateExamParams params) {
    return repository.createExam(
      classId: params.classId,
      title: params.title,
    );
  }
}

class UploadExamImagesParams extends Equatable {
  final int examId;
  final List<File> images;

  const UploadExamImagesParams({required this.examId, required this.images});

  @override
  List<Object?> get props => [examId, images];
}

class UploadExamImages
    implements UseCase<List<ExamImageEntity>, UploadExamImagesParams> {
  final TeacherRepository repository;

  const UploadExamImages(this.repository);

  @override
  Future<Either<Failure, List<ExamImageEntity>>> call(
    UploadExamImagesParams params,
  ) {
    return repository.uploadExamImages(
      examId: params.examId,
      images: params.images,
    );
  }
}

class GetExamStatus implements UseCase<ExamStatusEntity, int> {
  final TeacherRepository repository;

  const GetExamStatus(this.repository);

  @override
  Future<Either<Failure, ExamStatusEntity>> call(int examId) {
    return repository.getExamStatus(examId);
  }
}

class AddStudentParams extends Equatable {
  final int classId;
  final String fullName;
  final String email;
  final String password;

  const AddStudentParams({
    required this.classId,
    required this.fullName,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [classId, fullName, email, password];
}

class AddStudentToClass implements UseCase<StudentEntity, AddStudentParams> {
  final TeacherRepository repository;

  const AddStudentToClass(this.repository);

  @override
  Future<Either<Failure, StudentEntity>> call(AddStudentParams params) {
    return repository.addStudentToClass(
      classId: params.classId,
      fullName: params.fullName,
      email: params.email,
      password: params.password,
    );
  }
}
