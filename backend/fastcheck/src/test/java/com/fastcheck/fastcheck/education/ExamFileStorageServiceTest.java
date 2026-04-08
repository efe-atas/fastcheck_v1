package com.fastcheck.fastcheck.education;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.fastcheck.fastcheck.common.ApiException;
import com.fastcheck.fastcheck.config.FileStorageProperties;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.mock.web.MockMultipartFile;

class ExamFileStorageServiceTest {

    @TempDir
    Path tempDir;

    @Test
    void acceptsImageExtensionWhenMultipartContentTypeIsGeneric() {
        ExamFileStorageService service = new ExamFileStorageService(
                new FileStorageProperties(tempDir.toString(), "http://localhost:8080/files")
        );
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "scan.jpg",
                "application/octet-stream",
                new byte[] {1, 2, 3}
        );

        String imageUrl = service.save(file);

        assertTrue(imageUrl.startsWith("http://localhost:8080/files/"));
        assertTrue(imageUrl.endsWith(".jpg"));
    }

    @Test
    void rejectsNonImageUploadWhenContentTypeAndExtensionAreUnsupported() {
        ExamFileStorageService service = new ExamFileStorageService(
                new FileStorageProperties(tempDir.toString(), "http://localhost:8080/files")
        );
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "notes.txt",
                "application/octet-stream",
                "not-an-image".getBytes()
        );

        ApiException exception = assertThrows(ApiException.class, () -> service.save(file));

        assertTrue(exception.getMessage().contains("only image files are allowed"));
    }
}
