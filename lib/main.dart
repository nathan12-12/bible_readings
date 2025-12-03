import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'bible_plan.dart'; // Contains the dailyBibleReadings map

void main() {
  runApp(MaterialApp(
    theme: ThemeData.dark().copyWith(
      colorScheme: ColorScheme.dark(
        primary: Colors.grey[100]!,
        surface: Colors.grey[900]!,
      ),
    ),
    home: const MyApp(),
  ));
}

class DayReadingData {
  final DateTime date;
  final List<String> readings;

  DayReadingData({required this.date, required this.readings});
  
  String get formattedDate => DateFormat('MMMM d, yyyy').format(date);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const int _totalPages = 262144; // 2^18 days For "infinite" swiping
  
  // Base date for page 0 - far in the past (using UTC to avoid timezone issues)
  final DateTime _baseDate = DateTime.utc(1950, 1, 1);
  
  late DayReadingData _currentPageData;
  late PageController _pageController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // Simple: page index = days since base date
  DayReadingData _getPageData(int pageIndex) {
    final date = _baseDate.add(Duration(days: pageIndex));
    // Convert back to local time for display
    final localDate = DateTime(date.year, date.month, date.day);
    
    final dateKey = DateFormat.MMMd().format(localDate);
    final readings = dailyBibleReadings[dateKey] ??
        ['No readings found for ${DateFormat('MMMM d, yyyy').format(localDate)} using key "$dateKey".'];

    return DayReadingData(
      date: localDate,
      readings: readings,
    );
  }

  // Convert a date to its page index
  int _dateToPageIndex(DateTime date) {
    // Convert to UTC for consistent calculation
    final normalizedDate = DateTime.utc(date.year, date.month, date.day);
    final difference = normalizedDate.difference(_baseDate);
    return difference.inDays;
  }

  void _initializeData() {
    // Find today's page (use UTC for calculation)
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final initialPage = today.difference(_baseDate).inDays;
    
    _currentPageData = _getPageData(initialPage);
    _pageController = PageController(initialPage: initialPage);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _calendar() async {
    DateTime? _picked = await showDatePicker(
        context: context,
        initialDate: _currentPageData.date,
        firstDate: DateTime(1950),
        lastDate: DateTime(2200)
    );

    if (_picked != null) {
      // Simply convert the picked date to its page index
      final targetPage = _dateToPageIndex(_picked);

      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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

    final TextStyle chapterStyle = const TextStyle(
      fontSize: 29,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );

    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.grey[850],
          title: Text(
            ' Bible Companion',
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.calendar_today),
              color: Colors.white,
              onPressed: () {
                _calendar();
              },
            ),
          ],
          centerTitle: false,
        ),

        body: PageView.builder(
          controller: _pageController,
          itemCount: _totalPages,

          onPageChanged: (int newIndex) {
            setState(() {
              _currentPageData = _getPageData(newIndex);
            });
          },

          itemBuilder: (BuildContext context, int index) {
            final data = _getPageData(index);
            final readings = data.readings;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBar(
                    backgroundColor: Colors.grey[600],
                    title: Text(
                      _currentPageData.formattedDate,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    centerTitle: true,
                  ),
                  const SizedBox(height: 10),
                  for (int i = 0; i < readings.length; i++)
                  ... [
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: Text(readings[i], style: chapterStyle),
                    ),
                    const SizedBox(height: 20),
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