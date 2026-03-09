package com.fastcheck.fastcheck.education;

import com.fastcheck.fastcheck.common.ApiException;
import com.fastcheck.fastcheck.config.FileStorageProperties;
import java.io.IOException;
import java.net.MalformedURLException;
import java.nio.file.Files;
import java.nio.file.Path;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/files")
public class PublicFileController {

    private final Path basePath;

    public PublicFileController(FileStorageProperties properties) {
        this.basePath = Path.of(properties.storagePath()).toAbsolutePath().normalize();
    }

    @GetMapping("/{fileName}")
    public ResponseEntity<Resource> serve(@PathVariable String fileName) {
        Path target = basePath.resolve(fileName).normalize();
        if (!target.startsWith(basePath) || !Files.exists(target)) {
            throw new ApiException(HttpStatus.NOT_FOUND, "file not found");
        }

        try {
            Resource resource = new UrlResource(target.toUri());
            String contentType = Files.probeContentType(target);
            MediaType mediaType = contentType == null ? MediaType.APPLICATION_OCTET_STREAM : MediaType.parseMediaType(contentType);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CACHE_CONTROL, "public, max-age=86400")
                    .contentType(mediaType)
                    .body(resource);
        } catch (MalformedURLException exc) {
            throw new ApiException(HttpStatus.NOT_FOUND, "file not found");
        } catch (IOException exc) {
            throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "file read failed");
        }
    }
}
