import 'package:flutter/material.dart';

class ChatAvatar extends StatelessWidget {
  final bool isUser;
  const ChatAvatar({super.key, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isUser
              ? [const Color(0xFF1F6FEB), const Color(0xFF58A6FF)]
              : [const Color(0xFFFF6B35), const Color(0xFFFFB347)],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}

class ChatMessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isPartial;
  final DateTime? timestamp;

  const ChatMessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.isPartial = false,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            ChatAvatar(isUser: false),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFF1F6FEB)
                        : const Color(0xFF21262D),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isPartial
                        ? Border.all(
                            color: const Color(0xFF58A6FF).withValues(alpha: 0.5))
                        : null,
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isPartial
                          ? Colors.white60
                          : Colors.white,
                      fontSize: 15,
                      height: 1.4,
                      fontStyle: isPartial
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ),
                if (timestamp != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                    child: Text(
                      _formatTime(timestamp!),
                      style: const TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            ChatAvatar(isUser: true),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
