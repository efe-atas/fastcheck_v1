package com.fastcheck.fastcheck.ocr;

import com.fastcheck.fastcheck.common.ApiException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.context.annotation.Profile;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.RestClient;

@Component
@Profile("!mock-ocr")
public class FastApiOcrClient implements OcrClient {

    private final RestClient restClient;
    private final ObjectMapper objectMapper;

    public FastApiOcrClient(RestClient fastApiRestClient, ObjectMapper objectMapper) {
        this.restClient = fastApiRestClient;
        this.objectMapper = objectMapper;
    }

    @Override
    public OcrDtos.FastApiResponse extract(OcrDtos.FastApiRequest request, String serviceJwt, Long userId, String requestId) {
        try {
            String responseBody = restClient.post()
                    .uri("/v1/ocr/exams:extract")
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + serviceJwt)
                    .header("X-User-Id", String.valueOf(userId))
                    .header("X-Request-Id", requestId)
                    .body(request)
                    .retrieve()
                    .body(String.class);
            if (responseBody == null || responseBody.isBlank()) {
                throw new ApiException(HttpStatus.BAD_GATEWAY, "fastapi call failed: empty response");
            }
            return objectMapper.readValue(responseBody, OcrDtos.FastApiResponse.class);
        } catch (HttpStatusCodeException exc) {
            HttpStatus status = HttpStatus.resolve(exc.getStatusCode().value());
            if (status == null) {
                status = HttpStatus.BAD_GATEWAY;
            }
            throw new ApiException(status, "fastapi call failed: " + exc.getResponseBodyAsString());
        } catch (Exception exc) {
            String detail = exc.getClass().getSimpleName();
            if (exc.getMessage() != null && !exc.getMessage().isBlank()) {
                detail += ": " + exc.getMessage();
            }
            throw new ApiException(HttpStatus.BAD_GATEWAY, "fastapi call failed: " + detail);
        }
    }
}
