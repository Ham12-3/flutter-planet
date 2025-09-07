import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class ItineraryDetailsPage extends ConsumerWidget {
  const ItineraryDetailsPage({super.key, required this.itineraryId});
  
  final String itineraryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Load actual itinerary from database
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.go('/chat?itineraryId=$itineraryId');
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Share'),
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete),
                  title: Text('Delete'),
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'share':
                  // TODO: Implement sharing
                  break;
                case 'delete':
                  _showDeleteDialog(context);
                  break;
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Header
            _buildTripHeader(context),
            const SizedBox(height: 24),
            
            // Trip Overview
            _buildTripOverview(context),
            const SizedBox(height: 24),
            
            // Daily Itinerary
            Text(
              'Daily Itinerary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Sample Days
            _buildDayCard(context, 'Day 1', 'April 10, 2025', 'Fushimi Inari & Gion'),
            _buildDayCard(context, 'Day 2', 'April 11, 2025', 'Arashiyama Bamboo Grove'),
            _buildDayCard(context, 'Day 3', 'April 12, 2025', 'Kiyomizu-dera Temple'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.go('/chat?itineraryId=$itineraryId');
        },
        icon: const Icon(Icons.chat),
        label: const Text('Ask AI'),
      ),
    );
  }
  
  Widget _buildTripHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kyoto 5-Day Solo Trip',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'April 10-15, 2025',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Solo Trip',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTripOverview(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trip Overview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(context, 'Duration', '5 Days'),
                _buildStatItem(context, 'Activities', '12'),
                _buildStatItem(context, 'AI Cost', '\$2.50'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
  
  Widget _buildDayCard(BuildContext context, String dayTitle, String date, String summary) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(dayTitle),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(date),
            Text(
              summary,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        children: [
          _buildActivityItem(
            context,
            '09:00',
            'Climb Fushimi Inari Shrine',
            'Famous shrine with thousands of red torii gates',
            '34.9671,135.7727',
          ),
          _buildActivityItem(
            context,
            '14:00',
            'Lunch at Nishiki Market',
            'Traditional food market with local delicacies',
            '35.0047,135.7630',
          ),
          _buildActivityItem(
            context,
            '18:30',
            'Evening walk in Gion',
            'Historic geisha district with traditional architecture',
            '35.0037,135.7788',
          ),
        ],
      ),
    );
  }
  
  Widget _buildActivityItem(
    BuildContext context,
    String time,
    String activity,
    String description,
    String coordinates,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          time,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      title: Text(activity),
      subtitle: Text(description),
      trailing: IconButton(
        icon: const Icon(Icons.map),
        onPressed: () => _openMap(coordinates),
      ),
    );
  }
  
  void _openMap(String coordinates) async {
    final coords = coordinates.split(',');
    if (coords.length == 2) {
      final lat = coords[0];
      final lng = coords[1];
      final url = 'https://maps.google.com/?q=$lat,$lng';
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    }
  }
  
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: const Text('Are you sure you want to delete this trip? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Delete itinerary
              Navigator.of(context).pop();
              context.go('/home');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}