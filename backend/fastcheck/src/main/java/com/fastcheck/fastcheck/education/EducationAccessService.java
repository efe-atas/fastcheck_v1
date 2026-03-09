package com.fastcheck.fastcheck.education;

import com.fastcheck.fastcheck.auth.UserPrincipal;
import com.fastcheck.fastcheck.common.ApiException;
import com.fastcheck.fastcheck.user.Role;
import com.fastcheck.fastcheck.user.UserAccount;
import com.fastcheck.fastcheck.user.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

@Service
public class EducationAccessService {

    private final UserRepository userRepository;

    public EducationAccessService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public UserAccount currentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof UserPrincipal principal)) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "unauthorized");
        }
        return userRepository.findById(principal.getUserId())
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "user not found"));
    }

    public UserAccount requireRole(Role role) {
        UserAccount current = currentUser();
        if (current.getRole() != role) {
            throw new ApiException(HttpStatus.FORBIDDEN, "forbidden");
        }
        return current;
    }
}
