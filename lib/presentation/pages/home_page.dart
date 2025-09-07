import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_router.dart';
import '../../core/utils/app_theme.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _tripVisionController = TextEditingController();

  @override
  void dispose() {
    _tripVisionController.dispose();
    super.dispose();
  }

  void _handleCreateItinerary() {
    final vision = _tripVisionController.text.trim();
    if (vision.isNotEmpty) {
      // Navigate to itinerary creation page with the vision
      context.go('${AppRoute.itineraryCreation.path}?vision=${Uri.encodeComponent(vision)}');
    } else {
      // Show error if no vision is provided
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe your trip vision first'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _handleVoiceInput() {
    // TODO: Implement voice input
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice input not implemented yet')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with greeting and profile
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Hey Shubham ',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const Text('👋', style: TextStyle(fontSize: 20)),
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
              
              const SizedBox(height: 32),
              
              // Trip Vision Question
              const Text(
                'What\'s your vision\nfor this trip?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                  height: 1.2,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Trip Vision Input
              TextField(
                controller: _tripVisionController,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'Describe your dream trip here...\n\nExample: 7 days in Bali next April, 3 people, mid-range budget, wanted to explore less populated areas, it should be a peaceful trip!',
                  hintStyle: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryColor,
                      width: 3,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  suffixIcon: GestureDetector(
                    onTap: _handleVoiceInput,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 16,
                ),
                cursorColor: AppTheme.primaryColor,
              ),
              
              const SizedBox(height: 24),
              
              // Create My Itinerary Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleCreateItinerary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Create My Itinerary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Offline Saved Itineraries Section
              const Text(
                'Offline Saved Itineraries',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Saved Itineraries List
              Expanded(
                child: _buildSavedItineraries(),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSavedItineraries() {
    final savedTrips = [
      {
        'title': 'Japan Trip, 20 days vacation, explore ky...',
        'color': AppTheme.primaryColor,
      },
      {
        'title': 'India Trip, 7 days work trip, suggest affor...',
        'color': AppTheme.primaryColor,
      },
      {
        'title': 'Europe trip, include Paris, Berlin, Dortmun...',
        'color': AppTheme.primaryColor,
      },
      {
        'title': 'Two days weekend getaway to somewhe...',
        'color': AppTheme.primaryColor,
      },
    ];

    return ListView.builder(
      itemCount: savedTrips.length,
      itemBuilder: (context, index) {
        final trip = savedTrips[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.textSecondaryColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: trip['color'] as Color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  trip['title'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ],
          ),
        );
      },
    );
  }
}