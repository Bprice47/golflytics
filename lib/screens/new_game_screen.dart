// lib/screens/new_game_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';
import '../models/round.dart';

class ParInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    if ("3456".contains(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}

class HoleData {
  String par = '';
  String strokes = '';
  String putts = '';
  String fir = 'N/A';
  String gir = 'N/A';
}

class NewGameScreen extends StatefulWidget {
  final bool resumeRound;
  final SavedCourse? savedCourse;

  const NewGameScreen({super.key, this.resumeRound = false, this.savedCourse});

  @override
  State<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends State<NewGameScreen> {
  int _selectedIndex = 0;

  final List<HoleData> _roundData = List.generate(18, (_) => HoleData());
  int _currentHoleIndex = 0;
  String _courseName = '';

  @override
  void initState() {
    super.initState();
    if (widget.resumeRound) {
      _loadSavedRound();
    } else if (widget.savedCourse != null) {
      _loadSavedCourse();
    }
  }

  Future<void> _loadSavedRound() async {
    final savedRound = await StorageService.getCurrentRound();
    if (savedRound != null) {
      setState(() {
        _roundData.clear();
        _roundData.addAll(savedRound['roundData'] as List<HoleData>);
        _courseName = savedRound['courseName'] as String;
        _currentHoleIndex = savedRound['currentHoleIndex'] as int;
      });
    }
  }

  void _loadSavedCourse() {
    if (widget.savedCourse != null) {
      setState(() {
        _courseName = widget.savedCourse!.name;
        // Pre-populate pars for all 18 holes
        for (int i = 0; i < 18; i++) {
          if (i < widget.savedCourse!.pars.length) {
            _roundData[i].par = widget.savedCourse!.pars[i].toString();
          }
        }
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _updateCourseName(String name) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _courseName = name;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screenViews = <Widget>[
      GameEntryView(
        roundData: _roundData,
        currentHoleIndex: _currentHoleIndex,
        courseName: _courseName, // NEW: Pass current course name
        isSavedCourse:
            widget.savedCourse != null, // NEW: Pass saved course flag
        onHoleChanged: (newIndex) {
          setState(() {
            _currentHoleIndex = newIndex;
          });
        },
        onCourseNameChanged: _updateCourseName,
        onNavigateToStats: () {
          // NEW: Navigate to stats tab when user saves round
          setState(() {
            _selectedIndex = 2; // Stats tab
          });
        },
      ),
      ScorecardView(roundData: _roundData, courseName: _courseName),
      StatsView(roundData: _roundData, courseName: _courseName),
      const CalendarView(), // Restored Calendar tab
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Golflytics',
              style: TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              () {
                final now = DateTime.now();
                final month = now.month.toString().padLeft(2, '0');
                final day = now.day.toString().padLeft(2, '0');
                final year = now.year.toString();
                return '$month-$day-$year';
              }(),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const CircleAvatar(
              backgroundColor: Colors.white,
              foregroundColor: Colors.green,
              child: Text('BP', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // Banner Ad at top
          Container(
            height: 50,
            width: double.infinity,
            color: Colors.grey[300],
            child: const Center(child: Text('Banner Ad Placeholder')),
          ),
          Expanded(child: screenViews.elementAt(_selectedIndex)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.green[700],
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.edit_note), label: 'Entry'),
          BottomNavigationBarItem(
            icon: Icon(Icons.scoreboard),
            label: 'Scorecard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        onTap: _onItemTapped,
      ),
    );
  }
}

// --- ROUND ENTRY VIEW ---
class GameEntryView extends StatefulWidget {
  final List<HoleData> roundData;
  final int currentHoleIndex;
  final ValueChanged<int> onHoleChanged;
  final ValueChanged<String>? onCourseNameChanged;
  final String courseName; // NEW: Current course name
  final VoidCallback? onNavigateToStats; // NEW: Callback to navigate to stats
  final bool isSavedCourse; // NEW: Flag to indicate if using saved course

  const GameEntryView({
    super.key,
    required this.roundData,
    required this.currentHoleIndex,
    required this.onHoleChanged,
    this.onCourseNameChanged,
    this.courseName = '', // NEW: Default empty string
    this.onNavigateToStats, // NEW: Optional callback
    this.isSavedCourse = false, // NEW: Default to false
  });

  @override
  State<GameEntryView> createState() => _GameEntryViewState();
}

class _GameEntryViewState extends State<GameEntryView> {
  late TextEditingController _courseNameController;
  late TextEditingController _parController;
  late TextEditingController _strokesController;
  late TextEditingController _puttsController;

  late FocusNode _courseNameFocusNode; // NEW: Focus node for course name
  late FocusNode _parFocusNode;
  late FocusNode _strokesFocusNode;
  late FocusNode _puttsFocusNode;
  Timer? _debounce;

  String firValue = 'N/A';
  String girValue = 'N/A';

  // Track pan gesture for better swipe detection on hole navigation
  double _dragStartX = 0.0;
  bool _isDragging = false;

  void _handlePanStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _isDragging = true;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    // Optional: Add visual feedback during drag if needed
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!_isDragging) return;

    final double dragDistance = details.globalPosition.dx - _dragStartX;
    const double minSwipeDistance = 30.0; // Minimum distance for a swipe
    const double maxVelocity = 2000.0; // Maximum velocity to consider

    // Check if this is a valid swipe gesture
    bool isValidSwipe = false;
    bool swipeRight = false;

    // Method 1: Check drag distance
    if (dragDistance.abs() > minSwipeDistance) {
      isValidSwipe = true;
      swipeRight = dragDistance > 0;
    }
    // Method 2: Check velocity (for quick swipes)
    else if (details.primaryVelocity != null &&
        details.primaryVelocity!.abs() > 150 &&
        details.primaryVelocity!.abs() < maxVelocity) {
      isValidSwipe = true;
      swipeRight = details.primaryVelocity! > 0;
    }

    if (isValidSwipe) {
      if (swipeRight && widget.currentHoleIndex > 0) {
        // Swiped right - go to previous hole
        _previousHole();
      } else if (!swipeRight && widget.currentHoleIndex < 17) {
        // Swiped left - go to next hole
        _nextHole();
      }
    }

    _isDragging = false;
  }

  @override
  void initState() {
    super.initState();
    _courseNameController = TextEditingController();
    _parController = TextEditingController();
    _strokesController = TextEditingController();
    _puttsController = TextEditingController();

    _courseNameFocusNode =
        FocusNode(); // NEW: Initialize course name focus node
    _parFocusNode = FocusNode();
    _strokesFocusNode = FocusNode();
    _puttsFocusNode = FocusNode();

    _loadHoleData(widget.currentHoleIndex);

    // NEW: Set up course name listener to persist changes
    _courseNameController.addListener(() {
      if (widget.onCourseNameChanged != null) {
        widget.onCourseNameChanged!(_courseNameController.text);
      }
      // Auto-save when course name changes
      _autoSaveCurrentRound();
    });
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _parController.dispose();
    _strokesController.dispose();
    _puttsController.dispose();

    _courseNameFocusNode.dispose(); // NEW: Dispose course name focus node
    _parFocusNode.dispose();
    _strokesFocusNode.dispose();
    _puttsFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GameEntryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentHoleIndex != oldWidget.currentHoleIndex) {
      _loadHoleData(widget.currentHoleIndex);
    }
  }

  void _saveCurrentHoleData() {
    final currentData = widget.roundData[widget.currentHoleIndex];
    currentData.par = _parController.text;
    currentData.strokes = _strokesController.text;
    currentData.putts = _puttsController.text;
    currentData.fir = firValue;
    currentData.gir = girValue;

    // Auto-save current round progress
    _autoSaveCurrentRound();
  }

  Future<void> _autoSaveCurrentRound() async {
    await StorageService.saveCurrentRound(
      widget.roundData,
      widget.courseName,
      widget.currentHoleIndex,
    );
  }

  void _loadHoleData(int holeIndex) {
    final holeData = widget.roundData[holeIndex];
    _parController.text = holeData.par;
    _strokesController.text = holeData.strokes;
    _puttsController.text = holeData.putts;

    // NEW: Preserve course name when navigating between holes
    if (widget.courseName.isNotEmpty && _courseNameController.text.isEmpty) {
      _courseNameController.text = widget.courseName;
    }

    setState(() {
      firValue = holeData.fir;
      girValue = holeData.gir;
    });

    // NEW: Auto-focus appropriate field after loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _setAutoFocus();
      });
    });
  }

  // NEW: Auto-focus logic based on course type and hole data
  void _setAutoFocus() {
    // For new courses on hole 1 with empty course name, focus on course name
    if (!widget.isSavedCourse &&
        widget.currentHoleIndex == 0 &&
        widget.courseName.isEmpty) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _courseNameFocusNode.requestFocus();
      });
      return;
    }

    // If it's a saved course (pars are pre-filled), focus on strokes
    if (widget.isSavedCourse && _parController.text.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _strokesFocusNode.requestFocus();
      });
    }
    // If it's a new course and par is empty, focus on par
    else if (_parController.text.isEmpty) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _parFocusNode.requestFocus();
      });
    }
    // If par is filled but strokes is empty, focus on strokes
    else if (_strokesController.text.isEmpty) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _strokesFocusNode.requestFocus();
      });
    }
  }

  void _nextHole() {
    if (widget.currentHoleIndex < 17) {
      _saveCurrentHoleData();
      widget.onHoleChanged(widget.currentHoleIndex + 1);
    } else if (widget.currentHoleIndex == 17) {
      // On hole 18, show save round option
      _saveCurrentHoleData();
      _showRoundCompleteDialog();
    }
  }

  // NEW: Show dialog when round is complete
  void _showRoundCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber[600], size: 28),
              const SizedBox(width: 8),
              const Text(
                'Round Complete!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Congratulations on finishing your round!',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.save, color: Colors.green[600], size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Save this round to track your progress and build your golf history',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'Not Now',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await _saveRoundFromEntry();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save Round'),
            ),
          ],
        );
      },
    );
  }

  // NEW: Save round from entry screen
  Future<void> _saveRoundFromEntry() async {
    try {
      final savedRound = StorageService.convertToSavedRound(
        widget.roundData,
        _courseNameController.text.isEmpty
            ? 'Unnamed Course'
            : _courseNameController.text,
      );

      final success = await StorageService.saveRound(savedRound);

      // Clear the current round in progress since it's now completed
      if (success) {
        await StorageService.clearCurrentRound();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: success
                ? const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Round Saved Successfully!',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Check out your stats in the Stats tab',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const Row(
                    children: [
                      Icon(Icons.error, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'Failed to save round',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
            backgroundColor: success ? Colors.green[600] : Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 5),
            action: success
                ? SnackBarAction(
                    label: 'View Stats',
                    textColor: Colors.white,
                    backgroundColor: Colors.green[800],
                    onPressed: () {
                      _navigateToStats();
                    },
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error saving round'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // NEW: Navigate to stats (we'll need to add this callback)
  void _navigateToStats() {
    if (widget.onNavigateToStats != null) {
      widget.onNavigateToStats!();
    }
  }

  void _previousHole() {
    if (widget.currentHoleIndex > 0) {
      _saveCurrentHoleData();
      widget.onHoleChanged(widget.currentHoleIndex - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      behavior: HitTestBehavior.translucent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        // NEW: Alternating background colors by hole
        color: (widget.currentHoleIndex % 2 == 0)
            ? Colors.white
            : Colors.grey[200],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _courseNameController,
                  focusNode: _courseNameFocusNode, // NEW: Add focus node
                  textAlign: TextAlign.center,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Enter Course Name',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  onChanged: (value) {
                    widget.onCourseNameChanged?.call(value);
                  },
                  onSubmitted: (_) {
                    // NEW: When course name is entered, move to par field or dismiss
                    if (!widget.isSavedCourse) {
                      _parFocusNode.requestFocus();
                    } else {
                      FocusScope.of(context).unfocus();
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Centered hole navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (widget.currentHoleIndex > 0)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: _previousHole,
                      )
                    else
                      const SizedBox(width: 48),
                    Text(
                      'Hole ${widget.currentHoleIndex + 1}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.currentHoleIndex < 17)
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios),
                        onPressed: _nextHole,
                      )
                    else
                      // NEW: Show "Finish Round" button on hole 18
                      ElevatedButton.icon(
                        onPressed: _nextHole,
                        icon: const Icon(Icons.flag, color: Colors.white),
                        label: const Text(
                          'Finish',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                // Centered input section
                Column(
                  children: [
                    _buildInputRow(
                      label: 'Par',
                      controller: _parController,
                      focusNode: _parFocusNode,
                    ),
                    _buildInputRow(
                      label: 'Strokes',
                      controller: _strokesController,
                      focusNode: _strokesFocusNode,
                    ),
                    _buildInputRow(
                      label: 'Putts',
                      controller: _puttsController,
                      focusNode: _puttsFocusNode,
                    ),
                    const SizedBox(height: 16),
                    _buildSegmentedControl(
                      'FIR',
                      ['Yes', 'N/A', 'No'],
                      firValue,
                      (newValue) {
                        setState(() => firValue = newValue!);
                        _autoSaveCurrentRound(); // Auto-save when FIR changes
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildSegmentedControl(
                      'GIR',
                      ['Yes', 'N/A', 'No'],
                      girValue,
                      (newValue) {
                        setState(() => girValue = newValue!);
                        _autoSaveCurrentRound(); // Auto-save when GIR changes
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- THIS IS THE SIMPLIFIED AND CORRECTED INDICATOR LOGIC ---
  Widget _buildInputRow({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: SizedBox(
        height: 48,
        child: Stack(
          children: [
            // Position input box at exact center
            Center(
              child: SizedBox(
                width: 60,
                height: 48,
                child: (label == 'Strokes')
                    ? _buildStrokesInput()
                    : _buildRegularInput(controller, focusNode, label),
              ),
            ),
            // Position label to the left with proper spacing
            Positioned(
              right: MediaQuery.of(context).size.width / 2 + 40,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 80,
                  child: Text(
                    label,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build regular input field for Par and Putts
  Widget _buildRegularInput(
    TextEditingController controller,
    FocusNode focusNode,
    String label,
  ) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      inputFormatters: [
        if (label == 'Par') ParInputFormatter(),
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(label == 'Strokes' ? 2 : 1),
      ],
      onSubmitted: (value) {
        if (label == 'Par' && value.isNotEmpty) {
          _strokesFocusNode.requestFocus();
        } else if (label == 'Putts') {
          FocusScope.of(context).unfocus();
        } else {
          FocusScope.of(context).unfocus();
        }
      },
      onChanged: (value) {
        setState(() {});
        _autoSaveCurrentRound(); // Auto-save when field changes
        if (label == 'Par' && value.isNotEmpty) {
          _strokesFocusNode.requestFocus();
        } else if (label == 'Putts' && value.isNotEmpty) {
          final int putts = int.parse(value);
          if (putts >= 1 && putts <= 9) {
            _puttsFocusNode.unfocus();
          }
        }
      },
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  // Build strokes input with scorecard-style indicators around the number
  Widget _buildStrokesInput() {
    final int? par = int.tryParse(_parController.text);
    final int? strokes = int.tryParse(_strokesController.text);

    // Calculate score differential
    int? scoreDiff;
    if (par != null && strokes != null && strokes > 0) {
      scoreDiff = strokes - par;
    }

    // Determine indicator style
    Color? borderColor;
    BoxShape? shape;
    bool isDouble = false;

    if (scoreDiff != null && scoreDiff != 0) {
      if (scoreDiff == -1) {
        // Birdie - green circle
        borderColor = Colors.green;
        shape = BoxShape.circle;
      } else if (scoreDiff <= -2) {
        // Eagle or better - double green circle
        borderColor = Colors.green;
        shape = BoxShape.circle;
        isDouble = true;
      } else if (scoreDiff == 1) {
        // Bogey - red square
        borderColor = Colors.red;
        shape = BoxShape.rectangle;
      } else if (scoreDiff >= 2) {
        // Double bogey or worse - double red square
        borderColor = Colors.red;
        shape = BoxShape.rectangle;
        isDouble = true;
      }
    }

    // If no indicator needed, return regular text field
    if (borderColor == null || shape == null) {
      return Container(
        width: 60,
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 1.0),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: TextField(
          controller: _strokesController,
          focusNode: _strokesFocusNode,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          onChanged: (value) {
            setState(() {});
            _autoSaveCurrentRound(); // Auto-save when strokes change
            if (value.isNotEmpty) {
              _debounce?.cancel();
              if (value == '1') {
                _debounce = Timer(const Duration(seconds: 1), () {
                  if (mounted && _strokesController.text == '1') {
                    _puttsFocusNode.requestFocus();
                  }
                });
              } else {
                final int strokesVal = int.parse(value);
                if ((strokesVal >= 2 && strokesVal <= 9) ||
                    (strokesVal >= 10 && strokesVal <= 19)) {
                  _puttsFocusNode.requestFocus();
                }
              }
            }
          },
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _puttsFocusNode.requestFocus();
            } else {
              FocusScope.of(context).unfocus();
            }
          },
          decoration: const InputDecoration(
            border: InputBorder.none,
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      );
    }

    // Create the indicator with proper centering
    Widget indicator = Container(
      width: 60,
      height: 48,
      decoration: BoxDecoration(
        shape: shape,
        border: Border.all(color: borderColor, width: 2.0),
        color: Colors.white,
      ),
      child: Stack(
        children: [
          // Invisible TextField for input handling
          Positioned.fill(
            child: TextField(
              controller: _strokesController,
              focusNode: _strokesFocusNode,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.transparent,
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _puttsFocusNode.requestFocus();
                } else {
                  FocusScope.of(context).unfocus();
                }
              },
              onChanged: (value) {
                setState(() {});
                _autoSaveCurrentRound(); // Auto-save when strokes change
                if (value.isNotEmpty) {
                  _debounce?.cancel();
                  if (value == '1') {
                    _debounce = Timer(const Duration(seconds: 1), () {
                      if (mounted && _strokesController.text == '1') {
                        _puttsFocusNode.requestFocus();
                      }
                    });
                  } else {
                    final int strokesVal = int.parse(value);
                    if ((strokesVal >= 2 && strokesVal <= 9) ||
                        (strokesVal >= 10 && strokesVal <= 19)) {
                      _puttsFocusNode.requestFocus();
                    }
                  }
                }
              },
              decoration: const InputDecoration(
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          // Visible centered text
          Center(
            child: Text(
              _strokesController.text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );

    // Add double border for eagles and double bogeys
    if (isDouble) {
      indicator = Container(
        width: 60,
        height: 48,
        decoration: BoxDecoration(
          shape: shape,
          border: Border.all(color: borderColor, width: 2.0),
          color: Colors.transparent,
        ),
        child: Center(
          child: Container(
            width: 52,
            height: 40,
            decoration: BoxDecoration(
              shape: shape,
              border: Border.all(color: borderColor, width: 2.0),
              color: Colors.white,
            ),
            child: Stack(
              children: [
                // Invisible TextField for input handling
                Positioned.fill(
                  child: TextField(
                    controller: _strokesController,
                    focusNode: _strokesFocusNode,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.transparent,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    onChanged: (value) {
                      setState(() {});
                      _autoSaveCurrentRound(); // Auto-save when strokes change
                      if (value.isNotEmpty) {
                        _debounce?.cancel();
                        if (value == '1') {
                          _debounce = Timer(const Duration(seconds: 1), () {
                            if (mounted && _strokesController.text == '1') {
                              _puttsFocusNode.requestFocus();
                            }
                          });
                        } else {
                          final int strokesVal = int.parse(value);
                          if ((strokesVal >= 2 && strokesVal <= 9) ||
                              (strokesVal >= 10 && strokesVal <= 19)) {
                            _puttsFocusNode.requestFocus();
                          }
                        }
                      }
                    },
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                // Visible centered text
                Center(
                  child: Text(
                    _strokesController.text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return indicator;
  }

  Widget _buildSegmentedControl(
    String title,
    List<String> options,
    String? groupValue,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          // Title above the segmented control
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // Centered segmented control
          SegmentedButton<String>(
            segments: options
                .map(
                  (value) =>
                      ButtonSegment<String>(value: value, label: Text(value)),
                )
                .toList(),
            selected: {groupValue ?? 'N/A'},
            onSelectionChanged: (newSelection) {
              onChanged(newSelection.first);
            },
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: Colors.green,
              selectedForegroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// --- SCORECARD VIEW (This part is correct and unchanged) ---
class ScorecardView extends StatelessWidget {
  final List<HoleData> roundData;
  final String courseName;
  const ScorecardView({
    super.key,
    required this.roundData,
    this.courseName = '',
  });

  Widget _buildCell({
    String text = '',
    Widget? child,
    Color backgroundColor = Colors.transparent,
    double width = 50,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return Container(
      width: width,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: Colors.grey.shade400, width: 1.0),
      ),
      child: Center(
        child: child ??
            Text(text, style: TextStyle(fontWeight: fontWeight, fontSize: 16)),
      ),
    );
  }

  Widget _buildFrozenColumn() {
    return Column(
      children: [
        _buildCell(
          text: 'Hole',
          width: 75,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.grey.shade200,
        ),
        _buildCell(
          text: 'Par',
          width: 75,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.grey.shade100,
        ),
        _buildCell(
          text: 'Score',
          width: 75,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.grey.shade100,
        ),
        _buildCell(
          text: 'Putts',
          width: 75,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.grey.shade100,
        ),
        _buildCell(
          text: 'FIR',
          width: 75,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.grey.shade100,
        ),
        _buildCell(
          text: 'GIR',
          width: 75,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.grey.shade100,
        ),
      ],
    );
  }

  Widget _buildScrollableRows() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderRow(),
          _buildDataRow(getValue: (hole) => hole.par),
          _buildDataRow(
            getValue: (hole) => hole.strokes,
            showScoreIndicator: true,
          ),
          _buildDataRow(getValue: (hole) => hole.putts),
          _buildStatRow(getValue: (hole) => hole.fir),
          _buildStatRow(getValue: (hole) => hole.gir),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    List<Widget> cells = [];
    for (int i = 1; i <= 9; i++) {
      final isEvenHole = (i - 1) % 2 == 0; // hole 1,3,5,7,9
      cells.add(_buildCell(
        text: '$i',
        fontWeight: FontWeight.bold,
        backgroundColor: isEvenHole ? Colors.grey[100]! : Colors.white,
      ));
    }
    cells.add(
      _buildCell(
        text: 'Out',
        width: 60,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.grey.shade200,
      ),
    );
    for (int i = 10; i <= 18; i++) {
      final isEvenHole = (i - 1) % 2 == 0; // hole 10,12,14,16,18
      cells.add(_buildCell(
        text: '$i',
        fontWeight: FontWeight.bold,
        backgroundColor: isEvenHole ? Colors.grey[100]! : Colors.white,
      ));
    }
    cells.add(
      _buildCell(
        text: 'In',
        width: 60,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.grey.shade200,
      ),
    );
    cells.add(
      _buildCell(
        text: 'Total',
        width: 70,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.grey.shade300,
      ),
    );
    return Row(children: cells);
  }

  Widget _buildDataRow({
    required String Function(HoleData) getValue,
    bool showScoreIndicator = false,
  }) {
    List<Widget> cells = [];
    List<int> frontNine = [];
    List<int> backNine = [];

    for (int i = 0; i < 9; i++) {
      final par = int.tryParse(roundData[i].par) ?? 0;
      final value = int.tryParse(getValue(roundData[i])) ?? 0;
      final isEvenHole = i % 2 == 0; // i=0 (hole 1), i=2 (hole 3), etc.
      cells.add(
        showScoreIndicator
            ? _buildScoreCell(par, value,
                backgroundColor: isEvenHole ? Colors.grey[100]! : Colors.white)
            : _buildCell(
                text: value == 0 ? '' : '$value',
                backgroundColor: isEvenHole ? Colors.grey[100]! : Colors.white,
              ),
      );
      if (value > 0) frontNine.add(value);
    }
    cells.add(
      _buildCell(
        text: '${frontNine.fold(0, (a, b) => a + b)}',
        width: 60,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.grey.shade200,
      ),
    );

    for (int i = 9; i < 18; i++) {
      final par = int.tryParse(roundData[i].par) ?? 0;
      final value = int.tryParse(getValue(roundData[i])) ?? 0;
      final isEvenHole = i % 2 == 0; // i=8 (hole 9), i=10 (hole 11), etc.
      cells.add(
        showScoreIndicator
            ? _buildScoreCell(par, value,
                backgroundColor: isEvenHole ? Colors.grey[100]! : Colors.white)
            : _buildCell(
                text: value == 0 ? '' : '$value',
                backgroundColor: isEvenHole ? Colors.grey[100]! : Colors.white,
              ),
      );
      if (value > 0) backNine.add(value);
    }
    cells.add(
      _buildCell(
        text: '${backNine.fold(0, (a, b) => a + b)}',
        width: 60,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.grey.shade200,
      ),
    );
    cells.add(
      _buildCell(
        text:
            '${frontNine.fold(0, (a, b) => a + b) + backNine.fold(0, (a, b) => a + b)}',
        width: 70,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.grey.shade300,
      ),
    );

    return Row(children: cells);
  }

  Widget _buildScoreCell(int par, int score,
      {Color backgroundColor = Colors.transparent}) {
    if (score == 0) return _buildCell(backgroundColor: backgroundColor);

    final scoreText = Text('$score', style: const TextStyle(fontSize: 16));
    int diff = score - par;
    Widget? indicator;

    if (par > 0) {
      Color borderColor = Colors.transparent;
      BoxShape shape = BoxShape.rectangle;
      bool isDouble = false;

      if (diff == -1) {
        borderColor = Colors.green;
        shape = BoxShape.circle;
      } else if (diff <= -2) {
        borderColor = Colors.green;
        shape = BoxShape.circle;
        isDouble = true;
      } else if (diff == 1) {
        borderColor = Colors.red;
      } else if (diff >= 2) {
        borderColor = Colors.red;
        isDouble = true;
      }

      if (borderColor != Colors.transparent) {
        Widget singleBorder = Container(
          decoration: BoxDecoration(
            shape: shape,
            border: Border.all(color: borderColor, width: 2.0),
          ),
        );

        if (isDouble) {
          indicator = Container(
            padding: const EdgeInsets.all(3.0),
            decoration: BoxDecoration(
              shape: shape,
              border: Border.all(color: borderColor, width: 2.0),
            ),
            child: singleBorder,
          );
        } else {
          indicator = singleBorder;
        }
      }
    }

    return _buildCell(
      backgroundColor: backgroundColor,
      child: Stack(
        alignment: Alignment.center,
        children: [scoreText, if (indicator != null) indicator],
      ),
    );
  }

  Widget _buildStatRow({required String Function(HoleData) getValue}) {
    List<Widget> cells = [];
    int frontNineCount = 0;
    int backNineCount = 0;

    for (int i = 0; i < 9; i++) {
      final value = getValue(roundData[i]);
      if (value == 'Yes') frontNineCount++;
      final isEvenHole = i % 2 == 0; // i=0 (hole 1), i=2 (hole 3), etc.
      cells.add(
        _buildCell(
          text: value == 'Yes' ? '✓' : (value == 'No' ? 'X' : 'N/A'),
          backgroundColor: isEvenHole ? Colors.grey[100]! : Colors.white,
        ),
      );
    }
    cells.add(
      _buildCell(
        text: '$frontNineCount',
        width: 60,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.grey.shade200,
      ),
    );

    for (int i = 9; i < 18; i++) {
      final value = getValue(roundData[i]);
      if (value == 'Yes') backNineCount++;
      final isEvenHole = i % 2 == 0; // i=8 (hole 9), i=10 (hole 11), etc.
      cells.add(
        _buildCell(
          text: value == 'Yes' ? '✓' : (value == 'No' ? 'X' : 'N/A'),
          backgroundColor: isEvenHole ? Colors.grey[100]! : Colors.white,
        ),
      );
    }
    cells.add(
      _buildCell(
        text: '$backNineCount',
        width: 60,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.grey.shade200,
      ),
    );
    cells.add(
      _buildCell(
        text: '${frontNineCount + backNineCount}',
        width: 70,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.grey.shade300,
      ),
    );

    return Row(children: cells);
  }

  Map<String, dynamic> _calculateCurrentProgress() {
    int lastCompletedHole = 0;
    int totalPar = 0;
    int totalStrokes = 0;

    // Find the last hole with both par and strokes filled
    for (int i = 0; i < roundData.length; i++) {
      final par = int.tryParse(roundData[i].par);
      final strokes = int.tryParse(roundData[i].strokes);

      if (par != null && par > 0 && strokes != null && strokes > 0) {
        lastCompletedHole = i + 1; // 1-based hole number
        totalPar += par;
        totalStrokes += strokes;
      }
    }

    final scoreToPar = totalStrokes - totalPar;

    return {
      'holesCompleted': lastCompletedHole,
      'totalPar': totalPar,
      'totalStrokes': totalStrokes,
      'scoreToPar': scoreToPar,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course name header
          if (courseName.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              margin: const EdgeInsets.only(bottom: 16.0),
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                courseName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Scorecard grid
          Expanded(
            child: Row(
              children: [
                _buildFrozenColumn(),
                Expanded(child: _buildScrollableRows()),
              ],
            ),
          ),

          // Running score summary
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final progress = _calculateCurrentProgress();
              final holesCompleted = progress['holesCompleted'] as int;
              final scoreToPar = progress['scoreToPar'] as int;
              final totalStrokes = progress['totalStrokes'] as int;

              if (holesCompleted == 0) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.yellow[100],
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Colors.yellow.shade300),
                  ),
                  child: const Text(
                    'Score Summary - No holes completed yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              String scoreText;
              if (scoreToPar == 0) {
                scoreText = 'Even Par ($totalStrokes)';
              } else if (scoreToPar > 0) {
                scoreText = '+$scoreToPar ($totalStrokes)';
              } else {
                scoreText = '$scoreToPar ($totalStrokes)';
              }

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.yellow.shade300),
                ),
                child: Column(
                  children: [
                    Text(
                      'Score Summary Thru $holesCompleted Hole${holesCompleted == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scoreText,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: scoreToPar > 0
                            ? Colors.red[700]
                            : (scoreToPar < 0
                                ? Colors.green[700]
                                : Colors.black),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// --- STATS VIEW ---
class StatsView extends StatefulWidget {
  final List<HoleData> roundData;
  final String courseName;

  const StatsView({super.key, required this.roundData, this.courseName = ''});

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> with TickerProviderStateMixin {
  int _currentView = 0; // 0: Current Round, 1: Last Ten, 2: Lifetime
  int _selectedTab = 0; // 0: All, 1: Course (switched order)
  String? _selectedCourse; // For course dropdown
  List<SavedCourse> _savedCourses = []; // Store saved courses

  // Track pan gesture for better swipe detection
  double _dragStartX = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCourses();
  }

  Future<void> _loadSavedCourses() async {
    final courses = await StorageService.getSavedCourses();
    setState(() {
      _savedCourses = courses;
      // Set default to current course if available
      if (widget.courseName.isNotEmpty &&
          courses.any((course) => course.name == widget.courseName)) {
        _selectedCourse = widget.courseName;
      } else if (courses.isNotEmpty) {
        _selectedCourse = courses.first.name;
      }
    });
  }

  void _handlePanStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _isDragging = true;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    // Optional: Add visual feedback during drag if needed
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!_isDragging) return;

    final double dragDistance = details.globalPosition.dx - _dragStartX;
    const double minSwipeDistance = 30.0; // Reduced for more sensitivity
    const double maxVelocity = 2000.0; // Increased for faster swipes

    // Check if this is a valid swipe gesture
    bool isValidSwipe = false;
    bool swipeRight = false;

    // Method 1: Check drag distance (more forgiving)
    if (dragDistance.abs() > minSwipeDistance) {
      isValidSwipe = true;
      swipeRight = dragDistance > 0;
    }
    // Method 2: Check velocity (for quick swipes)
    else if (details.primaryVelocity != null &&
        details.primaryVelocity!.abs() > 150 && // Lower threshold
        details.primaryVelocity!.abs() < maxVelocity) {
      isValidSwipe = true;
      swipeRight = details.primaryVelocity! > 0;
    }

    if (isValidSwipe) {
      if (swipeRight && _currentView > 0) {
        // Swiped right - go to previous view
        setState(() {
          _currentView--;
        });
      } else if (!swipeRight && _currentView < 2) {
        // Swiped left - go to next view
        setState(() {
          _currentView++;
        });
      }
    }

    _isDragging = false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Navigation header with arrows
        _buildNavigationHeader(),
        // Content based on current view with improved swipe detection
        Expanded(
          child: GestureDetector(
            onPanStart: _handlePanStart,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            behavior: HitTestBehavior.translucent,
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: _currentView == 0
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildCurrentRoundStats(),
                    )
                  : Column(
                      children: [
                        // Custom tabs: Course and All (only for Last Ten and Lifetime)
                        _buildCustomTabs(),
                        const SizedBox(height: 16),
                        // Tab content
                        Expanded(
                          child: _buildTabContent(
                            isCourseFocused: _selectedTab == 0,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left arrow (only show for Last Ten and Lifetime)
          _currentView > 0
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      _currentView--;
                    });
                  },
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.green),
                )
              : const SizedBox(width: 48),

          // Current view title
          Text(
            _getCurrentViewTitle(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),

          // Right arrow (only show for Current Round and Last Ten)
          _currentView < 2
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      _currentView++;
                    });
                  },
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.green,
                  ),
                )
              : const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildCustomTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Tab buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _selectedTab = 0;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    decoration: BoxDecoration(
                      color: _selectedTab == 0
                          ? Colors.green[700]
                          : Colors.grey[200],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8.0),
                        bottomLeft: Radius.circular(8.0),
                      ),
                      border: Border.all(
                        color: _selectedTab == 0
                            ? Colors.green[700]!
                            : Colors.grey[300]!,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      'All',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _selectedTab == 0 ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _selectedTab = 1;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    decoration: BoxDecoration(
                      color: _selectedTab == 1
                          ? Colors.green[700]
                          : Colors.grey[200],
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8.0),
                        bottomRight: Radius.circular(8.0),
                      ),
                      border: Border.all(
                        color: _selectedTab == 1
                            ? Colors.green[700]!
                            : Colors.grey[300]!,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      'Course',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _selectedTab == 1 ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Course dropdown (only show when Course tab is selected)
          if (_selectedTab == 1) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedCourse,
                  hint: const Text('Select a course'),
                  icon: Icon(Icons.arrow_drop_down, color: Colors.green[700]),
                  items: _savedCourses.map((course) {
                    return DropdownMenuItem<String>(
                      value: course.name,
                      child: Text(
                        course.name,
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCourse = newValue;
                    });
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getCurrentViewTitle() {
    switch (_currentView) {
      case 0:
        return 'Current Round';
      case 1:
        return 'Last Ten';
      case 2:
        return 'Lifetime';
      default:
        return 'Current Round';
    }
  }

  Widget _buildTabContent({required bool isCourseFocused}) {
    // This method is only called for Last Ten and Lifetime views (not Current Round)
    // Tab 0 = All, Tab 1 = Course (switched order)
    switch (_currentView) {
      case 1:
        return _buildSavedRoundsContent(
          title: 'Last Ten Rounds',
          isLastTen: true,
          isCourseFocused: _selectedTab == 1, // Course tab is now index 1
          selectedCourse: _selectedTab == 1 ? _selectedCourse : null,
        );
      case 2:
        return _buildSavedRoundsContent(
          title: 'Lifetime Statistics',
          isLastTen: false,
          isCourseFocused: _selectedTab == 1, // Course tab is now index 1
          selectedCourse: _selectedTab == 1 ? _selectedCourse : null,
        );
      default:
        return _buildComingSoonContent(
          title: 'Statistics',
          subtitle: 'Coming soon!',
          icon: Icons.analytics,
        );
    }
  }

  Widget _buildComingSoonContent({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Text(
            'Coming soon!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedRoundsContent({
    required String title,
    required bool isLastTen,
    required bool isCourseFocused,
    String? selectedCourse,
  }) {
    return FutureBuilder<List<SavedRound>>(
      future: StorageService.getSavedRounds(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading rounds: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        List<SavedRound> rounds = snapshot.data ?? [];

        // Filter by course if needed
        if (isCourseFocused &&
            selectedCourse != null &&
            selectedCourse.isNotEmpty) {
          rounds = rounds
              .where((round) =>
                  round.courseName.toLowerCase() ==
                  selectedCourse.toLowerCase())
              .toList();
        }

        // Sort by date (most recent first)
        rounds.sort((a, b) => b.dateTime.compareTo(a.dateTime));

        // Limit to last 10 if needed
        if (isLastTen && rounds.length > 10) {
          rounds = rounds.take(10).toList();
        }

        if (rounds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isLastTen ? Icons.history : Icons.analytics,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isCourseFocused && selectedCourse != null
                      ? 'No rounds found for "$selectedCourse"'
                      : 'No saved rounds yet',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$title${isCourseFocused && selectedCourse != null ? ' - $selectedCourse' : ''}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: rounds.length,
                  itemBuilder: (context, index) {
                    final round = rounds[index];
                    final totalScore = round.holes.fold<int>(0,
                        (sum, hole) => sum + (int.tryParse(hole.strokes) ?? 0));
                    final totalPar = round.holes.fold<int>(
                        0, (sum, hole) => sum + (int.tryParse(hole.par) ?? 0));
                    final scoreToPar = totalScore - totalPar;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getScoreColor(scoreToPar),
                          child: Text(
                            scoreToPar > 0 ? '+$scoreToPar' : '$scoreToPar',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        title: Text(
                          round.courseName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${_formatDate(round.dateTime)} • $totalScore (${round.holes.length} holes)',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showRoundDetails(round),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getScoreColor(int scoreToPar) {
    if (scoreToPar <= -2) return Colors.purple; // Eagle or better
    if (scoreToPar == -1) return Colors.orange; // Birdie
    if (scoreToPar == 0) return Colors.green; // Par
    if (scoreToPar == 1) return Colors.blue; // Bogey
    if (scoreToPar == 2) return Colors.red; // Double bogey
    return Colors.grey; // Worse
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _showRoundDetails(SavedRound round) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(round.courseName),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Played on ${_formatDate(round.dateTime)}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: _buildRoundDetailsTable(round),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundDetailsTable(SavedRound round) {
    final totalScore = round.holes
        .fold<int>(0, (sum, hole) => sum + (int.tryParse(hole.strokes) ?? 0));
    final totalPar = round.holes
        .fold<int>(0, (sum, hole) => sum + (int.tryParse(hole.par) ?? 0));
    final totalPutts = round.holes
        .fold<int>(0, (sum, hole) => sum + (int.tryParse(hole.putts) ?? 0));
    final firs = round.holes.where((hole) => hole.fir == 'Yes').length;
    final girs = round.holes.where((hole) => hole.gir == 'Yes').length;

    return Column(
      children: [
        // Summary stats
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Score', '$totalScore'),
              _buildStatItem('Par', '$totalPar'),
              _buildStatItem('To Par',
                  '${totalScore - totalPar > 0 ? '+' : ''}${totalScore - totalPar}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Hole-by-hole breakdown
        Table(
          border: TableBorder.all(color: Colors.grey[300]!),
          columnWidths: const {
            0: FixedColumnWidth(40),
            1: FixedColumnWidth(40),
            2: FixedColumnWidth(50),
            3: FixedColumnWidth(50),
            4: FixedColumnWidth(40),
            5: FixedColumnWidth(40),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey[200]),
              children: [
                _buildTableHeader('Hole'),
                _buildTableHeader('Par'),
                _buildTableHeader('Strokes'),
                _buildTableHeader('Putts'),
                _buildTableHeader('FIR'),
                _buildTableHeader('GIR'),
              ],
            ),
            ...round.holes.asMap().entries.map((entry) {
              final index = entry.key;
              final hole = entry.value;
              return TableRow(
                decoration: BoxDecoration(
                  color: index.isEven ? Colors.grey[100] : Colors.white,
                ),
                children: [
                  _buildTableCell('${index + 1}'),
                  _buildTableCell(hole.par),
                  _buildTableCell(hole.strokes),
                  _buildTableCell(hole.putts),
                  _buildTableCell(hole.fir == 'Yes' ? '✓' : ''),
                  _buildTableCell(hole.gir == 'Yes' ? '✓' : ''),
                ],
              );
            }),
            // Totals row
            TableRow(
              decoration: BoxDecoration(color: Colors.grey[100]),
              children: [
                _buildTableHeader('Total'),
                _buildTableHeader('$totalPar'),
                _buildTableHeader('$totalScore'),
                _buildTableHeader('$totalPutts'),
                _buildTableHeader('$firs/${round.holes.length}'),
                _buildTableHeader('$girs/${round.holes.length}'),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildCurrentRoundStats() {
    // Calculate current round statistics
    int totalStrokes = 0;
    int totalPar = 0;
    int holesPlayed = 0;
    int birdies = 0;
    int eagles = 0;
    int pars = 0;
    int bogeys = 0;
    int doubleBogeys = 0;
    int holesInOne = 0; // Added holes in one
    int firHits = 0;
    int girHits = 0;
    int totalPutts = 0;
    int firAttempts = 0;
    int girAttempts = 0;

    for (final hole in widget.roundData) {
      final par = int.tryParse(hole.par);
      final strokes = int.tryParse(hole.strokes);
      final putts = int.tryParse(hole.putts);

      if (par != null && strokes != null && strokes > 0) {
        totalPar += par;
        totalStrokes += strokes;
        holesPlayed++;

        // Check for hole in one
        if (strokes == 1) {
          holesInOne++;
        }

        final diff = strokes - par;
        if (diff <= -2) {
          eagles++;
        } else if (diff == -1) {
          birdies++;
        } else if (diff == 0) {
          pars++;
        } else if (diff == 1) {
          bogeys++;
        } else if (diff >= 2) {
          doubleBogeys++;
        }
      }

      if (hole.fir != 'N/A') {
        firAttempts++;
        if (hole.fir == 'Yes') firHits++;
      }

      if (hole.gir != 'N/A') {
        girAttempts++;
        if (hole.gir == 'Yes') girHits++;
      }

      if (putts != null && putts > 0) {
        totalPutts += putts;
      }
    }

    final double scoring = holesPlayed > 0 ? totalStrokes / holesPlayed : 0.0;
    final double putting = holesPlayed > 0 ? totalPutts / holesPlayed : 0.0;
    final double firPercentage =
        firAttempts > 0 ? (firHits / firAttempts) * 100 : 0.0;
    final double girPercentage =
        girAttempts > 0 ? (girHits / girAttempts) * 100 : 0.0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.courseName.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              margin: const EdgeInsets.only(bottom: 16.0),
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                widget.courseName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Score Summary
          _buildStatCard(
            title: 'Score Summary',
            stats: [
              StatItem('Holes Played', '$holesPlayed/18'),
              StatItem('Total Strokes', '$totalStrokes'),
              StatItem('Total Par', '$totalPar'),
              StatItem(
                'Score to Par',
                totalStrokes > 0
                    ? '${totalStrokes - totalPar > 0 ? '+' : ''}${totalStrokes - totalPar}'
                    : '0',
              ),
              StatItem(
                'Scoring Average',
                holesPlayed > 0 ? scoring.toStringAsFixed(2) : '0.00',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Hole Performance
          _buildStatCard(
            title: 'Hole Performance',
            stats: [
              StatItem(
                'Holes in One',
                '$holesInOne',
              ), // Added holes in one at the top
              StatItem('Eagles+', '$eagles'),
              StatItem('Birdies', '$birdies'),
              StatItem('Pars', '$pars'),
              StatItem('Bogeys', '$bogeys'),
              StatItem('Double+', '$doubleBogeys'),
            ],
          ),

          const SizedBox(height: 16),

          // Course Management
          _buildStatCard(
            title: 'Course Management',
            stats: [
              StatItem('Fairways Hit', '$firHits/$firAttempts'),
              StatItem(
                'FIR %',
                firAttempts > 0
                    ? '${firPercentage.toStringAsFixed(1)}%'
                    : '0.0%',
              ),
              StatItem('Greens Hit', '$girHits/$girAttempts'),
              StatItem(
                'GIR %',
                girAttempts > 0
                    ? '${girPercentage.toStringAsFixed(1)}%'
                    : '0.0%',
              ),
              StatItem('Total Putts', '$totalPutts'),
              StatItem(
                'Putting Avg',
                holesPlayed > 0 ? putting.toStringAsFixed(2) : '0.00',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required List<StatItem> stats,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...stats.map(
            (stat) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(stat.label, style: const TextStyle(fontSize: 16)),
                  Text(
                    stat.value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StatItem {
  final String label;
  final String value;

  StatItem(this.label, this.value);
}

// --- SAVED COURSES VIEW ---
class SavedCoursesView extends StatefulWidget {
  final Function(SavedCourse) onCourseSelected;

  const SavedCoursesView({
    super.key,
    required this.onCourseSelected,
  });

  @override
  State<SavedCoursesView> createState() => _SavedCoursesViewState();
}

class _SavedCoursesViewState extends State<SavedCoursesView> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saved Courses',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              IconButton(
                onPressed: _showAddCourseDialog,
                icon: Icon(
                  Icons.add_circle,
                  color: Colors.green[700],
                  size: 28,
                ),
                tooltip: 'Add New Course',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<SavedCourse>>(
              future: StorageService.getSavedCourses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading courses: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final courses = snapshot.data ?? [];

                if (courses.isEmpty) {
                  return _buildEmptyState();
                }

                // Sort courses by most recently played
                courses.sort((a, b) => b.lastPlayed.compareTo(a.lastPlayed));

                return ListView.builder(
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return _buildCourseCard(course);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.golf_course,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Saved Courses',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Courses will be automatically saved\nwhen you complete rounds',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddCourseDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Course Manually'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(SavedCourse course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => widget.onCourseSelected(course),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      course.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditCourseDialog(course);
                      } else if (value == 'delete') {
                        _showDeleteCourseDialog(course);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildCourseStatChip('Par ${course.totalPar}', Icons.flag),
                  const SizedBox(width: 12),
                  _buildCourseStatChip(
                    'Played ${course.timesPlayed}x',
                    Icons.sports_golf,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Last played: ${_formatDate(course.lastPlayed)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Front 9: ${course.frontNinePar} • Back 9: ${course.backNinePar}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseStatChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.green[700]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.green[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _showAddCourseDialog() {
    _showCourseDialog(null);
  }

  void _showEditCourseDialog(SavedCourse course) {
    _showCourseDialog(course);
  }

  void _showCourseDialog(SavedCourse? existingCourse) {
    final nameController = TextEditingController(
      text: existingCourse?.name ?? '',
    );
    final List<TextEditingController> parControllers = List.generate(
      18,
      (index) => TextEditingController(
        text: existingCourse?.pars[index].toString() ?? '',
      ),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingCourse == null ? 'Add New Course' : 'Edit Course'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Course Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Par for each hole:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: _buildParInputGrid(parControllers),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _saveCourseFromDialog(
                nameController,
                parControllers,
                existingCourse,
              );
              if (mounted) navigator.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
            child: Text(existingCourse == null ? 'Add Course' : 'Save Changes'),
          ),
        ],
      ),
    );
  }

  Widget _buildParInputGrid(List<TextEditingController> controllers) {
    return Column(
      children: [
        // Front 9
        const Text('Front 9:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 9,
            childAspectRatio: 1,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: 9,
          itemBuilder: (context, index) =>
              _buildParInput(controllers[index], index + 1),
        ),
        const SizedBox(height: 16),
        // Back 9
        const Text('Back 9:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 9,
            childAspectRatio: 1,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: 9,
          itemBuilder: (context, index) =>
              _buildParInput(controllers[index + 9], index + 10),
        ),
      ],
    );
  }

  Widget _buildParInput(TextEditingController controller, int holeNumber) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$holeNumber',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              ParInputFormatter(),
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _saveCourseFromDialog(
    TextEditingController nameController,
    List<TextEditingController> parControllers,
    SavedCourse? existingCourse,
  ) async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a course name')),
      );
      return;
    }

    final pars = <int>[];
    for (final controller in parControllers) {
      final par = int.tryParse(controller.text);
      if (par == null || par < 3 || par > 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please enter valid pars (3-6) for all holes')),
        );
        return;
      }
      pars.add(par);
    }

    final course = existingCourse?.copyWith(
          name: name,
          pars: pars,
        ) ??
        SavedCourse(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          pars: pars,
          dateCreated: DateTime.now(),
          lastPlayed: DateTime.now(),
        );

    final success = await StorageService.saveCourse(course);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '✅ Course ${existingCourse == null ? 'added' : 'updated'} successfully!'
              : '❌ Failed to ${existingCourse == null ? 'add' : 'update'} course'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) setState(() {});
    }
  }

  void _showDeleteCourseDialog(SavedCourse course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text('Are you sure you want to delete "${course.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final success = await StorageService.deleteCourse(course.id);
              if (mounted) {
                navigator.pop();
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? '✅ Course deleted successfully!'
                        : '❌ Failed to delete course'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
                if (success) setState(() {});
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// --- CALENDAR VIEW ---
class CalendarView extends StatelessWidget {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Calendar',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Coming Soon!',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// --- SAVED STATS SCREEN (Standalone stats without current round) ---
class SavedStatsScreen extends StatefulWidget {
  const SavedStatsScreen({super.key});

  @override
  State<SavedStatsScreen> createState() => _SavedStatsScreenState();
}

class _SavedStatsScreenState extends State<SavedStatsScreen>
    with TickerProviderStateMixin {
  int _currentView = 0; // 0: Last Ten, 1: Lifetime (no current round)
  int _selectedTab = 0; // 0: All, 1: Course
  String? _selectedCourse;
  List<SavedCourse> _savedCourses = [];

  // Track pan gesture for better swipe detection
  double _dragStartX = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCourses();
  }

  Future<void> _loadSavedCourses() async {
    final courses = await StorageService.getSavedCourses();
    setState(() {
      _savedCourses = courses;
      if (courses.isNotEmpty) {
        _selectedCourse = courses.first.name;
      }
    });
  }

  void _handlePanStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _isDragging = true;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    // Optional: Add visual feedback during drag if needed
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!_isDragging) return;

    final double dragDistance = details.globalPosition.dx - _dragStartX;
    const double minSwipeDistance = 30.0;
    const double maxVelocity = 2000.0;

    bool isValidSwipe = false;
    bool swipeRight = false;

    if (dragDistance.abs() > minSwipeDistance) {
      isValidSwipe = true;
      swipeRight = dragDistance > 0;
    } else if (details.primaryVelocity != null &&
        details.primaryVelocity!.abs() > 150 &&
        details.primaryVelocity!.abs() < maxVelocity) {
      isValidSwipe = true;
      swipeRight = details.primaryVelocity! > 0;
    }

    if (isValidSwipe) {
      if (swipeRight && _currentView > 0) {
        setState(() {
          _currentView--;
        });
      } else if (!swipeRight && _currentView < 1) {
        // Only 2 views now
        setState(() {
          _currentView++;
        });
      }
    }

    _isDragging = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        title: const Text('Saved Stats'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Navigation header with arrows
          _buildNavigationHeader(),
          // Custom tabs
          _buildCustomTabs(),
          const SizedBox(height: 16),
          // Content with swipe detection
          Expanded(
            child: GestureDetector(
              onPanStart: _handlePanStart,
              onPanUpdate: _handlePanUpdate,
              onPanEnd: _handlePanEnd,
              behavior: HitTestBehavior.translucent,
              child: _buildTabContent(isCourseFocused: _selectedTab == 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left arrow
          _currentView > 0
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      _currentView--;
                    });
                  },
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.green),
                )
              : const SizedBox(width: 48),

          // Current view title
          Text(
            _getCurrentViewTitle(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),

          // Right arrow
          _currentView < 1 // Only 2 views now
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      _currentView++;
                    });
                  },
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.green,
                  ),
                )
              : const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildCustomTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Tab buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _selectedTab = 0;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    decoration: BoxDecoration(
                      color: _selectedTab == 0
                          ? Colors.green[700]
                          : Colors.grey[200],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8.0),
                        bottomLeft: Radius.circular(8.0),
                      ),
                      border: Border.all(
                        color: _selectedTab == 0
                            ? Colors.green[700]!
                            : Colors.grey[300]!,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      'All',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _selectedTab == 0 ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _selectedTab = 1;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    decoration: BoxDecoration(
                      color: _selectedTab == 1
                          ? Colors.green[700]
                          : Colors.grey[200],
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8.0),
                        bottomRight: Radius.circular(8.0),
                      ),
                      border: Border.all(
                        color: _selectedTab == 1
                            ? Colors.green[700]!
                            : Colors.grey[300]!,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      'Course',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _selectedTab == 1 ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Course dropdown (only show when Course tab is selected)
          if (_selectedTab == 1) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedCourse,
                  hint: const Text('Select a course'),
                  icon: Icon(Icons.arrow_drop_down, color: Colors.green[700]),
                  items: _savedCourses.map((course) {
                    return DropdownMenuItem<String>(
                      value: course.name,
                      child: Text(
                        course.name,
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCourse = newValue;
                    });
                    // Force rebuild to ensure filtering takes effect
                    Future.delayed(Duration.zero, () {
                      if (mounted) setState(() {});
                    });
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getCurrentViewTitle() {
    switch (_currentView) {
      case 0:
        return 'Last Ten';
      case 1:
        return 'Lifetime';
      default:
        return 'Last Ten';
    }
  }

  Widget _buildTabContent({required bool isCourseFocused}) {
    switch (_currentView) {
      case 0:
        return _buildSavedRoundsContent(
          title: 'Last Ten Rounds',
          isLastTen: true,
          isCourseFocused: isCourseFocused,
          selectedCourse: isCourseFocused ? _selectedCourse : null,
        );
      case 1:
        return _buildSavedRoundsContent(
          title: 'Lifetime Statistics',
          isLastTen: false,
          isCourseFocused: isCourseFocused,
          selectedCourse: isCourseFocused ? _selectedCourse : null,
        );
      default:
        return _buildComingSoonContent(
          title: 'Statistics',
          subtitle: 'Coming soon!',
          icon: Icons.analytics,
        );
    }
  }

  Widget _buildSavedRoundsContent({
    required String title,
    required bool isLastTen,
    required bool isCourseFocused,
    String? selectedCourse,
  }) {
    return FutureBuilder<List<SavedRound>>(
      future: StorageService.getSavedRounds(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading rounds: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        List<SavedRound> rounds = snapshot.data ?? [];

        // Filter by course if needed
        if (isCourseFocused &&
            selectedCourse != null &&
            selectedCourse.isNotEmpty) {
          rounds = rounds
              .where((round) =>
                  round.courseName.toLowerCase() ==
                  selectedCourse.toLowerCase())
              .toList();
        }

        // Sort by date (most recent first)
        rounds.sort((a, b) => b.dateTime.compareTo(a.dateTime));

        // Limit to last 10 if needed
        if (isLastTen && rounds.length > 10) {
          rounds = rounds.take(10).toList();
        }

        if (rounds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isLastTen ? Icons.history : Icons.analytics,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isCourseFocused && selectedCourse != null
                      ? 'No rounds found for "$selectedCourse"'
                      : 'No saved rounds yet',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Calculate comprehensive statistics from the rounds
        return _buildStatsFromRounds(
            rounds, title, isCourseFocused, selectedCourse);
      },
    );
  }

  Widget _buildStatsFromRounds(List<SavedRound> rounds, String title,
      bool isCourseFocused, String? selectedCourse) {
    // Calculate aggregate statistics
    int totalStrokes = 0;
    int totalPar = 0;
    int totalPutts = 0;
    int holesPlayed = 0;
    int firHits = 0;
    int firAttempts = 0;
    int girHits = 0;
    int girAttempts = 0;
    int eagles = 0;
    int birdies = 0;
    int pars = 0;
    int bogeys = 0;
    int doubleBogeys = 0;
    int holesInOne = 0;

    for (final round in rounds) {
      for (final hole in round.holes) {
        final strokes = int.tryParse(hole.strokes);
        final par = int.tryParse(hole.par);
        final putts = int.tryParse(hole.putts);

        if (strokes != null && strokes > 0 && par != null && par > 0) {
          totalStrokes += strokes;
          totalPar += par;
          holesPlayed++;

          // Calculate score relative to par
          final toPar = strokes - par;
          if (strokes == 1) {
            holesInOne++;
          } else if (toPar <= -2) {
            eagles++;
          } else if (toPar == -1) {
            birdies++;
          } else if (toPar == 0) {
            pars++;
          } else if (toPar == 1) {
            bogeys++;
          } else if (toPar >= 2) {
            doubleBogeys++;
          }

          // FIR calculation (only for par 4 and 5)
          if (par >= 4) {
            firAttempts++;
            if (hole.fir == 'Yes') {
              firHits++;
            }
          }

          // GIR calculation
          girAttempts++;
          if (hole.gir == 'Yes') {
            girHits++;
          }

          // Putts calculation
          if (putts != null && putts > 0) {
            totalPutts += putts;
          }
        }
      }
    }

    final double scoring = holesPlayed > 0 ? totalStrokes / holesPlayed : 0.0;
    final double putting = holesPlayed > 0 ? totalPutts / holesPlayed : 0.0;
    final double firPercentage =
        firAttempts > 0 ? (firHits / firAttempts) * 100 : 0.0;
    final double girPercentage =
        girAttempts > 0 ? (girHits / girAttempts) * 100 : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with course info
          Text(
            '$title${isCourseFocused && selectedCourse != null ? ' - $selectedCourse' : ''}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${rounds.length} round${rounds.length != 1 ? 's' : ''} • $holesPlayed holes played',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // Score Summary
          _buildStatCard(
            title: 'Score Summary',
            stats: [
              StatItem('Rounds Played', '${rounds.length}'),
              StatItem('Holes Played', '$holesPlayed'),
              StatItem('Total Strokes', '$totalStrokes'),
              StatItem('Total Par', '$totalPar'),
              StatItem(
                'Score to Par',
                totalStrokes > 0
                    ? '${totalStrokes - totalPar > 0 ? '+' : ''}${totalStrokes - totalPar}'
                    : '0',
              ),
              StatItem(
                'Scoring Average',
                holesPlayed > 0 ? scoring.toStringAsFixed(2) : '0.00',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Hole Performance
          _buildStatCard(
            title: 'Hole Performance',
            stats: [
              StatItem('Holes in One', '$holesInOne'),
              StatItem('Eagles+', '$eagles'),
              StatItem('Birdies', '$birdies'),
              StatItem('Pars', '$pars'),
              StatItem('Bogeys', '$bogeys'),
              StatItem('Double+', '$doubleBogeys'),
            ],
          ),

          const SizedBox(height: 16),

          // Course Management
          _buildStatCard(
            title: 'Course Management',
            stats: [
              StatItem('Fairways Hit', '$firHits/$firAttempts'),
              StatItem(
                'FIR %',
                firAttempts > 0
                    ? '${firPercentage.toStringAsFixed(1)}%'
                    : '0.0%',
              ),
              StatItem('Greens Hit', '$girHits/$girAttempts'),
              StatItem(
                'GIR %',
                girAttempts > 0
                    ? '${girPercentage.toStringAsFixed(1)}%'
                    : '0.0%',
              ),
              StatItem('Total Putts', '$totalPutts'),
              StatItem(
                'Putting Avg',
                holesPlayed > 0 ? putting.toStringAsFixed(2) : '0.00',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Recent Rounds
          _buildStatCard(
            title: 'Recent Rounds',
            stats: [],
            customContent: Column(
              children: [
                ...rounds.take(5).map((round) {
                  final totalScore = round.holes.fold<int>(0,
                      (sum, hole) => sum + (int.tryParse(hole.strokes) ?? 0));
                  final totalPar = round.holes.fold<int>(
                      0, (sum, hole) => sum + (int.tryParse(hole.par) ?? 0));
                  final scoreVsPar = totalScore - totalPar;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: scoreVsPar < 0
                            ? Colors.green
                            : scoreVsPar == 0
                                ? Colors.blue
                                : Colors.red,
                        child: Text(
                          scoreVsPar < 0
                              ? '$scoreVsPar'
                              : scoreVsPar == 0
                                  ? 'E'
                                  : '+$scoreVsPar',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        round.courseName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        '${round.dateTime.day}/${round.dateTime.month}/${round.dateTime.year}',
                      ),
                      trailing: Text(
                        '$totalScore',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RoundDetailScreen(round: round),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
                if (rounds.length > 5) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllRoundsScreen(
                            rounds: rounds,
                            title:
                                '$title${isCourseFocused && selectedCourse != null ? ' - $selectedCourse' : ''}',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.list),
                    label: Text('View All ${rounds.length} Rounds'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green[700],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonContent({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required List<StatItem> stats,
    Widget? customContent,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (customContent != null)
            customContent
          else
            ...stats.map(
              (stat) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(stat.label, style: const TextStyle(fontSize: 16)),
                    Text(
                      stat.value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Round Detail Screen for viewing completed round stats
class RoundDetailScreen extends StatelessWidget {
  final SavedRound round;

  const RoundDetailScreen({super.key, required this.round});

  @override
  Widget build(BuildContext context) {
    final totalScore = round.holes
        .fold<int>(0, (sum, hole) => sum + (int.tryParse(hole.strokes) ?? 0));
    final totalPar = round.holes
        .fold<int>(0, (sum, hole) => sum + (int.tryParse(hole.par) ?? 0));
    final scoreVsPar = totalScore - totalPar;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        title: Text(round.courseName),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Round Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Round Summary',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${round.dateTime.day}/${round.dateTime.month}/${round.dateTime.year}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Total Score',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '$totalScore',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Par',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '$totalPar',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Score vs Par',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: scoreVsPar < 0
                                    ? Colors.green
                                    : scoreVsPar == 0
                                        ? Colors.blue
                                        : Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                scoreVsPar < 0
                                    ? '$scoreVsPar'
                                    : scoreVsPar == 0
                                        ? 'E'
                                        : '+$scoreVsPar',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Scorecard
            Text(
              'Scorecard',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Header row
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: const [
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Hole',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Par',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Score',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Putts',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'FIR',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'GIR',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Data rows
                    ...round.holes.asMap().entries.map((entry) {
                      final index = entry.key;
                      final hole = entry.value;
                      final holeNumber = index + 1;
                      final par = int.tryParse(hole.par) ?? 0;
                      final strokes = int.tryParse(hole.strokes) ?? 0;
                      final holeScore = strokes - par;

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              index % 2 == 1 ? Colors.grey[100] : Colors.white,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                '$holeNumber',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                hole.par,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                hole.strokes,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: holeScore < 0
                                      ? Colors.green
                                      : holeScore == 0
                                          ? Colors.black
                                          : Colors.red,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                hole.putts.isEmpty ? '-' : hole.putts,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                hole.fir == 'Yes'
                                    ? '✓'
                                    : hole.fir == 'No'
                                        ? '✗'
                                        : '-',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: hole.fir == 'Yes'
                                      ? Colors.green
                                      : hole.fir == 'No'
                                          ? Colors.red
                                          : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                hole.gir == 'Yes'
                                    ? '✓'
                                    : hole.gir == 'No'
                                        ? '✗'
                                        : '-',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: hole.gir == 'Yes'
                                      ? Colors.green
                                      : hole.gir == 'No'
                                          ? Colors.red
                                          : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// All Rounds Screen for viewing all saved rounds with scorecards
class AllRoundsScreen extends StatelessWidget {
  final List<SavedRound> rounds;
  final String title;

  const AllRoundsScreen({
    super.key,
    required this.rounds,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        title: Text(title),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Rounds (${rounds.length})',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap any round to view detailed scorecard',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: rounds.length,
                itemBuilder: (context, index) {
                  final round = rounds[index];
                  final totalScore = round.holes.fold<int>(0,
                      (sum, hole) => sum + (int.tryParse(hole.strokes) ?? 0));
                  final totalPar = round.holes.fold<int>(
                      0, (sum, hole) => sum + (int.tryParse(hole.par) ?? 0));
                  final scoreVsPar = totalScore - totalPar;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: scoreVsPar < 0
                            ? Colors.green
                            : scoreVsPar == 0
                                ? Colors.blue
                                : Colors.red,
                        child: Text(
                          scoreVsPar < 0
                              ? '$scoreVsPar'
                              : scoreVsPar == 0
                                  ? 'E'
                                  : '+$scoreVsPar',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        round.courseName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${round.dateTime.day}/${round.dateTime.month}/${round.dateTime.year}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$totalScore',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Par $totalPar',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RoundDetailScreen(round: round),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
