import 'package:flutter/material.dart';
import 'package:coinspeech/screens/Home.dart';
import 'package:coinspeech/screens/Settings.dart';
import 'package:coinspeech/screens/About.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    SettingsPage(),
    // Ensure AboutPage exists if it's uncommented
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[150],
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              backgroundColor: isDark ? Colors.grey[900] : Colors.white,
              elevation: 0,
              selectedItemColor: Colors.redAccent,
              unselectedItemColor: Colors.grey,
              showUnselectedLabels: true,
              onTap: (index) => setState(() => _currentIndex = index),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: "Settings",
                ),
                BottomNavigationBarItem(icon: Icon(Icons.info), label: "About"),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
