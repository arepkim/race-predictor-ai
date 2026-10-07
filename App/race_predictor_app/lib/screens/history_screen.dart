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
      appBar: AppBar(
        title: const Text('Race History'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('predictions')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error loading history", style: TextStyle(color: Colors.red)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    "No predictions yet.\nGo run some miles!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
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

          int sessionIndex = -1;
          DateTime? lastDate;

          for (var doc in chartDocs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['timestamp'] == null) continue;
            
            final date = (data['timestamp'] as Timestamp).toDate();
            
            if (lastDate == null || date.difference(lastDate).inSeconds.abs() > 5) {
              sessionIndex++;
              lastDate = date;
            }

            final x = sessionIndex.toDouble();
            
            if (x < minX) minX = x;
            if (x > maxX) maxX = x;

            final distance = (data['target_distance_km'] as num).toDouble();
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

          final theme = Theme.of(context);

          return CustomScrollView(
            slivers: [
              // --- DASHBOARD SECTION ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Pace Trend', 
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(height: 30),
                          
                          // THE LINE CHART
                          SizedBox(
                            height: 250,
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: 1.0,
                                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), 
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 45,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          _formatPace(value), 
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12)
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                minX: minX,
                                maxX: maxX,
                                lineBarsData: [
                                  _buildLineChartBarData(spots5k, Colors.blue),
                                  _buildLineChartBarData(spots10k, Colors.green),
                                  _buildLineChartBarData(spotsHalf, Colors.orange),
                                  _buildLineChartBarData(spotsFull, Colors.red),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // CUSTOM LEGEND
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLegendItem(Colors.blue, '5k'),
                              const SizedBox(width: 16),
                              _buildLegendItem(Colors.green, '10k'),
                              const SizedBox(width: 16),
                              _buildLegendItem(Colors.orange, 'Half'),
                              const SizedBox(width: 16),
                              _buildLegendItem(Colors.red, 'Full'),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // --- HISTORY LIST TITLE ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Text(
                    'Prediction Log', 
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                  ),
                ),
              ),

              // --- HISTORY LIST SECTION ---
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    
                    final distance = (data['target_distance_km'] as num).toDouble();
                    final time = data['predicted_time'] ?? '--:--:--';
                    final pace = _formatPace(_calculatePace(time, distance));
                    
                    String dateString = "Just now";
                    if (data['timestamp'] != null) {
                      DateTime date = (data['timestamp'] as Timestamp).toDate();
                      dateString = DateFormat('MMM d, yyyy').format(date); 
                    }

                    // Determine color based on distance
                    Color iconColor = Colors.grey;
                    if (distance == 5.0) iconColor = Colors.blue;
                    else if (distance == 10.0) iconColor = Colors.green;
                    else if (distance == 21.1) iconColor = Colors.orange;
                    else if (distance == 42.2) iconColor = Colors.red;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            width: 8,
                            height: 32,
                            decoration: BoxDecoration(
                              color: iconColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          title: Text(
                            "${distance}k Prediction", 
                            style: theme.textTheme.titleMedium,
                          ),
                          subtitle: Text("Time: $time  •  Pace: $pace", style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                          trailing: Text(
                            dateString, 
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade400),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: docs.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
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
      isCurved: false, // Smooth curves like the Garmin chart
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