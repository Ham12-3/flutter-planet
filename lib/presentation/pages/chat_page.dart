import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../../core/utils/app_theme.dart';
import '../../core/utils/app_router.dart';
import '../../services/real_ai_service.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({
    super.key, 
    this.existingItineraryId,
    this.tripVision,
    this.existingItinerary,
  });
  
  final String? existingItineraryId;
  final String? tripVision;
  final String? existingItinerary;

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

  Future<void> _getAIResponse(String userMessage) async {
    try {
      final aiService = RealAIService();
      
      // Build chat history for context
      final chatHistory = _messages
          .where((msg) => !msg.containsKey('isInitialResponse'))
          .map((msg) => '${msg['isUser'] ? 'User' : 'Assistant'}: ${msg['content']}')
          .toList();

      final response = await aiService.handleFollowUpChat(
        userMessage: userMessage,
        originalTripVision: widget.tripVision ?? '',
        existingItinerary: widget.existingItinerary ?? '',
        chatHistory: chatHistory,
      );

      if (mounted) {
        setState(() {
          _isAIThinking = false;
          _messages.add({
            'content': response,
            'isUser': false,
            'timestamp': DateTime.now(),
          });
        });
        
        // Scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAIThinking = false;
          _messages.add({
            'content': 'Sorry, I encountered an error processing your request. Please try again.',
            'isUser': false,
            'timestamp': DateTime.now(),
            'isError': true,
          });
        });
      }
    }
  }

  void _initializeChat() {
    setState(() {
      _hasInitialContent = true;
      
      // Initialize with context from itinerary creation if available
      if (widget.tripVision != null && widget.existingItinerary != null) {
        _messages = [
          {
            'content': widget.tripVision!,
            'isUser': true,
            'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
          },
          {
            'content': widget.existingItinerary!,
            'isUser': false,
            'timestamp': DateTime.now().subtract(const Duration(minutes: 3)),
            'isInitialResponse': true,
          },
          {
            'content': 'I\'ve created your initial itinerary above! Feel free to ask me any questions or request changes. I can help you with:\n\n• Modifying activities or timing\n• Finding different restaurants\n• Alternative transportation options\n• Budget adjustments\n• Local recommendations\n\nWhat would you like to adjust?',
            'isUser': false,
            'timestamp': DateTime.now().subtract(const Duration(minutes: 1)),
          },
        ];
      } else {
        // Default chat initialization
        _messages = [
          {
            'content': 'Hi! I\'m your AI travel assistant. How can I help you plan your trip today?',
            'isUser': false,
            'timestamp': DateTime.now(),
          },
        ];
      }
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

    // Get real AI response with context
    _getAIResponse(message);
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
    // Extract destination from trip vision or use default
    final destination = _extractDestinationFromTripVision();
    final url = 'https://maps.google.com/?q=${Uri.encodeComponent(destination)}';
    
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open maps')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening maps: $e')),
        );
      }
    }
  }

  String _extractDestinationFromTripVision() {
    final tripVision = widget.tripVision ?? '';
    if (tripVision.isEmpty) return 'travel destination';

    // Simple extraction - look for common destination patterns
    final lowerVision = tripVision.toLowerCase();
    
    // Common destination patterns
    final patterns = [
      RegExp(r'trip to ([a-zA-Z\s,]+?)(?:\s|,|$|for|in|during)'),
      RegExp(r'visit ([a-zA-Z\s,]+?)(?:\s|,|$|for|in|during)'),
      RegExp(r'travel to ([a-zA-Z\s,]+?)(?:\s|,|$|for|in|during)'),
      RegExp(r'go to ([a-zA-Z\s,]+?)(?:\s|,|$|for|in|during)'),
      RegExp(r'in ([a-zA-Z\s,]+?)(?:\s|,|$|for)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(lowerVision);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.trim();
      }
    }

    // Also try to extract from JSON itinerary if available
    if (widget.existingItinerary != null) {
      try {
        final jsonData = json.decode(widget.existingItinerary!);
        if (jsonData['title'] != null) {
          final title = jsonData['title'].toString();
          // Look for destination in title
          for (final pattern in patterns) {
            final match = pattern.firstMatch(title.toLowerCase());
            if (match != null && match.group(1) != null) {
              return match.group(1)!.trim();
            }
          }
        }
      } catch (e) {
        // Not valid JSON, continue with fallback
      }
    }

    // Fallback to first few words if no pattern matches
    final words = tripVision.split(' ').take(3).join(' ');
    return words.isNotEmpty ? words : 'travel destination';
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

  String _getTripTitle() {
    if (widget.tripVision != null && widget.tripVision!.isNotEmpty) {
      // Extract key info from trip vision to create a title
      final tripVision = widget.tripVision!.toLowerCase();
      
      // Try to extract destination
      final destinationPatterns = [
        RegExp(r'trip to ([a-zA-Z\s,]+?)(?:\s|,|$|for|in|during)'),
        RegExp(r'visit ([a-zA-Z\s,]+?)(?:\s|,|$|for|in|during)'),
        RegExp(r'travel to ([a-zA-Z\s,]+?)(?:\s|,|$|for|in|during)'),
        RegExp(r'go to ([a-zA-Z\s,]+?)(?:\s|,|$|for|in|during)'),
        RegExp(r'in ([a-zA-Z\s,]+?)(?:\s|,|$|for)'),
      ];
      
      String? destination;
      for (final pattern in destinationPatterns) {
        final match = pattern.firstMatch(tripVision);
        if (match != null && match.group(1) != null) {
          destination = match.group(1)!.trim();
          break;
        }
      }
      
      // Try to extract duration
      final durationMatch = RegExp(r'(\d+)\s+day').firstMatch(tripVision);
      final duration = durationMatch?.group(1);
      
      // Create title based on extracted info
      if (destination != null && duration != null) {
        return '$duration days in ${_capitalizeWords(destination)}...';
      } else if (destination != null) {
        return '${_capitalizeWords(destination)} Trip...';
      } else if (duration != null) {
        return '$duration Day Trip...';
      } else {
        // Fallback to first few words
        final words = widget.tripVision!.split(' ').take(3).join(' ');
        return words.isNotEmpty ? '$words...' : 'Your Trip...';
      }
    }
    
    return 'Your Trip...';
  }
  
  String _capitalizeWords(String text) {
    return text.split(' ')
        .map((word) => word.isNotEmpty 
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : word)
        .join(' ');
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
                onTap: () {
                  if (Navigator.canPop(context)) {
                    context.pop();
                  } else {
                    context.go(AppRoute.main.path);
                  }
                },
                child: const Icon(
                  Icons.arrow_back,
                  color: AppTheme.textPrimaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _getTripTitle(),
                style: const TextStyle(
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
    // Get the actual itinerary content from the message
    final itineraryMessage = _messages.firstWhere(
      (msg) => msg['isInitialResponse'] == true,
      orElse: () => {'content': 'No itinerary found'},
    );
    
    final itineraryContent = itineraryMessage['content'] as String;
    
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
            
            // Real itinerary content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildFormattedItineraryForChat(itineraryContent),
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

  Widget _buildFormattedItineraryForChat(String itinerary) {
    try {
      // Try to parse as JSON first
      final jsonData = json.decode(itinerary);
      return _buildJsonItineraryForChat(jsonData);
    } catch (e) {
      // If not valid JSON, display as formatted text
      return _buildTextItineraryForChat(itinerary);
    }
  }

  Widget _buildJsonItineraryForChat(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        if (data['title'] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              data['title'].toString(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),

        // Date range
        if (data['startDate'] != null && data['endDate'] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${data['startDate']} to ${data['endDate']}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

        // Days (show only first 2 days in chat, with option to expand)
        if (data['days'] != null)
          ...((data['days'] as List).take(2).map((day) => _buildDayItemForChat(day)).toList()),
        
        if (data['days'] != null && (data['days'] as List).length > 2) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.textSecondaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+ ${(data['days'] as List).length - 2} more days...',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
        
        const SizedBox(height: 16),
        
        // Open in maps section
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
      ],
    );
  }

  Widget _buildDayItemForChat(Map<String, dynamic> day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.textSecondaryColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date and summary
          if (day['date'] != null || day['summary'] != null)
            Row(
              children: [
                if (day['date'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      day['date'].toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (day['summary'] != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      day['summary'].toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          
          // Activities (show only first 3)
          if (day['items'] != null) ...[
            const SizedBox(height: 8),
            ...((day['items'] as List).take(3).map((item) => _buildActivityItemForChat(item)).toList()),
            if ((day['items'] as List).length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+ ${(day['items'] as List).length - 3} more activities...',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondaryColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityItemForChat(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item['time'] != null)
            SizedBox(
              width: 50,
              child: Text(
                item['time'].toString(),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          
          const SizedBox(width: 8),
          
          Expanded(
            child: Text(
              item['activity']?.toString() ?? '',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textPrimaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextItineraryForChat(String itinerary) {
    final lines = itinerary.split('\n').take(10).toList(); // Show first 10 lines
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...lines.map((line) {
          final trimmedLine = line.trim();
          
          if (trimmedLine.isEmpty) {
            return const SizedBox(height: 4);
          }
          
          TextStyle style;
          if (trimmedLine.startsWith('🌟') || trimmedLine.startsWith('#')) {
            style = const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            );
          } else if (trimmedLine.startsWith('Day ') || RegExp(r'^\d+\.\s').hasMatch(trimmedLine)) {
            style = const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            );
          } else {
            style = const TextStyle(
              fontSize: 12,
              color: AppTheme.textPrimaryColor,
              height: 1.4,
            );
          }
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              trimmedLine,
              style: style,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        
        const SizedBox(height: 12),
        
        // Open in maps section
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
      ],
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
            
            // Message content - formatted
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildFormattedFollowUpContent(message['content']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedFollowUpContent(String content) {
    final lines = content.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmedLine = line.trim();
        
        if (trimmedLine.isEmpty) {
          return const SizedBox(height: 8);
        }
        
        // Style different types of lines
        TextStyle style;
        Color? backgroundColor;
        EdgeInsets? padding;
        
        if (trimmedLine.startsWith('## ') || trimmedLine.startsWith('# ')) {
          // Headers
          style = const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          );
          padding = const EdgeInsets.symmetric(vertical: 4);
        } else if (trimmedLine.startsWith('### ')) {
          // Subheaders
          style = const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          );
          padding = const EdgeInsets.symmetric(vertical: 3);
        } else if (trimmedLine.startsWith('• ') || trimmedLine.startsWith('- ') || trimmedLine.startsWith('* ')) {
          // Bullet points
          style = const TextStyle(
            fontSize: 14,
            color: AppTheme.textPrimaryColor,
            height: 1.4,
          );
          padding = const EdgeInsets.only(bottom: 4);
        } else if (RegExp(r'^\d+\.').hasMatch(trimmedLine)) {
          // Numbered lists
          style = const TextStyle(
            fontSize: 14,
            color: AppTheme.textPrimaryColor,
            height: 1.4,
            fontWeight: FontWeight.w500,
          );
          padding = const EdgeInsets.only(bottom: 4);
        } else if (trimmedLine.startsWith('**') && trimmedLine.endsWith('**')) {
          // Bold text
          final cleanText = trimmedLine.replaceAll('**', '');
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              cleanText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
                height: 1.4,
              ),
            ),
          );
        } else if (trimmedLine.toLowerCase().contains('note:') || 
                   trimmedLine.toLowerCase().contains('tip:') ||
                   trimmedLine.toLowerCase().contains('important:')) {
          // Special notes/tips
          style = const TextStyle(
            fontSize: 13,
            color: AppTheme.primaryColor,
            fontStyle: FontStyle.italic,
          );
          backgroundColor = AppTheme.primaryColor.withOpacity(0.1);
          padding = const EdgeInsets.all(8);
        } else if (trimmedLine.contains('€') || trimmedLine.contains('\$') || 
                   trimmedLine.contains('£') || trimmedLine.contains('¥')) {
          // Price information
          style = TextStyle(
            fontSize: 14,
            color: Colors.green[700],
            fontWeight: FontWeight.w500,
          );
          padding = const EdgeInsets.only(bottom: 4);
        } else {
          // Regular text
          style = const TextStyle(
            fontSize: 14,
            color: AppTheme.textPrimaryColor,
            height: 1.4,
          );
          padding = const EdgeInsets.only(bottom: 4);
        }
        
        Widget textWidget = Text(
          trimmedLine,
          style: style,
        );
        
        if (backgroundColor != null) {
          textWidget = Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: padding ?? EdgeInsets.zero,
              child: textWidget,
            ),
          );
        } else if (padding != null) {
          textWidget = Padding(
            padding: padding,
            child: textWidget,
          );
        }
        
        return textWidget;
      }).toList(),
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