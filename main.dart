import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bible_plan.dart';

void main() {
  runApp(MyApp());
}

class TodaysDate {
  final DateTime today = DateTime.now();
  // Used for the AppBar title ("January 1, 2025")
  String get formattedDate {
    return DateFormat('MMMM d, yyyy').format(today);
  }
  // Used as the key for the reading plan ('Jan 1')
  String get dateKey => DateFormat.MMMd().format(today);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TodaysDate todayObject = TodaysDate();
  List<String> readings = ['Loading...', 'Loading...', 'Loading...']; // Default values while loading

  @override
  void initState() {
    super.initState();
    loadReadings();
  }

  Future<void> loadReadings() async {
    // Get the key for today's reading
    final dateKey = todayObject.dateKey; 
    final newReadings = dailyBibleReadings[dateKey];
    // Check
    print('Generated Key: "$dateKey"');
    print('Map Lookup Result: ${newReadings != null ? "FOUND" : "NOT FOUND"}');
    
    // Get the SharedPreferences instance
    try {
      final prefs = await SharedPreferences.getInstance();
      print("Prefs loaded OK");
    } catch (e) {
      print("PREF ERROR: $e");
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('Prefs cleared!');

    // Try to read the saved reading list using the date key
    List<String>? savedReadings = prefs.getStringList(dateKey);

    if (savedReadings != null && savedReadings.length == 3) {
      print('Using saved readings');
      setState(() 
      { readings = savedReadings; });
    } else {
      print('Using map readings');
      final newReadings = dailyBibleReadings[dateKey];

      if (newReadings != null) {
        print('Saving and setting readings from map');
        await prefs.setStringList(dateKey, newReadings);
        setState(() {
          readings = newReadings;
        });
      } else {
        print('Map key NOT FOUND');
        setState(() {
          readings = ['No plan found', 'Check plan map', 'Have a great day!'];
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = const TextStyle(
      fontSize: 29,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
        
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.grey[850], // Dark Gray background
        appBar: AppBar(
          backgroundColor: Colors.grey[600],
          title: Text(
            todayObject.formattedDate,
            style: const TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text(readings[0], style: textStyle),
            ),
            const SizedBox(height: 100),
            Divider(color: Colors.white, thickness: 2),

            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text(readings[1], style: textStyle),
            ),
            const SizedBox(height: 100),
            Divider(color: Colors.white, thickness: 2),

            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text(readings[2], style: textStyle),
            ),
            const SizedBox(height: 100),
            Divider(color: Colors.white, thickness: 2),
          ],
        ),
      ),
    );
  }
}