import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/app_router.dart';

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
    // Phase 1: Creating itinerary
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      setState(() {
        _currentMessage = 'Curating a perfect plan for you...';
      });
    }
    
    // Phase 2: Curating plan
    await Future.delayed(const Duration(seconds: 4));
    
    if (mounted) {
      setState(() {
        _isCreationComplete = true;
      });
      _spinnerController.stop();
    }
  }

  void _handleFollowUp() {
    // Navigate to chat page for refinements
    context.go(AppRoute.chat.path);
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
            // Header with back button and profile
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                          Text(
                            _isCreationComplete ? 'Itinerary Created' : _currentMessage,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                            textAlign: TextAlign.center,
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
                    
                    const SizedBox(height: 16),
                    
                    // Action buttons
                    if (_isCreationComplete) ...[
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
                    
                    const SizedBox(height: 40),
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
            // Day 1 Header
            const Text(
              'Day 1: Arrival in Bali & Settle in Ubud',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Itinerary items
            _buildItineraryItem(
              '• Morning: Arrive in Bali, Denpasar Airport.',
            ),
            
            _buildItineraryItem(
              '• Transfer: Private driver to Ubud (around 1.5 hours).',
            ),
            
            _buildItineraryItem(
              '• Accommodation: Check-in at a peaceful boutique hotel or resort in Ubud (e.g., Ubud Aura Retreat).',
            ),
            
            _buildItineraryItem(
              '• Afternoon: Explore Ubud\'s local area, walk around the tranquil rice terraces at Tegallalang.',
            ),
            
            _buildItineraryItem(
              '• Evening: Dinner at Locavore (known for farm-to-table dishes in peaceful environment)',
            ),
            
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
            
            const SizedBox(height: 16),
            
            // Location info
            const Text(
              'Mumbai to Bali, Indonesia | 11hrs 5mins',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
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