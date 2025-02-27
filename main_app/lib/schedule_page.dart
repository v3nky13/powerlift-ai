import 'package:flutter/material.dart';

class SchedulePage extends StatefulWidget {
  @override
  _SchedulePageState createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  int currentIndex = 0;
  final List<String> days = ['Monday', 'Tuesday', 'Thursday', 'Saturday'];
  final List<String> dates = ['Feb 24', 'Feb 25', 'Feb 27', 'Mar 1'];

  void navigateLeft() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
    }
  }

  void navigateRight() {
    if (currentIndex < days.length - 1) {
      setState(() {
        currentIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: WorkoutCard(
          day: days[currentIndex],
          date: dates[currentIndex],
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
  final String date;
  final VoidCallback onNavigateLeft;
  final VoidCallback onNavigateRight;
  final bool isFirst;
  final bool isLast;

  WorkoutCard({
    required this.day,
    required this.date,
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
                icon: Icon(Icons.arrow_left, color: isFirst ? Colors.grey : Colors.white),
                onPressed: isFirst ? null : onNavigateLeft,
              ),
              Column(
                children: [
                  Text(
                    day,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  Text(
                    date,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.arrow_right, color: isLast ? Colors.grey : Colors.white),
                onPressed: isLast ? null : onNavigateRight,
              ),
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) {
                return ExerciseBlock();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ExerciseBlock extends StatefulWidget {
  @override
  _ExerciseBlockState createState() => _ExerciseBlockState();
}

class _ExerciseBlockState extends State<ExerciseBlock> {
  bool isExpanded = false;
  int? selectedStatus;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black,
      child: Column(
        children: [
          ListTile(
            title: Text(
              'Exercise Name',
              style: TextStyle(color: Colors.white),
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text('Weight: 50kg', style: TextStyle(color: Colors.white)),
                  Text('Reps: 10', style: TextStyle(color: Colors.white)),
                  Text('Sets: 3', style: TextStyle(color: Colors.white)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Radio(
                        value: 1,
                        groupValue: selectedStatus,
                        onChanged: (val) {
                          setState(() {
                            selectedStatus = val as int?;
                          });
                        },
                      ),
                      Text('Optimal', style: TextStyle(color: Colors.white)),
                      Radio(
                        value: 2,
                        groupValue: selectedStatus,
                        onChanged: (val) {
                          setState(() {
                            selectedStatus = val as int?;
                          });
                        },
                      ),
                      Text('Fatigue', style: TextStyle(color: Colors.white)),
                      Radio(
                        value: 3,
                        groupValue: selectedStatus,
                        onChanged: (val) {
                          setState(() {
                            selectedStatus = val as int?;
                          });
                        },
                      ),
                      Text('No', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
