import 'package:flutter/material.dart';
import 'dart:math';

class ProfilePage extends StatelessWidget {
  final String name = "John Doe";
  final DateTime dob = DateTime(1990, 5, 15);
  final double bodyWeight = 85.0;
  final double squatPR = 200.0;
  final double benchPR = 120.0;
  final double deadliftPR = 220.0;
  final String experienceLevel = "Intermediate";
  final String equipment = "Equipped";

  @override
  Widget build(BuildContext context) {
    // Calculate age from date of birth
    int age = DateTime.now().year - dob.year;
    if (DateTime.now().month < dob.month ||
        (DateTime.now().month == dob.month && DateTime.now().day < dob.day)) {
      age--;
    }

    // Example scores
    final int overallScore = 85;
    final int squatScore = 90;
    final int benchScore = 75;
    final int deadliftScore = 95;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image with reduced opacity
          Opacity(
            opacity: 0.3, // Set the opacity to 0.3 for reduced visibility
            child: Image.asset(
              'assets/background.jpg', // Update with your image path
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
            ),
          ),
          SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(8.0), // Reduced padding around content
              child: Column(
                children: [
                  // First Card: Athlete Stats
                  Card(
                    color: Colors.grey[100],
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0), // Reduced padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Athlete Stats',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, size: 24),
                                onPressed: () {
                                  // Implement the edit functionality here
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          buildStatRow('Name:', name),
                          buildStatRow('Age:', '$age'),
                          buildStatRow('Body Weight:', '$bodyWeight kg'),
                          buildStatRow('Squat PR:', '$squatPR kg'),
                          buildStatRow('Bench PR:', '$benchPR kg'),
                          buildStatRow('Deadlift PR:', '$deadliftPR kg'),
                          buildStatRow('Experience Level:', experienceLevel),
                          buildStatRow('Equipment:', equipment),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 8), // Reduced space between cards
                  // Second Card: Performance Indicators
                  Card(
                    color: Colors.grey[100],
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0), // Reduced padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Performance',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(Icons.info_outline, size: 30),
                                ),
                                onPressed: () {
                                  // Show the info dialog when pressed
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Performance Indicators Info'),
                                        content: Text(
                                          'Performance indicators represent the strength or skill level in various '
                                          'powerlifting movements. These scores are based on personal best lifts '
                                          'and other relevant factors. A higher score indicates better performance. '
                                          'Scores are calculated based on recent performance compared to ideal standards.',
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
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          PerformanceIndicatorRow(label: 'Overall', score: overallScore),
                          PerformanceIndicatorRow(label: 'Squat', score: squatScore),
                          PerformanceIndicatorRow(label: 'Bench Press', score: benchScore),
                          PerformanceIndicatorRow(label: 'Deadlift', score: deadliftScore),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
          Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
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
              Text(
                '$score / 100',
                style: TextStyle(fontSize: 16),
              ),
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

    // Draw the background arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      backgroundPaint,
    );

    // Draw the foreground arc based on the score
    double sweepAngle = (pi * score) / 100;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      sweepAngle,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
