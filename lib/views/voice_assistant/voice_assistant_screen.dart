import 'package:flutter/material.dart';
import 'package:gramiq_clone/models/voice_assistant_models.dart';
import 'package:gramiq_clone/view_models/voice_assistant_view_model.dart';
import 'package:gramiq_clone/widgets/chat_widgets.dart';
import 'package:provider/provider.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VoiceAssistantViewModel>().startSession();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceAssistantViewModel>(
      builder: (context, viewModel, _) {
        _scrollToBottom();

        return Scaffold(
          backgroundColor: const Color(0xFF0D1117),
          appBar: _buildAppBar(viewModel),
          body: Column(
            children: [
              _StatusBar(state: viewModel.state),
              Expanded(
                child: _ConversationView(
                  messages: viewModel.messages,
                  partialTranscript: viewModel.partialTranscript,
                  scrollController: _scrollController,
                ),
              ),
              _MicArea(viewModel: viewModel, pulseAnimation: _pulseAnimation),
            ],
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(VoiceAssistantViewModel viewModel) {
    return AppBar(
      backgroundColor: const Color(0xFF161B22),
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFFB347)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.record_voice_over,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'मराठी AI सहाय्यक',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Powered by Gemini',
                style: TextStyle(color: Color(0xFF8B949E), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFF8B949E)),
          tooltip: 'संभाषण साफ करा',
          onPressed: () {
            viewModel.clearConversation();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('संभाषण साफ झाले'),
                backgroundColor: Color(0xFF21262D),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _StatusBar extends StatelessWidget {
  final AssistantState state;
  const _StatusBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      AssistantState.idle => ('तयार आहे', const Color(0xFF3FB950)),
      AssistantState.starting => ('सुरू होत आहे...', const Color(0xFFD29922)),
      AssistantState.listening => ('ऐकत आहे...', const Color(0xFF58A6FF)),
      AssistantState.thinking => ('विचार करत आहे...', const Color(0xFFBC8CFF)),
      AssistantState.speaking => ('बोलत आहे...', const Color(0xFFFF7B72)),
      AssistantState.error => ('त्रुटी', const Color(0xFFF85149)),
    };

    return Container(
      color: const Color(0xFF161B22),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ConversationView extends StatelessWidget {
  final List<ConversationMessage> messages;
  final String partialTranscript;
  final ScrollController scrollController;

  const _ConversationView({
    required this.messages,
    required this.partialTranscript,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length + (partialTranscript.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && partialTranscript.isNotEmpty) {
          return ChatMessageBubble(
            text: partialTranscript,
            isUser: true,
            isPartial: true,
          );
        }
        final msg = messages[index];
        return ChatMessageBubble(
          text: msg.text,
          isUser: msg.isUser,
          timestamp: msg.timestamp,
        );
      },
    );
  }
}

class _MicArea extends StatelessWidget {
  final VoiceAssistantViewModel viewModel;
  final Animation<double> pulseAnimation;

  const _MicArea({required this.viewModel, required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    final isListening = viewModel.isListening;
    final isBusy = viewModel.isBusy;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        border: Border(top: BorderSide(color: Color(0xFF30363D))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isListening
                ? 'बोला...'
                : isBusy
                ? 'थांबा...'
                : 'मायक्रोफोन बटण दाबा',
            style: const TextStyle(color: Color(0xFF8B949E), fontSize: 13),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: isBusy ? null : viewModel.runTurn,
            child: AnimatedBuilder(
              animation: pulseAnimation,
              builder: (_, child) {
                return Transform.scale(
                  scale: isListening ? pulseAnimation.value : 1.0,
                  child: child,
                );
              },
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isBusy
                      ? const LinearGradient(
                          colors: [Color(0xFF30363D), Color(0xFF21262D)],
                        )
                      : isListening
                      ? const LinearGradient(
                          colors: [Color(0xFF58A6FF), Color(0xFF1F6FEB)],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFFFB347)],
                        ),
                  boxShadow: isListening
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF58A6FF,
                            ).withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  isListening
                      ? Icons.mic
                      : viewModel.isSpeaking
                      ? Icons.volume_up
                      : viewModel.isThinking
                      ? Icons.hourglass_top
                      : Icons.mic_none,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (isBusy)
            TextButton.icon(
              onPressed: viewModel.stopSession,
              icon: const Icon(
                Icons.stop_circle_outlined,
                color: Color(0xFFF85149),
                size: 18,
              ),
              label: const Text(
                'थांबवा',
                style: TextStyle(color: Color(0xFFF85149)),
              ),
            ),
        ],
      ),
    );
  }
}
