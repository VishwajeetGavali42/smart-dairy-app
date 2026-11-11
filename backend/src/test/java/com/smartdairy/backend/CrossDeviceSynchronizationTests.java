package com.smartdairy.backend;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartdairy.backend.dto.AuthRequest;
import com.smartdairy.backend.dto.AuthResponse;
import com.smartdairy.backend.dto.RegisterRequest;
import com.smartdairy.backend.entity.MilkCollection;
import com.smartdairy.backend.entity.User;
import com.smartdairy.backend.repository.UserRepository;
import com.smartdairy.backend.service.AuthService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDate;
import java.util.Optional;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
public class CrossDeviceSynchronizationTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private AuthService authService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    @DisplayName("Cross-device sync: Owner records 10L for Ramesh, Ramesh retrieves entry, Suresh cannot view it")
    void testCrossDeviceOwnerToMemberSyncAndTenantIsolation() throws Exception {
        // 1. Owner logs in (Phone A)
        AuthResponse ownerAuth = authService.login(new AuthRequest("owner", "password"));
        String ownerToken = "Bearer " + ownerAuth.getToken();

        // 2. Member Ramesh logs in (Phone B)
        AuthResponse rameshAuth = authService.login(new AuthRequest("ramesh", "password"));
        String rameshToken = "Bearer " + rameshAuth.getToken();

        // 3. Member Suresh logs in (Phone C)
        AuthResponse sureshAuth = authService.login(new AuthRequest("suresh", "password"));
        String sureshToken = "Bearer " + sureshAuth.getToken();

        // 4. Owner records 10 Litres of Cow milk for Ramesh (M001)
        MilkCollection entry = new MilkCollection();
        entry.setMemberCode("M001");
        entry.setMemberName("Ramesh Patil");
        entry.setAnimalType("Cow");
        entry.setShift("Morning");
        entry.setQuantity(10.0);
        entry.setFat(4.5);
        entry.setSnf(8.6);
        entry.setCollectionDate(LocalDate.now());

        mockMvc.perform(post("/api/v1/collections")
                        .header("Authorization", ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(entry)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.memberCode", is("M001")))
                .andExpect(jsonPath("$.quantity", is(10.0)));

        // 5. Ramesh queries his collections from Phone B -> sees the exact 10L entry
        mockMvc.perform(get("/api/v1/collections/my-collections")
                        .header("Authorization", rameshToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(greaterThanOrEqualTo(1))))
                .andExpect(jsonPath("$[?(@.memberCode == 'M001')]", not(empty())))
                .andExpect(jsonPath("$[?(@.memberCode == 'M002')]", empty()));

        // 6. Suresh queries his collections from Phone C -> NEVER sees Ramesh's entry
        mockMvc.perform(get("/api/v1/collections/my-collections")
                        .header("Authorization", sureshToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.memberCode == 'M001')]", empty()));

        // 7. Security: Suresh attempts to change URL parameter to query Ramesh's ID M001 -> FORBIDDEN (403)
        mockMvc.perform(get("/api/v1/collections/member/M001")
                        .header("Authorization", sureshToken))
                .andExpect(status().isForbidden());

        // 8. Security: Member Ramesh attempts to forge or record a milk entry -> FORBIDDEN (403)
        MilkCollection unauthorizedEntry = new MilkCollection();
        unauthorizedEntry.setMemberCode("M001");
        unauthorizedEntry.setQuantity(50.0);
        mockMvc.perform(post("/api/v1/collections")
                        .header("Authorization", rameshToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(unauthorizedEntry)))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Create Account validation: Duplicate usernames and password mismatches are rejected")
    void testCreateAccountValidation() throws Exception {
        // A. Password mismatch
        RegisterRequest mismatch = new RegisterRequest("testuser1", "secret123", "different123", "DAIRY_OWNER");
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(mismatch)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error", containsString("match")));

        // B. Short password
        RegisterRequest shortPass = new RegisterRequest("testuser2", "123", "123", "DAIRY_OWNER");
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(shortPass)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error", containsString("at least 6 characters")));

        // C. Existing username 'owner'
        RegisterRequest duplicate = new RegisterRequest("owner", "newpassword123", "newpassword123", "DAIRY_OWNER");
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(duplicate)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error", containsString("already taken")));
    }

    @Test
    @DisplayName("Security: Public self-registration cannot grant Admin privileges without secret key")
    void testAdminPrivilegeProtection() throws Exception {
        // Attempting to register as ADMIN without secret key must fail with 403 Forbidden
        RegisterRequest unauthAdmin = new RegisterRequest("fakeadmin", "adminpass123", "adminpass123", "ADMIN");
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(unauthAdmin)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error", containsString("Admin privileges")));

        // Registering as ADMIN with valid setup key succeeds with 201 Created
        unauthAdmin.setUsername("dev_admin_" + System.currentTimeMillis());
        unauthAdmin.setAdminSecretKey("SMART_DAIRY_ADMIN_2026");
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(unauthAdmin)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.role", is("ADMIN")))
                .andExpect(jsonPath("$.token", notNullValue()));
    }

    @Test
    @DisplayName("Role verification: Logging in with wrong role is rejected with role mismatch")
    void testLoginRoleMismatchRejection() throws Exception {
        // Ramesh is a registered MEMBER. Attempting to log in selecting OWNER role must fail
        AuthRequest wrongRoleLogin = new AuthRequest("ramesh", "password", "DAIRY_OWNER");
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(wrongRoleLogin)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error", containsString("Role mismatch")));

        // Logging in selecting correct MEMBER role succeeds
        AuthRequest correctLogin = new AuthRequest("ramesh", "password", "MEMBER");
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(correctLogin)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token", notNullValue()))
                .andExpect(jsonPath("$.role", is("MEMBER")));
    }

    @Test
    @DisplayName("Security: Passwords stored in MongoDB are hashed with BCrypt and not plain-text")
    void testPasswordsHashedWithBCrypt() {
        Optional<User> ownerOpt = userRepository.findByUsername("owner");
        assertTrue(ownerOpt.isPresent(), "Owner user should exist");

        User owner = ownerOpt.get();
        assertFalse(owner.getPassword().equals("password"), "Password must NEVER be stored as plain-text");
        assertTrue(owner.getPassword().startsWith("$2a$") || owner.getPassword().startsWith("$2b$"),
                "Password must be hashed with BCrypt");
        assertTrue(passwordEncoder.matches("password", owner.getPassword()),
                "BCrypt encoder must match raw password against hash");
    }

    @Test
    @DisplayName("BUG 1 Security: Members cannot record, update or delete collections via API")
    void testMemberCannotRecordOrModifyCollections() throws Exception {
        AuthResponse memberAuth = authService.login(new AuthRequest("ramesh", "password"));
        String memberToken = "Bearer " + memberAuth.getToken();

        // 1. Attempting to record collection as Member must fail with 403 Forbidden
        MilkCollection unauthorizedEntry = new MilkCollection();
        unauthorizedEntry.setMemberCode("M001");
        unauthorizedEntry.setMemberName("Ramesh Patil");
        unauthorizedEntry.setAnimalType("Cow");
        unauthorizedEntry.setShift("Evening");
        unauthorizedEntry.setQuantity(15.0);
        unauthorizedEntry.setFat(4.5);
        unauthorizedEntry.setSnf(8.5);

        mockMvc.perform(post("/api/v1/collections")
                        .header("Authorization", memberToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(unauthorizedEntry)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error", containsString("Unauthorized")));

        // 2. Attempting to update collection as Member must fail with 403 Forbidden
        mockMvc.perform(put("/api/v1/collections/col_test_123")
                        .header("Authorization", memberToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(unauthorizedEntry)))
                .andExpect(status().isForbidden());

        // 3. Attempting to delete collection as Member must fail with 403 Forbidden
        mockMvc.perform(delete("/api/v1/collections/col_test_123")
                        .header("Authorization", memberToken))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Farmer-User Linking: Owner creates farmer profile & records 10L, Member registers/links & retrieves entry, Suresh cannot view")
    void testFarmerAccountLinkingAndCrossDeviceRetrieval() throws Exception {
        long ts = System.currentTimeMillis();
        AuthResponse ownerAuth = authService.login(new AuthRequest("owner", "password"));
        String ownerToken = "Bearer " + ownerAuth.getToken();

        // 1. Owner creates a new farmer profile for Ramesh
        com.smartdairy.backend.entity.Member farmer = new com.smartdairy.backend.entity.Member();
        String uniqueCode = "M" + (ts % 10000);
        farmer.setMemberCode(uniqueCode);
        farmer.setName("Ramesh Patil " + ts);
        farmer.setPhone("98765" + (ts % 100000));
        farmer.setAnimalType("Cow");
        farmer.setAvgFat(4.5);

        mockMvc.perform(post("/api/v1/members")
                        .header("Authorization", ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(farmer)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.memberCode", is(uniqueCode)));

        // 2. Owner records a 10L Cow Morning milk collection for Ramesh
        MilkCollection entry = new MilkCollection();
        entry.setMemberCode(uniqueCode);
        entry.setMemberName("Ramesh Patil " + ts);
        entry.setAnimalType("Cow");
        entry.setShift("Morning");
        entry.setQuantity(10.0);
        entry.setFat(4.5);
        entry.setSnf(8.6);
        entry.setRatePerLitre(41.20);
        entry.setTotalAmount(412.00);
        entry.setCollectionDate(LocalDate.now());

        mockMvc.perform(post("/api/v1/collections")
                        .header("Authorization", ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(entry)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.quantity", is(10.0)))
                .andExpect(jsonPath("$.memberCode", is(uniqueCode)));

        // 3. Ramesh registers as MEMBER using the Owner-issued Member Code
        String rameshUser = "ramesh_" + ts;
        RegisterRequest registerReq = new RegisterRequest(rameshUser, "password123", "password123", "MEMBER");
        registerReq.setMemberCode(uniqueCode);

        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registerReq)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.memberCode", is(uniqueCode)))
                .andExpect(jsonPath("$.fullName", containsString("Ramesh Patil")));

        // 4. Ramesh logs in as MEMBER
        AuthResponse loginRes = authService.login(new AuthRequest(rameshUser, "password123", "MEMBER"));
        String rameshToken = "Bearer " + loginRes.getToken();

        // 5. Ramesh retrieves collections -> Sees the exact saved entry with matching fields
        mockMvc.perform(get("/api/v1/collections/my-collections")
                        .header("Authorization", rameshToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].memberCode", is(uniqueCode)))
                .andExpect(jsonPath("$[0].quantity", is(10.0)))
                .andExpect(jsonPath("$[0].fat", is(4.5)))
                .andExpect(jsonPath("$[0].snf", is(8.6)))
                .andExpect(jsonPath("$[0].shift", is("Morning")))
                .andExpect(jsonPath("$[0].animalType", is("Cow")))
                .andExpect(jsonPath("$[0].totalAmount", is(412.00)));

        // 6. Suresh logs in -> cannot see Ramesh's entry
        AuthResponse sureshAuth = authService.login(new AuthRequest("suresh", "password"));
        String sureshToken = "Bearer " + sureshAuth.getToken();
        mockMvc.perform(get("/api/v1/collections/my-collections")
                        .header("Authorization", sureshToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.memberCode == '" + uniqueCode + "')]", empty()));

        // 7. Duplicate linking attempt: Another user tries to register with Ramesh's code -> Rejected with 400
        RegisterRequest dupReq = new RegisterRequest("imposter_" + ts, "password123", "password123", "MEMBER");
        dupReq.setMemberCode(uniqueCode);
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(dupReq)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error", containsString("already linked")));

        // 8. Registering with non-existent memberCode -> Rejected with 400
        RegisterRequest fakeReq = new RegisterRequest("fake_" + ts, "password123", "password123", "MEMBER");
        fakeReq.setMemberCode("NON_EXISTENT_9999");
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(fakeReq)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error", containsString("not found")));

        // 9. Unlinked Member Account: Registered without code -> receives empty collections & can link later
        String unlinkedUser = "unlinked_" + ts;
        RegisterRequest unlinkedReq = new RegisterRequest(unlinkedUser, "password123", "password123", "MEMBER");
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(unlinkedReq)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.memberCode").doesNotExist());

        AuthResponse unlinkedLogin = authService.login(new AuthRequest(unlinkedUser, "password123", "MEMBER"));
        String unlinkedToken = "Bearer " + unlinkedLogin.getToken();
        mockMvc.perform(get("/api/v1/collections/my-collections")
                        .header("Authorization", unlinkedToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(0)));

        // 10. Unlinked user links profile via /api/v1/members/link-profile
        // Create another farmer profile to link
        String linkCode = "M" + ((ts + 1) % 10000);
        com.smartdairy.backend.entity.Member secondFarmer = new com.smartdairy.backend.entity.Member();
        secondFarmer.setMemberCode(linkCode);
        secondFarmer.setName("Second Farmer " + ts);
        secondFarmer.setAnimalType("Buffalo");
        mockMvc.perform(post("/api/v1/members")
                        .header("Authorization", ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(secondFarmer)))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/v1/members/link-profile")
                        .header("Authorization", unlinkedToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(java.util.Map.of("memberCode", linkCode))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.memberCode", is(linkCode)))
                .andExpect(jsonPath("$.fullName", is("Second Farmer " + ts)));
    }
}
