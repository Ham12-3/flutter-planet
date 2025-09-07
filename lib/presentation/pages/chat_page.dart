import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/app_router.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, this.existingItineraryId});
  
  final String? existingItineraryId;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasInitialContent = false;
  bool _isAIThinking = false;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    // Show initial conversation when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeChat() {
    setState(() {
      _hasInitialContent = true;
      _messages = [
        {
          'content': '7 days in Bali next April, 3 people, mid-range budget, wanted to explore less populated areas, it should be a peaceful trip!',
          'isUser': true,
          'timestamp': DateTime.now().subtract(const Duration(minutes: 10)),
        },
        {
          'content': 'Day 1: Arrival in Bali & Settle in Ubud',
          'isUser': false,
          'timestamp': DateTime.now().subtract(const Duration(minutes: 8)),
          'isInitialResponse': true,
        },
      ];
    });
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Add user message
    setState(() {
      _messages.add({
        'content': message,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
      _isAIThinking = true;
    });

    _messageController.clear();
    
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    // Simulate AI thinking and response (with random failure for testing)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // Simulate random failures (30% chance for testing)
        bool shouldFail = DateTime.now().millisecond % 10 < 3;
        
        setState(() {
          _isAIThinking = false;
          if (shouldFail) {
            _messages.add({
              'content': 'Oops! The LLM failed to generate answer. Please regenerate.',
              'isUser': false,
              'timestamp': DateTime.now(),
              'isError': true,
            });
          } else {
            _messages.add({
              'content': 'Absolutely! I\'ll include scuba diving in your Bali itinerary. The waters around Bali offer amazing diving spots with coral reefs and marine life.',
              'isUser': false,
              'timestamp': DateTime.now(),
            });
          }
        });
        
        // Scroll to bottom again
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    });
  }

  void _handleVoiceInput() {
    // TODO: Implement voice input
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice input not implemented yet')),
    );
  }

  void _copyContent() {
    const content = '''Day 1: Arrival in Bali & Settle in Ubud
• Morning: Arrive in Bali, Denpasar Airport.
• Transfer: Private driver to Ubud (around 1.5 hours).
• Accommodation: Check-in at a peaceful boutique hotel or villa in Ubud (e.g., Ubud Aura Retreat or Komuntara at Bisma).
• Afternoon: Explore Ubud's local area, walk around the tranquil rice terraces at Tegallalang.
• Evening: Dinner at Locavore (known for farm-to-table dishes in a peaceful setting).''';
    
    Clipboard.setData(const ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Itinerary copied to clipboard'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _saveOffline() {
    // TODO: Implement save offline functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Itinerary saved offline successfully!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _regenerate() {
    // TODO: Implement regenerate functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Regenerating itinerary...')),
    );
  }

  void _regenerateErrorMessage(int messageIndex) {
    // Remove the error message
    setState(() {
      _messages.removeAt(messageIndex);
      _isAIThinking = true;
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    // Simulate regeneration (lower failure rate for retry)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // Lower failure rate for regeneration (10%)
        bool shouldFail = DateTime.now().millisecond % 10 < 1;
        
        setState(() {
          _isAIThinking = false;
          if (shouldFail) {
            _messages.add({
              'content': 'Oops! The LLM failed to generate answer. Please regenerate.',
              'isUser': false,
              'timestamp': DateTime.now(),
              'isError': true,
            });
          } else {
            _messages.add({
              'content': 'Absolutely! I\'ll include scuba diving in your Bali itinerary. The waters around Bali offer amazing diving spots with coral reefs and marine life.',
              'isUser': false,
              'timestamp': DateTime.now(),
            });
          }
        });
        
        // Scroll to bottom again
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    });
  }

  void _openInMaps() async {
    // Open Bali in Google Maps
    const url = 'https://maps.google.com/?q=Bali,Indonesia';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Chat Messages
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    ..._buildMessageList(),
                    if (_isAIThinking) _buildThinkingMessage(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            
            // Input Area
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppTheme.textPrimaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '7 days in Bali...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => context.go(AppRoute.profile.path),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.primaryColor,
              child: const Text(
                'S',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMessageList() {
    List<Widget> messageWidgets = [];
    
    for (int i = 0; i < _messages.length; i++) {
      final message = _messages[i];
      final isUser = message['isUser'] as bool;
      
      if (isUser) {
        messageWidgets.add(_buildUserMessage(message));
      } else {
        if (message['isInitialResponse'] == true) {
          messageWidgets.add(_buildInitialAIResponse());
        } else if (message['isError'] == true) {
          messageWidgets.add(_buildErrorResponse(message, i));
        } else {
          messageWidgets.add(_buildFollowUpAIResponse(message));
        }
      }
      
      if (i < _messages.length - 1) {
        messageWidgets.add(const SizedBox(height: 16));
      }
    }
    
    return messageWidgets;
  }

  Widget _buildUserMessage(Map<String, dynamic> message) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: const Radius.circular(4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User avatar and label
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppTheme.primaryColor,
                    child: const Text(
                      'S',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'You',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Message content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                message['content'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
            // Copy button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.content_copy,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: message['content']));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Message copied')),
                      );
                    },
                    child: const Text(
                      'Copy',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialAIResponse() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI avatar and label
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.orangeAccent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.flight,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Itinera AI',
                    style: TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            // Itinerary content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Day 1: Arrival in Bali & Settle in Ubud',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildItineraryItem('• Morning: Arrive in Bali, Denpasar Airport.'),
                  _buildItineraryItem('• Transfer: Private driver to Ubud (around 1.5 hours).'),
                  _buildItineraryItem('• Accommodation: Check-in at a peaceful boutique hotel or villa in Ubud (e.g., Ubud Aura Retreat or Komuntara at Bisma).'),
                  _buildItineraryItem('• Afternoon: Explore Ubud\'s local area, walk around the tranquil rice terraces at Tegallalang.'),
                  _buildItineraryItem('• Evening: Dinner at Locavore (known for farm-to-table dishes in a peaceful setting).'),
                  
                  const SizedBox(height: 16),
                  
                  // Open in maps
                  Row(
                    children: [
                      const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _openInMaps,
                        child: const Text(
                          'Open in maps',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.open_in_new,
                        color: Colors.blue,
                        size: 14,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  const Text(
                    'Mumbai to Bali, Indonesia | 11hrs 5mins',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  _buildActionButton(Icons.content_copy, 'Copy', _copyContent),
                  const SizedBox(width: 16),
                  _buildActionButton(Icons.download, 'Save Offline', _saveOffline),
                  const SizedBox(width: 16),
                  _buildActionButton(Icons.refresh, 'Regenerate', _regenerate),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowUpAIResponse(Map<String, dynamic> message) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI avatar and label
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.orangeAccent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.flight,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Itinera AI',
                    style: TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            // Message content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                message['content'],
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimaryColor,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThinkingMessage() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16).copyWith(
              bottomLeft: const Radius.circular(4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI avatar and label
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppTheme.orangeAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.flight,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Itinera AI',
                      style: TextStyle(
                        color: AppTheme.textPrimaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Thinking indicator
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Thinking...',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimaryColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorResponse(Map<String, dynamic> message, int messageIndex) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI avatar and label
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.orangeAccent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.flight,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Itinera AI',
                    style: TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            // Error message with red indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      message['content'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Regenerate button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  const SizedBox(width: 16), // Align with error text
                  GestureDetector(
                    onTap: () => _regenerateErrorMessage(messageIndex),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.refresh,
                          color: AppTheme.textSecondaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Regenerate',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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
      ),
    );
  }

  Widget _buildItineraryItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.textPrimaryColor,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppTheme.textSecondaryColor,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.textSecondaryColor.withOpacity(0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Follow up to refine',
                        hintStyle: TextStyle(
                          color: AppTheme.textSecondaryColor,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _handleVoiceInput,
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}