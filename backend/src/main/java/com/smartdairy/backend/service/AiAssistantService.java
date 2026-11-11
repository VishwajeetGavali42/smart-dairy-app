package com.smartdairy.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.*;

@Service
public class AiAssistantService {

    @Value("${llm.provider:openai}")
    private String provider;

    @Value("${llm.api-key:${OPENAI_API_KEY:${LLM_API_KEY:}}}")
    private String apiKey;

    @Value("${llm.base-url:https://api.openai.com/v1}")
    private String baseUrl;

    @Value("${llm.model:${OPENAI_MODEL:gpt-4o-mini}}")
    private String model;

    @Value("${llm.temperature:0.3}")
    private double temperature;

    @Value("${llm.max-tokens:800}")
    private int maxTokens;

    @Value("${ollama.enabled:true}")
    private boolean ollamaEnabled = true;

    private static final Logger log = LoggerFactory.getLogger(AiAssistantService.class);

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(12))
            .build();
    private final OllamaService ollamaService;
    private final OnlineKnowledgeService onlineKnowledgeService;

    public AiAssistantService(OllamaService ollamaService, OnlineKnowledgeService onlineKnowledgeService) {
        this.ollamaService = ollamaService;
        this.onlineKnowledgeService = onlineKnowledgeService;
    }

    @PostConstruct
    public void logStartupStatus() {
        boolean ollamaReady = ollamaService != null && ollamaService.isOllamaAvailable();
        boolean configured = isLlmConfigured();
        String maskedKey;
        if (!configured || apiKey == null || apiKey.trim().isEmpty()) {
            maskedKey = "NONE (API key not configured)";
        } else if (apiKey.length() <= 8) {
            maskedKey = "*** (Set)";
        } else {
            maskedKey = apiKey.substring(0, 3) + "..." + apiKey.substring(apiKey.length() - 3);
        }

        log.info("=================================================");
        log.info("[AI Assistant Startup Check]");
        log.info("  Active Provider : {}", getProvider());
        log.info("  Active Model    : {}", getModel());
        log.info("  Ollama Status   : {}", ollamaReady ? "ONLINE & READY (llama3.1)" : "OFFLINE / UNREACHABLE");
        log.info("  OpenAI Status   : {}", (apiKey != null && !apiKey.isBlank()) ? "CONFIGURED (" + maskedKey + ")" : "NOT CONFIGURED");
        log.info("  Overall Status  : {}", configured ? "CONFIGURED & READY" : "USING LOCAL KNOWLEDGE FALLBACK");
        log.info("=================================================");
    }

    public static final String OLLAMA_COMPACT_SYSTEM_PROMPT = """
            You are the official Conversational AI Assistant for "Smart Dairy Application" (Late L D Kadam Milk Producers Cooperative Society Ltd., Kadamwadi, Kolhapur).
            You have two key roles:
            1. SMART DAIRY EXPERT: Answer any question regarding this dairy application: milk collection, dual-axis pricing (Cow base ₹38/L, Buffalo ₹54/L, FAT/SNF formulas), 10-day cycle billing (1-10, 11-20, 21-End), passbooks, cattle feed advances, and operational troubleshooting.
            2. UNIVERSAL KNOWLEDGE ASSISTANT: Answer ANY custom or general question asked by the user, including agriculture, dairy science, animal husbandry, cattle health, feed nutrition, weather, science, geography, technology, history, and general knowledge.
            Guidelines:
            - NEVER refuse a user's question by saying you can only discuss dairy or the app. Always provide a helpful, accurate, and polite answer to any custom question.
            - Provide clear, direct answers in 2 to 3 concise paragraphs in the requested language (English or Marathi).
            - When answering in Marathi, use natural and polite Marathi terms.
            - Never invent fake milk records or reveal passwords or private user data.
            """;

    public static final String SMART_DAIRY_SYSTEM_PROMPT = """
            You are the official Conversational AI Assistant for the "AI Assisted Smart Dairy Application".
            Your purpose is to answer any custom question about the dairy application, its operational features, billing calculations, milk collection workflows, data persistence, and troubleshooting.

            ### AUTHORITATIVE SMART DAIRY APPLICATION ARCHITECTURE & FEATURES:
            1. USER ROLES & ACCESS CONTROL:
               - DAIRY_OWNER / OWNER: Full dairy operational access. Can register farmers, record morning and evening milk collections, view dairy-wide metrics, grant cattle feed advances, generate 10-day or monthly billing statements, disburse payments, and dispatch milk tankers.
               - MEMBER (Farmer): Sells milk to the dairy. Can view only their personal Milk Passbook, collection history, daily milk slips, 10-day statement breakdowns, payment history, advances, and deductions. Can NEVER add, edit, or delete collections, and can NEVER view any other farmer's private data.
               - ADMIN: System configuration, developer support tickets, and audit trails. (Developer: Vishwajeet).

            2. ACCOUNT LINKING (MEMBER CODE):
               - Each farmer registered by the Dairy Owner has a unique Member Code (e.g., M001 for Ramesh Patil, M002 for Suresh Deshmukh, M003 for Pratik Kadam).
               - When a Member creates a login account, they must link their account to their dairy-issued Member Code.
               - If an account is not linked, the app displays "Account Not Linked to Farmer Profile" with a "Link Farmer Profile" action dialog.
               - TROUBLESHOOTING MISSING ENTRIES: If an Owner entered milk for a farmer (e.g., Pratik or Ramesh) but the farmer cannot see it on their phone:
                 a) Verify the farmer's login account is linked to the exact Member Code (e.g., M001) used by the Owner.
                 b) Check the date filter in the collection passbook (by default it might be set to 'Today'; switch to 'All Records' to view past dates).
                 c) Verify that both devices connect to the same Spring Boot / MongoDB backend server.

            3. MILK COLLECTION & PRICING RULES:
               - Shifts: Morning and Evening.
               - Animals: Cow (Base Rate around ₹38.0/L, min FAT 3.5%, min SNF 8.0%) and Buffalo (Base Rate around ₹54.0/L, min FAT 6.0%, min SNF 8.5%).
               - Dual-Axis Pricing Formula:
                 Rate (₹/L) = BaseRate + ((FAT - MinFAT) * 10 * FatStep) + ((SNF - MinSNF) * 10 * SnfStep).
                 Total Amount = Quantity (Ltr) * RatePerLitre.
               - FAT vs SNF Explained Simply:
                 • FAT: The butterfat / cream content in milk that floats on top.
                 • SNF (Solids-Not-Fat): Everything in milk solid matter except fat — primarily proteins (casein), lactose (milk sugar), and essential minerals (calcium, phosphorus).
               - Strict Validation: Quantity must be positive between 0.1 and 1000.0 L (decimal numbers only). FAT: 1.0%–15.0%, SNF: 4.0%–15.0%.
               - Hardware Auto-Read: Supports Bluetooth Low Energy (BLE) electronic weighing scales and ultrasonic milk analyzers (Auto-Read BLE button).
               - Duplicate Entry Prevention: If the same member code, date, shift, and quantity (within 0.001L) is submitted, the server rejects duplicates to prevent double-billing.

            4. BILLING CYCLES & SETTLEMENTS:
               - 10-Day Cooperative Cycles:
                 • Cycle 1: Days 1–10
                 • Cycle 2: Days 11–20
                 • Cycle 3: Day 21 to End of month.
               - Monthly Billing: Full calendar month consolidation.
               - Net Payable Calculation:
                 Net Amount = Gross Milk Total - Cattle Feed Advances Recovered - Store Deductions + Quality Bonuses.
               - Verification of 10-day Bills: To check whether a 10-day bill includes every collection, navigate to Billing & Invoices -> Select the cycle -> View the Shift Breakdown Table which lists date, shift, litres, FAT, SNF, and rate for each delivery. Compare the row count with your physical collection slips.
               - Certified PDF Reports: Generates downloadable/shareable PDF Detailed Bill Statements, Milk Slips, and Payout Receipts.

            5. ADVANCES & DEDUCTIONS:
               - Dairy Owners can grant advances (e.g., for cattle feed, festival, or medical emergencies).
               - Advances are recovered automatically across subsequent 10-day payment cycles until fully settled.

            6. TROUBLESHOOTING COMMON PROBLEMS:
               - WhatsApp Sharing: If WhatsApp sharing fails, ensure WhatsApp is installed on the phone, grant storage/media permission, or use the "Download PDF" button to save directly to local storage and share via standard Android share sheet.
               - Offline Synchronization: If network connection drops during collection, records are queued locally in the device's sync queue and automatically pushed to the backend MongoDB once connection resumes.

            7. AI CAPABILITIES DISCLOSURE:
               - The in-app Quality Score (0–100), Anomaly Detection (detecting dilution when FAT < 3.0% or SNF < 7.5%), and Yield Forecasting use deterministic, rule-based heuristics based on Indian dairy industry standards rather than trained neural networks.
               - The Conversational AI Chatbot connects to a real LLM for natural language conversation when configured.

            8. DATA PERSISTENCE & STORAGE:
               - Permanent Backend: Spring Boot 3.4.3 + MongoDB (`smart_dairy` database) + JWT security.
               - Reinstall & Restart: Because records reside in MongoDB, restarting the app, rebooting the phone/emulator, or uninstalling and reinstalling the app does NOT lose data. Logging back in retrieves all previously saved records.

            9. BILINGUAL SUPPORT:
               - Fully supports English and Marathi (मराठी). When the user asks in Marathi or requests Marathi, reply in fluent, polite Marathi.

            ### STRICT BEHAVIORAL INSTRUCTIONS:
            - Understand and answer ANY arbitrary or custom user question dynamically, including general knowledge, agriculture, animal care, science, and history. NEVER refuse to answer custom inquiries.
            - Answer follow-up questions naturally using conversation history.
            - If user asks to "explain more simply" or "explain it another way", adapt your tone with clear analogies.
            - When answering in Marathi, use natural dairy terms (दूध संकलन, फॅट, एसएनएफ, १०-दिवसीय बिल, आगाऊ रक्कम).
            - Ask a clarifying question when user intent is ambiguous.
            - NEVER reveal user passwords, secret keys, or another member's confidential records.
            - You are purely explanatory and advisory; you cannot directly mutate the database or trigger payments.
            """;

    public boolean isLlmConfigured() {
        if ("ollama".equalsIgnoreCase(getProvider())) {
            return ollamaEnabled && ollamaService != null && ollamaService.isOllamaAvailable();
        }
        if (baseUrl != null && (baseUrl.contains("localhost:11434") || baseUrl.contains("127.0.0.1:11434"))) {
            return true;
        }
        return apiKey != null && !apiKey.trim().isEmpty()
                && !apiKey.equalsIgnoreCase("none")
                && !apiKey.equalsIgnoreCase("YOUR_API_KEY");
    }

    public String getProvider() {
        if (provider != null && provider.equalsIgnoreCase("ollama")) {
            return "ollama";
        }
        if (apiKey != null && !apiKey.isBlank() && !apiKey.equalsIgnoreCase("none")) {
            return "openai";
        }
        if (ollamaEnabled && ollamaService != null && ollamaService.isOllamaAvailable()) {
            return "ollama";
        }
        return provider;
    }

    public String getModel() {
        if ("ollama".equalsIgnoreCase(getProvider())) {
            return ollamaService != null ? ollamaService.getModel() : "llama3.1";
        }
        return model;
    }

    public void setOllamaEnabled(boolean ollamaEnabled) {
        this.ollamaEnabled = ollamaEnabled;
    }

    public void setProvider(String provider) {
        this.provider = provider;
    }

    public String getBaseUrl() {
        return baseUrl;
    }

    public void setApiKey(String apiKey) {
        this.apiKey = apiKey;
    }

    public void setBaseUrl(String baseUrl) {
        this.baseUrl = baseUrl;
    }

    public void setModel(String model) {
        this.model = model;
    }

    public Map<String, Object> generateChatResponse(
            String prompt,
            String userRole,
            String screenContext,
            String language,
            List<Map<String, String>> history) {

        final String cleanPrompt = prompt != null ? prompt.trim() : "";
        final String lang = language != null && language.equalsIgnoreCase("mr") ? "mr" : "en";
        final String role = userRole != null ? userRole.toUpperCase() : "DAIRY_OWNER";

        // Check if real LLM is configured
        if (!isLlmConfigured()) {
            return buildNotConfiguredResponse(cleanPrompt, role, screenContext, lang, history);
        }

        // Live LLM is configured: execute genuine model request
        try {
            return callLlmApi(cleanPrompt, role, screenContext, lang, history);
        } catch (Exception e) {
            return buildErrorResponse(cleanPrompt, lang, e);
        }
    }

    private Map<String, Object> callLlmApi(
            String prompt,
            String userRole,
            String screenContext,
            String language,
            List<Map<String, String>> history) throws Exception {

        List<Map<String, String>> messages = new ArrayList<>();

        // 1. Search online knowledge (DuckDuckGo / Wikipedia) for real-time external info
        String onlineKnowledge = "";
        try {
            if (onlineKnowledgeService != null) {
                onlineKnowledge = onlineKnowledgeService.searchOnlineKnowledge(prompt);
            }
        } catch (Exception ignored) {}

        // 2. System Prompt with dynamic user context and online knowledge
        boolean isOllama = "ollama".equalsIgnoreCase(getProvider());
        String basePrompt = isOllama ? OLLAMA_COMPACT_SYSTEM_PROMPT : SMART_DAIRY_SYSTEM_PROMPT;
        StringBuilder sysBuilder = new StringBuilder(basePrompt);
        sysBuilder.append("\n\nCURRENT USER CONTEXT:\n");
        sysBuilder.append("- User Role: ").append(userRole).append("\n");
        sysBuilder.append("- Current App Screen: ").append(screenContext != null ? screenContext : "Home / General").append("\n");
        sysBuilder.append("- User Preferred Language: ").append(language.equals("mr") ? "Marathi (मराठी)" : "English").append("\n");
        if (!onlineKnowledge.isBlank()) {
            sysBuilder.append("\n").append(onlineKnowledge).append("\n");
            sysBuilder.append("Use the verified online knowledge above to enrich your answer accurately.\n");
        }
        sysBuilder.append("Please respond in ").append(language.equals("mr") ? "Marathi (मराठी)" : "English").append(".\n");

        messages.add(Map.of("role", "system", "content", sysBuilder.toString()));

        // 2. Multi-turn conversation history (last 10 messages for rich conversational context)
        if (history != null && !history.isEmpty()) {
            int start = Math.max(0, history.size() - 10);
            for (int i = start; i < history.size(); i++) {
                Map<String, String> h = history.get(i);
                String r = h.getOrDefault("role", "user");
                String c = sanitizeInput(h.getOrDefault("content", ""));
                if (!c.isBlank()) {
                    messages.add(Map.of("role", r.equals("assistant") ? "assistant" : "user", "content", c));
                }
            }
        }

        // 3. User's new prompt (sanitized to protect user privacy)
        messages.add(Map.of("role", "user", "content", sanitizeInput(prompt)));

        // Prefer local Ollama with Llama 3.1 model if available or configured
        if ("ollama".equalsIgnoreCase(getProvider())) {
            try {
                String reply = ollamaService.chat(messages);
                List<String> actions = generateFollowUpChips(prompt, language);
                return Map.of(
                        "reply", reply,
                        "suggestedActions", actions,
                        "isLlmGenerated", true,
                        "isConfigured", true,
                        "status", "SUCCESS",
                        "provider", "ollama",
                        "model", ollamaService.getModel()
                );
            } catch (Exception e) {
                log.warn("[AiAssistantService] Ollama chat attempt failed: {}", e.getMessage());
                // If OpenAI API key is set, attempt fallback to OpenAI; otherwise rethrow
                if (apiKey == null || apiKey.isBlank() || apiKey.equalsIgnoreCase("none")) {
                    throw e;
                }
            }
        }

        Map<String, Object> requestPayload = new HashMap<>();
        requestPayload.put("model", model);
        requestPayload.put("messages", messages);
        requestPayload.put("input", messages); // Support both Chat Completions & modern Responses API
        requestPayload.put("temperature", temperature);
        requestPayload.put("max_tokens", maxTokens);

        String jsonBody = objectMapper.writeValueAsString(requestPayload);

        String endpoint;
        if (baseUrl.endsWith("/chat/completions") || baseUrl.endsWith("/responses")) {
            endpoint = baseUrl;
        } else if (baseUrl.endsWith("/")) {
            endpoint = baseUrl + "chat/completions";
        } else {
            endpoint = baseUrl + "/chat/completions";
        }

        HttpRequest.Builder reqBuilder = HttpRequest.newBuilder()
                .uri(URI.create(endpoint))
                .header("Content-Type", "application/json")
                .timeout(Duration.ofSeconds(20))
                .POST(HttpRequest.BodyPublishers.ofString(jsonBody));

        if (apiKey != null && !apiKey.trim().isEmpty() && !apiKey.equalsIgnoreCase("none")) {
            reqBuilder.header("Authorization", "Bearer " + apiKey.trim());
        }

        HttpResponse<String> response = httpClient.send(reqBuilder.build(), HttpResponse.BodyHandlers.ofString());

        if (response.statusCode() == 200) {
            JsonNode root = objectMapper.readTree(response.body());
            
            // 1. Standard OpenAI Chat Completions API format
            JsonNode choices = root.path("choices");
            if (choices.isArray() && choices.size() > 0) {
                String reply = choices.get(0).path("message").path("content").asText();
                if (!reply.isBlank()) {
                    List<String> actions = generateFollowUpChips(prompt, language);
                    return Map.of(
                            "reply", reply,
                            "suggestedActions", actions,
                            "isLlmGenerated", true,
                            "isConfigured", true,
                            "status", "SUCCESS",
                            "provider", provider,
                            "model", model
                    );
                }
            }
            
            // 2. Modern OpenAI Responses API formats
            JsonNode outputText = root.path("output_text");
            if (!outputText.isMissingNode() && !outputText.asText().isBlank()) {
                return Map.of(
                        "reply", outputText.asText(),
                        "suggestedActions", generateFollowUpChips(prompt, language),
                        "isLlmGenerated", true,
                        "isConfigured", true,
                        "status", "SUCCESS",
                        "provider", provider,
                        "model", model
                );
            }
            JsonNode output = root.path("output");
            if (output.isArray() && output.size() > 0) {
                JsonNode contentArr = output.get(0).path("content");
                if (contentArr.isArray() && contentArr.size() > 0) {
                    String reply = contentArr.get(0).path("text").asText();
                    if (!reply.isBlank()) {
                        return Map.of(
                                "reply", reply,
                                "suggestedActions", generateFollowUpChips(prompt, language),
                                "isLlmGenerated", true,
                                "isConfigured", true,
                                "status", "SUCCESS",
                                "provider", provider,
                                "model", model
                        );
                    }
                }
            }
        }

        // If the configured endpoint explicitly returned 401 (Unauthorized) or 429 (Quota/Rate Limit),
        // throw so buildErrorResponse formats the transparent authentication/quota notice.
        if (response.statusCode() == 401 || response.statusCode() == 429) {
            throw new RuntimeException("LLM API returned status " + response.statusCode() + ": " + response.body());
        }

        // 3. Fallback to free online web LLM if direct API returned other error
        if (onlineKnowledgeService != null) {
            String freeReply = onlineKnowledgeService.fetchFreeOnlineLlmReply(prompt, sysBuilder.toString());
            if (freeReply != null && !freeReply.isBlank()) {
                return Map.of(
                        "reply", freeReply,
                        "suggestedActions", generateFollowUpChips(prompt, language),
                        "isLlmGenerated", true,
                        "isConfigured", true,
                        "status", "SUCCESS",
                        "provider", "online-knowledge",
                        "model", "web-ai"
                );
            }
        }

        throw new RuntimeException("LLM API returned status " + response.statusCode() + ": " + response.body());
    }

    private String sanitizeInput(String input) {
        if (input == null) return "";
        // Strip out passwords, tokens, or raw secrets from prompt/history before calling external LLM
        return input.replaceAll("(?i)(password|pwd|secret|auth_token|token)\\s*[:=]\\s*\\S+", "$1: [REDACTED]");
    }

    private Map<String, Object> buildNotConfiguredResponse(
            String prompt,
            String userRole,
            String screenContext,
            String language,
            List<Map<String, String>> history) {

        final boolean isMr = "mr".equalsIgnoreCase(language);
        final String p = prompt != null ? prompt.toLowerCase().trim() : "";

        // 1. Follow-up detection using conversation history
        boolean isFollowUp = p.contains("how do i fix") || p.contains("how to fix")
                || p.contains("how?") || p.equals("how")
                || p.contains("why not working") || p.contains("why is it not working")
                || p.contains("कसे दुरुस्त करावे") || p.contains("कसे करू");

        if (isFollowUp && history != null && !history.isEmpty()) {
            String lastUserMsg = "";
            for (int i = history.size() - 1; i >= 0; i--) {
                Map<String, String> m = history.get(i);
                if ("user".equalsIgnoreCase(m.get("role")) && !m.getOrDefault("content", "").equalsIgnoreCase(prompt)) {
                    lastUserMsg = m.getOrDefault("content", "").toLowerCase();
                    break;
                }
            }

            if (lastUserMsg.contains("missing") || lastUserMsg.contains("pratik") || lastUserMsg.contains("disappear")
                    || lastUserMsg.contains("entry") || lastUserMsg.contains("गायब")) {
                String reply = isMr
                        ? """
                        **शेतकऱ्याची गहाळ नोंद दुरुस्त करण्याचे टप्पे (Step-by-Step Fix for Missing Milk Entry):**

                        १. **शेतकरी आयडी पडताळा**: मालक डॅशबोर्डवरील 'Customer' यादीमध्ये जाऊन संबंधित शेतकऱ्याचा युनिक कोड (उदा. M001 किंवा M003) तपासा.
                        २. **खाते लिंक करा**: सभासदाने स्वतःचे मेंबर खाते तयार करताना मालकाने दिलेल्या शेतकरी प्रोफाइलशी खाते लिंक केले असल्याची खात्री करा.
                        ३. **तारीख आणि शिफ्ट तपासा**: संकलन स्क्रीनवर योग्य तारीख आणि शिफ्ट (Morning/Evening) निवडली आहे का ते पहा.
                        ४. **सिंक करा (Offline Sync)**: जर नोंद इंटरनेट नसताना नोंदवली असेल, तर डॅशबोर्डवरील क्लाउड आयकॉनवर (☁️) टॅप करून स्थानिक नोंदी सर्व्हरवर पाठवा.
                        """
                        : """
                        **Step-by-Step Fix for Missing Milk Entry:**

                        1. **Verify Member Code**: Open the Owner 'Customer' list and confirm the farmer's allocated member code (e.g. M001 or M003).
                        2. **Account Linking**: Ensure the Member login account has been correctly linked to the farmer profile created by the Owner.
                        3. **Check Date & Shift Filter**: Ensure the collection filter matches the exact date and shift (Morning / Evening) when the entry was recorded.
                        4. **Sync Queued Records**: If the record was added offline, tap the top Cloud (☁️) icon to flush local entries to the Spring Boot / MongoDB backend.
                        """;

                return buildDomainFallbackResponse(reply, isMr
                        ? List.of("दूध संकलन कसे नोंदवायचे?", "१०-दिवसीय बिलिंग")
                        : List.of("How to record milk collection?", "Explain 10-day billing"));
            }

            if (lastUserMsg.contains("pdf") || lastUserMsg.contains("अहवाल")) {
                String reply = isMr
                        ? """
                        **PDF समस्या निवारण टप्पे (Fixing PDF Issues):**

                        १. फोनच्या Settings -> Apps -> Smart Dairy -> Permissions मध्ये जाऊन स्टोरेज परवानगी ऑन करा.
                        २. निवडलेल्या बिलिंग सायकलमध्ये दूध संकलनाची किमान १ नोंद असल्याची खात्री करा.
                        ३. "Download PDF" बटणावर क्लिक करून फाइल थेट फोनच्या Downloads फोल्डरमध्ये सेव्ह करा.
                        """
                        : """
                        **Fixing PDF Generation & Download Issues:**

                        1. **Grant Storage Permission**: Go to device Settings -> Apps -> Smart Dairy -> Permissions and ensure Storage/Files access is enabled.
                        2. **Ensure Non-Empty Records**: Confirm that the selected member has recorded collections in the chosen billing cycle.
                        3. **Direct File Download**: Tap 'Download PDF' to write directly to your phone's public Downloads directory, then open with any PDF reader.
                        """;

                return buildDomainFallbackResponse(reply, isMr
                        ? List.of("तपशीलवार बिल मार्गदर्शक", "१०-दिवसीय बिलिंग")
                        : List.of("Detailed Bill guide", "Explain 10-day billing"));
            }
        }

        // 2. Detailed Bill & Statement Screen
        boolean isDetailedBill = p.contains("detailed bill") || p.contains("detail bill")
                || p.contains("तपशीलवार बिल") || p.contains("तपशील बिल")
                || p.contains("statement screen")
                || (p.matches(".*\\bbill\\b.*") && !p.contains("10-day") && !p.contains("cycle") && !p.contains("how does"))
                || (p.contains("बिल") && !p.contains("१० दिवस") && !p.contains("सायकल"));

        if (isDetailedBill) {
            String reply = isMr
                    ? """
                    **तपशीलवार बिल (Detailed Bill) स्क्रीन मार्गदर्शक:**

                    'तपशीलवार बिल' (Detailed Bill) स्क्रीन निवडलेल्या बिलिंग कालावधीतील (१०-दिवसीय सायकल, १५-दिवसीय किंवा मासिक) सभासदाच्या सर्व दूध संकलन नोंदींचे तपशीलवार विवरण दाखवते.

                    **यात खालील माहिती समाविष्ट असते:**
                    • **संकलन नोंदी (Shift Records)**: सायकलमधील प्रत्येक दिवसाचे सकाळ आणि संध्याकाळचे संकलन, तारीख, दुधाचे लिटर, FAT आणि SNF टक्केवारी.
                    • **दर आणि एकूण रक्कम (Rate & Gross Value)**: दुधाच्या गुणवत्तेनुसार संगणित केलेला प्रति लिटर दर आणि एकूण दुधाची किंमत.
                    • **कपाती (Deductions)**: पशूखाद्य खरेदी, औषधे किंवा आधी घेतलेली आगाऊ उचल (Advance Recovery).
                    • **निव्वळ देय रक्कम (Final Net Payable)**: शेतकऱ्याला प्रत्यक्षात बँक किंवा रोखीने द्यावयाची अंतिम रक्कम.

                    **कसे वापरावे?**:
                    1. डॅशबोर्ड किंवा मेनूमधून **"Detailed Bill"** (किंवा **"Billing & Invoices"**) उघडा.
                    2. शेतकरी निवडा आणि योग्य बिलिंग सायकल निवडा (उदा. सायकल १: १ ते १० तारीख).
                    3. सर्व नोंदी अचूक असल्याची खात्री करा.
                    4. शेतकऱ्याला देण्यासाठी किंवा व्हॉट्सॲपवर पाठवण्यासाठी **"Download PDF Statement"** वर टॅप करा.
                    """
                    : """
                    **Detailed Bill Screen Guide:**

                    The Detailed Bill screen shows a member's milk collection records for the selected billing period, including collection dates, morning and evening quantities, FAT, SNF, rates, amounts, applicable deductions, and the final payable amount, depending on the features implemented in the application.

                    **Key information displayed:**
                    • **Shift Collection Records**: Daily morning and evening deliveries showing date, milk volume (litres), FAT %, and SNF %.
                    • **Quality Rate & Gross Value**: Quality-adjusted rate per litre based on the FAT/SNF formula and total gross milk value.
                    • **Deductions & Advances**: Repayment of cattle feed loans, store purchases, and previous advance installments.
                    • **Final Net Payable**: The final net payout to be disbursed to the farmer after all applicable deductions.

                    **How to use:**
                    1. Open **Detailed Bill** (or **Billing & Invoices**) from the Dashboard or navigation menu.
                    2. Select the member / farmer and the desired settlement cycle (e.g. Cycle 1: Days 1–10).
                    3. Check that every eligible collection appears in the table.
                    4. Tap **Download PDF Statement** to generate, print, or share the statement via WhatsApp.
                    """;

            return buildDomainFallbackResponse(reply, isMr
                    ? List.of("१०-दिवसीय बिलिंग कसे चालते?", "PDF बिल कसे डाऊनलोड करावे?", "दूध दर कसा ठरवला जातो?")
                    : List.of("How does 10-day billing work?", "How to download PDF statement?", "How is milk rate calculated?"));
        }

        // 3. PDF Troubleshooting
        boolean isPdfTroubleshoot = (p.contains("pdf") || p.contains("अहवाल"))
                && (p.contains("not working") || p.contains("not work") || p.contains("error")
                || p.contains("fail") || p.contains("issue") || p.contains("problem")
                || p.contains("काम करत नाही") || p.contains("चालत नाही"));

        if (isPdfTroubleshoot) {
            String reply = isMr
                    ? """
                    **PDF अहवाल डाऊनलोड किंवा शेअर न झाल्यास उपाय (PDF Troubleshooting):**

                    १. **स्टोरेज परवानगी (Storage Permission)**: तुमच्या फोनच्या Settings -> Apps -> Smart Dairy -> Permissions मध्ये जाऊन स्टोरेज/फाइल्स परवानगी सक्रिय करा.
                    २. **नोंदी उपलब्ध आहेत का ते तपासा**: निवडलेल्या तारखेत किंवा बिलिंग सायकलमध्ये दूध संकलनाची किमान १ नोंद असणे आवश्यक आहे. रिकाम्या सायकलचे PDF तयार होत नाही.
                    ३. **पर्यायी मार्ग (Direct Download)**: थेट WhatsApp शेअर अयशस्वी झाल्यास **"Download PDF"** बटणावर टॅप करा. फाइल तुमच्या फोनच्या 'Downloads' फोल्डरमध्ये सेव्ह होईल.
                    ४. **PDF Viewer**: तुमच्या फोनमध्ये Google Drive किंवा कोणताही PDF व्ह्यूअर ॲप इन्स्टॉल असल्याची खात्री करा.
                    """
                    : """
                    **Troubleshooting PDF Generation and Sharing:**

                    If PDF statement or slip generation fails, follow these steps:
                    1. **Device Storage Permissions**: Open phone Settings -> Apps -> Smart Dairy -> Permissions and ensure "Files & Media" / Storage permission is granted.
                    2. **Verify Recorded Collections**: Ensure the selected date or billing cycle contains at least one collection record. An empty cycle cannot generate a statement.
                    3. **Use Direct Download**: If sharing directly to WhatsApp fails, tap **"Download PDF"** to save the file locally into your phone's 'Downloads' directory first.
                    4. **PDF Reader Installed**: Verify you have a standard PDF viewer (e.g. Google Drive Viewer) installed to preview generated documents.
                    """;

            return buildDomainFallbackResponse(reply, isMr
                    ? List.of("तपशीलवार बिल मार्गदर्शक", "१०-दिवसीय बिलिंग")
                    : List.of("Detailed bill guide", "Explain 10-day billing"));
        }

        // 4. Missing Milk Entry & Member Account Linking
        boolean isAccountLinking = (p.contains("link") || p.contains("connect") || p.contains("जोडा") || p.contains("लिंक"))
                && (p.contains("account") || p.contains("member") || p.contains("farmer") || p.contains("profile") || p.contains("खाते"));

        boolean isMissingEntry = (p.contains("missing") || p.contains("disappear") || p.contains("not visible")
                || p.contains("can't see") || p.contains("cant see") || p.contains("pratik") || p.contains("गायब") || p.contains("दिसत नाही"))
                && (p.contains("entry") || p.contains("milk") || p.contains("collection") || p.contains("record")
                || p.contains("दूध") || p.contains("नोंद") || p.contains("pratik"));

        if (isAccountLinking || isMissingEntry) {
            String reply = isMr
                    ? """
                    **दूध संकलन नोंद न दिसण्याची कारणे व उपाय (Troubleshooting Missing Milk Entries):**

                    १. **खाते लिंकिंग (Account Linking)**:
                       - मालकाने (Owner) शेतकरी तयार केल्यानंतर सभासदाने (Member) स्वतःचे खाते तयार केले असल्यास, मेंबर खाते त्या शेतकरी प्रोफाईलशी लिंक असणे आवश्यक आहे.
                    २. **भूमिका आधारित दृश्य (Role Isolation)**:
                       - मालक सर्व शेतकऱ्यांच्या नोंदी पाहू शकतात, परंतु सभासद केवळ त्यांच्या स्वतःच्या शेतकरी आयडीशी जोडलेल्या नोंदी पाहू शकतात.
                    ३. **तारीख व शिफ्ट फिल्टर**:
                       - संकलन स्क्रीनवरील तारीख आणि शिफ्ट (Morning/Evening) योग्य असल्याची खात्री करा.
                    ४. **ऑफलाईन सिंक**:
                       - जर नोंद इंटरनेट नसताना केली असेल, तर इंटरनेट आल्यावर डॅशबोर्डवरील वरच्या ढग आयकॉनवर (☁️) टॅप करून डेटा सिंक करा.
                    """
                    : """
                    **Why a Milk Entry Might Be Missing and How to Resolve It:**

                    1. **Account Linking**:
                       - When the Owner creates a farmer profile and the Member registers their own login account, the Member account must be linked to that specific farmer profile.
                    2. **Role Isolation & Permissions**:
                       - The Owner sees collection records across all farmers; a Member can only see entries strictly linked to their unique member ID.
                    3. **Date and Shift Filter**:
                       - Verify that the date picker and shift toggle (Morning / Evening) match the recorded entry.
                    4. **Offline Synchronization**:
                       - If the entry was saved offline, it resides in the local phone queue. Tap the Cloud (☁️) icon once connected to sync it to the MongoDB backend.
                    """;

            return buildDomainFallbackResponse(reply, isMr
                    ? List.of("दुरुस्ती कशी करावी?", "दूध संकलन कसे नोंदवायचे?", "१०-दिवसीय बिलिंग")
                    : List.of("How do I fix it?", "How to record milk collection?", "Explain 10-day billing"));
        }

        // 5. FAT and SNF
        boolean isFatSnf = (p.contains("fat") && p.contains("snf"))
                || p.contains("explain fat") || p.contains("explain snf")
                || p.contains("what is fat") || p.contains("what is snf")
                || (p.contains("फॅट") && p.contains("एसएनएफ"));

        if (isFatSnf) {
            String reply = isMr
                    ? """
                    **FAT आणि SNF म्हणजे काय? (Understanding Milk Quality):**

                    • **FAT (स्निग्धता / लोणी)**: दुधामधील नैसर्गिक चरबीचे (Butterfat) शेकडा प्रमाण.
                      - गायीच्या दुधात सामान्यतः **3.2% ते 4.5%** फॅट असते.
                      - म्हशीच्या दुधात **6.0% ते 9.0%** फॅट असते.

                    • **SNF (Solids-Not-Fat / फॅटरहित घटक)**: दुधामधून फॅट आणि पाणी वगळता उरलेले घटक—जसे की प्रथिने (Protein), लॅक्टोज आणि खनिजे.
                      - गायीसाठी प्रमाणभूत SNF: **8.3% ते 8.8%**.
                      - म्हशीसाठी प्रमाणभूत SNF: **8.8% ते 9.5%**.

                    💡 **महत्त्व**: ॲपमधील दर पत्रक (Rate Chart) हे फॅट आणि एसएनएफ यांच्या आधारावर प्रति लिटर भाव ठरवते. जर दुधात पाणी मिसळले असेल तर SNF कमी होतो, ज्यावर ॲपमधील AI अनॉमली डिटेक्शन त्वरित इशारा देते.
                    """
                    : """
                    **What are FAT and SNF in Milk Quality & Pricing?**

                    • **FAT (Butterfat %)**: The percentage of natural fatty oils in milk.
                      - Standard Cow Milk: **3.2% to 4.5%**.
                      - Standard Buffalo Milk: **6.0% to 9.0%** (richer in fat).

                    • **SNF (Solids-Not-Fat)**: All the nutritious solid components of milk other than butterfat and water—primarily protein, lactose (milk sugar), and essential minerals.
                      - Standard Cow Milk SNF: **8.3% to 8.8%**.
                      - Standard Buffalo Milk SNF: **8.8% to 9.5%**.

                    💡 **Why it matters**: The cooperative pricing matrix directly multiplies your FAT and SNF readings by configured step values. If water is added to milk, the SNF drops sharply, which our AI Anomaly Detector immediately flags.
                    """;

            return buildDomainFallbackResponse(reply, isMr
                    ? List.of("दूध दर कसा ठरवला जातो?", "१०-दिवसीय बिलिंग कसे चालते?")
                    : List.of("How is milk rate calculated?", "How does 10-day billing work?"));
        }

        // 6. AI & ML Features (using exact word boundary for AI/ML)
        boolean isAiQuery = p.matches(".*\\b(ai|ml)\\b.*")
                || p.contains("ai features") || p.contains("ai insights")
                || p.contains("quality score") || p.contains("forecast")
                || p.contains("anomaly") || p.contains("अनॉमली");

        if (isAiQuery) {
            String reply = isMr
                    ? """
                    **ॲपमधील AI आणि मशीन लर्निंग (ML) फिचर्स काय आहेत?**

                    1. **अनॉमली डिटेक्शन (Anomaly Detection)**:
                       - संकलन करताना फॅट (FAT) किंवा एसएनएफ (SNF) असामान्य आढळल्यास (उदा. दुधात पाणी मिसळल्यास SNF अचानक कमी होणे) ॲप त्वरित इशारा देते.
                    2. **दुधाचा गुणवत्ता स्कोअर (Milk Quality Prediction)**:
                       - संकलित दुधाचे शुद्धतेनुसार परीक्षण करून **Grade A / Good / Attention** असा दर्जा व स्कोअर (उदा. 86.5/100) देते.
                    3. **संकलन अंदाज (Collection Forecast)**:
                       - सकाळ आणि संध्याकाळच्या शिफ्टमध्ये एकूण किती लिटर दूध जमा होईल याचा अचूक अंदाज वर्तवते (उदा. Morning Shift: 720.5 Ltr), ज्यामुळे टँकर वाहतुकीचे नियोजन सोपे होते.

                    💡 **कसे पाहायचे?**: डॅशबोर्डवरील **"AI Insights"** कार्ड खाली **"View All"** वर टॅप करा!
                    """
                    : """
                    **What do the AI & ML Features in this App do?**

                    1. **Real-time Anomaly Detection**:
                       - Compares incoming FAT/SNF readings against biological norms. If excessive water dilution or bad sensor calibration occurs, an instant alert is triggered.
                    2. **Milk Quality Prediction**:
                       - Analyzes quality parameters and awards a purity score (e.g. **86.5/100 - Grade A Purity**), determining eligibility for clean milk bonuses.
                    3. **Shift Yield Forecasting**:
                       - Predicts upcoming collection volume (e.g. **Morning Shift: 720.5 Ltr • Evening: 533.5 Ltr**) using trend modeling to help schedule dispatch tankers efficiently.

                    💡 **How to view**: Tap **"View All"** next to **AI Insights** on your Dashboard home screen!
                    """;

            return buildDomainFallbackResponse(reply, isMr
                    ? List.of("FAT आणि SNF म्हणजे काय?", "दूध दर कसा ठरवला जातो?")
                    : List.of("What are FAT and SNF?", "How is milk rate calculated?"));
        }

        // 7. General Milk Collection
        if (p.contains("record milk") || p.contains("add collection") || p.contains("milk collection")
                || p.contains("दूध संकलन") || p.contains("संकलन कसे")) {
            String reply = isMr
                    ? """
                    **दूध संकलन नोंदवण्याची सोपी पद्धत (Recording Milk Collection):**

                    १. डॅशबोर्डवरील **"Milk Collection"** वर टॅप करा.
                    २. **तारीख आणि वेळ**: आजची तारीख व सकाळ (Morning) किंवा संध्याकाळ (Evening) शिफ्ट निवडा.
                    ३. **शेतकरी निवडा**: यादीतून नाव किंवा मेंबर आयडी निवडा.
                    ४. **जनावराचा प्रकार**: Cow (गाय) किंवा Buffalo (मशीचे दूध) निवडा.
                    ५. **वजन (Litre)**, **FAT%** आणि **SNF%** भरा. (किंवा BLE वजनकाटा वापरून Auto-Read करा).
                    ६. **SAVE COLLECTION** वर टॅप करा!
                    """
                    : """
                    **How to Record Milk Collection:**

                    1. Tap **"Milk Collection"** on the Dashboard.
                    2. Select the **Date** and Shift (**Morning** or **Evening**).
                    3. Select the **Farmer/Member** from the dropdown.
                    4. Choose **Animal Type** (Cow or Buffalo).
                    5. Enter **Quantity in Litres**, **FAT%**, and **SNF%** (or tap **Auto-Read (BLE)**).
                    6. Tap **"SAVE COLLECTION"** to commit the entry and generate a receipt!
                    """;

            return buildDomainFallbackResponse(reply, isMr
                    ? List.of("FAT आणि SNF म्हणजे काय?", "१०-दिवसीय बिलिंग कसे चालते?")
                    : List.of("What are FAT and SNF?", "How does 10-day billing work?"));
        }

        // 8. Unrelated Custom Question: Honestly inform user that Live LLM is unconfigured
        String reply = isMr
                ? String.format(
                """
                ⚠️ **थेट AI सहाय्यक सध्या अनुपलब्ध आहे (Live AI Unavailable)**

                तुम्ही विचारलेला सानुकूल प्रश्न: *"%s"*

                मी या सानुकूल प्रश्नाचे गतिमान उत्तर देऊ शकत नाही कारण बॅकएंडवर Large Language Model (LLM) API की जोडलेली नाही. अनपेक्षित किंवा नवीन प्रश्नांची हुबेहूब उत्तरे मिळवण्यासाठी कृपया खालीलप्रमाणे कॉन्फिगर करा:

                **१. API की मिळवा:**
                OpenAI (platform.openai.com) किंवा इतर OpenAI-सुसंगत सेवेची API Key मिळवा.

                **२. बॅकएंडवर की सेट करा:**
                • Windows PowerShell मध्ये:
                  `$env:OPENAI_API_KEY="sk-..."`
                • Linux/macOS मध्ये:
                  `export OPENAI_API_KEY="sk-..."`
                • किंवा `backend/src/main/resources/application.yml` मध्ये `llm.api-key` सेट करा.

                **३. मोफत स्थानिक मॉडेल (Ollama):**
                `ollama run llama3.1` सुरू करा आणि `llm.base-url: "http://localhost:11434/v1"` सेट करा.
                """, prompt)
                : String.format(
                """
                ⚠️ **Conversational AI Model Not Configured (Live AI Unavailable)**

                Your custom query: *"%s"*

                The AI Assistant cannot dynamically answer arbitrary custom questions because a live Large Language Model (LLM) API key has not been configured in the backend server.

                To enable genuine ChatGPT-like dynamic answers for any custom question:

                **1. Obtain an API Key:**
                Sign up at OpenAI (https://platform.openai.com) or an OpenAI-compatible provider.

                **2. Set Backend Environment Variable:**
                • In Windows PowerShell:
                  `$env:OPENAI_API_KEY="sk-..."`
                • In Linux/macOS:
                  `export OPENAI_API_KEY="sk-..."`
                • Or update `backend/src/main/resources/application.yml`:
                  ```yaml
                  llm:
                    api-key: "your-api-key-here"
                    model: "gpt-4o-mini"
                  ```

                **3. Free Local Offline Option (Ollama):**
                Run `ollama run llama3.1` and configure `llm.base-url: "http://localhost:11434/v1"`.

                **4. Restart the Spring Boot Backend Server.**
                """, prompt);

        List<String> actions = isMr
                ? List.of("तपशीलवार बिल कसे पाहावे?", "दूध संकलन कसे नोंदवायचे?", "FAT आणि SNF म्हणजे काय?")
                : List.of("Explain Detailed Bill", "How do I record milk collection?", "Explain FAT and SNF");

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("reply", reply);
        result.put("suggestedActions", actions);
        result.put("isLlmGenerated", false);
        result.put("isConfigured", false);
        result.put("status", "NOT_CONFIGURED");
        result.put("provider", provider);
        result.put("model", model);
        return result;
    }

    private Map<String, Object> buildDomainFallbackResponse(String baseReply, List<String> actions) {
        String note = "\n\n*(Note: This response is provided from Smart Dairy App Knowledge because the live Conversational LLM is unconfigured. To enable dynamic answers for any custom question, configure your OPENAI_API_KEY on the backend.)*";
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("reply", baseReply.trim() + note);
        result.put("suggestedActions", actions);
        result.put("isLlmGenerated", false);
        result.put("isConfigured", false);
        result.put("status", "LOCAL_FALLBACK");
        result.put("provider", provider);
        result.put("model", model);
        return result;
    }

    private Map<String, Object> buildErrorResponse(String prompt, String language, Exception e) {
        final boolean isMr = "mr".equalsIgnoreCase(language);
        String errorMsg = e.getMessage() != null ? e.getMessage() : "Unknown LLM error";
        String userFriendlyError;

        if (errorMsg.contains("401") || errorMsg.contains("Unauthorized") || errorMsg.contains("invalid_api_key")) {
            userFriendlyError = isMr
                    ? "❌ **LLM प्रमाणीकरण अयशस्वी (401 Unauthorized)**: पुरवलेली API Key अवैध किंवा अमान्य आहे. कृपया तुमची OpenAI किंवा LLM Provider API की तपासा."
                    : "❌ **LLM Authentication Failed (401 Unauthorized)**: The configured API key is invalid or expired. Please verify your OpenAI or LLM provider credentials.";
        } else if (errorMsg.contains("429") || errorMsg.contains("quota") || errorMsg.contains("Rate limit")) {
            userFriendlyError = isMr
                    ? "⚠️ **LLM कोटा संपला (429 Rate Limit / Quota Exceeded)**: तुमच्या API खात्याचा वापर मर्यादा किंवा क्रेडिट संपले आहे. कृपया तुमचे बिलिंग खाते तपासा."
                    : "⚠️ **LLM Rate Limit / Quota Exceeded (429)**: Your LLM provider quota or credit balance has been exhausted. Please verify your account billing at the provider portal.";
        } else if (errorMsg.contains("ConnectException") || errorMsg.contains("timed out") || errorMsg.contains("TimeoutException")) {
            userFriendlyError = isMr
                    ? "⏱️ **LLM सर्व्हरशी संपर्क होऊ शकला नाही (Connection Timeout)**: मॉडेल सर्व्हर वेळेत प्रतिसाद देत नाही. तुमचे इंटरनेट किंवा स्थानिक LLM चालू असल्याची खात्री करा."
                    : "⏱️ **LLM Service Timeout / Unreachable**: The LLM server did not respond within the timeout window. Please check your network connection or local LLM runner.";
        } else {
            userFriendlyError = (isMr ? "❌ **LLM त्रुटी**: " : "❌ **LLM Service Error**: ") + errorMsg;
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("reply", userFriendlyError);
        result.put("suggestedActions", isMr ? List.of("पुन्हा प्रयत्न करा", "सेटअप तपासा") : List.of("Retry query", "Check configuration"));
        result.put("isLlmGenerated", false);
        result.put("isConfigured", true);
        result.put("status", "ERROR");
        result.put("error", errorMsg);
        result.put("provider", provider);
        result.put("model", model);
        return result;
    }

    private List<String> generateFollowUpChips(String prompt, String language) {
        boolean isMr = "mr".equalsIgnoreCase(language);
        String p = prompt.toLowerCase();
        if (p.contains("collection") || p.contains("milk") || p.contains("दूध") || p.contains("नोंद")) {
            return isMr
                    ? List.of("उदाहरणासह समजावून सांगा", "FAT आणि SNF कसे ठरतात?", "पुढील पायरी काय?")
                    : List.of("Explain that more simply", "Give me an example", "What should I do next?");
        } else if (p.contains("billing") || p.contains("payment") || p.contains("बिल") || p.contains("पैसे")) {
            return isMr
                    ? List.of("१०-दिवसीय सायकल समजावा", "ॲडव्हान्स कसा वजा होतो?", "PDF बिल डाऊनलोड")
                    : List.of("Explain 10-day cycles", "How are advances deducted?", "How to check every entry in bill?");
        } else {
            return isMr
                    ? List.of("अधिक सोप्या भाषेत सांगा", "उदाहरणासह स्पष्ट करा", "पुढील पायरी काय?")
                    : List.of("Explain that more simply", "Can you explain it another way?", "What should I do next?");
        }
    }
}
