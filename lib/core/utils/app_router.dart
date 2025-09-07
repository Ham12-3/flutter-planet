import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/pages/home_page.dart';
import '../../presentation/pages/chat_page.dart';
import '../../presentation/pages/itinerary_details_page.dart';
import '../../presentation/pages/splash_page.dart';
import '../../presentation/pages/auth/signup_page.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/itinerary_creation_page.dart';
import '../../presentation/pages/profile_page.dart';

enum AppRoute {
  splash('/'),
  login('/login'),
  signup('/signup'),
  home('/home'),
  chat('/chat'),
  itineraryCreation('/create-itinerary'),
  profile('/profile'),
  itineraryDetails('/itinerary/:id');

  const AppRoute(this.path);
  final String path;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoute.splash.path,
    routes: [
      GoRoute(
        path: AppRoute.splash.path,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoute.login.path,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoute.signup.path,
        name: 'signup',
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: AppRoute.home.path,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoute.chat.path,
        name: 'chat',
        builder: (context, state) {
          final itineraryId = state.uri.queryParameters['itineraryId'];
          return ChatPage(existingItineraryId: itineraryId);
        },
      ),
      GoRoute(
        path: AppRoute.itineraryCreation.path,
        name: 'itinerary-creation',
        builder: (context, state) {
          final tripVision = state.uri.queryParameters['vision'];
          return ItineraryCreationPage(tripVision: tripVision);
        },
      ),
      GoRoute(
        path: AppRoute.profile.path,
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/itinerary/:id',
        name: 'itinerary-details',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ItineraryDetailsPage(itineraryId: id);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.matchedLocation}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoute.home.path),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});