package com.fastcheck.fastcheck.ocr;

import com.fastcheck.fastcheck.auth.ServiceTokenProvider;
import com.fastcheck.fastcheck.auth.UserPrincipal;
import com.fastcheck.fastcheck.common.ApiException;
import com.fastcheck.fastcheck.user.UserAccount;
import com.fastcheck.fastcheck.user.UserRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class OcrProcessingService {

    private final OcrClient ocrClient;
    private final ServiceTokenProvider serviceTokenProvider;
    private final UserRepository userRepository;
    private final OcrJobRepository ocrJobRepository;
    private final ObjectMapper objectMapper;

    public OcrProcessingService(
            OcrClient ocrClient,
            ServiceTokenProvider serviceTokenProvider,
            UserRepository userRepository,
            OcrJobRepository ocrJobRepository,
            ObjectMapper objectMapper
    ) {
        this.ocrClient = ocrClient;
        this.serviceTokenProvider = serviceTokenProvider;
        this.userRepository = userRepository;
        this.ocrJobRepository = ocrJobRepository;
        this.objectMapper = objectMapper;
    }

    @Transactional
    public OcrDtos.OcrResultResponse extract(OcrDtos.OcrExtractRequest request, String requestId) {
        UserPrincipal principal = currentPrincipal();
        UserAccount user = userRepository.findById(principal.getUserId())
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "user not found"));

        String serviceJwt = serviceTokenProvider.createServiceToken();

        OcrDtos.FastApiResponse apiResponse = ocrClient.extract(
                new OcrDtos.FastApiRequest(request.imageUrl(), request.sourceId(), request.languageHint()),
                serviceJwt,
                user.getId(),
                requestId
        );

        UUID fastApiRequestId = UUID.fromString(apiResponse.requestId());

        OcrJob job = new OcrJob();
        job.setUser(user);
        job.setImageUrl(request.imageUrl());
        job.setSourceId(request.sourceId());
        job.setRequestId(fastApiRequestId);
        job.setStatus(OcrJobStatus.COMPLETED);
        try {
            job.setOcrResultJson(objectMapper.writeValueAsString(apiResponse.result()));
        } catch (Exception exc) {
            throw new ApiException(HttpStatus.BAD_GATEWAY, "invalid fastapi response payload");
        }
        job = ocrJobRepository.save(job);

        return toResponse(job);
    }

    @Transactional(readOnly = true)
    public List<OcrDtos.OcrResultResponse> listMine() {
        Long userId = currentPrincipal().getUserId();
        return ocrJobRepository.findByUser_IdOrderByCreatedAtDesc(userId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public OcrDtos.OcrResultResponse getMine(UUID jobId) {
        Long userId = currentPrincipal().getUserId();
        OcrJob job = ocrJobRepository.findByJobIdAndUser_Id(jobId, userId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "ocr job not found"));
        return toResponse(job);
    }

    private UserPrincipal currentPrincipal() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof UserPrincipal principal)) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "unauthorized");
        }
        return principal;
    }

    private OcrDtos.OcrResultResponse toResponse(OcrJob job) {
        try {
            JsonNode result = objectMapper.readTree(job.getOcrResultJson());
            Object responsePayload = objectMapper.convertValue(result, Object.class);
            return new OcrDtos.OcrResultResponse(
                    job.getJobId(),
                    job.getRequestId(),
                    job.getUser().getId(),
                    job.getImageUrl(),
                    job.getSourceId(),
                    job.getStatus().name(),
                    job.getCreatedAt(),
                    responsePayload
            );
        } catch (Exception exc) {
            throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "stored OCR result is corrupted");
        }
    }
}
