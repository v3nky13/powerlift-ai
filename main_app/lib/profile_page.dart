import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Map<String, dynamic>> _athleteData;

  @override
  void initState() {
    super.initState();
    _athleteData = _fetchAthleteStats();
  }

  Future<Map<String, dynamic>> _fetchAthleteStats() async {
    final url = Uri.parse('http://10.0.2.2:5001/get_user'); // Change URL as needed

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load athlete stats');
      }
    } catch (e) {
      throw Exception('Error: Unable to connect to server');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Opacity(
            opacity: 0.3,
            child: Image.asset(
              'assets/background.jpg',
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
            ),
          ),
          FutureBuilder<Map<String, dynamic>>(
            future: _athleteData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text("Error loading data"));
              } else if (!snapshot.hasData) {
                return Center(child: Text("No data available"));
              }

              final athlete = snapshot.data!;
              int age = DateTime.now().year - DateTime.parse(athlete['dob']).year;
              if (DateTime.now().month < DateTime.parse(athlete['dob']).month ||
                  (DateTime.now().month == DateTime.parse(athlete['dob']).month &&
                      DateTime.now().day < DateTime.parse(athlete['dob']).day)) {
                age--;
              }

              return SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      // Athlete Stats Card
                      Card(
                        color: Colors.grey[100],
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Athlete Stats',
                                      style: TextStyle(
                                          fontSize: 20, fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: Icon(Icons.refresh, size: 24),
                                    onPressed: () {
                                      setState(() {
                                        _athleteData = _fetchAthleteStats();
                                      });
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              buildStatRow('Name:', athlete['name']),
                              buildStatRow('Age:', '$age'),
                              buildStatRow('Body Weight:', '${athlete['weight']} kg'),
                              buildStatRow('Squat PR:', '${athlete['squatPR']} kg'),
                              buildStatRow('Bench PR:', '${athlete['benchPR']} kg'),
                              buildStatRow('Deadlift PR:', '${athlete['deadliftPR']} kg'),
                              buildStatRow('Experience Level:', athlete['experienceLevel']),
                              buildStatRow('Equipment:', athlete['equipment']),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 8),

                      // Performance Indicators Card
                      Card(
                        color: Colors.grey[100],
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Performance',
                                      style: TextStyle(
                                          fontSize: 20, fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: Icon(Icons.info_outline, size: 30),
                                    onPressed: () {
                                      _showInfoDialog(context);
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              PerformanceIndicatorRow(label: 'Overall', score: athlete['overallScore']),
                              PerformanceIndicatorRow(label: 'Squat', score: athlete['squatScore']),
                              PerformanceIndicatorRow(label: 'Bench Press', score: athlete['benchScore']),
                              PerformanceIndicatorRow(label: 'Deadlift', score: athlete['deadliftScore']),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Performance Indicators Info'),
          content: Text(
            'Performance indicators represent the strength or skill level in various '
            'powerlifting movements. A higher score indicates better performance.',
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

class PerformanceIndicatorRow extends StatelessWidget {
  final String label;
  final int score;

  const PerformanceIndicatorRow({
    required this.label,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Row(
            children: [
              SizedBox(
                width: 80,
                height: 40,
                child: CustomPaint(
                  painter: SemiCircleProgressPainter(score),
                ),
              ),
              SizedBox(width: 8),
              Text('$score / 100', style: TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}

class SemiCircleProgressPainter extends CustomPainter {
  final int score;

  SemiCircleProgressPainter(this.score);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;

    final Paint foregroundPaint = Paint()
      ..color = Colors.grey[700]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height);
    final radius = size.height - 8;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), pi, pi, false, backgroundPaint);
    double sweepAngle = (pi * score) / 100;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), pi, sweepAngle, false, foregroundPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
