// lib/screens/new_game_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ParInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
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
  const NewGameScreen({super.key});

  @override
  State<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends State<NewGameScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screenViews = <Widget>[
    GameEntryView(),
    Center(child: Text('Scorecard View')),
    Center(child: Text('Stats View')),
    Center(child: Text('Calendar View')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        title: const Text('New Game'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const CircleAvatar(
              backgroundColor: Colors.white,
              foregroundColor: Colors.green,
              child: Text(
                'BP',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      resizeToAvoidBottomInset: false,
      body: _screenViews.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note),
            label: 'Entry',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.scoreboard),
            label: 'Scorecard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

class GameEntryView extends StatefulWidget {
  const GameEntryView({super.key});

  @override
  State<GameEntryView> createState() => _GameEntryViewState();
}

class _GameEntryViewState extends State<GameEntryView> {
  final List<HoleData> _roundData = List.generate(18, (_) => HoleData());
  int _currentHoleIndex = 0;

  late TextEditingController _courseNameController;
  late TextEditingController _parController;
  late TextEditingController _strokesController;
  late TextEditingController _puttsController;

  late FocusNode _parFocusNode;
  late FocusNode _strokesFocusNode;
  late FocusNode _puttsFocusNode;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _courseNameController = TextEditingController();
    _parController = TextEditingController();
    _strokesController = TextEditingController();
    _puttsController = TextEditingController();

    _parFocusNode = FocusNode();
    _strokesFocusNode = FocusNode();
    _puttsFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _parController.dispose();
    _strokesController.dispose();
    _puttsController.dispose();

    _parFocusNode.dispose();
    _strokesFocusNode.dispose();
    _puttsFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _saveCurrentHoleData() {
    final currentData = _roundData[_currentHoleIndex];
    currentData.par = _parController.text;
    currentData.strokes = _strokesController.text;
    currentData.putts = _puttsController.text;
    currentData.fir = firValue;
    currentData.gir = girValue;
  }

  void _loadHoleData(int holeIndex) {
    final holeData = _roundData[holeIndex];
    _parController.text = holeData.par;
    _strokesController.text = holeData.strokes;
    _puttsController.text = holeData.putts;
    firValue = holeData.fir;
    girValue = holeData.gir;
  }

  void _nextHole() {
    if (_currentHoleIndex < 17) {
      _saveCurrentHoleData();
      setState(() {
        _currentHoleIndex++;
        _loadHoleData(_currentHoleIndex);
      });
    }
  }

  void _previousHole() {
    if (_currentHoleIndex > 0) {
      _saveCurrentHoleData();
      setState(() {
        _currentHoleIndex--;
        _loadHoleData(_currentHoleIndex);
      });
    }
  }

  String firValue = 'N/A';
  String girValue = 'N/A';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _courseNameController,
            decoration: InputDecoration(
              hintText: 'Enter Course Name',
              hintStyle: TextStyle(color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              filled: true,
              fillColor: Colors.grey[200],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (_currentHoleIndex > 0)
                IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: _previousHole)
              else
                const SizedBox(width: 48),
              Text('Hole ${_currentHoleIndex + 1}',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              if (_currentHoleIndex < 17)
                IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: _nextHole)
              else
                const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          _buildInputRow(
              label: 'Par',
              controller: _parController,
              focusNode: _parFocusNode),
          _buildInputRow(
              label: 'Strokes',
              controller: _strokesController,
              focusNode: _strokesFocusNode),
          _buildInputRow(
              label: 'Putts',
              controller: _puttsController,
              focusNode: _puttsFocusNode),
          const SizedBox(height: 16),
          _buildSegmentedControl('FIR', ['Yes', 'N/A', 'No'], firValue,
              (newValue) {
            setState(() => firValue = newValue!);
          }),
          const SizedBox(height: 8),
          _buildSegmentedControl('GIR', ['Yes', 'N/A', 'No'], girValue,
              (newValue) {
            setState(() => girValue = newValue!);
          }),
          const Spacer(),
          Container(
            height: 50,
            width: double.infinity,
            color: Colors.grey[300],
            child: const Center(
              child: Text('Banner Ad Placeholder'),
            ),
          )
        ],
      ),
    );
  }

  // New, simpler helper widget that returns the correct border decoration
  Widget _buildScoreIndicator() {
    final int? par = int.tryParse(_parController.text);
    final int? strokes = int.tryParse(_strokesController.text);

    if (par == null || strokes == null || strokes == 0) {
      return const SizedBox.shrink(); // Return an empty widget
    }

    final int score = strokes - par;
    Color borderColor = Colors.transparent;
    BoxShape shape = BoxShape.rectangle;
    bool isDouble = false;

    if (score == -1) {
      // Birdie
      borderColor = Colors.green;
      shape = BoxShape.circle;
    } else if (score <= -2) {
      // Eagle
      borderColor = Colors.green;
      shape = BoxShape.circle;
      isDouble = true;
    } else if (score == 1) {
      // Bogey
      borderColor = Colors.red;
    } else if (score >= 2) {
      // Double Bogey
      borderColor = Colors.red;
      isDouble = true;
    } else {
      return const SizedBox.shrink(); // No indicator for Par
    }

    // This is the widget for a single outline
    Widget singleBorder = Container(
      decoration: BoxDecoration(
        shape: shape,
        border: Border.all(color: borderColor, width: 2.0),
      ),
    );

    // If it's a double, we wrap the single border in another one
    if (isDouble) {
      return Container(
        padding: const EdgeInsets.all(3.0), // Space between borders
        decoration: BoxDecoration(
          shape: shape,
          border: Border.all(color: borderColor, width: 2.0),
        ),
        child: singleBorder,
      );
    }

    return singleBorder;
  }

  Widget _buildInputRow(
      {required String label,
      required TextEditingController controller,
      required FocusNode focusNode}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),

          // We use a Stack to layer the indicator ON TOP of the TextField
          SizedBox(
            width: 60,
            height: 48,
            child: Stack(
              children: [
                // Layer 1: The TextField is always visible
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    if (label == 'Par') ParInputFormatter(),
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(
                        label == 'Strokes' ? 2 : 1),
                  ],
                  onChanged: (value) {
                    setState(() {});
                    if (label == 'Par' && value.isNotEmpty) {
                      _strokesFocusNode.requestFocus();
                    } else if (label == 'Strokes') {
                      _debounce?.cancel();
                      if (value.isNotEmpty) {
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
                ),
                // Layer 2: The score indicator is drawn on top
                if (label == 'Strokes') _buildScoreIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl(String title, List<String> options,
      String? groupValue, ValueChanged<String?> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SegmentedButton<String>(
          segments: options
              .map((value) =>
                  ButtonSegment<String>(value: value, label: Text(value)))
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
    );
  }
}
