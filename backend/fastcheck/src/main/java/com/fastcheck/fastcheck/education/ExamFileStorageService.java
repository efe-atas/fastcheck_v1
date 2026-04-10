package com.fastcheck.fastcheck.education;

import com.fastcheck.fastcheck.common.ApiException;
import com.fastcheck.fastcheck.config.FileStorageProperties;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Locale;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
public class ExamFileStorageService {

    private final Path basePath;
    private final String publicBaseUrl;

    public ExamFileStorageService(FileStorageProperties properties) {
        this.basePath = Path.of(properties.storagePath()).toAbsolutePath().normalize();
        this.publicBaseUrl = properties.publicBaseUrl();
        try {
            Files.createDirectories(basePath);
        } catch (IOException exc) {
            throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "failed to prepare file storage");
        }
    }

    public String save(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "image file is required");
        }

        String contentType = file.getContentType() == null ? "" : file.getContentType().toLowerCase(Locale.ROOT);
        String originalFilename = file.getOriginalFilename();
        if (!isSupportedImageUpload(contentType, originalFilename)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "only image files are allowed");
        }

        String extension = extensionFor(contentType, originalFilename);
        String fileName = UUID.randomUUID() + extension;
        Path target = basePath.resolve(fileName);

        try {
            Files.copy(file.getInputStream(), target, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException exc) {
            throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "failed to store image");
        }

        return publicBaseUrl.replaceAll("/$", "") + "/" + fileName;
    }

    private boolean isSupportedImageUpload(String contentType, String originalFilename) {
        if (contentType.startsWith("image/")) {
            return true;
        }
        if (originalFilename == null || originalFilename.isBlank()) {
            return false;
        }

        String lower = originalFilename.toLowerCase(Locale.ROOT);
        return lower.endsWith(".jpg")
                || lower.endsWith(".jpeg")
                || lower.endsWith(".png")
                || lower.endsWith(".webp")
                || lower.endsWith(".gif");
    }

    private String extensionFor(String contentType, String originalFilename) {
        if (contentType.endsWith("png")) {
            return ".png";
        }
        if (contentType.endsWith("heic")) {
            return ".heic";
        }
        if (contentType.endsWith("heif")) {
            return ".heif";
        }
        if (contentType.endsWith("jpeg") || contentType.endsWith("jpg")) {
            return ".jpg";
        }
        if (contentType.endsWith("webp")) {
            return ".webp";
        }
        if (originalFilename != null) {
            int idx = originalFilename.lastIndexOf('.');
            if (idx > -1 && idx < originalFilename.length() - 1) {
                return originalFilename.substring(idx);
            }
        }
        return ".img";
    }
}
