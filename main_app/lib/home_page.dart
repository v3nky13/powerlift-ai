import 'package:flutter/material.dart';
import 'package:main_app/chat_app.dart';
import 'schedule_page.dart';
import 'events_page.dart';
import 'posture_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // List of pages for bottom navigation
  final List<Widget> _pages = [
    SchedulePage(),
    EventsPage(),
    PosturePage(),
    ChatApp(), // Chat page added between Posture and Profile
    ProfilePage(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getPageTitle(),
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
      ),
      body: _pages[_currentIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag),
            label: 'Goal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.accessibility),
            label: 'Posture',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Ask AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Schedule';
      case 1:
        return 'Goal';
      case 2:
        return 'Posture';
      case 3:
        return 'Ask AI';
      case 4:
        return 'Profile';
      default:
        return '';
    }
  }
}