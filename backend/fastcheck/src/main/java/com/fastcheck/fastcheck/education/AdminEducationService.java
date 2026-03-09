package com.fastcheck.fastcheck.education;

import com.fastcheck.fastcheck.common.ApiException;
import com.fastcheck.fastcheck.user.Role;
import com.fastcheck.fastcheck.user.UserAccount;
import com.fastcheck.fastcheck.user.UserRepository;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AdminEducationService {

    private final EducationAccessService accessService;
    private final SchoolRepository schoolRepository;
    private final UserRepository userRepository;
    private final ParentStudentLinkRepository parentStudentLinkRepository;

    public AdminEducationService(
            EducationAccessService accessService,
            SchoolRepository schoolRepository,
            UserRepository userRepository,
            ParentStudentLinkRepository parentStudentLinkRepository
    ) {
        this.accessService = accessService;
        this.schoolRepository = schoolRepository;
        this.userRepository = userRepository;
        this.parentStudentLinkRepository = parentStudentLinkRepository;
    }

    @Transactional
    public EducationDtos.SchoolResponse createSchool(EducationDtos.CreateSchoolRequest request) {
        accessService.requireRole(Role.ROLE_ADMIN);

        String schoolName = request.schoolName().trim();
        if (schoolName.isEmpty()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "school name cannot be empty");
        }
        if (schoolRepository.findByNameIgnoreCase(schoolName).isPresent()) {
            throw new ApiException(HttpStatus.CONFLICT, "school already exists");
        }

        School school = new School();
        school.setName(schoolName);
        school = schoolRepository.save(school);

        return new EducationDtos.SchoolResponse(school.getId(), school.getName(), school.getCreatedAt());
    }

    @Transactional
    public EducationDtos.StudentResponse assignUserToSchool(Long userId, Long schoolId) {
        accessService.requireRole(Role.ROLE_ADMIN);

        UserAccount user = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "user not found"));
        School school = schoolRepository.findById(schoolId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "school not found"));

        user.setSchool(school);
        if (user.getRole() != Role.ROLE_STUDENT) {
            user.setSchoolClass(null);
        }
        user = userRepository.save(user);

        return new EducationDtos.StudentResponse(
                user.getId(),
                user.getFullName(),
                user.getEmail(),
                user.getRole().name(),
                user.getSchoolClass() == null ? null : user.getSchoolClass().getId(),
                null
        );
    }

    @Transactional
    public EducationDtos.ParentStudentLinkResponse linkParentStudent(EducationDtos.ParentStudentLinkRequest request) {
        accessService.requireRole(Role.ROLE_ADMIN);

        UserAccount parent = userRepository.findById(request.parentUserId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "parent user not found"));
        UserAccount student = userRepository.findById(request.studentUserId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "student user not found"));

        if (parent.getRole() != Role.ROLE_PARENT) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "parentUserId must belong to ROLE_PARENT");
        }
        if (student.getRole() != Role.ROLE_STUDENT) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "studentUserId must belong to ROLE_STUDENT");
        }
        if (parentStudentLinkExists(parent.getId(), student.getId())) {
            throw new ApiException(HttpStatus.CONFLICT, "parent-student link already exists");
        }

        ParentStudentLink link = new ParentStudentLink();
        link.setParent(parent);
        link.setStudent(student);
        link = parentStudentLinkRepository.save(link);

        return new EducationDtos.ParentStudentLinkResponse(
                link.getId(),
                parent.getId(),
                student.getId(),
                link.getCreatedAt()
        );
    }

    private boolean parentStudentLinkExists(Long parentId, Long studentId) {
        return parentStudentLinkRepository.existsByParent_IdAndStudent_Id(parentId, studentId);
    }

    @Transactional(readOnly = true)
    public List<EducationDtos.ParentStudentView> listParentStudents(Long parentUserId) {
        accessService.requireRole(Role.ROLE_ADMIN);

        UserAccount parent = userRepository.findById(parentUserId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "parent user not found"));
        if (parent.getRole() != Role.ROLE_PARENT) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "parentUserId must belong to ROLE_PARENT");
        }

        return parentStudentLinkRepository.findByParent_IdOrderByCreatedAtDesc(parentUserId)
                .stream()
                .map(link -> new EducationDtos.ParentStudentView(
                        link.getStudent().getId(),
                        link.getStudent().getFullName(),
                        link.getStudent().getEmail(),
                        link.getStudent().getSchoolClass() == null ? null : link.getStudent().getSchoolClass().getId()
                ))
                .toList();
    }
}
