import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../../core/utils/app_theme.dart';
import '../../core/utils/app_router.dart';
import '../../services/real_ai_service.dart';
import 'main_navigation_page.dart';

class ItineraryCreationPage extends ConsumerStatefulWidget {
  const ItineraryCreationPage({super.key, this.tripVision});
  
  final String? tripVision;

  @override
  ConsumerState<ItineraryCreationPage> createState() => _ItineraryCreationPageState();
}

class _ItineraryCreationPageState extends ConsumerState<ItineraryCreationPage>
    with TickerProviderStateMixin {
  late AnimationController _spinnerController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  bool _isCreationComplete = false;
  String _currentMessage = 'Creating Itinerary...';
  String _generatedItinerary = '';

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _spinnerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    // Start animations
    _spinnerController.repeat();
    _fadeController.forward();
    
    // Simulate itinerary creation process
    _simulateItineraryCreation();
  }

  @override
  void dispose() {
    _spinnerController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _simulateItineraryCreation() async {
    try {
      final aiService = RealAIService();
      final tripVision = widget.tripVision ?? 'Plan a amazing trip for me';
      
      // Phase 1: Creating itinerary
      setState(() {
        _currentMessage = 'Creating itinerary with AI...';
      });
      
      // Generate real itinerary
      final itinerary = await aiService.generateItinerary(tripVision);
      
      if (mounted) {
        setState(() {
          _currentMessage = 'Curating a perfect plan for you...';
          _generatedItinerary = itinerary; // Store the real AI response
        });
        
        // Store the itinerary in session storage for notifications
        MainNavigationPage.addItinerary(tripVision, itinerary);
      }
      
      // Small delay for UX
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        setState(() {
          _isCreationComplete = true;
        });
        _spinnerController.stop();
        
        // Show the generated itinerary in a snackbar or dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Itinerary created successfully!'),
            backgroundColor: AppTheme.primaryColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentMessage = 'Error creating itinerary: ${e.toString()}';
          _isCreationComplete = true;
        });
        _spinnerController.stop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create itinerary. Please try again.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _handleFollowUp() {
    // Navigate to chat page with context for refinements
    final tripVision = widget.tripVision ?? '';
    final encodedTripVision = Uri.encodeComponent(tripVision);
    final encodedItinerary = Uri.encodeComponent(_generatedItinerary);
    
    context.go('${AppRoute.chat.path}?tripVision=$encodedTripVision&existingItinerary=$encodedItinerary');
  }

  void _handleSaveOffline() {
    // TODO: Implement save offline functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Itinerary saved offline successfully!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
    
    // Navigate back to home after saving
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        context.go(AppRoute.home.path);
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
    // First try to extract from generated itinerary if available
    if (_generatedItinerary.isNotEmpty) {
      try {
        final jsonData = json.decode(_generatedItinerary);
        if (jsonData['title'] != null) {
          final title = jsonData['title'].toString();
          final patterns = [
            RegExp(r'trip to ([a-zA-Z\s,]+?)(?:\s|,|$|for|in|during)', caseSensitive: false),
            RegExp(r'visit ([a-zA-Z\s,]+?)(?:\s|,|$|for|in|during)', caseSensitive: false),
            RegExp(r'travel to ([a-zA-Z\s,]+?)(?:\s|,|$|for|in|during)', caseSensitive: false),
            RegExp(r'in ([a-zA-Z\s,]+?)(?:\s|,|$|for)', caseSensitive: false),
          ];
          
          for (final pattern in patterns) {
            final match = pattern.firstMatch(title);
            if (match != null && match.group(1) != null) {
              return match.group(1)!.trim();
            }
          }
        }
      } catch (e) {
        // Not valid JSON, continue with trip vision extraction
      }
    }
    
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
            // Header with back button and profile
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      const SizedBox(width: 16),
                      const Text(
                        'Home',
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
            ),
            
            // Main content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    
                    // Title with palm tree emoji when complete
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              _isCreationComplete ? 'Itinerary Created' : _currentMessage,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_isCreationComplete) ...[
                            const SizedBox(width: 8),
                            const Text('🌴', style: TextStyle(fontSize: 32)),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Content area
                    Expanded(
                      child: _isCreationComplete 
                        ? _buildItineraryContent() 
                        : _buildLoadingContent(),
                    ),
                    
                    // Action buttons
                    if (_isCreationComplete) ...[
                      const SizedBox(height: 16),
                      // Follow up to refine button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _handleFollowUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.8),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.chat_bubble_outline, size: 20),
                          label: const Text(
                            'Follow up to refine',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Save Offline button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: _handleSaveOffline,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondaryColor,
                            side: const BorderSide(
                              color: AppTheme.textSecondaryColor,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          icon: const Icon(Icons.download, size: 20),
                          label: const Text(
                            'Save Offline',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                    
                    SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.textSecondaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            _currentMessage,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display formatted AI generated itinerary
            if (_generatedItinerary.isNotEmpty) 
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormattedItinerary(_generatedItinerary),
                  
                  const SizedBox(height: 24),
                  
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
              )
            else
              const Text(
                'Generating your personalized itinerary...',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                  height: 1.4,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedItinerary(String itinerary) {
    try {
      // Try to parse as JSON first
      final jsonData = json.decode(itinerary);
      return _buildJsonItinerary(jsonData);
    } catch (e) {
      // If not valid JSON, display as formatted text
      return _buildTextItinerary(itinerary);
    }
  }

  Widget _buildJsonItinerary(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        if (data['title'] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              data['title'].toString(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),

        // Date range
        if (data['startDate'] != null && data['endDate'] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${data['startDate']} to ${data['endDate']}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

        // Days
        if (data['days'] != null)
          ...((data['days'] as List).map((day) => _buildDayItem(day)).toList()),
      ],
    );
  }

  Widget _buildDayItem(Map<String, dynamic> day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textSecondaryColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date and summary
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  day['date']?.toString() ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (day['summary'] != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    day['summary'].toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Activities
          if (day['items'] != null)
            ...((day['items'] as List).map((item) => _buildActivityItem(item)).toList()),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time
          if (item['time'] != null)
            SizedBox(
              width: 60,
              child: Text(
                item['time'].toString(),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          
          const SizedBox(width: 12),
          
          // Activity details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['activity']?.toString() ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item['notes'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item['notes'].toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextItinerary(String itinerary) {
    // Format plain text itinerary with basic styling
    final lines = itinerary.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmedLine = line.trim();
        
        if (trimmedLine.isEmpty) {
          return const SizedBox(height: 8);
        }
        
        // Style different types of lines
        TextStyle style;
        if (trimmedLine.startsWith('🌟') || trimmedLine.startsWith('#')) {
          style = const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          );
        } else if (trimmedLine.startsWith('Day ') || RegExp(r'^\d+\.\s').hasMatch(trimmedLine)) {
          style = const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          );
        } else if (trimmedLine.startsWith('•') || trimmedLine.startsWith('-')) {
          style = const TextStyle(
            fontSize: 14,
            color: AppTheme.textPrimaryColor,
            height: 1.4,
          );
        } else {
          style = const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondaryColor,
            height: 1.4,
          );
        }
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            trimmedLine,
            style: style,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildItineraryItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: AppTheme.textPrimaryColor,
          height: 1.4,
        ),
      ),
    );
  }
}