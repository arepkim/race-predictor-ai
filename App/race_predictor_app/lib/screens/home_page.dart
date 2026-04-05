import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'prediction_screen.dart';
import 'history_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Race Predictor', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.blue),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
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
                  return const Text('Loading...', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey));
                }
                return Text(
                  'Hello, ${snapshot.data}!',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
                );
              },
            ),
            const SizedBox(height: 8),
            const Text(
              "What would you like to do today?",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // --- The Navigation Cards ---
            Expanded(
              child: GridView.count(
                crossAxisCount: 1, // Stacks them vertically. Change to 2 for side-by-side squares!
                childAspectRatio: 2.0,
                mainAxisSpacing: 20,
                children: [
                  _buildNavCard(
                    context,
                    title: 'Predict Race Time',
                    subtitle: 'Use AI to forecast your next finish line.',
                    icon: Icons.timer,
                    color: Colors.blue.shade600,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PredictionScreen()));
                    },
                  ),
                  _buildNavCard(
                    context,
                    title: 'View Analytics',
                    subtitle: 'Check your pacing trends and past predictions.',
                    icon: Icons.auto_graph,
                    color: Colors.black87,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
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