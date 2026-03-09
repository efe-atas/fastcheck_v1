package com.fastcheck.fastcheck.common;

import jakarta.validation.ConstraintViolationException;
import java.time.Instant;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ApiException.class)
    public ResponseEntity<ErrorBody> handleApi(ApiException exception) {
        return ResponseEntity.status(exception.getStatus())
                .body(new ErrorBody(exception.getStatus().value(), exception.getMessage(), Instant.now().toString()));
    }

    @ExceptionHandler({MethodArgumentNotValidException.class, ConstraintViolationException.class})
    public ResponseEntity<ErrorBody> handleValidation(Exception exception) {
        return ResponseEntity.badRequest()
                .body(new ErrorBody(HttpStatus.BAD_REQUEST.value(), "validation failed", Instant.now().toString()));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorBody> handleUnknown(Exception exception) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new ErrorBody(HttpStatus.INTERNAL_SERVER_ERROR.value(), "internal server error", Instant.now().toString()));
    }

    public record ErrorBody(int status, String message, String timestamp) {
    }
}
