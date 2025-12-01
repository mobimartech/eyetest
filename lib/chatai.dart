import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({Key? key}) : super(key: key);

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage>
    with SingleTickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  bool _showOptionsDialog = false;

  late AnimationController _typingController;
  late Animation<double> _typingAnimation;

  // Replace with your actual server URL
  static const String apiUrl = 'https://eyeshealthtest.com/chat.php';

  final List<QuickResponse> _quickResponses = [
    QuickResponse(text: 'ai_chat.quick_1'.tr(), icon: '💧'),
    QuickResponse(text: 'ai_chat.quick_2'.tr(), icon: '👁️'),
    QuickResponse(text: 'ai_chat.quick_3'.tr(), icon: '💻'),
    QuickResponse(text: 'ai_chat.quick_4'.tr(), icon: '👨‍⚕️'),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _addInitialMessage();
  }

  void _initializeAnimations() {
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _typingAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _typingController, curve: Curves.easeInOut),
    );
  }

  void _addInitialMessage() {
    _messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch,
        text: 'ai_chat.disclaimer'.tr(),
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _typingController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      text: _textController.text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });

    final currentInput = _textController.text.trim();
    _textController.clear();

    _typingController.repeat(reverse: true);
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': currentInput}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['message'] != null) {
          final aiMessage = ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch + 1,
            text: data['message'],
            isUser: false,
            timestamp: DateTime.now(),
          );

          setState(() {
            _messages.add(aiMessage);
          });
        } else {
          _addFallbackMessage();
        }
      } else {
        _addFallbackMessage();
      }
    } catch (error) {
      debugPrint('API Error: $error');
      final aiResponse = _generateFallbackResponse(currentInput);
      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch + 1,
        text: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiMessage);
      });
    } finally {
      setState(() {
        _isTyping = false;
      });
      _typingController.stop();
      _scrollToBottom();
    }
  }

  void _addFallbackMessage() {
    final fallbackMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch + 1,
      text:
          "I apologize, but I'm experiencing technical difficulties. Please try again in a moment. For urgent eye health concerns, please contact your eye care provider directly.",
      isUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(fallbackMessage);
    });
  }

  String _generateFallbackResponse(String userInput) {
    final input = userInput.toLowerCase();

    if (input.contains('dry') && input.contains('eye')) {
      return "As your eye care consultant, dry eyes are a common concern I see daily. Symptoms include irritation, burning, and a gritty feeling. I recommend using preservative-free artificial tears, taking regular screen breaks (20-20-20 rule), and ensuring proper humidity in your environment. However, if symptoms persist, it's important to see an eye care professional for a comprehensive evaluation.";
    } else if (input.contains('astigmatism')) {
      return "Based on my experience in eye care, astigmatism is a very common refractive error affecting how your eye focuses light. It can cause blurry or distorted vision at all distances, eye strain, and headaches. The good news is it's easily correctable with glasses, contact lenses, or refractive surgery. I'd recommend scheduling an eye exam for proper assessment and correction options.";
    } else if (input.contains('glasses') || input.contains('contact')) {
      return "As an eye care specialist, I can help you understand your vision correction options. Both glasses and contact lenses can effectively correct refractive errors. The choice depends on your lifestyle, comfort preferences, and eye health. Contact lenses require proper hygiene and care. I'd suggest discussing both options with an eye care professional during your next comprehensive eye exam.";
    } else if (input.contains('screen') || input.contains('computer')) {
      return "Digital eye strain is increasingly common in our screen-heavy world. As your eye care consultant, I recommend the 20-20-20 rule: every 20 minutes, look at something 20 feet away for 20 seconds. Also consider blue light filtering, proper screen distance (arm's length), and ensuring adequate lighting. If you're experiencing persistent symptoms, an eye exam can rule out underlying vision problems.";
    } else if (input.contains('children') || input.contains('kid')) {
      return "Children's vision development is crucial for their learning and overall development. As an eye care professional, I recommend the first eye exam by age 1, then at age 3, before starting school, and annually thereafter. Watch for signs like squinting, covering one eye, sitting too close to screens, or complaints of headaches. Early detection of vision problems can make a significant difference.";
    } else if (input.contains('hello') || input.contains('hi')) {
      return "Hello! I'm an AI assistant, not a real doctor. This is educational information only, not medical advice. Please see a real eye doctor for actual diagnosis or treatment.";
    } else {
      return "I'm an AI assistant, not a real doctor. This is educational information only, not medical advice. Please see a real eye doctor for actual diagnosis or treatment.";
    }
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

  void _clearChat() {
    setState(() {
      _messages.clear();
      _addInitialMessage();
      _showOptionsDialog = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _MessageBubble(message: _messages[index]);
                        },
                      ),
                    ),
                    if (_isTyping) _buildTypingIndicator(),
                  ],
                ),
              ),
              if (_messages.length <= 1) _buildQuickResponses(),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(bottom: BorderSide(color: Color(0xFF333333))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(Icons.arrow_back, color: Colors.white, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ai_chat.title'.tr(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  _isTyping ? 'ai_chat.typing'.tr() : 'ai_chat.online'.tr(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF18FFFF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF18FFFF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF18FFFF).withOpacity(0.3),
              ),
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF333333)),
            ),
            child: AnimatedBuilder(
              animation: _typingAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.3 + (_typingAnimation.value * 0.7),
                  child: const Text(
                    '•••',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF18FFFF),
                      letterSpacing: 2,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickResponses() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(top: BorderSide(color: Color(0xFF1A1A1A))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _quickResponses.map((response) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () {
                  _textController.text = response.text;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF333333)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(response.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        response.text,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFCCCCCC),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Color(0xFF333333))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF333333)),
              ),
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'ai_chat.input_placeholder'.tr(),
                  hintStyle: TextStyle(color: Color(0xFF666666)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: null,
                maxLength: 1000,
                buildCounter:
                    (
                      context, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) {
                      return null;
                    },
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _textController.text.trim().isNotEmpty
                    ? const Color(0xFF18FFFF)
                    : const Color(0xFF333333),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(
                child: Text(
                  '➤',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _textController.text.trim().isNotEmpty
                        ? const Color(0xFF0A0A0A)
                        : const Color(0xFF666666),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF18FFFF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF18FFFF).withOpacity(0.3),
                ),
              ),
              child: const Center(
                child: Text('🤖', style: TextStyle(fontSize: 14)),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? const Color(0xFF18FFFF)
                    : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomRight: message.isUser ? const Radius.circular(6) : null,
                  bottomLeft: !message.isUser ? const Radius.circular(6) : null,
                ),
                border: message.isUser
                    ? null
                    : Border.all(color: const Color(0xFF333333)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 16,
                      color: message.isUser
                          ? const Color(0xFF0A0A0A)
                          : Colors.white,
                      fontWeight: message.isUser
                          ? FontWeight.w500
                          : FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: message.isUser
                          ? const Color(0xFF0A0A0A).withOpacity(0.6)
                          : const Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8, bottom: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('👤', style: TextStyle(fontSize: 14)),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class ChatMessage {
  final int id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class QuickResponse {
  final String text;
  final String icon;

  QuickResponse({required this.text, required this.icon});
}
