import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'bible_plan.dart'; // Contains the dailyBibleReadings map

void main() {
  runApp(MyApp());
}

class TodaysDate {
  // Use a final DateTime as the source of truth
  final DateTime date; 
  
  // Constructor: takes the initial start date (Jan 1) and adds an offset (when)
  TodaysDate({required DateTime startDate, required int offset}) 
    : date = startDate.add(Duration(days: offset));

  // Used for the AppBar title ("December 2, 2025")
  String get formattedDate {
    return DateFormat('MMMM d, yyyy').format(date);
  }
  
  // Used as the key for the reading plan ('Dec 2')
  String get dateKey => DateFormat.MMMd().format(date);
}

class DayReadingData {
  final DateTime date;
  final List<String> readings;

  DayReadingData({required this.date, required this.readings});
  
  // Helper to format the date for the AppBar (used by the onPageChanged callback)
  String get formattedDate => DateFormat('MMMM d, yyyy').format(date);
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const int _totalPages = 65536; // 2^16 days for "infinite" swiping
  // A fixed start date for the plan (Jan 1 of the current year)
  late final DateTime _planStartDate;
  
  // The index corresponding to today's date in the _yearReadings list
  late int _initialPageIndex;
  // The DayReadingData object for the currently displayed page (used for AppBar)
  late DayReadingData _currentPageData;

  // PageController manages the PageView position
  late PageController _pageController; 
  
  // Flag to manage the loading state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }
  
  // To dynamically calculate data for any page index
  DayReadingData _getPageData(int index) {
    // Calculate the actual DateTime: Add the index offset to a distant starting point.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // Accounting midnight
    final todayOffset = (_totalPages ~/ 2) + today.difference(DateTime(today.year, 1, 1)).inDays;
    final date = today.add(Duration(days: index - todayOffset));

    // Formate date
    final dateKey = DateFormat.MMMd().format(date);
    
    // Get the reading from the 366-day map
    final readings = dailyBibleReadings[dateKey] ?? 
        ['No readings found for ${DateFormat('MMMM d, yyyy').format(date)} using key "$dateKey".'];

    return DayReadingData(
      date: date,
      readings: readings,
    );
  }

  // Pre-calculate all data and find the initial position
  void _initializeData() {
    // Determine the start of the current year
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // Accounting midnight
    _planStartDate = DateTime(today.year, 1, 1); // Current date as the baseline
    
    // The offset of 'today' from Jan 1 of the current year
    final todayOffset = today.difference(_planStartDate).inDays;
    
    // Set the initial page index to be in the middle of the large range.
    // This allows swiping backward and forward.
    _initialPageIndex = (_totalPages ~/ 2) + todayOffset;

     // Get the data for the initial page
    _currentPageData = _getPageData(_initialPageIndex);
    
    _pageController = PageController(initialPage: _initialPageIndex);

    setState(() {
      _isLoading = false;
    });
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    
    final TextStyle textStyle = const TextStyle(
      fontSize: 29,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
        
    return MaterialApp(
      home: Scaffold( 
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.grey[600],
          title: Text(
            // Use the data of the currently visible page for the title
            _currentPageData.formattedDate, 
            style: const TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        
        // Use PageView for smooth horizontal swiping
        body: PageView.builder(
          controller: _pageController,
          itemCount: _totalPages, // The count is the very large number
          
          // Update the AppBar title when a page transition is complete
          onPageChanged: (int newIndex) {
            setState(() {
              // Dynamically fetch the data for the new index
              _currentPageData = _getPageData(newIndex);
            });
          },

          // Builder now uses the _getPageData method
          itemBuilder: (BuildContext context, int index) {
            final data = _getPageData(index);
            final readings = data.readings;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  for (int i = 0; i < readings.length; i++)
                  ... [
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: Text(readings[i], style: textStyle),
                    ),
                    const SizedBox(height: 50),
                    Divider(color: Colors.grey[850], thickness: 2),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}