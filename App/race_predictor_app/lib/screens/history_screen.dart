import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  // Helper method to convert HH:MM:SS to total Pace (minutes per km)
  double _calculatePace(String timeStr, double distanceKm) {
    try {
      final parts = timeStr.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final s = int.parse(parts[2]);
      final totalMinutes = (h * 60) + m + (s / 60.0);
      return totalMinutes / distanceKm;
    } catch (e) {
      return 0.0;
    }
  }

  // Helper method to format decimal pace back to MM:SS for the chart labels
  String _formatPace(double paceDecimal) {
    int minutes = paceDecimal.floor();
    int seconds = ((paceDecimal - minutes) * 60).round();
    if (seconds == 60) {
      minutes += 1;
      seconds = 0;
    }
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("Please log in to view history."));
    }

    return Scaffold(
      backgroundColor: Colors.black, // Matching Garmin's dark mode vibe
      appBar: AppBar(
        title: const Text('Race Predictor', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('predictions')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.blue));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error loading history", style: TextStyle(color: Colors.red.shade300)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No predictions yet.\nGo run some miles!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final docs = snapshot.data!.docs;
          
          // Reverse docs for the chart so time goes left-to-right (oldest to newest)
          final chartDocs = docs.reversed.toList();

          // Data buckets for the 4 line charts
          List<FlSpot> spots5k = [];
          List<FlSpot> spots10k = [];
          List<FlSpot> spotsHalf = [];
          List<FlSpot> spotsFull = [];

          double minX = double.maxFinite;
          double maxX = -double.maxFinite;

          for (var doc in chartDocs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['timestamp'] == null) continue;
            
            final date = (data['timestamp'] as Timestamp).toDate();
            // Convert date to a double for the X-axis (days since epoch)
            final x = date.millisecondsSinceEpoch / (1000 * 60 * 60 * 24);
            
            if (x < minX) minX = x;
            if (x > maxX) maxX = x;

            final distance = data['target_distance_km'] as double;
            final timeStr = data['predicted_time'] as String;
            final pace = _calculatePace(timeStr, distance);

            if (pace > 0) {
              if (distance == 5.0) spots5k.add(FlSpot(x, pace));
              else if (distance == 10.0) spots10k.add(FlSpot(x, pace));
              else if (distance == 21.1) spotsHalf.add(FlSpot(x, pace));
              else if (distance == 42.2) spotsFull.add(FlSpot(x, pace));
            }
          }

          // If there's only one data point, expand the X-axis slightly so it renders
          if (minX == maxX) {
            minX -= 1;
            maxX += 1;
          }

          return CustomScrollView(
            slivers: [
              // --- DASHBOARD SECTION (GARMIN STYLE) ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Pace Trend', 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)
                      ),
                      const SizedBox(height: 24),
                      
                      // THE LINE CHART
                      SizedBox(
                        height: 250,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 1.0,
                              getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade800, strokeWidth: 1),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide bottom dates to match your screenshot
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 45,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      _formatPace(value), 
                                      style: const TextStyle(color: Colors.grey, fontSize: 12)
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minX: minX,
                            maxX: maxX,
                            lineBarsData: [
                              _buildLineChartBarData(spots5k, Colors.blue.shade400),
                              _buildLineChartBarData(spots10k, Colors.green.shade400),
                              _buildLineChartBarData(spotsHalf, Colors.orange.shade400),
                              _buildLineChartBarData(spotsFull, Colors.red.shade400),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // CUSTOM LEGEND
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItem(Colors.blue.shade400, '5k'),
                          const SizedBox(width: 16),
                          _buildLegendItem(Colors.green.shade400, '10k', isTriangle: true),
                          const SizedBox(width: 16),
                          _buildLegendItem(Colors.orange.shade400, 'Half', isSquare: true),
                          const SizedBox(width: 16),
                          _buildLegendItem(Colors.red.shade400, 'Marathon', isDiamond: true),
                        ],
                      )
                    ],
                  ),
                ),
              ),

              // --- HISTORY LIST TITLE ---
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: Text(
                    'Prediction Log', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
                  ),
                ),
              ),

              // --- HISTORY LIST SECTION ---
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    
                    final distance = data['target_distance_km'];
                    final time = data['predicted_time'] ?? '--:--:--';
                    final pace = _formatPace(_calculatePace(time, distance));
                    
                    String dateString = "Just now";
                    if (data['timestamp'] != null) {
                      DateTime date = (data['timestamp'] as Timestamp).toDate();
                      dateString = DateFormat('MMM d • h:mm a').format(date); 
                    }

                    // Determine color based on distance
                    Color iconColor = Colors.grey;
                    if (distance == 5.0) iconColor = Colors.blue.shade400;
                    else if (distance == 10.0) iconColor = Colors.green.shade400;
                    else if (distance == 21.1) iconColor = Colors.orange.shade400;
                    else if (distance == 42.2) iconColor = Colors.red.shade400;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: Card(
                        color: Colors.grey.shade900,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Icon(Icons.circle, color: iconColor, size: 16),
                          title: Text(
                            "${distance}k Prediction", 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)
                          ),
                          subtitle: Text("Time: $time  •  Pace: $pace", style: TextStyle(color: Colors.grey.shade400)),
                          trailing: Text(
                            dateString, 
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: docs.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper method to build each line
  LineChartBarData _buildLineChartBarData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true, // Smooth curves like the Garmin chart
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: true), // Shows the dots on the data points
      belowBarData: BarAreaData(show: false),
    );
  }

  // Helper method for the custom legend
  Widget _buildLegendItem(Color color, String label, {bool isSquare = false, bool isTriangle = false, bool isDiamond = false}) {
    IconData iconData = Icons.circle;
    if (isSquare) iconData = Icons.square;
    // Note: Standard material icons don't have perfect small diamonds/triangles, so we use similar shapes or default to circle for the prototype.
    
    return Row(
      children: [
        Icon(iconData, color: color, size: 12),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}