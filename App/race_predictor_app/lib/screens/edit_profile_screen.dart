import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late String _fitnessLevel;
  late double _consistency;

  final List<String> _fitnessLevels = ['Absolute Beginner', 'Beginner', 'Intermediate', 'Advanced'];

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.userData['firstName']);
    _lastNameController = TextEditingController(text: widget.userData['lastName']);
    _ageController = TextEditingController(text: widget.userData['age']?.toString());
    _heightController = TextEditingController(text: widget.userData['height']?.toString());
    _weightController = TextEditingController(text: widget.userData['weight']?.toString());
    _fitnessLevel = widget.userData['fitnessLevel'] ?? 'Beginner';
    _consistency = widget.userData['avgConsistency'] ?? 0.7;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    double weight = double.parse(_weightController.text);
    double height = double.parse(_heightController.text);
    double bmi = weight / ((height / 100) * (height / 100));

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'age': int.parse(_ageController.text),
      'height': height,
      'weight': weight,
      'bmi': double.parse(bmi.toStringAsFixed(1)),
      'fitnessLevel': _fitnessLevel,
      'avgConsistency': _consistency,
    });

    if (mounted) {
      Navigator.pop(context, true); // Return true to indicate data changed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text('SAVE'),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Personal Info'),
              Row(
                children: [
                  Expanded(child: _buildTextField(_firstNameController, 'First Name')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_lastNameController, 'Last Name')),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(_ageController, 'Age', isNumber: true),
              
              const SizedBox(height: 32),
              _buildSectionTitle('Physical Metrics'),
              Row(
                children: [
                  Expanded(child: _buildTextField(_heightController, 'Height (cm)', isNumber: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_weightController, 'Weight (kg)', isNumber: true)),
                ],
              ),
              
              const SizedBox(height: 32),
              _buildSectionTitle('Fitness Background'),
              DropdownButtonFormField<String>(
                value: _fitnessLevel,
                decoration: const InputDecoration(labelText: 'Fitness Level'),
                items: _fitnessLevels.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                onChanged: (v) => setState(() => _fitnessLevel = v!),
              ),
              const SizedBox(height: 24),
              Text('Training Consistency: ${(_consistency * 100).toInt()}%', style: theme.textTheme.titleSmall),
              Slider(
                value: _consistency,
                onChanged: (v) => setState(() => _consistency = v),
                divisions: 10,
                label: "${(_consistency * 100).toInt()}%",
                activeColor: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(title, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (isNumber) {
          final val = double.tryParse(v);
          if (val == null) return 'Invalid';
          
          if (label.contains('Age')) {
            if (val < 5 || val > 100) return '5-100 years';
          } else if (label.contains('Height')) {
            if (val < 50 || val > 250) return '50-250 cm';
          } else if (label.contains('Weight')) {
            if (val < 20 || val > 300) return '20-300 kg';
          }
        }
        return null;
      },
    );
  }
}
