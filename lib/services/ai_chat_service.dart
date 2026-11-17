import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/chat_message.dart';
import '../data/dairy_assistant_knowledge.dart';
import 'api_service.dart';
import 'language_service.dart';

class AiChatService {
  /// Base API URL inherited from centralized ApiService
  static String get baseUrl => ApiService.baseUrl;

  /// Endpoint path for backend AI gateway
  static const String chatEndpoint = '/ai/chat';
  static const String statusEndpoint = '/ai/status';

  // --- Cloud AI Configuration (Always-On 24/7 Mobile AI without Laptop) ---
  static String? groqApiKey;
  static String? geminiApiKey;
  static String preferredCloudProvider = 'groq'; // 'groq' or 'gemini'
  static bool _configLoaded = false;

  static File _getConfigFile() {
    return File('${Directory.systemTemp.path}/smartdairy_ai_cloud_config.json');
  }

  /// Initialize and load stored Cloud API keys from local persistence
  static Future<void> loadCloudConfig() async {
    if (_configLoaded) return;
    try {
      final file = _getConfigFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final map = jsonDecode(content) as Map<String, dynamic>;
        groqApiKey = map['groqApiKey']?.toString();
        geminiApiKey = map['geminiApiKey']?.toString();
        preferredCloudProvider = map['provider']?.toString() ?? 'groq';
      }
      _configLoaded = true;
    } catch (e) {
      debugPrint('Error loading AI cloud config: $e');
    }
  }

  /// Save Free Cloud AI keys permanently on the mobile phone
  static Future<void> saveCloudConfig({
    String? groqKey,
    String? geminiKey,
    String? provider,
  }) async {
    if (groqKey != null) groqApiKey = groqKey.trim();
    if (geminiKey != null) geminiApiKey = geminiKey.trim();
    if (provider != null) preferredCloudProvider = provider.trim();
    try {
      final file = _getConfigFile();
      final map = {
        'groqApiKey': groqApiKey,
        'geminiApiKey': geminiApiKey,
        'provider': preferredCloudProvider,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await file.writeAsString(jsonEncode(map), flush: true);
      _configLoaded = true;
    } catch (e) {
      debugPrint('Error saving AI cloud config: $e');
    }
  }

  /// Returns true if any 24/7 Cloud AI provider is configured
  static bool get isCloudConfigured {
    if (preferredCloudProvider == 'gemini') {
      return geminiApiKey != null && geminiApiKey!.trim().isNotEmpty;
    }
    return groqApiKey != null && groqApiKey!.trim().isNotEmpty;
  }

  /// Ping and test Free Cloud AI key
  static Future<Map<String, dynamic>> testCloudAi({
    required String apiKey,
    String provider = 'groq',
  }) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      return {'success': false, 'message': 'API Key cannot be empty'};
    }

    final sw = Stopwatch()..start();
    try {
      if (provider == 'gemini') {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$cleanKey',
        );
        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': [
                  {
                    'role': 'user',
                    'parts': [
                      {'text': 'Hello, confirm AI connection in 3 words.'}
                    ],
                  }
                ],
              }),
            )
            .timeout(const Duration(seconds: 8));
        sw.stop();

        if (response.statusCode == 200) {
          return {
            'success': true,
            'latencyMs': sw.elapsedMilliseconds,
            'message': 'Connected to Google Gemini Flash successfully! (${sw.elapsedMilliseconds} ms)',
          };
        } else {
          return {
            'success': false,
            'latencyMs': sw.elapsedMilliseconds,
            'message': 'Gemini Error (${response.statusCode}): ${response.body}',
          };
        }
      } else {
        // Groq Cloud Llama 3.1
        final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
        final response = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $cleanKey',
              },
              body: jsonEncode({
                'model': 'llama-3.1-8b-instant',
                'messages': [
                  {'role': 'user', 'content': 'Hello, confirm connection in 3 words.'}
                ],
                'max_tokens': 20,
              }),
            )
            .timeout(const Duration(seconds: 8));
        sw.stop();

        if (response.statusCode == 200) {
          return {
            'success': true,
            'latencyMs': sw.elapsedMilliseconds,
            'message': 'Connected to Groq Llama 3.1 Cloud successfully! (${sw.elapsedMilliseconds} ms)',
          };
        } else {
          return {
            'success': false,
            'latencyMs': sw.elapsedMilliseconds,
            'message': 'Groq Error (${response.statusCode}): ${response.body}',
          };
        }
      }
    } catch (e) {
      sw.stop();
      return {
        'success': false,
        'latencyMs': sw.elapsedMilliseconds,
        'message': 'Cloud AI connection failed: $e',
      };
    }
  }

  /// Check backend AI configuration status
  static Future<Map<String, dynamic>> checkAiStatus() async {
    await loadCloudConfig();

    final candidateHosts = [
      '$baseUrl$statusEndpoint',
      'https://smart-dairy-app-ak9w.onrender.com/api/v1$statusEndpoint',
      'http://192.168.118.201:8080/api/v1$statusEndpoint',
      'http://10.0.2.2:8080/api/v1$statusEndpoint',
      'http://127.0.0.1:8080/api/v1$statusEndpoint',
      'http://localhost:8080/api/v1$statusEndpoint',
    ].toSet().toList();

    for (final testUrl in candidateHosts) {
      try {
        final uri = Uri.parse(testUrl);
        final response = await http
            .get(
              uri,
              headers: {
                'Accept': 'application/json',
                if (ApiService.authToken != null)
                  'Authorization': 'Bearer ${ApiService.authToken}',
              },
            )
            .timeout(const Duration(milliseconds: 1500));

        if (response.statusCode == 200) {
          ApiService.isOffline = false;
          ApiService.setServerHost(uri.authority);
          final res = jsonDecode(response.body) as Map<String, dynamic>;
          res['source'] = 'laptop';
          return res;
        }
      } catch (_) {}
    }

    if (isCloudConfigured) {
      return {
        'configured': true,
        'status': 'CLOUD_AI_ACTIVE',
        'source': 'cloud',
        'provider': preferredCloudProvider,
        'offline': false,
      };
    }

    return {'configured': false, 'status': 'UNREACHABLE', 'offline': true};
  }

  /// Query 24/7 Free Cloud AI directly from mobile phone
  static Future<String?> _queryFreeCloudAi({
    required String prompt,
    required String role,
    required String languageCode,
    String? currentScreen,
    List<Map<String, String>>? history,
  }) async {
    await loadCloudConfig();

    final isMr = languageCode == 'mr';
    final systemPrompt = '''
You are the Smart Dairy Conversational AI Assistant. You are an expert in dairy management, milk collection, FAT and SNF calculation, dual-axis pricing, 10-day settlement billing, cattle nutrition, and app guidance.
User role: $role
Active Screen context: ${currentScreen ?? 'General'}
User language: ${isMr ? 'Marathi (मराठी)' : 'English'}

Provide concise, highly accurate, and helpful answers. If asked in Marathi, respond naturally in Marathi (देवनागरी). If asked in English, answer in English. Similar to ChatGPT, answer any general or technical dairy questions accurately.
'''.trim();

    // 1. Try Groq Cloud (Free Llama 3.1)
    if (preferredCloudProvider == 'groq' && groqApiKey != null && groqApiKey!.trim().isNotEmpty) {
      try {
        final messages = <Map<String, String>>[
          {'role': 'system', 'content': systemPrompt},
          if (history != null) ...history,
          {'role': 'user', 'content': prompt},
        ];

        final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
        final response = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${groqApiKey!.trim()}',
              },
              body: jsonEncode({
                'model': 'llama-3.1-8b-instant',
                'messages': messages,
                'temperature': 0.3,
                'max_tokens': 800,
              }),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content = data['choices']?[0]?['message']?['content']?.toString();
          if (content != null && content.trim().isNotEmpty) {
            return content.trim();
          }
        }
      } catch (e) {
        debugPrint('Groq Cloud AI error: $e');
      }
    }

    // 2. Try Google Gemini Flash (Free Tier)
    if (geminiApiKey != null && geminiApiKey!.trim().isNotEmpty) {
      try {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiApiKey!.trim()}',
        );
        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': [
                  {
                    'role': 'user',
                    'parts': [
                      {'text': '$systemPrompt\n\nUser Question:\n$prompt'}
                    ],
                  }
                ],
              }),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content = data['candidates']?[0]?['content']?['parts']?[0]?['text']?.toString();
          if (content != null && content.trim().isNotEmpty) {
            return content.trim();
          }
        }
      } catch (e) {
        debugPrint('Gemini Cloud AI error: $e');
      }
    }

    return null;
  }

  /// Sends a user question to the Conversational AI Assistant and returns a structured ChatMessage.
  /// 1. Tries Laptop Spring Boot + Ollama (when laptop is running on Wi-Fi).
  /// 2. Seamlessly falls back to 24/7 Free Cloud AI (Groq Llama 3.1 / Gemini) directly on mobile!
  /// 3. If offline / no internet, falls back to local verified knowledge.
  static Future<ChatMessage> sendMessage({
    required String prompt,
    String? currentScreen,
    String? userRole,
    String? preferredLanguageCode,
    List<ChatMessage>? conversationHistory,
  }) async {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty) {
      throw ArgumentError('Prompt cannot be empty');
    }

    final activeRole = userRole ?? ApiService.userRole;
    final langCode = preferredLanguageCode ?? LanguageService.currentLanguageCode;
    final isMr = langCode == 'mr';

    final historyPayload = (conversationHistory ?? [])
        .where((m) => m.id != 'welcome_msg')
        .map((m) => {
              'role': m.sender == MessageSender.user ? 'user' : 'assistant',
              'content': m.text,
            })
        .toList();

    // -------------------------------------------------------------
    // Tier 1: Laptop Backend Gateway (Spring Boot + Ollama Llama 3.1)
    // -------------------------------------------------------------
    final candidateUrls = [
      '$baseUrl$chatEndpoint',
      'http://192.168.118.201:8080/api/v1$chatEndpoint',
      'http://10.0.2.2:8080/api/v1$chatEndpoint',
      'http://127.0.0.1:8080/api/v1$chatEndpoint',
      'http://localhost:8080/api/v1$chatEndpoint',
    ].toSet().toList();

    for (final targetUrl in candidateUrls) {
      try {
        final uri = Uri.parse(targetUrl);
        // Fast probe to verify if host is alive before waiting for full Ollama inference
        final probeUri = Uri.parse('${uri.scheme}://${uri.authority}/api/v1/auth/health');
        try {
          final probeRes = await http.get(probeUri).timeout(const Duration(seconds: 4));
          if (probeRes.statusCode != 200 && probeRes.statusCode != 401) {
            continue;
          }
        } catch (_) {
          continue; // Host dead, immediately try next candidate or fall back to 24/7 Cloud AI
        }

        final response = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                if (ApiService.authToken != null)
                  'Authorization': 'Bearer ${ApiService.authToken}',
              },
              body: jsonEncode({
                'prompt': cleanPrompt,
                'role': activeRole,
                'screenContext': currentScreen,
                'language': langCode,
                'history': historyPayload,
              }),
            )
            .timeout(const Duration(seconds: 45));

        if (response.statusCode == 200) {
          ApiService.isOffline = false;
          ApiService.setServerHost(uri.authority);
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final replyText = data['reply'] ?? data['text'] ?? data['answer'] ?? '';
          if (replyText.isNotEmpty) {
            final isLlm = data['isLlmGenerated'] == true || data['llmGenerated'] == true;
            final isConfigured = data['isConfigured'] != false && data['configured'] != false;
            final status = data['status']?.toString() ?? 'SUCCESS';
            final isError = status == 'ERROR';

            return ChatMessage(
              id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
              text: replyText.toString(),
              sender: MessageSender.assistant,
              timestamp: DateTime.now(),
              isOfflineResponse: false,
              isLlmGenerated: isLlm,
              isConfigured: isConfigured,
              isError: isError,
              suggestedActions: (data['suggestedActions'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList(),
              featureContext: currentScreen,
            );
          }
        }
      } catch (_) {
        // Continue to next candidate URL
      }
    }

    // -------------------------------------------------------------
    // Tier 2: Direct 24/7 Free Cloud AI (Groq Llama 3.1 / Gemini)
    // Works always on mobile, even when laptop is turned off!
    // -------------------------------------------------------------
    final cloudReply = await _queryFreeCloudAi(
      prompt: cleanPrompt,
      role: activeRole,
      languageCode: langCode,
      currentScreen: currentScreen,
      history: historyPayload,
    );

    if (cloudReply != null && cloudReply.isNotEmpty) {
      return ChatMessage(
        id: 'cloud_${DateTime.now().millisecondsSinceEpoch}',
        text: cloudReply,
        sender: MessageSender.assistant,
        timestamp: DateTime.now(),
        isOfflineResponse: false,
        isLlmGenerated: true,
        isConfigured: true,
        isError: false,
        suggestedActions: isMr
            ? ['दूध संकलन कसे नोंदवायचे?', '१०-दिवसीय बिलिंग कसे चालते?']
            : ['How do I record milk collection?', 'How does 10-day billing work?'],
        featureContext: currentScreen,
      );
    }

    // -------------------------------------------------------------
    // Tier 3: Local Knowledge-Based Engine Fallback
    // -------------------------------------------------------------
    final knowledgeResult = DairyAssistantKnowledge.findAnswer(
      query: cleanPrompt,
      userRole: activeRole,
      currentScreen: currentScreen,
      languageCode: langCode,
      conversationHistory: conversationHistory,
    );

    final localText = knowledgeResult['text'] as String?;
    final fallbackText = localText ??
        (isMr
            ? '''⚠️ लॅपटॉप सध्या बंद आहे किंवा संपर्क होत नाही.

तुमच्या मोबाईलवर २४/७ कोणत्याही सानुकूल प्रश्नाचे अचूक उत्तर मिळवण्यासाठी '24/7 Mobile Cloud AI' चालू करा.
हे १००% विनामूल्य आहे आणि क्रेडिट कार्ड लागत नाही!

वर ⚙️ सेटिंग्जवर टॅप करून विनामूल्य Groq API Key (Llama 3.1) टाका.'''
            : '''⚠️ Laptop server is currently unreachable.

To get dynamic answers to arbitrary custom questions 24/7 directly on your mobile, enable '24/7 Mobile Cloud AI'.
It is 100% Free Forever with NO credit card needed!

Tap ⚙️ Settings above and enter your free Groq API key (Llama 3.1).''');

    return ChatMessage(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      text: fallbackText,
      sender: MessageSender.assistant,
      timestamp: DateTime.now(),
      isOfflineResponse: true,
      isLlmGenerated: false,
      isConfigured: false,
      suggestedActions: (knowledgeResult['suggestedActions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          (isMr
              ? ['⚙️ 24/7 Mobile AI चालू करा (Free)', 'दूध संकलन कसे नोंदवायचे?', '१०-दिवसीय बिलिंग कसे चालते?']
              : [
                  '⚙️ Enable 24/7 Mobile AI (Free)',
                  'How do I record milk collection?',
                  'How does 10-day billing work?',
                ]),
      featureContext: currentScreen,
    );
  }

  /// Welcome greeting for the chatbot
  static ChatMessage getWelcomeMessage({
    String? currentScreen,
    String? userRole,
    String? languageCode,
    bool isLlmConfigured = true,
  }) {
    final lang = languageCode ?? LanguageService.currentLanguageCode;
    final isMr = lang == 'mr';
    final role = (userRole ?? ApiService.userRole).toUpperCase();

    String roleName = isMr ? 'डेअरी मालक' : 'Dairy Owner';
    if (role == 'EMPLOYEE' || role == 'OPERATOR') {
      roleName = isMr ? 'ऑपरेटर / कर्मचारी' : 'Operator';
    } else if (role == 'MEMBER') {
      roleName = isMr ? 'शेतकरी / सभासद' : 'Farmer / Member';
    } else if (role == 'ADMIN') {
      roleName = isMr
          ? 'सिस्टम ॲडमिन आणि डेव्हलपर (विश्वजीत)'
          : 'System Admin & App Developer (Vishwajeet)';
    }

    final welcomeText = isMr
        ? '''नमस्कार $roleName! मी तुमचा **Smart Dairy Conversational AI Assistant** आहे. 🥛

मी ChatGPT प्रमाणे तुमच्या कोणत्याही सानुकूल प्रश्नाचे उत्तर, दूध संकलन, FAT/SNF हिशोब, १०-दिवसीय बिलिंग, शेतकरी कोड लिंकिंग, आणि तांत्रिक अडचणी सोडवण्यात थेट मार्गदर्शन करू शकतो.

तुम्ही लॅपटॉप चालू असताना (Ollama Llama 3.1) किंवा लॅपटॉप बंद असताना २४/७ मोबाईलवर (Cloud AI) कोणताही प्रश्न स्वतःच्या शब्दांत विचारू शकता!'''
        : '''Hello, $roleName! I am your **Smart Dairy Conversational AI Assistant**. 🥛

Similar to ChatGPT, I can understand arbitrary questions in natural language, explain FAT/SNF pricing calculations, guide 10-day settlement billing, troubleshoot missing milk entries, and help navigate every feature.

Whether your laptop is running or off, I can assist you 24/7 directly on your mobile device!''';

    final starterActions = isMr
        ? (role == 'ADMIN'
            ? [
                'डेअरी मालकांच्या समस्या कशा सोडवायच्या?',
                'ॲडमिनचे पूर्ण अधिकार (Full Access) समजावा',
                'दूध संकलन कसे नोंदवायचे?',
                'FAT आणि SNF म्हणजे काय?',
                'दूध दर कसा ठरवला जातो?',
                '१०-दिवसीय बिलिंग कसे चालते?',
              ]
            : [
                'दूध संकलन कसे नोंदवायचे?',
                'FAT आणि SNF म्हणजे काय?',
                'दूध दर कसा ठरवला जातो?',
                '१०-दिवसीय बिलिंग कसे चालते?',
                'शेतकऱ्याला नोंद का दिसत नाही?',
                'PDF बिल कसे काढायचे?',
              ])
        : (role == 'ADMIN'
            ? [
                'How do I solve dairy owner issues?',
                'Explain Admin Full Access permissions',
                'How do I record milk collection?',
                'Explain FAT and SNF in simple words',
                'How is milk rate calculated?',
                'How does 10-day billing work?',
              ]
            : [
                'How do I record milk collection?',
                'Explain FAT and SNF in simple words',
                'How is milk rate calculated?',
                'How does 10-day billing work?',
                "Why is milk not visible in farmer's account?",
                'How do I generate a PDF report?',
              ]);

    return ChatMessage(
      id: 'welcome_msg',
      text: welcomeText,
      sender: MessageSender.assistant,
      timestamp: DateTime.now(),
      isOfflineResponse: false,
      isLlmGenerated: false,
      isConfigured: isLlmConfigured,
      suggestedActions: starterActions,
      featureContext: currentScreen,
    );
  }
}

