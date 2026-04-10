package com.fastcheck.fastcheck.education;

import com.fastcheck.fastcheck.user.UserAccount;
import java.text.Normalizer;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import org.springframework.stereotype.Service;

@Service
public class StudentNameMatcherService {

    public StudentNameMatchResult match(String detectedStudentName, List<UserAccount> students) {
        if (detectedStudentName == null || detectedStudentName.isBlank() || students == null || students.isEmpty()) {
            return StudentNameMatchResult.unmatched(detectedStudentName, 0.0, List.of());
        }

        String normalizedDetected = normalize(detectedStudentName);
        if (normalizedDetected.isBlank()) {
            return StudentNameMatchResult.unmatched(detectedStudentName, 0.0, List.of());
        }

        List<ScoredStudent> scoredStudents = students.stream()
                .map(student -> new ScoredStudent(student, score(normalizedDetected, normalize(student.getFullName()))))
                .sorted(Comparator.comparingDouble(ScoredStudent::score).reversed())
                .toList();

        List<UserAccount> exactMatches = scoredStudents.stream()
                .filter(item -> item.score() >= 0.999)
                .map(ScoredStudent::student)
                .toList();

        if (exactMatches.size() == 1) {
            UserAccount matched = exactMatches.get(0);
            return StudentNameMatchResult.matched(detectedStudentName, matched, 1.0, List.of(matched.getId()));
        }

        if (exactMatches.size() > 1) {
            return StudentNameMatchResult.ambiguous(
                    detectedStudentName,
                    1.0,
                    exactMatches.stream().map(UserAccount::getId).toList()
            );
        }

        ScoredStudent best = scoredStudents.get(0);
        double bestScore = best.score();
        double secondScore = scoredStudents.size() > 1 ? scoredStudents.get(1).score() : 0.0;

        List<Long> suggestedCandidates = scoredStudents.stream()
                .filter(item -> item.score() >= 0.45)
                .limit(3)
                .map(item -> item.student().getId())
                .toList();

        if (bestScore >= 0.88 && (bestScore - secondScore) >= 0.08) {
            return StudentNameMatchResult.matched(
                    detectedStudentName,
                    best.student(),
                    bestScore,
                    uniqueIds(best.student().getId(), suggestedCandidates)
            );
        }

        List<Long> ambiguousCandidates = scoredStudents.stream()
                .filter(item -> item.score() >= Math.max(0.72, bestScore - 0.05))
                .limit(3)
                .map(item -> item.student().getId())
                .toList();

        if (ambiguousCandidates.size() > 1 && bestScore >= 0.72) {
            return StudentNameMatchResult.ambiguous(detectedStudentName, bestScore, ambiguousCandidates);
        }

        return StudentNameMatchResult.unmatched(detectedStudentName, bestScore, suggestedCandidates);
    }

    private List<Long> uniqueIds(Long preferredId, List<Long> rest) {
        Set<Long> ids = new LinkedHashSet<>();
        ids.add(preferredId);
        ids.addAll(rest);
        return new ArrayList<>(ids);
    }

    private double score(String normalizedDetected, String normalizedStudentName) {
        if (normalizedDetected.isBlank() || normalizedStudentName.isBlank()) {
            return 0.0;
        }
        if (normalizedDetected.equals(normalizedStudentName)) {
            return 1.0;
        }

        double editScore = levenshteinSimilarity(normalizedDetected, normalizedStudentName);
        double tokenScore = tokenOverlap(normalizedDetected, normalizedStudentName);
        double containmentBonus = normalizedStudentName.contains(normalizedDetected)
                || normalizedDetected.contains(normalizedStudentName)
                ? 0.08
                : 0.0;
        return Math.min(1.0, (editScore * 0.65) + (tokenScore * 0.35) + containmentBonus);
    }

    private double tokenOverlap(String left, String right) {
        Set<String> leftTokens = new LinkedHashSet<>(List.of(left.split(" ")));
        Set<String> rightTokens = new LinkedHashSet<>(List.of(right.split(" ")));
        leftTokens.removeIf(String::isBlank);
        rightTokens.removeIf(String::isBlank);
        if (leftTokens.isEmpty() || rightTokens.isEmpty()) {
            return 0.0;
        }

        long matches = leftTokens.stream().filter(rightTokens::contains).count();
        return (2.0 * matches) / (leftTokens.size() + rightTokens.size());
    }

    private double levenshteinSimilarity(String left, String right) {
        int maxLength = Math.max(left.length(), right.length());
        if (maxLength == 0) {
            return 1.0;
        }
        return 1.0 - ((double) levenshteinDistance(left, right) / maxLength);
    }

    private int levenshteinDistance(String left, String right) {
        int[][] dp = new int[left.length() + 1][right.length() + 1];
        for (int i = 0; i <= left.length(); i++) {
            dp[i][0] = i;
        }
        for (int j = 0; j <= right.length(); j++) {
            dp[0][j] = j;
        }
        for (int i = 1; i <= left.length(); i++) {
            for (int j = 1; j <= right.length(); j++) {
                int cost = left.charAt(i - 1) == right.charAt(j - 1) ? 0 : 1;
                dp[i][j] = Math.min(
                        Math.min(dp[i - 1][j] + 1, dp[i][j - 1] + 1),
                        dp[i - 1][j - 1] + cost
                );
            }
        }
        return dp[left.length()][right.length()];
    }

    private String normalize(String value) {
        if (value == null) {
            return "";
        }
        String normalized = value
                .toLowerCase(Locale.forLanguageTag("tr"))
                .replace('ı', 'i')
                .replace('ğ', 'g')
                .replace('ü', 'u')
                .replace('ş', 's')
                .replace('ö', 'o')
                .replace('ç', 'c');
        normalized = Normalizer.normalize(normalized, Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "")
                .replaceAll("[^a-z0-9 ]", " ")
                .replaceAll("\\s+", " ")
                .trim();
        return normalized;
    }

    private record ScoredStudent(UserAccount student, double score) {
    }

    public record StudentNameMatchResult(
            String detectedStudentName,
            Long matchedStudentId,
            String matchedStudentName,
            double confidence,
            StudentMatchStatus status,
            List<Long> candidateStudentIds
    ) {
        private static StudentNameMatchResult matched(
                String detectedStudentName,
                UserAccount student,
                double confidence,
                List<Long> candidateStudentIds
        ) {
            return new StudentNameMatchResult(
                    detectedStudentName,
                    student.getId(),
                    student.getFullName(),
                    confidence,
                    StudentMatchStatus.MATCHED,
                    candidateStudentIds
            );
        }

        private static StudentNameMatchResult ambiguous(
                String detectedStudentName,
                double confidence,
                List<Long> candidateStudentIds
        ) {
            return new StudentNameMatchResult(
                    detectedStudentName,
                    null,
                    null,
                    confidence,
                    StudentMatchStatus.AMBIGUOUS,
                    candidateStudentIds
            );
        }

        private static StudentNameMatchResult unmatched(
                String detectedStudentName,
                double confidence,
                List<Long> candidateStudentIds
        ) {
            return new StudentNameMatchResult(
                    detectedStudentName,
                    null,
                    null,
                    confidence,
                    StudentMatchStatus.UNMATCHED,
                    candidateStudentIds
            );
        }
    }
}
