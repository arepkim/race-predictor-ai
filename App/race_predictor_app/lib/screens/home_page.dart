import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'prediction_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'coach_screen.dart';

class HomePage extends StatelessWidget {
  final Function(int)? onTabSwitch;
  const HomePage({super.key, this.onTabSwitch});

  // Fetch the user's first name from Firestore
  Future<String> _getUserFirstName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return doc.data()?['firstName'] ?? 'Runner'; // Fallback to 'Runner' if name is missing
    }
    return 'Runner';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Race Predictor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- The Greeting Section ---
            FutureBuilder<String>(
              future: _getUserFirstName(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text('Loading...', style: theme.textTheme.headlineMedium?.copyWith(color: Colors.grey));
                }
                return Text(
                  'Hello, ${snapshot.data}!',
                  style: theme.textTheme.headlineLarge,
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              "What would you like to do today?",
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // --- The Navigation Cards ---
            Expanded(
              child: ListView(
                children: [
                  _buildNavCard(
                    context,
                    title: 'Predict Race Time',
                    subtitle: 'Use AI to forecast your next finish line.',
                    icon: Icons.timer,
                    color: theme.colorScheme.primary,
                    onTap: () {
                      if (onTabSwitch != null) {
                        onTabSwitch!(1); // Index of PredictionScreen
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const PredictionScreen()));
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildNavCard(
                    context,
                    title: 'Elite AI Coach',
                    subtitle: 'Chat with your AI coach for training advice.',
                    icon: Icons.chat_bubble,
                    color: Colors.orange.shade700,
                    onTap: () {
                      if (onTabSwitch != null) {
                        onTabSwitch!(2); // Index of CoachScreen
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const CoachScreen()));
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildNavCard(
                    context,
                    title: 'View Analytics',
                    subtitle: 'Check your pacing trends and past predictions.',
                    icon: Icons.auto_graph,
                    color: theme.colorScheme.secondary,
                    onTap: () {
                      if (onTabSwitch != null) {
                        onTabSwitch!(3); // Index of HistoryScreen
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildNavCard(
                    context,
                    title: 'My Profile',
                    subtitle: 'Manage your account and physical metrics.',
                    icon: Icons.person,
                    color: theme.colorScheme.tertiary,
                    onTap: () {
                      if (onTabSwitch != null) {
                        onTabSwitch!(4); // Index of ProfileScreen
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // A custom widget to make beautiful navigation buttons
  Widget _buildNavCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}