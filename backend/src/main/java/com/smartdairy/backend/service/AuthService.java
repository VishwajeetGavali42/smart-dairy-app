package com.smartdairy.backend.service;

import com.smartdairy.backend.dto.*;
import com.smartdairy.backend.entity.Member;
import com.smartdairy.backend.entity.RoleType;
import com.smartdairy.backend.entity.User;
import com.smartdairy.backend.repository.MemberRepository;
import com.smartdairy.backend.repository.UserRepository;
import com.smartdairy.backend.security.JwtTokenProvider;
import org.springframework.security.authentication.*;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class AuthService {

    private static final String ADMIN_SETUP_KEY = "SMART_DAIRY_ADMIN_2026";

    private final AuthenticationManager authenticationManager;
    private final UserRepository userRepository;
    private final MemberRepository memberRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;

    public AuthService(AuthenticationManager authenticationManager,
                       UserRepository userRepository,
                       MemberRepository memberRepository,
                       PasswordEncoder passwordEncoder,
                       JwtTokenProvider tokenProvider) {
        this.authenticationManager = authenticationManager;
        this.userRepository = userRepository;
        this.memberRepository = memberRepository;
        this.passwordEncoder = passwordEncoder;
        this.tokenProvider = tokenProvider;
    }

    public AuthResponse login(AuthRequest request) {
        if (request.getUsername() == null || request.getUsername().trim().isEmpty()) {
            throw new IllegalArgumentException("Username is required");
        }
        if (request.getPassword() == null || request.getPassword().trim().isEmpty()) {
            throw new IllegalArgumentException("Password is required");
        }

        final String cleanUsername = request.getUsername().trim().toLowerCase();

        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(cleanUsername, request.getPassword())
        );

        SecurityContextHolder.getContext().setAuthentication(authentication);
        User user = userRepository.findByUsername(cleanUsername)
                .orElseThrow(() -> new BadCredentialsException("Invalid username or password"));

        if (!user.isEnabled()) {
            throw new DisabledException("Your account is disabled. Please contact the administrator.");
        }

        // Validate selected role against actual registered role
        if (request.getRole() != null && !request.getRole().trim().isEmpty()) {
            RoleType requestedRole = parseRole(request.getRole());
            if (user.getRole() != requestedRole) {
                throw new BadCredentialsException("Role mismatch: Your account is registered as " +
                        formatRoleName(user.getRole()) + ", not " + formatRoleName(requestedRole) + ".");
            }
        }

        String jwt = tokenProvider.generateToken(
                user.getUsername(),
                user.getRole().name(),
                user.getMemberCode(),
                user.getMemberId()
        );

        return new AuthResponse(
                jwt,
                user.getUsername(),
                user.getFullName(),
                user.getRole().name(),
                user.getDairyName(),
                user.getCenterCode(),
                user.getMemberId(),
                user.getMemberCode()
        );
    }

    public AuthResponse register(RegisterRequest request) {
        // 1. Validate required fields
        if (request.getUsername() == null || request.getUsername().trim().isEmpty()) {
            throw new IllegalArgumentException("Username is required");
        }
        final String cleanUsername = request.getUsername().trim().toLowerCase();
        if (cleanUsername.length() < 3) {
            throw new IllegalArgumentException("Username must be at least 3 characters long");
        }
        if (cleanUsername.contains(" ")) {
            throw new IllegalArgumentException("Username cannot contain spaces");
        }

        // Uniqueness check
        if (userRepository.existsByUsername(cleanUsername)) {
            throw new IllegalArgumentException("Username '" + cleanUsername + "' is already taken. Please choose another username.");
        }

        if (request.getPassword() == null || request.getPassword().trim().isEmpty()) {
            throw new IllegalArgumentException("Password is required");
        }
        if (request.getPassword().length() < 6) {
            throw new IllegalArgumentException("Password must be at least 6 characters long");
        }

        if (request.getConfirmPassword() == null || !request.getPassword().equals(request.getConfirmPassword())) {
            throw new IllegalArgumentException("Password and Confirm Password do not match");
        }

        if (request.getRole() == null || request.getRole().trim().isEmpty()) {
            throw new IllegalArgumentException("Role selection is required");
        }

        RoleType roleType = parseRole(request.getRole());

        // 2. Security restriction: Public self-registration cannot grant Admin privileges without approval/secret
        if (roleType == RoleType.ADMIN) {
            String adminKey = request.getAdminSecretKey();
            if (adminKey == null || !adminKey.trim().equals(ADMIN_SETUP_KEY)) {
                throw new SecurityException("Public self-registration cannot grant Admin privileges. A valid Admin Authorization Key is required.");
            }
        }

        // 3. Prepare User Entity
        String fullName = request.getFullName();
        if (fullName == null || fullName.trim().isEmpty()) {
            fullName = formatDefaultFullName(cleanUsername, roleType);
        }

        String encodedPassword = passwordEncoder.encode(request.getPassword().trim());
        User user = new User(cleanUsername, encodedPassword, fullName.trim(), request.getPhone(), roleType);

        // 4. If role is MEMBER, securely link to existing farmer profile or leave unlinked
        if (roleType == RoleType.MEMBER) {
            String mCode = request.getMemberCode();
            if (mCode != null && !mCode.trim().isEmpty()) {
                String cleanCode = mCode.trim().toUpperCase();
                // Check if existing Member profile matches
                Optional<Member> existingMember = memberRepository.findByMemberCodeIgnoreCase(cleanCode)
                        .or(() -> memberRepository.findById(cleanCode));
                if (existingMember.isEmpty()) {
                    throw new IllegalArgumentException("Farmer profile not found with code '" + cleanCode + "'. Please check the Member Code provided by your Dairy Owner.");
                }
                // Check if already linked to another account
                Optional<User> alreadyLinked = userRepository.findByMemberCodeIgnoreCase(existingMember.get().getMemberCode());
                if (alreadyLinked.isPresent()) {
                    throw new IllegalArgumentException("Farmer profile '" + cleanCode + "' is already linked to another account (" + alreadyLinked.get().getUsername() + ").");
                }
                user.setMemberCode(existingMember.get().getMemberCode());
                user.setMemberId(existingMember.get().getId() != null ? existingMember.get().getId() : existingMember.get().getMemberCode());
                user.setFullName(existingMember.get().getName());
                if (existingMember.get().getPhone() != null && !existingMember.get().getPhone().isBlank() && (user.getPhone() == null || user.getPhone().isBlank())) {
                    user.setPhone(existingMember.get().getPhone());
                }
            } else {
                // Explicitly unlinked Member account - do NOT generate fake arbitrary member codes
                user.setMemberCode(null);
                user.setMemberId(null);
            }
        }

        User saved = userRepository.save(user);

        String jwt = tokenProvider.generateToken(
                saved.getUsername(),
                saved.getRole().name(),
                saved.getMemberCode(),
                saved.getMemberId()
        );

        return new AuthResponse(
                jwt,
                saved.getUsername(),
                saved.getFullName(),
                saved.getRole().name(),
                saved.getDairyName(),
                saved.getCenterCode(),
                saved.getMemberId(),
                saved.getMemberCode()
        );
    }

    public AuthResponse linkMemberProfile(String username, String memberCode) {
        if (memberCode == null || memberCode.trim().isEmpty()) {
            throw new IllegalArgumentException("Member code is required to link farmer profile.");
        }
        String cleanCode = memberCode.trim().toUpperCase();
        User user = userRepository.findByUsername(username.trim().toLowerCase())
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + username));

        if (user.getRole() != RoleType.MEMBER) {
            throw new IllegalStateException("Only Member accounts can be linked to a farmer profile.");
        }

        Member member = memberRepository.findByMemberCodeIgnoreCase(cleanCode)
                .or(() -> memberRepository.findById(cleanCode))
                .orElseThrow(() -> new IllegalArgumentException("Farmer profile not found with code '" + cleanCode + "'. Please check the Member Code provided by your Dairy Owner."));

        Optional<User> existingLink = userRepository.findByMemberCodeIgnoreCase(member.getMemberCode());
        if (existingLink.isPresent() && !existingLink.get().getUsername().equalsIgnoreCase(user.getUsername())) {
            throw new IllegalArgumentException("Farmer profile '" + cleanCode + "' is already linked to another account (" + existingLink.get().getUsername() + ").");
        }

        user.setMemberCode(member.getMemberCode());
        user.setMemberId(member.getId() != null ? member.getId() : member.getMemberCode());
        user.setFullName(member.getName());
        if (member.getPhone() != null && !member.getPhone().isBlank() && (user.getPhone() == null || user.getPhone().isBlank())) {
            user.setPhone(member.getPhone());
        }

        User saved = userRepository.save(user);

        String jwt = tokenProvider.generateToken(
                saved.getUsername(),
                saved.getRole().name(),
                saved.getMemberCode(),
                saved.getMemberId()
        );

        return new AuthResponse(
                jwt,
                saved.getUsername(),
                saved.getFullName(),
                saved.getRole().name(),
                saved.getDairyName(),
                saved.getCenterCode(),
                saved.getMemberId(),
                saved.getMemberCode()
        );
    }

    public RoleType parseRole(String roleStr) {
        if (roleStr == null) return RoleType.DAIRY_OWNER;
        String clean = roleStr.trim().toUpperCase().replaceAll("ROLE_", "");
        return switch (clean) {
            case "OWNER", "DAIRY_OWNER" -> RoleType.DAIRY_OWNER;
            case "MEMBER", "FARMER" -> RoleType.MEMBER;
            case "ADMIN", "DEVELOPER" -> RoleType.ADMIN;
            case "EMPLOYEE", "OPERATOR" -> RoleType.EMPLOYEE;
            default -> RoleType.DAIRY_OWNER;
        };
    }

    public String formatRoleName(RoleType role) {
        return switch (role) {
            case DAIRY_OWNER -> "Owner (Dairy Center)";
            case MEMBER -> "Member (Farmer)";
            case ADMIN -> "Admin";
            case EMPLOYEE -> "Operator / Employee";
        };
    }

    private String formatDefaultFullName(String username, RoleType role) {
        String capitalized = username.substring(0, 1).toUpperCase() + username.substring(1);
        return switch (role) {
            case DAIRY_OWNER -> capitalized + " (Dairy Owner)";
            case MEMBER -> capitalized + " (Farmer Member)";
            case ADMIN -> capitalized + " (Administrator)";
            case EMPLOYEE -> capitalized + " (Operator)";
        };
    }
}
