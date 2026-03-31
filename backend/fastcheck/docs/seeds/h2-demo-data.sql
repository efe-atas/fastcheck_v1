-- Demo seed data for local H2 runs. Execute with:
--   SPRING_PROFILES_ACTIVE=seed ./mvnw spring-boot:run
-- or import manually via your SQL client.

INSERT INTO schools (id, name, created_at) VALUES
    (100, 'FastCheck Demo School', CURRENT_TIMESTAMP())
ON DUPLICATE KEY UPDATE name = VALUES(name);

INSERT INTO users (id, email, full_name, password_hash, role, created_at, updated_at, school_id)
VALUES
    (1, 'admin@fastcheck.demo', 'Demo Admin', '$2a$10$1kZIuP89xDSHLVbkP4SRpeeqCkCmZJLdnOjFkMrDXLI4YAlnXrhxS', 'ROLE_ADMIN', CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), 100),
    (2, 'teacher@fastcheck.demo', 'Demo Teacher', '$2a$10$1kZIuP89xDSHLVbkP4SRpeeqCkCmZJLdnOjFkMrDXLI4YAlnXrhxS', 'ROLE_TEACHER', CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), 100),
    (3, 'student@fastcheck.demo', 'Demo Student', '$2a$10$1kZIuP89xDSHLVbkP4SRpeeqCkCmZJLdnOjFkMrDXLI4YAlnXrhxS', 'ROLE_STUDENT', CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), 100),
    (4, 'parent@fastcheck.demo', 'Demo Parent', '$2a$10$1kZIuP89xDSHLVbkP4SRpeeqCkCmZJLdnOjFkMrDXLI4YAlnXrhxS', 'ROLE_PARENT', CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), 100)
ON DUPLICATE KEY UPDATE full_name = VALUES(full_name);

INSERT INTO school_classes (id, school_id, teacher_id, name, created_at)
VALUES (200, 100, 2, '10-A', CURRENT_TIMESTAMP())
ON DUPLICATE KEY UPDATE name = VALUES(name);

UPDATE users SET class_id = 200 WHERE id = 3;

INSERT INTO parent_student_links (id, parent_id, student_id, created_at)
VALUES (300, 4, 3, CURRENT_TIMESTAMP())
ON DUPLICATE KEY UPDATE created_at = VALUES(created_at);
