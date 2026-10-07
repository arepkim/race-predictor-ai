import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_screen.dart';
import '../main.dart'; // Import themeNotifier

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<Map<String, dynamic>> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return doc.data() ?? {};
    }
    return {};
  }

  Future<int> _getPredictionCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('predictions')
          .where('userId', isEqualTo: user.uid)
          .get();
      return snapshot.docs.length;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        automaticallyImplyLeading: false,
        actions: [
          FutureBuilder<Map<String, dynamic>>(
            future: _getUserData(),
            builder: (context, snapshot) {
              return IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  if (snapshot.hasData) {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(userData: snapshot.data!),
                      ),
                    );
                    if (result == true) setState(() {}); // Refresh data
                  }
                },
              );
            },
          )
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? {};
          final firstName = data['firstName'] ?? 'Runner';
          final lastName = data['lastName'] ?? '';
          final email = data['email'] ?? FirebaseAuth.instance.currentUser?.email ?? 'No email';
          final age = data['age']?.toString() ?? 'N/A';
          final gender = (data['gender_encoded'] == 1) ? 'Male' : 'Female';
          
          // New Data
          final height = data['height']?.toString() ?? 'N/A';
          final weight = data['weight']?.toString() ?? 'N/A';
          final bmi = data['bmi']?.toString() ?? 'N/A';
          final fitnessLevel = data['fitnessLevel'] ?? 'Not Set';
          final targetGoal = data['targetGoal'] ?? 'Not Set';
          
          String targetDateStr = 'Not Set';
          if (data['targetDate'] != null) {
            final date = DateTime.parse(data['targetDate']);
            targetDateStr = "${date.day}/${date.month}/${date.year}";
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // --- Profile Header ---
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: theme.colorScheme.primary,
                      child: const Icon(Icons.person, size: 60, color: Colors.white),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: theme.colorScheme.surface,
                        child: IconButton(
                          icon: Icon(Icons.camera_alt, size: 16, color: theme.colorScheme.primary),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Profile picture update coming soon!")),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '$firstName $lastName',
                  style: theme.textTheme.headlineMedium,
                ),
                Text(
                  email,
                  style: theme.textTheme.bodyMedium?.copyWith(color: isDark ? Colors.grey.shade400 : Colors.grey),
                ),
                const SizedBox(height: 30),

                // --- Statistics Row ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('BMI', bmi),
                    _buildStatItem('Level', fitnessLevel.split(' ').last),
                    FutureBuilder<int>(
                      future: _getPredictionCount(),
                      builder: (context, countSnapshot) {
                        return _buildStatItem('Predictions', countSnapshot.data?.toString() ?? '0');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // --- Goal Card ---
                _buildInfoCard(
                  title: 'My Current Goal',
                  items: [
                    _buildInfoTile(Icons.flag_outlined, 'Target Race', targetGoal),
                    _buildInfoTile(Icons.event_available, 'Achievement Date', targetDateStr),
                  ],
                ),
                const SizedBox(height: 20),

                // --- Physical Information List ---
                _buildInfoCard(
                  title: 'Physical Metrics',
                  items: [
                    _buildInfoTile(Icons.height, 'Height', '$height cm'),
                    _buildInfoTile(Icons.monitor_weight_outlined, 'Weight', '$weight kg'),
                    _buildInfoTile(Icons.cake_outlined, 'Age', '$age years old'),
                    _buildInfoTile(Icons.wc_outlined, 'Gender', gender),
                  ],
                ),
                const SizedBox(height: 20),
                
                _buildInfoCard(
                  title: 'App Preferences',
                  items: [
                    _buildThemeToggleTile(), // Night Mode Toggle
                    _buildInfoTile(Icons.notifications_none, 'Notifications', 'Enabled'),
                    _buildInfoTile(Icons.straighten, 'Unit System', 'Metric (km)'),
                  ],
                ),
                const SizedBox(height: 40),

                // --- Logout Button ---
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                    },
                    icon: Icon(Icons.logout, color: theme.colorScheme.error),
                    label: Text('Log Out', style: TextStyle(color: theme.colorScheme.error)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildThemeToggleTile() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isDark ? Icons.dark_mode : Icons.light_mode, 
            size: 20, 
            color: theme.colorScheme.primary.withOpacity(0.6)
          ),
          const SizedBox(width: 12),
          Text(
            'Night Mode', 
            style: theme.textTheme.bodyMedium?.copyWith(color: isDark ? Colors.grey.shade400 : Colors.grey)
          ),
          const Spacer(),
          Switch(
            value: isDark,
            onChanged: (value) {
              themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
            },
            activeColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary)),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey)),
      ],
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> items}) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.labelLarge?.copyWith(color: theme.brightness == Brightness.dark ? Colors.grey.shade400 : Colors.black54)),
          const SizedBox(height: 10),
          ...items,
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary.withOpacity(0.6)),
          const SizedBox(width: 12),
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: isDark ? Colors.grey.shade400 : Colors.grey)),
          const Spacer(),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
