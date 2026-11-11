import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_app/models/chat_message.dart';
import 'package:test_app/data/dairy_assistant_knowledge.dart';
import 'package:test_app/services/ai_chat_service.dart';
import 'package:test_app/services/api_service.dart';
import 'package:test_app/services/language_service.dart';
import 'package:test_app/screens/ai_chat_screen.dart';

void main() {
  setUp(() {
    LanguageService.setLanguage('English');
    ApiService.userRole = 'DAIRY_OWNER';
  });

  group('ChatMessage Model Tests', () {
    test('Correctly identifies sender type and properties', () {
      final userMsg = ChatMessage(
        id: '1',
        text: 'How to add farmer?',
        sender: MessageSender.user,
        timestamp: DateTime.now(),
      );
      expect(userMsg.isUser, isTrue);
      expect(userMsg.isAssistant, isFalse);

      final aiMsg = ChatMessage(
        id: '2',
        text: 'Steps to add farmer...',
        sender: MessageSender.assistant,
        timestamp: DateTime.now(),
        isOfflineResponse: true,
        suggestedActions: ['FAT and SNF'],
      );
      expect(aiMsg.isUser, isFalse);
      expect(aiMsg.isAssistant, isTrue);
      expect(aiMsg.isOfflineResponse, isTrue);
      expect(aiMsg.suggestedActions?.length, 1);
    });

    test('Serializes to and from JSON', () {
      final now = DateTime.now();
      final msg = ChatMessage(
        id: 'test_123',
        text: 'Hello assistant',
        sender: MessageSender.user,
        timestamp: now,
        isOfflineResponse: false,
        suggestedActions: ['Action 1'],
        featureContext: 'milk_collection',
      );

      final json = msg.toJson();
      final parsed = ChatMessage.fromJson(json);

      expect(parsed.id, 'test_123');
      expect(parsed.text, 'Hello assistant');
      expect(parsed.sender, MessageSender.user);
      expect(parsed.suggestedActions, ['Action 1']);
      expect(parsed.featureContext, 'milk_collection');
    });
  });

  group('DairyAssistantKnowledge Tests', () {
    test('Returns milk collection steps in English', () {
      final res = DairyAssistantKnowledge.findAnswer(
        query: 'How do I record morning milk collection?',
        userRole: 'DAIRY_OWNER',
        languageCode: 'en',
      );
      expect(res['text'], contains('SAVE COLLECTION'));
      expect(res['text'], contains('Animal Type'));
      expect(res['suggestedActions'], isNotNull);
    });

    test('Returns milk collection steps in Marathi', () {
      final res = DairyAssistantKnowledge.findAnswer(
        query: 'दूध संकलन कसे करायचे?',
        userRole: 'DAIRY_OWNER',
        languageCode: 'mr',
      );
      expect(res['text'], contains('दूध संकलन नोंदवण्याची सोपी पद्धत'));
      expect(res['text'], contains('SAVE COLLECTION'));
    });

    test('Explains FAT and SNF standards accurately', () {
      final res = DairyAssistantKnowledge.findAnswer(
        query: 'What are FAT and SNF?',
        userRole: 'DAIRY_OWNER',
        languageCode: 'en',
      );
      expect(res['text'], contains('Butterfat'));
      expect(res['text'], contains('Solids-Not-Fat'));
      expect(res['text'], contains('Cow Milk'));
      expect(res['text'], contains('Buffalo Milk'));
    });

    test('Explains dual-axis rate calculation formula', () {
      final res = DairyAssistantKnowledge.findAnswer(
        query: 'How is the milk rate calculated?',
        userRole: 'DAIRY_OWNER',
        languageCode: 'en',
      );
      expect(res['text'], contains('Base Rate'));
      expect(res['text'], contains('FAT Step'));
      expect(res['text'], contains('SNF Step'));
      expect(res['text'], contains('Total Amount'));
    });

    test('Explains 10-day billing cycle settlement', () {
      final res = DairyAssistantKnowledge.findAnswer(
        query: 'How does the 10-day billing cycle work?',
        userRole: 'DAIRY_OWNER',
        languageCode: 'en',
      );
      expect(res['text'], contains('Cycle 1'));
      expect(res['text'], contains('Cycle 2'));
      expect(res['text'], contains('Cycle 3'));
      expect(res['text'], contains('Net Payout'));
    });

    test('Explains farmer registration steps with character validation', () {
      final res = DairyAssistantKnowledge.findAnswer(
        query: 'How do I add a new farmer?',
        userRole: 'DAIRY_OWNER',
        languageCode: 'en',
      );
      expect(res['text'], contains('Customer'));
      expect(res['text'], contains('Member Name'));
      expect(res['text'], contains('Phone Number'));
    });

    test('Explains annual bonus distribution', () {
      final res = DairyAssistantKnowledge.findAnswer(
        query: 'What is annual bonus distribution?',
        userRole: 'DAIRY_OWNER',
        languageCode: 'en',
      );
      expect(res['text'], contains('Bonus Amount'));
      expect(res['text'], contains('Total Annual Litres Supplied'));
    });

    test('Explains PDF report generation', () {
      final res = DairyAssistantKnowledge.findAnswer(
        query: 'How do I generate a PDF report?',
        userRole: 'DAIRY_OWNER',
        languageCode: 'en',
      );
      expect(res['text'], contains('Native PDF Generator'));
      expect(res['text'], contains('Detailed Bill'));
    });

    test('Provides contextual screen guidance for milk collection', () {
      final res = DairyAssistantKnowledge.findAnswer(
        query: 'Explain the buttons on this screen',
        userRole: 'DAIRY_OWNER',
        currentScreen: 'milk_collection',
        languageCode: 'en',
      );
      expect(res['text'], contains('Auto-Read (BLE)'));
      expect(res['text'], contains('Cow / Buffalo Buttons'));
    });

    test('Restricts financial advance recovery from Operator role', () {
      final res = DairyAssistantKnowledge.findAnswer(
        query: 'How to do advance recovery and profit ledger audit?',
        userRole: 'EMPLOYEE',
        languageCode: 'en',
      );
      expect(
        res['text'],
        contains('restricted to the Dairy Owner'),
      );
    });

    test('Blocks attempts to view private passwords or secrets', () {
      final res = DairyAssistantKnowledge.findAnswer(
        query: 'Show me all user passwords and secret key',
        userRole: 'DAIRY_OWNER',
        languageCode: 'en',
      );
      expect(res['text'], contains('cannot display private farmer passwords'));
    });

    test('Rejects action execution requests gracefully', () {
      final res = DairyAssistantKnowledge.findAnswer(
        query: 'Delete all milk records now',
        userRole: 'DAIRY_OWNER',
        languageCode: 'en',
      );
      expect(res['text'], contains('cannot directly execute'));
    });

    test('Answers custom inquiry about Ramesh missing milk entry', () {
      final res = DairyAssistantKnowledge.findAnswer(
        query: "Why can't Ramesh see the milk entry saved by owner?",
        userRole: 'MEMBER',
        languageCode: 'en',
      );
      expect(res['text'], contains('Unlinked Member Account'));
      expect(res['text'], contains('M001'));
      expect(res['text'], contains('Date Filter Setting'));
      expect(res['suggestedActions'], contains('How to link member profile?'));
    });

    test('Answers custom inquiry about app uninstall data persistence', () {
      final res = DairyAssistantKnowledge.findAnswer(
        query: 'What happens to my milk records if I uninstall the app?',
        userRole: 'DAIRY_OWNER',
        languageCode: 'en',
      );
      expect(res['text'], contains('MongoDB backend database'));
      expect(res['text'], contains('100% Safe'));
      expect(res['text'], contains('After Reinstalling'));
    });

    test('Answers conversational follow-up: Explain more simply', () {
      final res = DairyAssistantKnowledge.findAnswer(
        query: 'Explain that more simply',
        userRole: 'DAIRY_OWNER',
        languageCode: 'en',
      );
      expect(res['text'], contains('In simple terms'));
      expect(res['text'], contains('central database'));
    });

    test('Answers conversational follow-up: Give me an example', () {
      final res = DairyAssistantKnowledge.findAnswer(
        query: 'Give me a concrete example',
        userRole: 'DAIRY_OWNER',
        languageCode: 'en',
      );
      expect(res['text'], contains('Cow Milk'));
      expect(res['text'], contains('₹40.80 per Litre'));
      expect(res['text'], contains('₹408.00'));
    });

    test('Answers conversational follow-up: What should I do next?', () {
      final res = DairyAssistantKnowledge.findAnswer(
        query: 'What should I do next?',
        userRole: 'DAIRY_OWNER',
        languageCode: 'en',
      );
      expect(res['text'], contains('Recommended next steps'));
      expect(res['text'], contains('SAVE COLLECTION'));
    });

    test('Handles Marathi custom inquiry and follow-ups', () {
      final res = DairyAssistantKnowledge.findAnswer(
        query: 'रमेशला दुधाची नोंद का दिसत नाही?',
        userRole: 'MEMBER',
        languageCode: 'mr',
      );
      expect(res['text'], contains('M001'));
      expect(res['text'], contains('अकाउंट लिंक नसणे'));

      final followUp = DairyAssistantKnowledge.findAnswer(
        query: 'सोप्या भाषेत सांगा',
        userRole: 'MEMBER',
        languageCode: 'mr',
      );
      expect(followUp['text'], contains('थोडक्यात सांगायचे तर'));
    });
  });

  group('AiChatService Tests', () {
    test('Generates role-specific welcome message in English and Marathi', () {
      final enWelcome = AiChatService.getWelcomeMessage(
        userRole: 'DAIRY_OWNER',
        languageCode: 'en',
      );
      expect(enWelcome.text, contains('Hello, Dairy Owner!'));
      expect(enWelcome.suggestedActions?.isNotEmpty, isTrue);

      final mrWelcome = AiChatService.getWelcomeMessage(
        userRole: 'DAIRY_OWNER',
        languageCode: 'mr',
      );
      expect(mrWelcome.text, contains('मी तुमचा'));
    });

    test(
      'Sends inquiry and receives grounded response with offline fallback',
      () async {
        final response = await AiChatService.sendMessage(
          prompt: 'What are FAT and SNF?',
          userRole: 'DAIRY_OWNER',
          preferredLanguageCode: 'en',
        );

        expect(response.isAssistant, isTrue);
        expect(response.text, contains('Butterfat'));
        expect(response.isOfflineResponse, isTrue);
      },
    );

    test('Rejects empty prompts', () async {
      expect(
        () => AiChatService.sendMessage(prompt: '   '),
        throwsArgumentError,
      );
    });

    test('Explains Admin role and Developer Vishwajeet problem resolution', () {
      final resEn = DairyAssistantKnowledge.findAnswer(
        query: 'Owner is facing a problem how to contact developer',
        userRole: 'DAIRY_OWNER',
      );
      expect(resEn['text'], contains('Developer (Vishwajeet)'));
      expect(resEn['text'], contains('Full Unrestricted Access'));
      expect(resEn['text'], contains('+91 98220 12345'));

      final resMr = DairyAssistantKnowledge.findAnswer(
        query: 'डेव्हलपर किंवा ॲडमिनशी संपर्क कसा करावा?',
        userRole: 'DAIRY_OWNER',
        languageCode: 'mr',
      );
      expect(resMr['text'], contains('विश्वजीत'));
      expect(resMr['text'], contains('Full Access'));
    });

    test(
      'Admin role receives full access developer greeting and diagnostics',
      () {
        final welcome = AiChatService.getWelcomeMessage(
          userRole: 'ADMIN',
          languageCode: 'en',
        );
        expect(
          welcome.text,
          contains('System Admin & App Developer (Vishwajeet)'),
        );
        expect(
          welcome.suggestedActions,
          contains('How do I solve dairy owner issues?'),
        );
        expect(
          welcome.suggestedActions,
          contains('Explain Admin Full Access permissions'),
        );
      },
    );

    test('Support ticket creation and Admin resolution workflow', () {
      final initialCount = ApiService.supportTickets.length;
      ApiService.addSupportTicket(
        title: 'Bluetooth Scale Lag',
        description: 'Scale takes time to respond',
        submittedBy: 'Dairy Owner (Late L D Kadam Dairy)',
        contact: '9822012345',
        screen: 'Milk Collection',
      );
      expect(ApiService.supportTickets.length, initialCount + 1);
      final newTicket = ApiService.supportTickets.first;
      expect(newTicket['status'], 'Open');
      expect(newTicket['title'], 'Bluetooth Scale Lag');

      // Admin resolves the ticket
      ApiService.resolveSupportTicket(newTicket['id']);
      expect(newTicket['status'], 'Resolved');
    });
  });

  group('AiChatScreen Widget Tests', () {
    testWidgets('Renders header, welcome message and starter chips', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: AiChatScreen()));
      await tester.pumpAndSettle();

      expect(find.text('AI Smart Dairy Assistant'), findsOneWidget);
      expect(find.text('Offline Knowledge'), findsOneWidget);
      expect(find.text('Owner'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);

      // Starter chips
      expect(
        find.widgetWithText(ActionChip, 'How do I record milk collection?'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Typing a query and sending renders user message and assistant reply',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: AiChatScreen()));
        await tester.pumpAndSettle();

        // Enter query and submit via onSubmitted
        await tester.enterText(find.byType(TextField), 'What are FAT and SNF?');
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.textContaining('Butterfat'), findsOneWidget);
        expect(find.text('Local Knowledge Engine'), findsWidgets);

        // Scroll back up to verify user message was rendered
        await tester.drag(find.byType(ListView).first, const Offset(0, 400));
        await tester.pumpAndSettle();
        expect(find.text('What are FAT and SNF?'), findsWidgets);
      },
    );

    testWidgets('Tapping starter chip sends the inquiry automatically', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: AiChatScreen()));
      await tester.pumpAndSettle();

      // Tap the action chip
      await tester.tap(
        find.widgetWithText(ActionChip, 'How do I record milk collection?'),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.textContaining('SAVE COLLECTION'), findsOneWidget);
    });

    testWidgets(
      'Clear chat shows confirmation dialog and resets session on confirm',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: AiChatScreen()));
        await tester.pumpAndSettle();

        // Tap clear icon in app bar
        await tester.tap(find.byIcon(Icons.delete_outline_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Clear Chat?'), findsOneWidget);
        expect(find.text('Clear'), findsOneWidget);

        // Confirm clear
        await tester.tap(find.text('Clear'));
        await tester.pumpAndSettle();

        // Welcome message re-initializes
        expect(find.text('AI Smart Dairy Assistant'), findsOneWidget);
      },
    );
  });

  group('Unseen Questions & Conversational Context Tests', () {
    test('Unseen Q1: Explains why Pratik cannot see yesterday milk entry', () {
      final res = DairyAssistantKnowledge.findAnswer(
        query: 'I entered milk for Pratik yesterday. Why is it not visible in his account?',
        userRole: 'DAIRY_OWNER',
        languageCode: 'en',
      );
      expect(res['text'], contains('Unlinked Member Account'));
      expect(res['text'], contains('Date Filter Setting'));
      expect(res['text'], contains('Today'));
      expect(res['text'], contains('All Records'));
      expect(res['text'], contains('MongoDB'));
    });

    test('Unseen Q2: Explains FAT vs SNF in simple words', () {
      final res = DairyAssistantKnowledge.findAnswer(
        query: 'Explain the difference between FAT and SNF in simple words.',
        userRole: 'DAIRY_OWNER',
        languageCode: 'en',
      );
      expect(res['text'], contains('Butterfat'));
      expect(res['text'], contains('Solids-Not-Fat'));
      expect(res['text'], contains('proteins'));
      expect(res['text'], contains('minerals'));
    });

    test('Unseen Q3: Explains how to check whether 10-day bill includes every collection', () {
      final res = DairyAssistantKnowledge.findAnswer(
        query: 'How can I check whether my 10-day bill includes every collection?',
        userRole: 'MEMBER',
        languageCode: 'en',
      );
      expect(res['text'], contains('Shift Breakdown Table'));
      expect(res['text'], contains('10-day settlement cycle'));
      expect(res['text'], contains('Download PDF Statement'));
    });

    test('Unseen Q4: Explains troubleshooting when WhatsApp sharing fails', () {
      final res = DairyAssistantKnowledge.findAnswer(
        query: 'What should I do if WhatsApp sharing fails?',
        userRole: 'DAIRY_OWNER',
        languageCode: 'en',
      );
      expect(res['text'], contains('WhatsApp'));
      expect(res['text'], contains('Download PDF'));
      expect(res['text'], contains('Storage Permissions'));
    });

    test('Unseen Q5: Explains the process in Marathi when requested', () {
      final res = DairyAssistantKnowledge.findAnswer(
        query: 'Explain the same process in Marathi.',
        userRole: 'DAIRY_OWNER',
        languageCode: 'en',
      );
      expect(res['text'], contains('मराठीत'));
      expect(res['text'], contains('दूध संकलन'));
      expect(res['text'], contains('१०-दिवसीय बिलिंग'));
    });

    test('Unseen Q6: Explains another way with bank account analogy', () {
      final res = DairyAssistantKnowledge.findAnswer(
        query: 'I changed my question. Can you explain it another way?',
        userRole: 'DAIRY_OWNER',
        languageCode: 'en',
      );
      expect(res['text'], contains('digital dairy bank account'));
      expect(res['text'], contains('Milk Deposits'));
      expect(res['text'], contains('Deductions'));
      expect(res['text'], contains('Payouts'));
    });

    test('ChatMessage model supports isLlmGenerated and isConfigured flags', () {
      final msg = ChatMessage(
        id: 'llm_test',
        text: 'Dynamic response from GPT-4o-mini',
        sender: MessageSender.assistant,
        timestamp: DateTime.now(),
        isLlmGenerated: true,
        isConfigured: true,
      );
      expect(msg.isLlmGenerated, isTrue);
      expect(msg.isConfigured, isTrue);

      final json = msg.toJson();
      expect(json['isLlmGenerated'], isTrue);
      expect(json['isConfigured'], isTrue);

      final parsed = ChatMessage.fromJson(json);
      expect(parsed.isLlmGenerated, isTrue);
      expect(parsed.isConfigured, isTrue);
    });

    test('AiChatService.checkAiStatus returns map structure', () async {
      ApiService.isOffline = true;
      final status = await AiChatService.checkAiStatus();
      expect(status['configured'], isFalse);
      expect(status['offline'], isTrue);
      ApiService.isOffline = false;
    });

    group('Task 5 Verification: 8 Core Conversational & Fallback Scenarios', () {
      test('1. User asks "detailed bill" -> returns Detailed Bill guide, NOT AI features', () {
        final res = DairyAssistantKnowledge.findAnswer(
          query: 'detailed bill',
          userRole: 'DAIRY_OWNER',
          languageCode: 'en',
        );
        expect(res['text'], contains('Detailed Bill Screen Guide'));
        expect(res['text'], contains('Shift Collection Records'));
        expect(res['text'], contains('Final Net Payable'));
        expect(res['text'], contains('Download PDF Statement'));
        // Critical: Must NOT return AI & ML features
        expect(res['text'], isNot(contains('What do the AI & ML Features in this App do?')));
      });

      test('2. User asks "PDF is not working" -> returns PDF troubleshooting', () {
        final res = DairyAssistantKnowledge.findAnswer(
          query: 'PDF is not working',
          userRole: 'DAIRY_OWNER',
          languageCode: 'en',
        );
        expect(res['text'], contains('Troubleshooting PDF Generation and Sharing'));
        expect(res['text'], contains('Storage Permissions'));
        expect(res['text'], contains('Download PDF'));
      });

      test('3. User asks "why is Pratik\'s milk entry missing?" -> returns missing entry explanation', () {
        final res = DairyAssistantKnowledge.findAnswer(
          query: "why is Pratik's milk entry missing?",
          userRole: 'DAIRY_OWNER',
          languageCode: 'en',
        );
        expect(res['text'], contains('Unlinked Member Account'));
        expect(res['text'], contains('Date Filter Setting'));
        expect(res['text'], contains('Link Farmer Profile'));
      });

      test('4. User asks "explain FAT and SNF" -> returns accurate FAT & SNF explanation', () {
        final res = DairyAssistantKnowledge.findAnswer(
          query: 'explain FAT and SNF',
          userRole: 'DAIRY_OWNER',
          languageCode: 'en',
        );
        expect(res['text'], contains('Difference between FAT and SNF'));
        expect(res['text'], contains('Butterfat'));
        expect(res['text'], contains('Solids-Not-Fat'));
        expect(res['text'], contains('Cow Milk'));
        expect(res['text'], contains('Buffalo Milk'));
      });

      test('5. User asks "tell me about the AI features" -> returns AI & ML features explanation', () {
        final res = DairyAssistantKnowledge.findAnswer(
          query: 'tell me about the AI features',
          userRole: 'DAIRY_OWNER',
          languageCode: 'en',
        );
        expect(res['text'], contains('What do the AI & ML Features in this App do?'));
        expect(res['text'], contains('Real-time Anomaly Detection'));
        expect(res['text'], contains('Milk Quality Prediction'));
        expect(res['text'], contains('Shift Yield Forecasting'));
      });

      test('6. User asks arbitrary custom question -> honestly returns Live AI Unavailable notice', () {
        final res = DairyAssistantKnowledge.findAnswer(
          query: 'What is the capital of France and what is quantum physics?',
          userRole: 'DAIRY_OWNER',
          languageCode: 'en',
        );
        expect(res['text'], contains('Live Conversational AI is Currently Unavailable'));
        expect(res['text'], contains('Large Language Model (LLM)'));
        // Must NOT return random FAQ or AI features
        expect(res['text'], isNot(contains('What do the AI & ML Features in this App do?')));
      });

      test('7. Follow-up "how do I fix it?" after missing entry -> resolves context and gives fix', () {
        final history = [
          ChatMessage(
            id: 'm1',
            text: "why is Pratik's milk entry missing?",
            sender: MessageSender.user,
            timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
          ),
          ChatMessage(
            id: 'm2',
            text: 'Here are the reasons why an entry might be missing...',
            sender: MessageSender.assistant,
            timestamp: DateTime.now().subtract(const Duration(seconds: 45)),
          ),
        ];

        final res = DairyAssistantKnowledge.findAnswer(
          query: 'how do I fix it?',
          userRole: 'DAIRY_OWNER',
          languageCode: 'en',
          conversationHistory: history,
        );

        expect(res['text'], contains("Here is how to fix the missing entry in Pratik's account"));
        expect(res['text'], contains('Link Farmer Profile'));
        expect(res['text'], contains('Member Code'));
      });

      test('8. Offline / LLM unconfigured fallback -> relevant response and no false live claim', () async {
        ApiService.isOffline = true;
        final responseMsg = await AiChatService.sendMessage(
          prompt: 'detailed bill',
          currentScreen: 'dashboard',
          conversationHistory: [],
        );

        expect(responseMsg.isOfflineResponse, isTrue);
        expect(responseMsg.isLlmGenerated, isFalse);
        expect(responseMsg.isConfigured, isFalse);
        expect(responseMsg.text, contains('Detailed Bill Screen Guide'));
        expect(responseMsg.text, isNot(contains('What do the AI & ML Features in this App do?')));
        ApiService.isOffline = false;
      });
    });
  });
}
