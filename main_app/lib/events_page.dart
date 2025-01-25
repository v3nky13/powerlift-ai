import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class EventsPage extends StatelessWidget {
  final TextEditingController _dobController = TextEditingController();
  final List<Map<String, String>> events = [
    {
      'date': '07 Feb - 09 Feb',
      'title': 'North India Senior, Sub Junior & Junior Equipped Powerlifting Championship 2024-25',
      'region': 'Zonal',
      'location': 'Bhiwani, Haryana',
    },
    {
      'date': '19 Feb - 23 Feb',
      'title': 'National Senior Classic Powerlifting Championship 2025',
      'region': 'National',
      'location': 'Phagwara, Punjab',
    },
    {
      'date': '20 May - 25 May',
      'title': 'National Sub Junior & Junior Classic Powerlifting Championship 2025',
      'region': 'National',
      'location': 'Maharashtra',
    },
    {
      'date': '19 Jun - 27 Jun',
      'title': 'National Sub Junior, Junior & Senior Equipped Powerlifting Championship 2025',
      'region': 'National',
      'location': 'Davanagere, Karnataka',
    },
    {
      'date': '01 Aug - 06 Aug',
      'title': 'National Masters Classic & Equipped Powerlifting Championship 2025',
      'region': 'National',
      'location': 'TBA',
    },
    {
      'date': '16 Dec - 19 Dec',
      'title': 'Federation Cup Equipped Powerlifting Championship 2025',
      'region': 'National',
      'location': 'TBA',
    },
  ];

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
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          readOnly: true,
                          controller: _dobController,
                          decoration: InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(),
                          ),
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (pickedDate != null && pickedDate != DateTime.now()) {
                              
                              _dobController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                             
                            }
                          },
                        ),
                        SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Expected Squat Weight',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Expected Benchpress Weight',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Expected Deadlift Weight',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            // Handle submission logic
                          },
                          child: Text('Set Goal'),
                        ),
                      ],
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
  final TextEditingController squatController = TextEditingController(text: '200');
  final TextEditingController benchController = TextEditingController(text: '150');
  final TextEditingController deadliftController = TextEditingController(text: '250');

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Region:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(event['region']!),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Location:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(event['location']!),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Predicted Rank:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('1'),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Predicted Squat Weight:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: squatController,
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          inputFormatters: [LengthLimitingTextInputFormatter(3),
                          FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Predicted Benchpress Weight:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: benchController,
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          inputFormatters: [LengthLimitingTextInputFormatter(3),
                          FilteringTextInputFormatter.digitsOnly]
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Predicted Deadlift Weight:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(
                        width:100,
                        child: TextField(
                          controller: deadliftController,
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          inputFormatters: [LengthLimitingTextInputFormatter(3),
                          FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Days to Event:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('$daysToEvent'),
                    ],
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      // Handle setting the goal
                    },
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
