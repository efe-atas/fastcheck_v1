package com.fastcheck.fastcheck.ocr;

public interface OcrClient {
    OcrDtos.FastApiResponse extract(
            OcrDtos.FastApiRequest request,
            String serviceJwt,
            Long userId,
            String requestId
    );
}
