import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'config.dart';

class EventsPage extends StatefulWidget {
  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  DateTime? _selectedDate;
  bool _isLoading = false;
  
  final TextEditingController squatController = TextEditingController();
  final TextEditingController benchController = TextEditingController();
  final TextEditingController deadliftController = TextEditingController();

  final List<Map<String, String>> events = [
    {
      'id': '1',
      'date': '07 Feb - 09 Feb',
      'title': 'North India Sub Junior & Junior Equipped Powerlifting Championship 2024-25',
      'region': 'Zonal',
      'location': 'Bhiwani, Haryana',
    },
    {
      'id': '2',
      'date': '20 May - 25 May',
      'title': 'National Sub Junior & Junior Classic Powerlifting Championship 2025',
      'region': 'National',
      'location': 'Maharashtra',
    },
    {
      'id': '3',
      'date': '19 Jun - 27 Jun',
      'title': 'National Sub Junior & Junior Equipped Powerlifting Championship 2025',
      'region': 'National',
      'location': 'Davanagere, Karnataka',
    },
    {
      'id': '4',
      'date': '01 Aug - 06 Aug',
      'title': 'National Masters Classic & Equipped Powerlifting Championship 2025',
      'region': 'National',
      'location': 'TBA',
    },
    {
      'id': '5',
      'date': '16 Dec - 19 Dec',
      'title': 'Federation Cup Equipped Powerlifting Championship 2025',
      'region': 'National',
      'location': 'TBA',
    },
  ];

  Future<void> _pickDate(BuildContext context) async {
    DateTime now = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now, // Prevents selecting past dates
      lastDate: DateTime(2026),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _setCustomGoal() async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('${backendUrl}set_goal');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'goal_date': _selectedDate?.toIso8601String(),
        'goal_squat_weight': squatController.text,
        'goal_bench_weight': benchController.text,
        'goal_deadlift_weight': deadliftController.text,
      }),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Custom goal set successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set custom goal. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: 'Competition'),
                Tab(text: 'Custom'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Competition Tab
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return EventCard(event: event);
                      },
                    ),
                  ),

                  // Custom Tab
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Select Goal Date:'),
                          SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _pickDate(context),
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _selectedDate == null
                                    ? 'Tap to select a date'
                                    : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: squatController,
                            decoration: InputDecoration(labelText: 'Set Squat Weight'),
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: benchController,
                            decoration: InputDecoration(labelText: 'Set Benchpress Weight'),
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: deadliftController,
                            decoration: InputDecoration(labelText: 'Set Deadlift Weight'),
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(height: 16),
                          _isLoading
                              ? Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: _setCustomGoal,
                                  child: Text('Set Custom Goal'),
                                ),
                          SizedBox(height: 100), // Adds extra space to prevent keyboard overflow
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EventCard extends StatefulWidget {
  final Map<String, String> event;

  EventCard({required this.event});

  @override
  _EventCardState createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _isExpanded = false;
  bool _isLoading = false;
  String? _rankScore;
  final TextEditingController squatController = TextEditingController();
  final TextEditingController benchController = TextEditingController();
  final TextEditingController deadliftController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRankScore();
  }

  Future<void> _fetchRankScore() async {
    final url = Uri.parse('${backendUrl}get_rank_score');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'event_id': widget.event['id'],
        'event_date': widget.event['date']!.split(' - ')[0],
        'squat_weight': '200', // Default value
        'bench_weight': '150', // Default value
        'deadlift_weight': '250', // Default value
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _rankScore = data['rank_score'];
        squatController.text = data['default_squat_weight'];
        benchController.text = data['default_bench_weight'];
        deadliftController.text = data['default_deadlift_weight'];
      });
    } else {
      setState(() {
        _rankScore = 'N/A';
      });
    }
  }

  Future<void> _setGoal() async {
    setState(() {
      _isLoading = true; // Show loading spinner
    });

    final url = Uri.parse('${backendUrl}set_goal');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'goal_date': widget.event['date']!.split(' - ')[0],
        'goal_squat_weight': squatController.text,
        'goal_bench_weight': benchController.text,
        'goal_deadlift_weight': deadliftController.text,
      }),
    );

    setState(() {
      _isLoading = false; // Hide loading spinner
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Goal set successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set goal. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final now = DateTime.now();
    final eventDate = DateFormat('dd MMM yyyy').parse('${event['date']!.split(' - ')[0]} ${now.year}');
    final daysToEvent = eventDate.difference(now).inDays;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          ListTile(
            title: Text(
              event['title']!,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(event['date']!),
            trailing: IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Region: ${event['region']}'),
                  SizedBox(height: 8),
                  Text('Location: ${event['location']}'),
                  SizedBox(height: 8),
                  Text('Days to Event: ${daysToEvent < 0 ? 'Past' : daysToEvent}'),
                  SizedBox(height: 8),
                  Text('Predicted Rank: ${_rankScore ?? 'Loading...'}'),
                  SizedBox(height: 16),
                  TextField(
                    controller: squatController,
                    decoration: InputDecoration(labelText: 'Set Squat Weight'),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: benchController,
                    decoration: InputDecoration(labelText: 'Set Benchpress Weight'),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: deadliftController,
                    decoration: InputDecoration(labelText: 'Set Deadlift Weight'),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),
                  _isLoading
                      ? Center(child: CircularProgressIndicator()) // Show spinner when loading
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: daysToEvent < 0 ? null : _setGoal,
                          child: Text('Set Goal'),
                        ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}