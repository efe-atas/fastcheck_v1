package com.fastcheck.fastcheck.ocr;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import java.time.Instant;
import java.util.UUID;

public class OcrDtos {

    public record OcrExtractRequest(
            @NotBlank @Pattern(regexp = "^https?://.*", message = "imageUrl must be http/https") String imageUrl,
            String sourceId,
            String languageHint
    ) {
    }

    public record FastApiRequest(
            @JsonProperty("image_url") String imageUrl,
            @JsonProperty("source_id") String sourceId,
            @JsonProperty("language_hint") String languageHint
    ) {
    }

    public record FastApiResponse(
            @JsonProperty("request_id") String requestId,
            JsonNode result
    ) {
    }

    public record OcrResultResponse(
            UUID jobId,
            UUID requestId,
            Long userId,
            String imageUrl,
            String sourceId,
            String status,
            Instant createdAt,
            Object result
    ) {
    }

    public record OcrUploadImageResponse(String imageUrl) {
    }
}
