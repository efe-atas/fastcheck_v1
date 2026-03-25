package com.fastcheck.fastcheck.ocr;

import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.fastcheck.fastcheck.education.ExamFileStorageService;

@RestController
@RequestMapping("/v1/ocr")
public class OcrController {

    private final OcrProcessingService ocrProcessingService;
    private final ExamFileStorageService examFileStorageService;

    public OcrController(
            OcrProcessingService ocrProcessingService,
            ExamFileStorageService examFileStorageService
    ) {
        this.ocrProcessingService = ocrProcessingService;
        this.examFileStorageService = examFileStorageService;
    }

    @PostMapping("/upload-image")
    @ResponseStatus(HttpStatus.CREATED)
    public OcrDtos.OcrUploadImageResponse uploadImage(@RequestPart("file") MultipartFile file) {
        String imageUrl = examFileStorageService.save(file);
        return new OcrDtos.OcrUploadImageResponse(imageUrl);
    }

    @PostMapping("/extract")
    @ResponseStatus(HttpStatus.CREATED)
    public OcrDtos.OcrResultResponse extract(
            @Valid @RequestBody OcrDtos.OcrExtractRequest request,
            @RequestHeader(name = "X-Request-Id", required = false) String requestId
    ) {
        String reqId = requestId == null || requestId.isBlank() ? UUID.randomUUID().toString() : requestId;
        return ocrProcessingService.extract(request, reqId);
    }

    @GetMapping("/results")
    public List<OcrDtos.OcrResultResponse> listMine() {
        return ocrProcessingService.listMine();
    }

    @GetMapping("/results/{jobId}")
    public OcrDtos.OcrResultResponse getMine(@PathVariable UUID jobId) {
        return ocrProcessingService.getMine(jobId);
    }
}
