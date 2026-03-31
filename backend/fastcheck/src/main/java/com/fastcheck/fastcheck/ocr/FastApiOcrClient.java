package com.fastcheck.fastcheck.ocr;

import com.fastcheck.fastcheck.common.ApiException;
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

    public FastApiOcrClient(RestClient fastApiRestClient) {
        this.restClient = fastApiRestClient;
    }

    @Override
    public OcrDtos.FastApiResponse extract(OcrDtos.FastApiRequest request, String serviceJwt, Long userId, String requestId) {
        try {
            return restClient.post()
                    .uri("/v1/ocr/exams:extract")
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + serviceJwt)
                    .header("X-User-Id", String.valueOf(userId))
                    .header("X-Request-Id", requestId)
                    .body(request)
                    .retrieve()
                    .body(OcrDtos.FastApiResponse.class);
        } catch (HttpStatusCodeException exc) {
            HttpStatus status = HttpStatus.resolve(exc.getStatusCode().value());
            if (status == null) {
                status = HttpStatus.BAD_GATEWAY;
            }
            throw new ApiException(status, "fastapi call failed: " + exc.getResponseBodyAsString());
        } catch (Exception exc) {
            throw new ApiException(HttpStatus.BAD_GATEWAY, "fastapi call failed");
        }
    }
}
