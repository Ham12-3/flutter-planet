import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'dart:math';
import '../../core/utils/app_theme.dart';
import '../../core/utils/app_router.dart';
import 'home_page.dart';
import 'chat_page.dart';
import 'profile_page.dart';
import 'itinerary_creation_page.dart';
import '../../services/real_ai_service.dart';

class MainNavigationPage extends ConsumerStatefulWidget {
  const MainNavigationPage({super.key});

  // Static storage for itineraries created during this session
  static List<Map<String, dynamic>> _sessionItineraries = [];
  
  // Static methods to manage session itineraries
  static void addItinerary(String tripVision, String itineraryContent) {
    final destination = _extractDestinationFromVision(tripVision);
    final itinerary = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'tripVision': tripVision,
      'content': itineraryContent,
      'destination': destination,
      'title': _generateTitle(destination),
      'created': DateTime.now(),
    };
    _sessionItineraries.insert(0, itinerary); // Add to beginning
    
    // Keep only the most recent 5 itineraries
    if (_sessionItineraries.length > 5) {
      _sessionItineraries = _sessionItineraries.take(5).toList();
    }
  }
  
  static List<Map<String, dynamic>> getRecentItineraries() {
    return _sessionItineraries;
  }
  
  static String _extractDestinationFromVision(String tripVision) {
    final lowerVision = tripVision.toLowerCase();
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
    
    // Also try to extract from JSON if itinerary content is provided
    return tripVision.split(' ').take(2).join(' ').trim();
  }
  
  static String _generateTitle(String destination) {
    return '${destination[0].toUpperCase()}${destination.substring(1)} Adventure';
  }

  @override
  ConsumerState<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends ConsumerState<MainNavigationPage>
    with TickerProviderStateMixin {
  int _currentPage = 0;
  final GlobalKey<CurvedNavigationBarState> _navigationKey = GlobalKey();
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  // Store recent itineraries for notifications
  List<Map<String, dynamic>> _recentItineraries = [];
  final RealAIService _aiService = RealAIService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Widget> get _pages => [
        const HomePage(),
        _buildNotificationsPage(), // Notifications page
        const ProfilePage(),
      ];

  List<IconData> get _icons => [
        Icons.home_rounded,
        Icons.notifications_rounded,
        Icons.person_rounded,
      ];

  List<String> get _labels => [
        'Home',
        'Notifications',
        'Profile',
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _currentPage == 2 ? 1.0 : _scaleAnimation.value,
            child: IndexedStack(
              index: _currentPage,
              children: _pages,
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: CurvedNavigationBar(
          key: _navigationKey,
          index: _currentPage,
          backgroundColor: Colors.transparent,
          buttonBackgroundColor: AppTheme.primaryColor,
          color: AppTheme.primaryColor,
          animationDuration: const Duration(milliseconds: 300),
          animationCurve: Curves.easeInOutCubic,
          height: 65,
          letIndexChange: (index) => true,
          items: _buildNavigationItems(),
          onTap: _onNavigationTap,
        ),
      ),
    );
  }

  List<Widget> _buildNavigationItems() {
    return _icons.asMap().entries.map((entry) {
      final index = entry.key;
      final icon = entry.value;
      
      return Container(
        padding: const EdgeInsets.all(8),
        child: AnimatedScale(
          scale: _currentPage == index ? 1.2 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Icon(
            icon,
            size: index == 2 ? 32 : 28, // Make create button larger
            color: Colors.white,
          ),
        ),
      );
    }).toList();
  }

  void _onNavigationTap(int index) {
    setState(() {
      _currentPage = index;
    });

    // Trigger scale animation for page transition
    _animationController.reset();
    _animationController.forward();

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Show label briefly
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _labels[index],
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: AppTheme.primaryColor,
          duration: const Duration(milliseconds: 800),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: const EdgeInsets.only(
            bottom: 100,
            left: 20,
            right: 20,
          ),
        ),
      );
    }
  }

  Widget? _buildFloatingCreateButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: FloatingActionButton.extended(
        onPressed: () {
          // Show quick create options
          _showQuickCreateDialog();
        },
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text(
          'Quick Create',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showQuickCreateDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Quick Create',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildQuickCreateOption(
              icon: Icons.flight_takeoff_rounded,
              title: 'New Trip',
              subtitle: 'Plan a complete itinerary',
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentPage = 0); // Go to home to create trip
              },
            ),
            _buildQuickCreateOption(
              icon: Icons.chat_rounded,
              title: 'Ask AI',
              subtitle: 'Get travel advice',
              onTap: () {
                Navigator.pop(context);
                context.go('/chat'); // Navigate to chat page directly
              },
            ),
            _buildQuickCreateOption(
              icon: Icons.bookmark_add_rounded,
              title: 'Save Idea',
              subtitle: 'Save for later planning',
              onTap: () {
                Navigator.pop(context);
                _showSaveIdeaDialog();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCreateOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _showSaveIdeaDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Travel Idea'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Describe your travel idea...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                // Save the idea (implement storage)
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Travel idea saved!'),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsPage() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _generateDynamicNotifications(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      );
                    }
                    
                    final notifications = snapshot.data ?? [];
                    
                    if (notifications.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 64,
                              color: AppTheme.textSecondaryColor.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No notifications yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppTheme.textSecondaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Create an itinerary to get personalized notifications!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _buildNotificationCard(
                          icon: notification['icon'],
                          title: notification['title'],
                          message: notification['message'],
                          time: notification['time'],
                          isNew: notification['isNew'],
                          onTap: notification['onTap'],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _generateDynamicNotifications() async {
    final notifications = <Map<String, dynamic>>[];
    
    // Mock some recent itineraries for demonstration
    // In a real app, this would come from local storage/database
    _recentItineraries = await _getMockRecentItineraries();
    
    for (int i = 0; i < _recentItineraries.length && i < 4; i++) {
      final itinerary = _recentItineraries[i];
      final destination = _extractDestination(itinerary);
      
      // Generate different types of notifications based on itinerary data
      switch (i % 4) {
        case 0:
          // Trip Reminder
          final daysUntilTrip = Random().nextInt(14) + 1;
          notifications.add({
            'icon': Icons.flight_takeoff,
            'title': 'Trip Reminder',
            'message': 'Your $destination trip is in $daysUntilTrip days! Check your itinerary.',
            'time': _getRandomTime(),
            'isNew': i == 0,
            'onTap': () => _openItineraryDetails(itinerary),
          });
          break;
        case 1:
          // Weather Update
          final weatherConditions = ['sunny', 'partly cloudy', 'clear skies', 'mild temperatures'];
          final weather = weatherConditions[Random().nextInt(weatherConditions.length)];
          notifications.add({
            'icon': Icons.wb_sunny,
            'title': 'Weather Update',
            'message': 'Great weather expected for your $destination trip - $weather ahead!',
            'time': _getRandomTime(),
            'isNew': false,
            'onTap': () => _openWeatherDetails(destination),
          });
          break;
        case 2:
          // Deal Alert
          final discounts = [15, 20, 25, 30];
          final discount = discounts[Random().nextInt(discounts.length)];
          final activities = ['activities', 'tours', 'restaurants', 'accommodations'];
          final activity = activities[Random().nextInt(activities.length)];
          notifications.add({
            'icon': Icons.local_offer,
            'title': 'Deal Alert',
            'message': 'Special offer: $discount% off $activity in $destination.',
            'time': _getRandomTime(),
            'isNew': false,
            'onTap': () => _openDeals(destination),
          });
          break;
        case 3:
          // AI Suggestion
          final suggestions = ['restaurants', 'hidden gems', 'local experiences', 'photo spots'];
          final suggestion = suggestions[Random().nextInt(suggestions.length)];
          notifications.add({
            'icon': Icons.auto_awesome,
            'title': 'AI Suggestion',
            'message': 'New $suggestion discovered for your $destination itinerary.',
            'time': _getRandomTime(),
            'isNew': false,
            'onTap': () => _openAISuggestions(itinerary),
          });
          break;
      }
    }
    
    // If no itineraries, add a sample notification encouraging creation
    if (notifications.isEmpty) {
      notifications.add({
        'icon': Icons.explore,
        'title': 'Welcome to Smart Trip Planner!',
        'message': 'Create your first itinerary to get personalized notifications.',
        'time': 'Now',
        'isNew': true,
        'onTap': () => _goToHome(),
      });
    }
    
    return notifications;
  }
  
  Future<List<Map<String, dynamic>>> _getMockRecentItineraries() async {
    // Get real itineraries from session storage
    final realItineraries = MainNavigationPage.getRecentItineraries();
    
    // If we have real itineraries, return them
    if (realItineraries.isNotEmpty) {
      return realItineraries;
    }
    
    // If no real itineraries, return empty list (will show welcome message)
    return [];
  }
  
  String _extractDestination(Map<String, dynamic> itinerary) {
    return itinerary['destination'] ?? itinerary['title']?.toString().split(' ').first ?? 'your destination';
  }
  
  String _getRandomTime() {
    final times = ['2 hours ago', '1 day ago', '3 days ago', '1 week ago', '2 weeks ago'];
    return times[Random().nextInt(times.length)];
  }
  
  void _openItineraryDetails(Map<String, dynamic> itinerary) {
    // Navigate to chat page with the real itinerary data
    final tripVision = itinerary['tripVision'] ?? '';
    final itineraryContent = itinerary['content'] ?? '';
    
    if (tripVision.isNotEmpty && itineraryContent.isNotEmpty) {
      final encodedTripVision = Uri.encodeComponent(tripVision);
      final encodedItinerary = Uri.encodeComponent(itineraryContent);
      context.go('${AppRoute.chat.path}?tripVision=$encodedTripVision&existingItinerary=$encodedItinerary');
    } else {
      // Fallback to itinerary details page if data is not available
      context.go('/itinerary/${itinerary['id']}');
    }
  }
  
  void _openWeatherDetails(String destination) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Weather for $destination'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wb_sunny, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text('Current conditions in $destination look great for your trip!'),
            const SizedBox(height: 8),
            const Text('Temperature: 22°C\nConditions: Sunny\nWind: 5 mph'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _openDeals(String destination) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Deals in $destination'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_offer, size: 64, color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text('Special offers available for $destination:'),
            const SizedBox(height: 8),
            const Text('• 20% off city tours\n• 15% off restaurants\n• 25% off museums'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _openAISuggestions(Map<String, dynamic> itinerary) async {
    final destination = _extractDestination(itinerary);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Getting AI suggestions...'),
          ],
        ),
      ),
    );
    
    // Simulate AI suggestion generation
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('AI Suggestions for $destination'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 64, color: AppTheme.primaryColor),
              const SizedBox(height: 16),
              Text('Here are some AI-powered suggestions for your $destination trip:'),
              const SizedBox(height: 8),
              const Text('• Try the local morning markets\n• Visit the hidden rooftop cafes\n• Explore the artisan neighborhoods'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
  
  void _goToHome() {
    setState(() {
      _currentPage = 0; // Switch to home tab
    });
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required String title,
    required String message,
    required String time,
    required bool isNew,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isNew ? AppTheme.primaryColor.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNew 
              ? AppTheme.primaryColor.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isNew ? FontWeight.bold : FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
            if (isNew)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        onTap: onTap ?? () {
          // Default action if no specific onTap provided
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification opened')),
          );
        },
      ),
    );
  }
}

// Add haptic feedback support
class HapticFeedback {
  static void lightImpact() {
    // Platform-specific haptic feedback would go here
    // For web/desktop, this is a no-op
  }
}