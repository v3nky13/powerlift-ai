import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MaterialApp(
    home: SchedulePage(),
    debugShowCheckedModeBanner: false,
  ));
}

class SchedulePage extends StatefulWidget {
  @override
  _SchedulePageState createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  int currentIndex = 0;
  final List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final Set<String> restDays = {'Wednesday', 'Friday', 'Sunday'};
  List<Map<String, String>> exercises = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWorkoutData();
  }

  Future<void> fetchWorkoutData() async {
    final String currentDay = days[currentIndex];
    final String apiUrl = 'https://your-backend.com/api/workout?day=$currentDay'; // Replace with actual backend URL

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          exercises = List<Map<String, String>>.from(data['exercises']);
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load data");
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void navigateLeft() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        isLoading = true;
      });
      fetchWorkoutData();
    }
  }

  void navigateRight() {
    if (currentIndex < days.length - 1) {
      setState(() {
        currentIndex++;
        isLoading = true;
      });
      fetchWorkoutData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : WorkoutCard(
                day: days[currentIndex],
                isRestDay: restDays.contains(days[currentIndex]),
                exercises: exercises,
                onNavigateLeft: navigateLeft,
                onNavigateRight: navigateRight,
                isFirst: currentIndex == 0,
                isLast: currentIndex == days.length - 1,
              ),
      ),
    );
  }
}

class WorkoutCard extends StatelessWidget {
  final String day;
  final bool isRestDay;
  final VoidCallback onNavigateLeft;
  final VoidCallback onNavigateRight;
  final bool isFirst;
  final bool isLast;
  final List<Map<String, String>> exercises;

  WorkoutCard({
    required this.day,
    required this.isRestDay,
    required this.exercises,
    required this.onNavigateLeft,
    required this.onNavigateRight,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_left, color: isFirst ? Colors.grey : Colors.black),
                onPressed: isFirst ? null : onNavigateLeft,
              ),
              Text(
                day,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              IconButton(
                icon: Icon(Icons.arrow_right, color: isLast ? Colors.grey : Colors.black),
                onPressed: isLast ? null : onNavigateRight,
              ),
            ],
          ),
          SizedBox(height: 20),
          if (isRestDay)
            Center(
              child: Text(
                "Rest day",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  return ExerciseBlock(
                    exercise: exercises[index],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class ExerciseBlock extends StatefulWidget {
  final Map<String, String> exercise;

  ExerciseBlock({required this.exercise});

  @override
  _ExerciseBlockState createState() => _ExerciseBlockState();
}

class _ExerciseBlockState extends State<ExerciseBlock> {
  bool isExpanded = false;
  int? selectedStatus;

  Future<void> sendStatusToBackend(int status) async {
    final String apiUrl = "https://your-backend.com/api/updateStatus"; // Replace with actual API

    final Map<String, dynamic> data = {
      "exercise": widget.exercise['name'],
      "status": status,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(data),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to update status");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(
              widget.exercise['name']!,
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: IconButton(
              icon: Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
            ),
          ),
          if (isExpanded)
            Column(
              children: [
                Text("Weight: ${widget.exercise['weight']}", style: TextStyle(color: Colors.white)),
                Text("Reps: ${widget.exercise['reps']}", style: TextStyle(color: Colors.white)),
                Text("Sets: ${widget.exercise['sets']}", style: TextStyle(color: Colors.white)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Radio(
                      value: 1,
                      groupValue: selectedStatus,
                      onChanged: (val) {
                        setState(() => selectedStatus = val as int?);
                        sendStatusToBackend(val as int);
                      },
                    ),
                    Text('Optimal', style: TextStyle(color: Colors.white)),
                    Radio(
                      value: 2,
                      groupValue: selectedStatus,
                      onChanged: (val) {
                        setState(() => selectedStatus = val as int?);
                        sendStatusToBackend(val as int);
                      },
                    ),
                    Text('Fatigue', style: TextStyle(color: Colors.white)),
                    Radio(
                      value: 3,
                      groupValue: selectedStatus,
                      onChanged: (val) {
                        setState(() => selectedStatus = val as int?);
                        sendStatusToBackend(val as int);
                      },
                    ),
                    Text('No', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}