import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/api_config.dart';

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final _formKey = GlobalKey<FormState>();

  // Input Controllers for "Current" metrics
  final _paceMinController = TextEditingController(text: '5');
  final _paceSecController = TextEditingController(text: '30');
  final _mileageController = TextEditingController(text: '40');
  final _restingHrController = TextEditingController(text: '60');
  final _maxHrController = TextEditingController(text: '190');
  final _vo2MaxController = TextEditingController(); 
  final _customDistanceController = TextEditingController();

  // Background data (Retrieved from Profile)
  double _profileConsistency = 0.85;
  int _userAge = 25;
  int _userGender = 1;

  bool _isLoading = false;
  List<dynamic>? _multiPredictions;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _profileConsistency = data['avgConsistency'] ?? 0.85;
          _userAge = data['age'] ?? 25;
          _userGender = data['gender_encoded'] ?? 1;
        });
      }
    }
  }

  double? _parsePace(TextEditingController min, TextEditingController sec) {
    if (min.text.isEmpty && sec.text.isEmpty) return null;
    double m = double.tryParse(min.text) ?? 0;
    double s = double.tryParse(sec.text) ?? 0;
    return m + (s / 60.0);
  }

  Future<void> _getPrediction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _multiPredictions = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final url = Uri.parse(ApiConfig.predictAllUrl);

    try {
      final Map<String, dynamic> requestBody = {
        "target_distance_km": 0.0, // Placeholder, backend handles the 4 distances
        "weekly_mileage_km": double.parse(_mileageController.text),
        "resting_hr": double.parse(_restingHrController.text),
        "max_hr": double.parse(_maxHrController.text),
        "age": _userAge,
        "gender_encoded": _userGender,
        "training_consistency": _profileConsistency,
        "avg_pace_min_km": _parsePace(_paceMinController, _paceSecController),
        "vo2_max": double.tryParse(_vo2MaxController.text),
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> predictions = data['predictions'];
        setState(() => _multiPredictions = predictions);
        
        // Save each prediction as a separate document for the History Chart
        for (var pred in predictions) {
          await FirebaseFirestore.instance.collection('predictions').add({
            'userId': user.uid,
            'target_distance_km': pred['distance'],
            'predicted_time': pred['predicted_time'],
            'timestamp': FieldValue.serverTimestamp(),
            'weekly_mileage_km': double.parse(_mileageController.text),
            'label': pred['label'],
          });
        }
      } else {
        if (mounted) {
          final errorData = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${errorData['detail'] ?? response.statusCode}")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to connect to backend: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Race Predictions'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0), 
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Health & Training Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Current Training Stats'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _restingHrController,
                              decoration: const InputDecoration(labelText: 'Resting HR'),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                final val = int.tryParse(v);
                                if (val == null) return 'Invalid number';
                                if (val < 30 || val > 120) return '30-120 BPM';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _maxHrController,
                              decoration: const InputDecoration(labelText: 'Max HR'),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                final val = int.tryParse(v);
                                if (val == null) return 'Invalid number';
                                if (val < 100 || val > 240) return '100-240 BPM';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _mileageController,
                        decoration: const InputDecoration(labelText: 'Weekly Mileage (km)', prefixIcon: Icon(Icons.directions_run)),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final val = double.tryParse(v);
                          if (val == null) return 'Invalid number';
                          if (val <= 0) return 'Must be > 0';
                          if (val > 300) return 'Max 300km';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _paceMinController,
                              decoration: const InputDecoration(labelText: 'Avg Pace (Min)'),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                final val = int.tryParse(v);
                                if (val == null) return 'Invalid';
                                if (val < 2) return 'Min 2 min';
                                if (val > 15) return 'Max 15 min';
                                return null;
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            child: Text(':', style: theme.textTheme.titleLarge),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _paceSecController,
                              decoration: const InputDecoration(labelText: 'Sec'),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                final val = int.tryParse(v);
                                if (val == null) return 'Invalid';
                                if (val < 0 || val >= 60) return '0-59';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _vo2MaxController,
                        decoration: const InputDecoration(
                          labelText: 'VO2 Max (Optional)', 
                          prefixIcon: Icon(Icons.monitor_heart), 
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "* Stats like age and consistency are pulled from your profile.",
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _getPrediction,
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Predict All Races'),
              ),
              const SizedBox(height: 32),
              
              if (_multiPredictions != null) ...[
                _buildSectionTitle('Predicted Finish Times'),
                const SizedBox(height: 12),
                ..._multiPredictions!.map((pred) => _buildPredictionResultCard(pred)).toList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPredictionResultCard(Map<String, dynamic> prediction) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              radius: 28,
              child: Text(
                prediction['label'].contains('Full') ? 'FM' : 
                prediction['label'].contains('Half') ? 'HM' : 
                prediction['label'],
                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(prediction['label'], style: theme.textTheme.titleMedium),
                  Text("Target Pace: ${prediction['pace']}", style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                  if (prediction['top_factors'] != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: (prediction['top_factors'] as List).map((factor) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
                        ),
                        child: Text(
                          factor.toString(),
                          style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              prediction['predicted_time'],
              style: TextStyle(color: theme.colorScheme.primary, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
