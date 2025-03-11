import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:main_app/home_page.dart';
import 'config.dart';

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
    currentIndex = _getCurrentDayIndex();
    fetchWorkoutData();
  }

  int _getCurrentDayIndex() {
    String today = DateFormat('EEEE').format(DateTime.now());
    return days.indexOf(today);
  }

  Future<void> fetchWorkoutData() async {
    final String currentDay = days[currentIndex];
    final String apiUrl = '${backendUrl}workout?day=$currentDay';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          exercises = (data[currentDay] as List? ?? [])
              .map((e) => {
                    "name": e["name"].toString(),
                    "weight": e["weight"].toString(),
                    "reps": e["reps"].toString(),
                    "sets": e["sets"].toString(),
                  })
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load data");
      }
    } catch (e) {
      print("Error from fetchWorkoutData: $e");
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
                isToday: currentIndex == _getCurrentDayIndex(),
              ),
      ),
    );
  }
}

class WorkoutCard extends StatefulWidget {
  final String day;
  final bool isRestDay;
  final VoidCallback onNavigateLeft;
  final VoidCallback onNavigateRight;
  final bool isFirst;
  final bool isLast;
  final bool isToday;
  final List<Map<String, String>> exercises;

  WorkoutCard({
    required this.day,
    required this.isRestDay,
    required this.exercises,
    required this.onNavigateLeft,
    required this.onNavigateRight,
    required this.isFirst,
    required this.isLast,
    required this.isToday,
  });

  @override
  _WorkoutCardState createState() => _WorkoutCardState();
}

class _WorkoutCardState extends State<WorkoutCard> {
  Map<String, int?> exerciseStatus = {};
  bool isWorkoutCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkWorkoutCompletion();
    for (var exercise in widget.exercises) {
      exerciseStatus[exercise['name']!] = null; // Initially no status selected
    }
  }

  void _checkWorkoutCompletion() async {
    // API call to check if today's workout is already completed
    final response = await http.get(
      Uri.parse("${backendUrl}checkWorkout"),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        isWorkoutCompleted = data['completed'] ?? false;
      });
    }
  }

  void updateExerciseStatus(String exerciseName, int status) {
    setState(() {
      exerciseStatus[exerciseName] = status;
    });
  }

  bool _canCompleteWorkout() {
    return !exerciseStatus.values.contains(null); // Ensures all exercises have a status
  }

  Future<void> completeWorkout() async {
    if (!_canCompleteWorkout()) return;

    final String apiUrl = "${backendUrl}updateStatus";

    final List<Map<String, dynamic>> statusData = exerciseStatus.entries
        .map((entry) => {
              "exercise": entry.key,
              "status": entry.value ?? "Not Selected",
            })
        .toList();

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"day": widget.day, "statuses": statusData}),
      );

      if (response.statusCode == 200) {
        print("Workout status updated successfully!");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        print("Error updating workout status: ${response.body}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

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
                icon: Icon(Icons.arrow_left, color: widget.isFirst ? Colors.grey : Colors.black),
                onPressed: widget.isFirst ? null : widget.onNavigateLeft,
              ),
              Text(
                widget.day,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              IconButton(
                icon: Icon(Icons.arrow_right, color: widget.isLast ? Colors.grey : Colors.black),
                onPressed: widget.isLast ? null : widget.onNavigateRight,
              ),
            ],
          ),
          SizedBox(height: 20),
          if (widget.isRestDay)
            Center(
              child: Text(
                "Rest day",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: widget.exercises.length,
                itemBuilder: (context, index) {
                  return ExerciseBlock(
                    exercise: widget.exercises[index],
                    selectedStatus: exerciseStatus[widget.exercises[index]['name']!],
                    onStatusSelected: updateExerciseStatus,
                  );
                },
              ),
            ),
          SizedBox(height: 10),
          if (widget.isToday)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isWorkoutCompleted || !_canCompleteWorkout()
                  ? null
                  : completeWorkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isWorkoutCompleted || !_canCompleteWorkout() ? Colors.grey : Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: Text(isWorkoutCompleted ? "Workout Completed" : "Complete Today's Workout"),
              ),
            ),
        ],
      ),
    );
  }
}

class ExerciseBlock extends StatefulWidget {
  final Map<String, String> exercise;
  final int? selectedStatus;
  final Function(String, int) onStatusSelected;

  ExerciseBlock({
    required this.exercise,
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  @override
  _ExerciseBlockState createState() => _ExerciseBlockState();
}

class _ExerciseBlockState extends State<ExerciseBlock> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.exercise['name']!,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      setState(() {
                        isExpanded = !isExpanded;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          if (isExpanded)
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      _buildInfoRow("Sets", widget.exercise['sets']!),
                      _buildInfoRow("Reps", widget.exercise['reps']!),
                      _buildInfoRow("Weight", widget.exercise['weight']!),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _radioOption(1, "Optimal"),
                    _radioOption(2, "Fatigue"),
                  ],
                ),
                Center(child: _radioOption(3, "Not Completed")),
                SizedBox(height: 10),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),
          Text(
            value,
            style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _radioOption(int value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio(
          value: value,
          groupValue: widget.selectedStatus,
          onChanged: (val) {
            setState(() {
              widget.onStatusSelected(widget.exercise['name']!, val as int);
            });
          },
        ),
        Text(label, style: TextStyle(color: Colors.black)),
      ],
    );
  }
}