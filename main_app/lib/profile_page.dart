import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'login_page.dart';

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
    final url = Uri.parse('http://10.0.2.2:5001/get_user');

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

  Future<void> _logout(BuildContext context) async {
    final url = Uri.parse('http://10.0.2.2:5001/logout');

    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Unable to connect to server')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
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
          int age = _calculateAge(athlete['dob']);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      buildAthleteStatsCard(athlete, age),
                      SizedBox(height: 8),
                      buildPerformanceCard(athlete),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _logout(context),
        backgroundColor: Colors.black,
        child: Icon(Icons.logout, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  int _calculateAge(String dob) {
    DateTime birthDate = DateTime.parse(dob);
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;

    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Widget buildAthleteStatsCard(Map<String, dynamic> athlete, int age) {
    return Card(
      color: Colors.grey[100],
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildHeader('Athlete Stats'),
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
    );
  }

  Widget buildPerformanceCard(Map<String, dynamic> athlete) {
    return Card(
      color: Colors.grey[100],
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildHeader('Performance'),
            PerformanceIndicatorRow(label: 'Overall', score: athlete['overallScore'] ?? 0),
            PerformanceIndicatorRow(label: 'Squat', score: athlete['squatScore'] ?? 0),
            PerformanceIndicatorRow(label: 'Bench Press', score: athlete['benchScore'] ?? 0),
            PerformanceIndicatorRow(label: 'Deadlift', score: athlete['deadliftScore'] ?? 0),
          ],
        ),
      ),
    );
  }

  Widget buildHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        IconButton(
          icon: Icon(Icons.refresh, size: 24),
          onPressed: () {
            setState(() {
              _athleteData = _fetchAthleteStats();
            });
          },
        ),
      ],
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
