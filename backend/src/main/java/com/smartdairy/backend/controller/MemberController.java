package com.smartdairy.backend.controller;

import com.smartdairy.backend.dto.AuthResponse;
import com.smartdairy.backend.entity.Member;
import com.smartdairy.backend.entity.RoleType;
import com.smartdairy.backend.entity.User;
import com.smartdairy.backend.repository.MemberRepository;
import com.smartdairy.backend.repository.UserRepository;
import com.smartdairy.backend.service.AuthService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/v1/members")
public class MemberController {

    private final MemberRepository memberRepository;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthService authService;

    public MemberController(MemberRepository memberRepository, UserRepository userRepository, PasswordEncoder passwordEncoder, AuthService authService) {
        this.memberRepository = memberRepository;
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.authService = authService;
    }

    @GetMapping
    public ResponseEntity<List<Member>> getAllMembers() {
        return ResponseEntity.ok(memberRepository.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Member> getMemberById(@PathVariable String id) {
        return memberRepository.findById(id)
                .or(() -> memberRepository.findByMemberCode(id))
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<Member> createMember(@RequestBody Member member) {
        if (member.getMemberCode() == null || member.getMemberCode().isBlank()) {
            long count = memberRepository.count() + 1;
            String code = "M" + String.format("%03d", count);
            while (memberRepository.findByMemberCode(code).isPresent()) {
                count++;
                code = "M" + String.format("%03d", count);
            }
            member.setMemberCode(code);
        }
        Member saved = memberRepository.save(member);

        // Auto-provision or link login account if username/password provided
        return ResponseEntity.ok(saved);
    }

    @PostMapping("/{memberCode}/create-login")
    public ResponseEntity<?> createMemberLogin(
            @PathVariable String memberCode,
            @RequestBody Map<String, String> payload) {
        Optional<Member> memberOpt = memberRepository.findByMemberCode(memberCode)
                .or(() -> memberRepository.findById(memberCode));
        if (memberOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("error", "Member not found with code: " + memberCode));
        }

        Member member = memberOpt.get();
        String username = payload.get("username");
        String password = payload.get("password");

        if (username == null || username.trim().isEmpty() || password == null || password.trim().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Username and password are required."));
        }

        username = username.trim().toLowerCase();
        Optional<User> existingUser = userRepository.findByUsername(username);
        User user;
        if (existingUser.isPresent()) {
            user = existingUser.get();
            // Ensure not overwriting another member
            if (user.getMemberCode() != null && !user.getMemberCode().equalsIgnoreCase(member.getMemberCode())) {
                return ResponseEntity.status(HttpStatus.CONFLICT)
                        .body(Map.of("error", "Username '" + username + "' is already assigned to member " + user.getMemberCode()));
            }
            user.setPassword(passwordEncoder.encode(password));
            user.setMemberCode(member.getMemberCode());
            user.setMemberId(member.getId() != null ? member.getId() : member.getMemberCode());
            user.setFullName(member.getName());
            user.setPhone(member.getPhone());
            user.setRole(RoleType.MEMBER);
        } else {
            user = new User(
                    username,
                    passwordEncoder.encode(password),
                    member.getName(),
                    member.getPhone() != null ? member.getPhone() : "",
                    RoleType.MEMBER,
                    member.getMemberCode()
            );
            user.setMemberId(member.getId() != null ? member.getId() : member.getMemberCode());
        }

        userRepository.save(user);
        return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "Login account linked successfully for " + member.getName(),
                "username", username,
                "memberCode", member.getMemberCode()
        ));
    }

    @PostMapping("/link-profile")
    public ResponseEntity<?> linkMemberProfile(@RequestBody Map<String, String> payload, Authentication auth) {
        if (auth == null || !auth.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Unauthorized"));
        }
        String memberCode = payload.get("memberCode");
        try {
            AuthResponse response = authService.linkMemberProfile(auth.getName(), memberCode);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/search")
    public ResponseEntity<List<Member>> searchMembers(@RequestParam String query) {
        return ResponseEntity.ok(memberRepository.findByNameContainingIgnoreCaseOrMemberCodeContainingIgnoreCase(query, query));
    }

    @PutMapping("/{idOrCode}")
    public ResponseEntity<Member> updateMember(@PathVariable String idOrCode, @RequestBody Member updated) {
        return memberRepository.findByMemberCode(idOrCode)
                .or(() -> memberRepository.findById(idOrCode))
                .map(existing -> {
                    if (updated.getName() != null) existing.setName(updated.getName());
                    if (updated.getPhone() != null) existing.setPhone(updated.getPhone());
                    if (updated.getAnimalType() != null) existing.setAnimalType(updated.getAnimalType());
                    if (updated.getBankName() != null) existing.setBankName(updated.getBankName());
                    if (updated.getAccountNumber() != null) existing.setAccountNumber(updated.getAccountNumber());
                    if (updated.getIfscCode() != null) existing.setIfscCode(updated.getIfscCode());
                    return ResponseEntity.ok(memberRepository.save(existing));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{idOrCode}")
    public ResponseEntity<Void> deleteMember(@PathVariable String idOrCode) {
        memberRepository.findByMemberCode(idOrCode)
                .or(() -> memberRepository.findById(idOrCode))
                .ifPresent(memberRepository::delete);
        return ResponseEntity.noContent().build();
    }
}
