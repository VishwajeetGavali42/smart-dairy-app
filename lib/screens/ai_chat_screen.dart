import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../services/ai_chat_service.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../services/theme_service.dart';

class AiChatScreen extends StatefulWidget {
  final String? initialScreenContext;
  final String? initialPrompt;

  const AiChatScreen({
    super.key,
    this.initialScreenContext,
    this.initialPrompt,
  });

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  static const Color primaryColor = Color(0xFF087F73);
  static const Color darkText = Color(0xFF14213D);
  static const Color mutedText = Color(0xFF7A869A);

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _lastFailedPrompt;

  bool? _isLlmConfigured;
  Map<String, dynamic>? _aiStatusInfo;
  bool _bannerDismissed = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _checkBackendAiStatus();
  }

  void _initializeChat() {
    final welcome = AiChatService.getWelcomeMessage(
      currentScreen: widget.initialScreenContext,
      userRole: ApiService.userRole,
      languageCode: LanguageService.currentLanguageCode,
      isLlmConfigured: _isLlmConfigured ?? true,
    );
    _messages.add(welcome);

    if (widget.initialPrompt != null &&
        widget.initialPrompt!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSendMessage(widget.initialPrompt!);
      });
    }
  }

  Future<void> _checkBackendAiStatus() async {
    final status = await AiChatService.checkAiStatus();
    if (mounted) {
      setState(() {
        _aiStatusInfo = status;
        _isLlmConfigured = status['configured'] == true;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  Future<void> _handleSendMessage(String text) async {
    final prompt = text.trim();
    if (prompt.isEmpty || _isLoading) return;

    _textController.clear();

    final userMessage = ChatMessage(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      text: prompt,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
      featureContext: widget.initialScreenContext,
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _lastFailedPrompt = null;
    });

    _scrollToBottom();

    try {
      final response = await AiChatService.sendMessage(
        prompt: prompt,
        currentScreen: widget.initialScreenContext,
        userRole: ApiService.userRole,
        preferredLanguageCode: LanguageService.currentLanguageCode,
        conversationHistory: _messages,
      );

      if (mounted) {
        setState(() {
          _messages.add(response);
          _isLoading = false;
          if (response.isConfigured == false) {
            _isLlmConfigured = false;
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lastFailedPrompt = prompt;
          _isLoading = false;
          _messages.add(
            ChatMessage(
              id: 'err_${DateTime.now().millisecondsSinceEpoch}',
              text: LanguageService.currentLanguageCode == 'mr'
                  ? 'क्षमस्व, विनंतीवर प्रक्रिया करताना त्रुटी आली. कृपया पुन्हा प्रयत्न करा.'
                  : 'Sorry, an error occurred while processing your query. Please tap Retry.',
              sender: MessageSender.assistant,
              timestamp: DateTime.now(),
              isError: true,
            ),
          );
        });
        _scrollToBottom();
      }
    }
  }

  void _confirmClearChat() {
    final isMr = LanguageService.currentLanguageCode == 'mr';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isMr ? 'संभाषण साफ करायचे?' : 'Clear Chat?'),
        content: Text(
          isMr
              ? 'हे चालू सत्रातील सर्व संदेश हटवेल. तुम्हाला पुढे जायचे आहे का?'
              : 'This will reset your current conversation. Do you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isMr ? 'रद्द करा' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _messages.clear();
                _initializeChat();
              });
            },
            child: Text(isMr ? 'साफ करा' : 'Clear'),
          ),
        ],
      ),
    );
  }

  void _showServerConnectionDialog(bool isMr) {
    final hostController = TextEditingController(text: ApiService.serverHost);
    final groqKeyController = TextEditingController(text: AiChatService.groqApiKey ?? '');
    final geminiKeyController = TextEditingController(text: AiChatService.geminiApiKey ?? '');
    String selectedProvider = AiChatService.preferredCloudProvider;
    bool obscureKey = true;

    bool testingHost = false;
    String? hostMsg;
    bool? hostSuccess;

    bool testingCloud = false;
    String? cloudMsg;
    bool? cloudSuccess;

    int activeTab = 0; // 0: Mobile 24/7 AI, 1: Laptop Backend

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Row(
              children: [
                const Icon(Icons.settings_suggest_rounded, color: primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isMr ? 'AI जोडणी आणि 24/7 मोबाईल सेटअप' : 'AI Connection & 24/7 Mobile Setup',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Segmented Tab Switcher
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setDialogState(() => activeTab = 0),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: activeTab == 0 ? primaryColor : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  isMr ? '📱 24/7 मोबाईल AI (Free)' : '📱 24/7 Mobile AI (Free)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: activeTab == 0 ? Colors.white : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => setDialogState(() => activeTab = 1),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: activeTab == 1 ? primaryColor : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  isMr ? '💻 लॅपटॉप बॅकएंड' : '💻 Laptop Backend',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: activeTab == 1 ? Colors.white : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (activeTab == 0) ...[
                      // TAB 0: 24/7 Mobile Cloud AI (Zero Laptop Needed)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.rocket_launch_rounded, color: Color(0xFF2563EB), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isMr
                                    ? 'लॅपटॉप बंद असतानाही तुमच्या मोबाईलवर २४/७ AI चालवण्यासाठी हे वापरा. हे १००% मोफत आहे आणि क्रेडिट कार्ड लागत नाही!'
                                    : 'Runs AI 24/7 directly on your phone even when laptop is OFF! 100% Free Forever with NO credit card.',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF1E3A8A)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Provider selection
                      Text(
                        isMr ? 'मोफत AI प्रदाता (Provider):' : 'Free AI Provider:',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Groq Llama 3.1 (Fast)', style: TextStyle(fontSize: 11)),
                              selected: selectedProvider == 'groq',
                              onSelected: (val) {
                                if (val) setDialogState(() => selectedProvider = 'groq');
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Google Gemini Flash', style: TextStyle(fontSize: 11)),
                              selected: selectedProvider == 'gemini',
                              onSelected: (val) {
                                if (val) setDialogState(() => selectedProvider = 'gemini');
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Key Input
                      TextField(
                        controller: selectedProvider == 'groq' ? groqKeyController : geminiKeyController,
                        obscureText: obscureKey,
                        decoration: InputDecoration(
                          labelText: selectedProvider == 'groq' ? 'Groq API Key (gsk_...)' : 'Gemini API Key (AIza...)',
                          hintText: selectedProvider == 'groq' ? 'gsk_xxxxxxxxxxxx' : 'AIzaSyxxxxxxxxxxxx',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.key_rounded, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(obscureKey ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 18),
                            onPressed: () => setDialogState(() => obscureKey = !obscureKey),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Quick Guide on how to get free key
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMr ? '📌 मोफत की कशी मिळवायची (२० सेकंद):' : '📌 How to get Free Key (20 Seconds):',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedProvider == 'groq'
                                  ? (isMr
                                      ? '१. console.groq.com उघडा\n२. Google ने Sign In करा\n३. "Create API Key" वर क्लिक करून की इथे पेस्ट करा.'
                                      : '1. Visit console.groq.com\n2. Sign in with Google (No credit card)\n3. Click "Create API Key" & paste here.')
                                  : (isMr
                                      ? '१. aistudio.google.com उघडा\n२. "Get API Key" वर क्लिक करा\n३. नवीन की तयार करून इथे पेस्ट करा.'
                                      : '1. Visit aistudio.google.com\n2. Click "Get API Key"\n3. Create key & paste here.'),
                              style: TextStyle(fontSize: 10, color: Colors.grey[700], height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (testingCloud)
                        const Center(child: Padding(padding: EdgeInsets.all(6), child: CircularProgressIndicator(strokeWidth: 2)))
                      else if (cloudMsg != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: cloudSuccess == true ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            cloudMsg!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: cloudSuccess == true ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                            ),
                          ),
                        ),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.verified_rounded, size: 16),
                          label: Text(
                            isMr ? 'तपासा आणि सेव्ह करा (Save & Activate)' : 'Test & Save 24/7 Cloud AI',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onPressed: () async {
                            final key = selectedProvider == 'groq'
                                ? groqKeyController.text.trim()
                                : geminiKeyController.text.trim();
                            if (key.isEmpty) {
                              setDialogState(() {
                                cloudSuccess = false;
                                cloudMsg = isMr ? 'कृपया वैध API Key टाका.' : 'Please enter a valid API key.';
                              });
                              return;
                            }

                            setDialogState(() {
                              testingCloud = true;
                              cloudMsg = null;
                            });

                            final result = await AiChatService.testCloudAi(apiKey: key, provider: selectedProvider);

                            if (result['success'] == true) {
                              await AiChatService.saveCloudConfig(
                                groqKey: selectedProvider == 'groq' ? key : null,
                                geminiKey: selectedProvider == 'gemini' ? key : null,
                                provider: selectedProvider,
                              );
                              setDialogState(() {
                                testingCloud = false;
                                cloudSuccess = true;
                                cloudMsg = isMr
                                    ? 'सक्रिय झाले! आता लॅपटॉप बंद असतानाही मोबाईलवर AI २४/७ चालेल.'
                                    : 'Activated! AI will now work 24/7 on your mobile without laptop.';
                              });
                              if (mounted) {
                                _checkBackendAiStatus();
                              }
                            } else {
                              setDialogState(() {
                                testingCloud = false;
                                cloudSuccess = false;
                                cloudMsg = result['message']?.toString() ?? 'Validation failed';
                              });
                            }
                          },
                        ),
                      ),
                    ] else ...[
                      // TAB 1: Laptop Backend (Spring Boot)
                      Text(
                        isMr
                            ? 'Spring Boot बॅकएंड आणि Ollama AI शी जोडणी करण्यासाठी कॉम्प्युटरचा IP टाका:'
                            : 'Enter your PC host IP to connect mobile app with Spring Boot & Ollama AI:',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: hostController,
                        decoration: InputDecoration(
                          labelText: isMr ? 'सर्व्हर पत्ता (IP:Port)' : 'Server Host (IP:Port)',
                          hintText: '192.168.118.201:8080',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.wifi_rounded, size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: [
                          ActionChip(
                            label: const Text('192.168.118.201:8080', style: TextStyle(fontSize: 10)),
                            onPressed: () {
                              setDialogState(() {
                                hostController.text = '192.168.118.201:8080';
                              });
                            },
                          ),
                          ActionChip(
                            label: const Text('10.0.2.2:8080', style: TextStyle(fontSize: 10)),
                            onPressed: () {
                              setDialogState(() {
                                hostController.text = '10.0.2.2:8080';
                              });
                            },
                          ),
                          ActionChip(
                            label: const Text('127.0.0.1:8080', style: TextStyle(fontSize: 10)),
                            onPressed: () {
                              setDialogState(() {
                                hostController.text = '127.0.0.1:8080';
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (testingHost)
                        const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)))
                      else if (hostMsg != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: hostSuccess == true ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            hostMsg!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: hostSuccess == true ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                            ),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.sync_rounded, size: 16),
                          label: Text(isMr ? 'जोडा आणि तपासा (Connect & Test)' : 'Connect & Test Laptop'),
                          onPressed: () async {
                            setDialogState(() {
                              testingHost = true;
                              hostMsg = null;
                            });
                            ApiService.setServerHost(hostController.text.trim());
                            final status = await AiChatService.checkAiStatus();
                            setDialogState(() {
                              testingHost = false;
                              if (status['configured'] == true && status['source'] == 'laptop') {
                                hostSuccess = true;
                                hostMsg = isMr
                                    ? 'सक्रिय! मॉडेल: ' + (status['model'] ?? 'Llama 3.1').toString() + ' (लॅपटॉप)'
                                    : 'Online! Model: ' + (status['model'] ?? 'Llama 3.1').toString() + ' (Laptop)';
                              } else if (status['source'] == 'cloud') {
                                hostSuccess = true;
                                hostMsg = isMr
                                    ? 'लॅपटॉप बंद आहे, परंतु २४/७ मोबाईल Cloud AI सक्रिय आहे.'
                                    : 'Laptop is off, but 24/7 Mobile Cloud AI is active!';
                              } else {
                                hostSuccess = false;
                                hostMsg = isMr
                                    ? 'लॅपटॉप सर्व्हरशी संपर्क झाला नाही. Spring Boot चालू करा किंवा डावीकडील "24/7 मोबाईल AI" टॅब वापरा.'
                                    : 'Cannot reach laptop server. Make sure Spring Boot is running, or use "24/7 Mobile AI" tab.';
                              }
                            });
                            if (mounted) {
                              _checkBackendAiStatus();
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isMr ? 'पूर्ण (Done)' : 'Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSetupDialog(bool isMr) {
    final currentProvider = _aiStatusInfo?['provider'] ?? 'openai';
    final currentModel = _aiStatusInfo?['model'] ?? 'gpt-4o-mini';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.psychology_rounded, color: primaryColor),
            const SizedBox(width: 8),
            Text(isMr ? 'AI मॉडेल सेटअप मार्गदर्शक' : 'LLM Setup Guide'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Target Provider: $currentProvider | Model: $currentModel',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryColor),
              ),
              const SizedBox(height: 8),
              Text(
                isMr
                    ? 'ChatGPT प्रमाणे सानुकूल प्रश्नांची गतिशील उत्तरे मिळवण्यासाठी बॅकएंडवर LLM कॉन्फिगर करा:'
                    : 'To enable dynamic ChatGPT-like answers for arbitrary custom questions, configure the LLM on your backend:',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text(
                isMr ? 'पर्याय १: OpenAI API Key (शिफारस)' : 'Option 1: OpenAI API Key (Recommended)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const SelectableText(
                  'Windows PowerShell:\n\$env:OPENAI_API_KEY="sk-..."\n\nLinux/macOS:\nexport OPENAI_API_KEY="sk-..."',
                  style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isMr ? 'पर्याय २: स्थानिक मोफत मॉडेल (Ollama)' : 'Option 2: Free Local Offline Model (Ollama)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const SelectableText(
                  '1. Install Ollama (ollama.com)\n2. Terminal: ollama run llama3.1\n3. backend application.yml:\n   llm.base-url: http://localhost:11434/v1',
                  style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isMr
                    ? 'टीप: बॅकएंड रीस्टार्ट केल्यानंतर AI आपोआप चालू होईल.'
                    : 'Note: Restart the Spring Boot backend server after setting the key.',
                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isMr ? 'समजले' : 'Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode;
    final isMr = LanguageService.currentLanguageCode == 'mr';
    final isLaptopOnline = _aiStatusInfo?['configured'] == true && _aiStatusInfo?['source'] == 'laptop';
    final isCloudOnline = AiChatService.isCloudConfigured || (_aiStatusInfo?['source'] == 'cloud');
    final isOnlineActive = isLaptopOnline || isCloudOnline;
    final isSetupNeeded = !isOnlineActive && _isLlmConfigured == false;
    
    final String statusTitle = isLaptopOnline
        ? (isMr ? 'लॅपटॉप AI (Llama 3.1)' : 'Laptop AI (Llama 3.1)')
        : (isCloudOnline
            ? (isMr ? 'मोबाईल AI २४/७ (Cloud)' : 'Mobile AI 24/7 (Cloud)')
            : (isMr ? 'स्थानिक ज्ञान केंद्र' : 'Offline Knowledge'));
    final Color statusColor = isLaptopOnline
        ? const Color(0xFF10B981)
        : (isCloudOnline ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF));

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8FAFA),
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : darkText,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryColor, Color(0xFF0F9D8F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'AI Smart Dairy Assistant'.tr,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: () => _showServerConnectionDialog(isMr),
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          statusTitle,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            ApiService.userRole.toUpperCase() == 'ADMIN'
                                ? 'Admin'
                                : (ApiService.userRole.toUpperCase() == 'MEMBER'
                                    ? 'Member'
                                    : 'Owner'),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isMr ? 'AI जोडणी व २४/७ मोबाईल सेटिंग्ज' : 'AI Connection & 24/7 Mobile Setup',
            icon: Icon(
              isOnlineActive ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
              size: 22,
              color: statusColor,
            ),
            onPressed: () => _showServerConnectionDialog(isMr),
          ),
          IconButton(
            tooltip: isMr ? 'संभाषण साफ करा' : 'Clear Chat',
            icon: const Icon(Icons.delete_outline_rounded, size: 21),
            onPressed: _confirmClearChat,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // LLM Setup Required Notice Banner (Honest reporting when API key not set)
            if (isSetupNeeded && !_bannerDismissed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: isDark ? const Color(0xFF332A15) : const Color(0xFFFFFBEB),
                child: Row(
                  children: [
                    const Icon(
                      Icons.settings_suggest_rounded,
                      size: 18,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isMr
                            ? 'AI मॉडेल की सेट केलेली नाही. सेटअप सूचना पाहण्यासाठी टॅप करा.'
                            : 'LLM API key not configured. Tap for setup instructions.',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                        ),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () => _showSetupDialog(isMr),
                      child: Text(
                        isMr ? 'पहा' : 'Setup',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: isDark ? Colors.white60 : Colors.black54,
                      onPressed: () => setState(() => _bannerDismissed = true),
                    ),
                  ],
                ),
              ),

            // Context indicator if initiated from a specific screen
            if (widget.initialScreenContext != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                color: isDark
                    ? const Color(0xFF262626)
                    : const Color(0xFFE7F6F3),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isMr
                            ? 'सक्रिय स्क्रीन: ${widget.initialScreenContext}'
                            : 'Active Screen Context: ${widget.initialScreenContext}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Message List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isLoading) {
                    return _buildTypingIndicator(isDark);
                  }
                  final msg = _messages[index];
                  return _buildMessageBubble(msg, isDark);
                },
              ),
            ),

            // Suggested Question Chips
            _buildSuggestedChips(isDark),

            // Bottom Input Bar
            _buildInputBar(isDark, isMr),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isDark) {
    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      msg.text,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(msg.timestamp),
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Assistant Bubble
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, right: 30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(top: 2, right: 8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: primaryColor,
              size: 18,
            ),
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(
                  color: msg.isError
                      ? Colors.redAccent
                      : (isDark
                            ? const Color(0xFF333333)
                            : const Color(0xFFE2E8F0)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live LLM tag
                  if (msg.isLlmGenerated)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: 12,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            LanguageService.currentLanguageCode == 'mr'
                                ? 'ChatGPT / LLM जनरेटेड उत्तर'
                                : 'Conversational LLM Generated',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Offline / Setup tag
                  if (msg.isOfflineResponse)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.library_books_rounded,
                            size: 11,
                            color: isDark ? const Color(0xFF9CA3AF) : mutedText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            LanguageService.currentLanguageCode == 'mr'
                                ? 'स्थानिक ज्ञान स्त्रोत'
                                : 'Local Knowledge Engine',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF9CA3AF)
                                  : mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (!msg.isConfigured && !msg.isUser)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 12,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            LanguageService.currentLanguageCode == 'mr'
                                ? 'LLM सेटअप सूचना'
                                : 'LLM Setup Notice',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Formatted Markdown Message Text
                  _buildFormattedText(msg.text, isDark),

                  // Retry button if error
                  if (msg.isError && _lastFailedPrompt != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _handleSendMessage(_lastFailedPrompt!),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(
                        LanguageService.currentLanguageCode == 'mr'
                            ? 'पुन्हा प्रयत्न करा'
                            : 'Retry Query',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],

                  // Suggested Actions attached to message
                  if (msg.suggestedActions != null &&
                      msg.suggestedActions!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: msg.suggestedActions!.map((action) {
                        final isMrAction = LanguageService.currentLanguageCode == 'mr';
                        return InkWell(
                          onTap: () {
                            if (action.contains('24/7 Mobile AI') || action.contains('24/7') || action.contains('Enable 24/7')) {
                              _showServerConnectionDialog(isMrAction);
                            } else {
                              _handleSendMessage(action);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: primaryColor.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 12,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  action,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      _formatTime(msg.timestamp),
                      style: TextStyle(
                        fontSize: 9,
                        color: isDark ? const Color(0xFF888888) : mutedText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedText(String text, bool isDark) {
    final textColor = isDark ? Colors.white : darkText;
    final lines = text.split('\n');
    final List<Widget> widgets = [];

    for (int i = 0; i < lines.length; i++) {
      final rawLine = lines[i];
      final trimmed = rawLine.trim();

      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // Headers
      if (trimmed.startsWith('### ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              trimmed.substring(4).replaceAll('**', ''),
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
        );
        continue;
      }
      if (trimmed.startsWith('## ') || trimmed.startsWith('# ')) {
        final headerText = trimmed.replaceAll(RegExp(r'^#+\s*'), '').replaceAll('**', '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Text(
              headerText,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : primaryColor,
              ),
            ),
          ),
        );
        continue;
      }

      // Bullet points
      if (trimmed.startsWith('• ') || trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        final bulletContent = trimmed.substring(2);
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '• ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildInlineRichText(bulletContent, textColor),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Numbered lists
      final numMatch = RegExp(r'^(\d+[\.\)])\s+(.*)$').firstMatch(trimmed);
      if (numMatch != null) {
        final numPrefix = numMatch.group(1)!;
        final numContent = numMatch.group(2)!;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$numPrefix ',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildInlineRichText(numContent, textColor),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Code blocks
      if (trimmed.startsWith('```') || trimmed.endsWith('```')) {
        final codeContent = trimmed.replaceAll('```', '');
        widgets.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141414) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFCBD5E1),
              ),
            ),
            child: Text(
              codeContent,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF0F766E),
              ),
            ),
          ),
        );
        continue;
      }

      // Standard paragraph
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _buildInlineRichText(rawLine, textColor),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildInlineRichText(String text, Color defaultColor) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'(\*\*[^*]+\*\*)|(`[^`]+`)|(\*[^*]+\*)');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: TextStyle(fontSize: 13.5, height: 1.45, color: defaultColor),
        ));
      }

      final matched = match.group(0)!;
      if (matched.startsWith('**') && matched.endsWith('**')) {
        spans.add(TextSpan(
          text: matched.substring(2, matched.length - 2),
          style: TextStyle(
            fontSize: 13.5,
            height: 1.45,
            fontWeight: FontWeight.bold,
            color: defaultColor,
          ),
        ));
      } else if (matched.startsWith('`') && matched.endsWith('`')) {
        spans.add(TextSpan(
          text: matched.substring(1, matched.length - 1),
          style: const TextStyle(
            fontSize: 12.5,
            fontFamily: 'monospace',
            backgroundColor: Color(0x1F087F73),
            fontWeight: FontWeight.w600,
            color: Color(0xFF087F73),
          ),
        ));
      } else if (matched.startsWith('*') && matched.endsWith('*')) {
        spans.add(TextSpan(
          text: matched.substring(1, matched.length - 1),
          style: TextStyle(
            fontSize: 13.5,
            height: 1.45,
            fontStyle: FontStyle.italic,
            color: defaultColor,
          ),
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: TextStyle(fontSize: 13.5, height: 1.45, color: defaultColor),
      ));
    }

    return SelectableText.rich(
      TextSpan(children: spans),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 40),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF333333)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  LanguageService.currentLanguageCode == 'mr'
                      ? 'AI सहाय्यक विचार करत आहे...'
                      : 'AI Assistant is thinking...',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDark ? const Color(0xFFAAAAAA) : mutedText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedChips(bool isDark) {
    final lastMsg = _messages.isNotEmpty ? _messages.last : null;
    final suggestions =
        lastMsg?.suggestedActions ??
        (LanguageService.currentLanguageCode == 'mr'
            ? [
                'दूध संकलन कसे नोंदवायचे?',
                'FAT आणि SNF म्हणजे काय?',
                'दूध दर कसा ठरवला जातो?',
                '१०-दिवसीय बिलिंग कसे चालते?',
              ]
            : [
                'How do I record milk collection?',
                'Explain FAT and SNF in simple words',
                'How is the payment calculated?',
                'How do I generate a PDF report?',
              ]);

    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final query = suggestions[index];
          return ActionChip(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            side: BorderSide(
              color: isDark ? const Color(0xFF333333) : const Color(0xFFD1D5DB),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            label: Text(
              query,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : darkText,
              ),
            ),
            onPressed: () => _handleSendMessage(query),
          );
        },
      ),
    );
  }

  Widget _buildInputBar(bool isDark, bool isMr) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                textInputAction: TextInputAction.send,
                onSubmitted: _handleSendMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : darkText,
                ),
                decoration: InputDecoration(
                  hintText: isMr
                      ? 'डेअरी किंवा ॲपबद्दल विचारा...'
                      : 'Ask anything about dairy operations or app...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF777777) : mutedText,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => _handleSendMessage(_textController.text),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}
