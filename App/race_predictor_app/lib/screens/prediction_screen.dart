import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  // --- ENVIRONMENT TOGGLE ---
  // Change to 'true' when using the laptop emulator, 'false' for physical phone
  final bool _isEmulator = false; 
  final String _wifiIpAddress = '10.213.65.78'; // Replace with your actual laptop IP
  // --------------------------
  
  final _formKey = GlobalKey<FormState>();

  // Target Race
  String _selectedDistancePreset = '10.0';
  final _customDistanceController = TextEditingController();
  
  // Training & Health Stats
  final _paceMinController = TextEditingController(text: '5');
  final _paceSecController = TextEditingController(text: '30');
  final _mileageController = TextEditingController(text: '40');
  final _restingHrController = TextEditingController(text: '60');
  final _maxHrController = TextEditingController(text: '190');
  
  // --- RESTORED: Optional VO2 Max ---
  final _vo2MaxController = TextEditingController();
  
  double _consistency = 0.85;

  // Personal Bests (Optional)
  final _pb5kMinController = TextEditingController();
  final _pb5kSecController = TextEditingController();
  final _pb10kMinController = TextEditingController();
  final _pb10kSecController = TextEditingController();
  final _pbHalfHrController = TextEditingController();
  final _pbHalfMinController = TextEditingController();
  final _pbHalfSecController = TextEditingController();
  final _pbFullHrController = TextEditingController();
  final _pbFullMinController = TextEditingController();
  final _pbFullSecController = TextEditingController();

  final List<Map<String, dynamic>> _distancePresets = [
    {'label': '5K', 'value': '5.0'},
    {'label': '10K', 'value': '10.0'},
    {'label': 'Half', 'value': '21.1'},
    {'label': 'Full', 'value': '42.2'},
    {'label': 'Custom', 'value': 'custom'},
  ];

  String? _predictedTime;
  bool _isLoading = false;

  double? _parsePace(TextEditingController min, TextEditingController sec) {
    if (min.text.isEmpty && sec.text.isEmpty) return null;
    double m = double.tryParse(min.text) ?? 0;
    double s = double.tryParse(sec.text) ?? 0;
    if (m == 0 && s == 0) return null;
    return m + (s / 60.0);
  }

  double? _parseTime(TextEditingController? hr, TextEditingController min, TextEditingController sec) {
    if ((hr == null || hr.text.isEmpty) && min.text.isEmpty && sec.text.isEmpty) return null;
    double h = hr != null ? (double.tryParse(hr.text) ?? 0) : 0;
    double m = double.tryParse(min.text) ?? 0;
    double s = double.tryParse(sec.text) ?? 0;
    if (h == 0 && m == 0 && s == 0) return null;
    return (h * 60) + m + (s / 60.0);
  }

  Future<void> _getPrediction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _predictedTime = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    double distance = _selectedDistancePreset == 'custom' 
        ? double.parse(_customDistanceController.text) 
        : double.parse(_selectedDistancePreset);

    // final url = Uri.parse('http://10.213.65.78:8000/predict');
    // Automatically picks the right URL based on your toggle above!
    final String serverIp = _isEmulator ? '10.0.2.2' : _wifiIpAddress;
    final url = Uri.parse('http://$serverIp:8000/predict');
    String formattedTime = "";

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      
      final int userAge = userData?['age'] ?? 25; 
      final int userGender = userData?['gender_encoded'] ?? 1;

      final Map<String, dynamic> requestBody = {
        "target_distance_km": distance,
        "weekly_mileage_km": double.parse(_mileageController.text),
        "resting_hr": double.parse(_restingHrController.text),
        "max_hr": double.parse(_maxHrController.text),
        "age": userAge,                 
        "gender_encoded": userGender,   
        "avg_pace_min_km": _parsePace(_paceMinController, _paceSecController),
        "training_consistency": _consistency,
        
        // --- RESTORED: Passing VO2 Max (sends null if left empty) ---
        "vo2_max": double.tryParse(_vo2MaxController.text),
        
        "avg_easy_pace_min_km": null,
        "avg_tempo_pace_min_km": null,
        "pb_5k_mins": _parseTime(null, _pb5kMinController, _pb5kSecController),
        "pb_10k_mins": _parseTime(null, _pb10kMinController, _pb10kSecController),
        "pb_half_mins": _parseTime(_pbHalfHrController, _pbHalfMinController, _pbHalfSecController),
        "pb_full_mins": _parseTime(_pbFullHrController, _pbFullMinController, _pbFullSecController),
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        formattedTime = data['formatted_time'];
        setState(() => _predictedTime = formattedTime);
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
    }

    try {
      if (formattedTime.isNotEmpty) {
        await FirebaseFirestore.instance.collection('predictions').add({
          'userId': user.uid,
          'target_distance_km': distance,
          'predicted_time': formattedTime,
          'timestamp': FieldValue.serverTimestamp(),
          'weekly_mileage_km': double.parse(_mileageController.text),
        });
      }
    } catch (e) {
      debugPrint("History Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text('New Prediction')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0), 
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Target Race Section
              _buildCard([
                _buildSectionTitle('Target Race'),
                Wrap(
                  spacing: 8,
                  children: _distancePresets.map((preset) {
                    bool isSelected = _selectedDistancePreset == preset['value'];
                    return ChoiceChip(
                      label: Text(preset['label']),
                      selected: isSelected,
                      selectedColor: Colors.blue.shade100,
                      labelStyle: TextStyle(color: isSelected ? Colors.blue.shade800 : Colors.black),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedDistancePreset = preset['value']);
                      },
                    );
                  }).toList(),
                ),
                if (_selectedDistancePreset == 'custom') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customDistanceController,
                    decoration: const InputDecoration(labelText: 'Distance (km)', prefixIcon: Icon(Icons.straighten), border: OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter distance' : null,
                  ),
                ],
              ]),

              // 2. Health & Training Section
              _buildCard([
                _buildSectionTitle('Training & Health'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _restingHrController,
                        decoration: const InputDecoration(labelText: 'Resting HR', hintText: '60', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _maxHrController,
                        decoration: const InputDecoration(labelText: 'Max HR', hintText: '190', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // --- RESTORED: VO2 Max Input UI ---
                TextFormField(
                  controller: _vo2MaxController,
                  decoration: const InputDecoration(
                    labelText: 'VO2 Max (Optional)', 
                    hintText: 'e.g. 52.5', 
                    prefixIcon: Icon(Icons.monitor_heart), 
                    border: OutlineInputBorder()
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  // No validator needed because it is completely optional
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _mileageController,
                  decoration: const InputDecoration(labelText: 'Weekly Mileage (km)', prefixIcon: Icon(Icons.directions_run), border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _paceMinController,
                        decoration: const InputDecoration(labelText: 'Avg Pace (Min)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      child: Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _paceSecController,
                        decoration: const InputDecoration(labelText: 'Sec', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Training Consistency: ${(_consistency * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.w500)),
                Slider(
                  value: _consistency,
                  onChanged: (v) => setState(() => _consistency = v),
                  divisions: 20,
                  label: '${(_consistency * 100).toInt()}%',
                ),
              ]),

              // 3. Personal Bests Section (Optional)
              ExpansionTile(
                title: const Text('Personal Bests (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  _buildCard([
                    const Text('5K PB (Min:Sec)'),
                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: _pb5kMinController, decoration: const InputDecoration(labelText: 'Min', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                        const SizedBox(width: 8),
                        Expanded(child: TextFormField(controller: _pb5kSecController, decoration: const InputDecoration(labelText: 'Sec', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('10K PB (Min:Sec)'),
                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: _pb10kMinController, decoration: const InputDecoration(labelText: 'Min', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                        const SizedBox(width: 8),
                        Expanded(child: TextFormField(controller: _pb10kSecController, decoration: const InputDecoration(labelText: 'Sec', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Half Marathon PB (Hr:Min:Sec)'),
                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: _pbHalfHrController, decoration: const InputDecoration(labelText: 'Hr', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                        const SizedBox(width: 8),
                        Expanded(child: TextFormField(controller: _pbHalfMinController, decoration: const InputDecoration(labelText: 'Min', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                        const SizedBox(width: 8),
                        Expanded(child: TextFormField(controller: _pbHalfSecController, decoration: const InputDecoration(labelText: 'Sec', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Full Marathon PB (Hr:Min:Sec)'),
                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: _pbFullHrController, decoration: const InputDecoration(labelText: 'Hr', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                        const SizedBox(width: 8),
                        Expanded(child: TextFormField(controller: _pbFullMinController, decoration: const InputDecoration(labelText: 'Min', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                        const SizedBox(width: 8),
                        Expanded(child: TextFormField(controller: _pbFullSecController, decoration: const InputDecoration(labelText: 'Sec', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                      ],
                    ),
                  ]),
                ],
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _getPrediction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Predict Race Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 32),
              if (_predictedTime != null)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    children: [
                      const Text('ESTIMATED FINISH TIME', style: TextStyle(color: Colors.white70, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        _predictedTime!,
                        style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}