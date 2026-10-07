import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Data to save
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _fitnessLevel = 'Beginner';
  double _consistency = 0.7;
  String _targetGoal = '10K';
  DateTime _targetDate = DateTime.now().add(const Duration(days: 90));

  final List<String> _fitnessLevels = ['Absolute Beginner', 'Beginner', 'Intermediate', 'Advanced'];
  final List<String> _goals = ['5K', '10K', 'Half Marathon', 'Marathon'];

  Future<void> _completeOnboarding() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    double height = double.tryParse(_heightController.text) ?? 170;
    double weight = double.tryParse(_weightController.text) ?? 70;
    double bmi = weight / ((height / 100) * (height / 100));

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'height': height,
      'weight': weight,
      'bmi': double.parse(bmi.toStringAsFixed(1)),
      'fitnessLevel': _fitnessLevel,
      'avgConsistency': _consistency,
      'targetGoal': _targetGoal,
      'targetDate': _targetDate.toIso8601String(),
      'isOnboardingComplete': true,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / 3,
                backgroundColor: Colors.grey.shade200,
                color: theme.colorScheme.primary,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                children: [
                  _buildPhysicalStep(),
                  _buildFitnessStep(),
                  _buildGoalStep(),
                ],
              ),
            ),
            _buildNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhysicalStep() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Let's get to know you!", style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text("Your height and weight help us calculate BMI and calorie burn.", style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 40),
          TextField(
            controller: _heightController,
            decoration: const InputDecoration(labelText: 'Height (cm)', prefixIcon: Icon(Icons.height)),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _weightController,
            decoration: const InputDecoration(labelText: 'Weight (kg)', prefixIcon: Icon(Icons.monitor_weight_outlined)),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildFitnessStep() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Your Fitness Level", style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text("How would you describe your current running experience?", style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 30),
          ..._fitnessLevels.map((level) => RadioListTile<String>(
                title: Text(level),
                value: level,
                groupValue: _fitnessLevel,
                onChanged: (val) => setState(() => _fitnessLevel = val!),
                activeColor: theme.colorScheme.primary,
              )),
          const SizedBox(height: 30),
          Text("Training Consistency", style: theme.textTheme.titleMedium),
          Text("How often do you stick to your plan? ${( _consistency * 100).toInt()}%", style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          Slider(
            value: _consistency,
            onChanged: (v) => setState(() => _consistency = v),
            divisions: 10,
            label: "${(_consistency * 100).toInt()}%",
            activeColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalStep() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Set Your Goal", style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text("What is the next finish line you're chasing?", style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 30),
          DropdownButtonFormField<String>(
            value: _targetGoal,
            decoration: const InputDecoration(labelText: 'Target Distance'),
            items: _goals.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: (v) => setState(() => _targetGoal = v!),
          ),
          const SizedBox(height: 30),
          Text("Target Achievement Date", style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          ListTile(
            tileColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: Icon(Icons.calendar_month, color: theme.colorScheme.primary),
            title: Text("${_targetDate.day}/${_targetDate.month}/${_targetDate.year}"),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _targetDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
              );
              if (picked != null) setState(() => _targetDate = picked);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
              child: const Text("Back"),
            )
          else
            const SizedBox.shrink(),
          ElevatedButton(
            onPressed: () {
              if (_currentPage < 2) {
                _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              } else {
                _completeOnboarding();
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              minimumSize: const Size(120, 54), // Fixed: override the infinite width from global theme
            ),
            child: Text(_currentPage == 2 ? "Finish" : "Next"),
          ),
        ],
      ),
    );
  }
}
