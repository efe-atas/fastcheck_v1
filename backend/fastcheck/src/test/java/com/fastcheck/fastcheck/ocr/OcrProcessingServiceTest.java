package com.fastcheck.fastcheck.ocr;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.when;

import com.fastcheck.fastcheck.auth.ServiceTokenProvider;
import com.fastcheck.fastcheck.auth.UserPrincipal;
import com.fastcheck.fastcheck.user.Role;
import com.fastcheck.fastcheck.user.UserAccount;
import com.fastcheck.fastcheck.user.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class OcrProcessingServiceTest {

    @Mock
    private OcrClient ocrClient;

    @Mock
    private ServiceTokenProvider serviceTokenProvider;

    @Mock
    private UserRepository userRepository;

    @Mock
    private OcrJobRepository ocrJobRepository;

    private OcrProcessingService ocrProcessingService;

    @BeforeEach
    void setUp() {
        ocrProcessingService = new OcrProcessingService(
                ocrClient,
                serviceTokenProvider,
                userRepository,
                ocrJobRepository,
                new ObjectMapper()
        );
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void getMineReturnsFallbackPayloadWhenStoredResultIsCorrupted() {
        Long userId = 42L;
        UUID jobId = UUID.randomUUID();

        UserAccount user = new UserAccount();
        ReflectionTestUtils.setField(user, "id", userId);
        user.setRole(Role.ROLE_TEACHER);
        user.setEmail("teacher@fastcheck.local");

        OcrJob job = new OcrJob();
        job.setUser(user);
        job.setImageUrl("http://localhost:8080/files/sample.jpg");
        job.setSourceId("sample");
        job.setRequestId(UUID.randomUUID());
        job.setStatus(OcrJobStatus.COMPLETED);
        job.setOcrResultJson("{not-valid-json");

        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(
                        new UserPrincipal(userId, user.getEmail(), "hash", Role.ROLE_TEACHER.name()),
                        null
                )
        );

        when(ocrJobRepository.findByJobIdAndUser_Id(jobId, userId)).thenReturn(Optional.of(job));

        OcrDtos.OcrResultResponse response = ocrProcessingService.getMine(jobId);

        Map<?, ?> result = assertInstanceOf(Map.class, response.result());
        assertEquals(true, result.get("corrupted"));
        assertEquals("stored OCR result is corrupted", result.get("message"));
        assertTrue(result.get("rawPreview").toString().contains("not-valid-json"));
    }
}
