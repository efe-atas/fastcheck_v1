package com.fastcheck.fastcheck.education;

import com.fastcheck.fastcheck.common.ApiException;
import com.fastcheck.fastcheck.user.Role;
import com.fastcheck.fastcheck.user.UserAccount;
import com.fastcheck.fastcheck.user.UserRepository;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

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

        return assignUserToSchoolInternal(user, school);
    }

    @Transactional(readOnly = true)
    public EducationDtos.PagedResponse<EducationDtos.AdminUserSummary> listUsers(
            String role,
            String q,
            int page,
            int size
    ) {
        accessService.requireRole(Role.ROLE_ADMIN);
        Role parsedRole = parseRole(role);
        String query = normalizeQuery(q);
        Pageable pageable = toPageable(page, size);

        Page<UserAccount> users = userRepository.searchAdminUsers(parsedRole, query, pageable);
        List<EducationDtos.AdminUserSummary> items = users.getContent().stream()
                .map(user -> new EducationDtos.AdminUserSummary(
                        user.getId(),
                        user.getFullName(),
                        user.getEmail(),
                        user.getRole().name(),
                        user.getSchool() == null ? null : user.getSchool().getId(),
                        user.getSchoolClass() == null ? null : user.getSchoolClass().getId()
                ))
                .toList();

        return new EducationDtos.PagedResponse<>(
                items,
                users.getNumber(),
                users.getSize(),
                users.getTotalElements(),
                users.getTotalPages()
        );
    }

    @Transactional(readOnly = true)
    public EducationDtos.PagedResponse<EducationDtos.AdminSchoolSummary> listSchools(
            String q,
            int page,
            int size
    ) {
        accessService.requireRole(Role.ROLE_ADMIN);
        String query = normalizeQuery(q);
        Pageable pageable = toPageable(page, size);

        Page<School> schools = schoolRepository.searchByName(query, pageable);
        List<EducationDtos.AdminSchoolSummary> items = schools.getContent().stream()
                .map(school -> new EducationDtos.AdminSchoolSummary(
                        school.getId(),
                        school.getName(),
                        school.getCreatedAt()
                ))
                .toList();

        return new EducationDtos.PagedResponse<>(
                items,
                schools.getNumber(),
                schools.getSize(),
                schools.getTotalElements(),
                schools.getTotalPages()
        );
    }

    @Transactional
    public EducationDtos.BulkOperationResponse bulkAssignUsersToSchools(MultipartFile file) {
        accessService.requireRole(Role.ROLE_ADMIN);
        List<EducationDtos.BulkRowError> errors = new ArrayList<>();
        int processed = 0;
        int success = 0;

        List<String> lines = readCsvLines(file);
        for (int i = 0; i < lines.size(); i++) {
            String line = lines.get(i).trim();
            int rowNumber = i + 1;
            if (line.isEmpty()) {
                continue;
            }
            if (processed == 0 && isHeader(line, "useremail", "schoolname")) {
                continue;
            }

            processed++;
            String[] parts = line.split(",", -1);
            if (parts.length < 2) {
                errors.add(new EducationDtos.BulkRowError(
                        rowNumber,
                        "row must contain userEmail,schoolName"
                ));
                continue;
            }

            String userEmail = parts[0].trim();
            String schoolName = parts[1].trim();
            if (userEmail.isEmpty() || schoolName.isEmpty()) {
                errors.add(new EducationDtos.BulkRowError(
                        rowNumber,
                        "userEmail and schoolName are required"
                ));
                continue;
            }

            try {
                assignUserToSchoolByEmailAndSchoolName(userEmail, schoolName);
                success++;
            } catch (ApiException e) {
                errors.add(new EducationDtos.BulkRowError(rowNumber, e.getMessage()));
            } catch (Exception e) {
                errors.add(new EducationDtos.BulkRowError(rowNumber, "unexpected error"));
            }
        }

        return new EducationDtos.BulkOperationResponse(
                processed,
                success,
                processed - success,
                errors
        );
    }

    @Transactional
    public EducationDtos.ParentStudentLinkResponse linkParentStudent(EducationDtos.ParentStudentLinkRequest request) {
        accessService.requireRole(Role.ROLE_ADMIN);

        UserAccount parent = userRepository.findById(request.parentUserId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "parent user not found"));
        UserAccount student = userRepository.findById(request.studentUserId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "student user not found"));

        return linkParentStudentInternal(parent, student);
    }

    @Transactional
    public EducationDtos.BulkOperationResponse bulkLinkParentStudents(MultipartFile file) {
        accessService.requireRole(Role.ROLE_ADMIN);
        List<EducationDtos.BulkRowError> errors = new ArrayList<>();
        int processed = 0;
        int success = 0;

        List<String> lines = readCsvLines(file);
        for (int i = 0; i < lines.size(); i++) {
            String line = lines.get(i).trim();
            int rowNumber = i + 1;
            if (line.isEmpty()) {
                continue;
            }
            if (processed == 0 && isHeader(line, "parentemail", "studentemail")) {
                continue;
            }

            processed++;
            String[] parts = line.split(",", -1);
            if (parts.length < 2) {
                errors.add(new EducationDtos.BulkRowError(
                        rowNumber,
                        "row must contain parentEmail,studentEmail"
                ));
                continue;
            }

            String parentEmail = parts[0].trim();
            String studentEmail = parts[1].trim();
            if (parentEmail.isEmpty() || studentEmail.isEmpty()) {
                errors.add(new EducationDtos.BulkRowError(
                        rowNumber,
                        "parentEmail and studentEmail are required"
                ));
                continue;
            }

            try {
                linkParentStudentByEmails(parentEmail, studentEmail);
                success++;
            } catch (ApiException e) {
                errors.add(new EducationDtos.BulkRowError(rowNumber, e.getMessage()));
            } catch (Exception e) {
                errors.add(new EducationDtos.BulkRowError(rowNumber, "unexpected error"));
            }
        }

        return new EducationDtos.BulkOperationResponse(
                processed,
                success,
                processed - success,
                errors
        );
    }

    private EducationDtos.StudentResponse assignUserToSchoolByEmailAndSchoolName(
            String userEmail,
            String schoolName
    ) {
        UserAccount user = userRepository.findByEmailIgnoreCase(userEmail.trim())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "user not found for email: " + userEmail));
        School school = schoolRepository.findByNameIgnoreCase(schoolName.trim())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "school not found for name: " + schoolName));

        return assignUserToSchoolInternal(user, school);
    }

    private EducationDtos.StudentResponse assignUserToSchoolInternal(UserAccount user, School school) {
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

    private EducationDtos.ParentStudentLinkResponse linkParentStudentByEmails(
            String parentEmail,
            String studentEmail
    ) {
        UserAccount parent = userRepository.findByEmailIgnoreCase(parentEmail.trim())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "parent user not found for email: " + parentEmail));
        UserAccount student = userRepository.findByEmailIgnoreCase(studentEmail.trim())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "student user not found for email: " + studentEmail));

        return linkParentStudentInternal(parent, student);
    }

    private EducationDtos.ParentStudentLinkResponse linkParentStudentInternal(UserAccount parent, UserAccount student) {
        validateParentAndStudent(parent, student);
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

    private void validateParentAndStudent(UserAccount parent, UserAccount student) {
        if (parent.getRole() != Role.ROLE_PARENT) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "parentUserId must belong to ROLE_PARENT");
        }
        if (student.getRole() != Role.ROLE_STUDENT) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "studentUserId must belong to ROLE_STUDENT");
        }
    }

    private List<String> readCsvLines(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "csv file is required");
        }
        try {
            String content = new String(file.getBytes(), StandardCharsets.UTF_8);
            return List.of(content.split("\\r?\\n"));
        } catch (IOException e) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "cannot read csv file");
        }
    }

    private boolean isHeader(String line, String col1, String col2) {
        String normalized = line.toLowerCase()
                .replace("\"", "")
                .replace(" ", "");
        return normalized.equals(col1 + "," + col2);
    }

    private String normalizeQuery(String q) {
        return q == null ? "" : q.trim();
    }

    private Pageable toPageable(int page, int size) {
        int safePage = Math.max(page, 0);
        int safeSize = Math.min(Math.max(size, 1), 100);
        return PageRequest.of(safePage, safeSize);
    }

    private Role parseRole(String role) {
        if (role == null || role.isBlank()) {
            return null;
        }
        try {
            return Role.valueOf(role.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "invalid role");
        }
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
