enum MessageSender { user, assistant, system }

class ChatMessage {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final bool isOfflineResponse;
  final bool isError;
  final bool isLlmGenerated;
  final bool isConfigured;
  final List<String>? suggestedActions;
  final String? featureContext;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isOfflineResponse = false,
    this.isError = false,
    this.isLlmGenerated = false,
    this.isConfigured = true,
    this.suggestedActions,
    this.featureContext,
  });

  bool get isUser => sender == MessageSender.user;
  bool get isAssistant => sender == MessageSender.assistant;
  bool get isSystem => sender == MessageSender.system;

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'sender': sender.name,
    'timestamp': timestamp.toIso8601String(),
    'isOfflineResponse': isOfflineResponse,
    'isError': isError,
    'isLlmGenerated': isLlmGenerated,
    'isConfigured': isConfigured,
    'suggestedActions': suggestedActions,
    'featureContext': featureContext,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id:
        json['id'] as String? ??
        DateTime.now().millisecondsSinceEpoch.toString(),
    text: json['text'] as String? ?? '',
    sender: MessageSender.values.firstWhere(
      (e) => e.name == json['sender'],
      orElse: () => MessageSender.assistant,
    ),
    timestamp: json['timestamp'] != null
        ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
        : DateTime.now(),
    isOfflineResponse: json['isOfflineResponse'] as bool? ?? false,
    isError: json['isError'] as bool? ?? false,
    isLlmGenerated: json['isLlmGenerated'] as bool? ?? false,
    isConfigured: json['isConfigured'] as bool? ?? true,
    suggestedActions: (json['suggestedActions'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList(),
    featureContext: json['featureContext'] as String?,
  );

  ChatMessage copyWith({
    String? id,
    String? text,
    MessageSender? sender,
    DateTime? timestamp,
    bool? isOfflineResponse,
    bool? isError,
    bool? isLlmGenerated,
    bool? isConfigured,
    List<String>? suggestedActions,
    String? featureContext,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      isOfflineResponse: isOfflineResponse ?? this.isOfflineResponse,
      isError: isError ?? this.isError,
      isLlmGenerated: isLlmGenerated ?? this.isLlmGenerated,
      isConfigured: isConfigured ?? this.isConfigured,
      suggestedActions: suggestedActions ?? this.suggestedActions,
      featureContext: featureContext ?? this.featureContext,
    );
  }
}
