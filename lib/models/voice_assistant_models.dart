enum AssistantState {
  idle,
  starting,
  listening,
  thinking,
  speaking,
  error,
}

class ConversationMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ConversationMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
