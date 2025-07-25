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

  final List<HoleData> _roundData = List.generate(18, (_) => HoleData());
  int _currentHoleIndex = 0;
  String _courseName = '';

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _updateCourseName(String name) {
    setState(() {
      _courseName = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screenViews = <Widget>[
      GameEntryView(
        roundData: _roundData,
        currentHoleIndex: _currentHoleIndex,
        onHoleChanged: (newIndex) {
          setState(() {
            _currentHoleIndex = newIndex;
          });
        },
        onCourseNameChanged: _updateCourseName,
      ),
      ScorecardView(roundData: _roundData, courseName: _courseName),
      const Center(child: Text('Stats View')),
      const Center(child: Text('Calendar View')),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        title: const Text(
          'Golf Trainer',
          style: TextStyle(
              fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
      body: Column(
        children: [
          Expanded(
            child: screenViews.elementAt(_selectedIndex),
          ),
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.green[700],
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
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        onTap: _onItemTapped,
      ),
    );
  }
}

// --- GAME ENTRY VIEW ---
class GameEntryView extends StatefulWidget {
  final List<HoleData> roundData;
  final int currentHoleIndex;
  final ValueChanged<int> onHoleChanged;
  final ValueChanged<String>? onCourseNameChanged;

  const GameEntryView({
    super.key,
    required this.roundData,
    required this.currentHoleIndex,
    required this.onHoleChanged,
    this.onCourseNameChanged,
  });

  @override
  State<GameEntryView> createState() => _GameEntryViewState();
}

class _GameEntryViewState extends State<GameEntryView> {
  late TextEditingController _courseNameController;
  late TextEditingController _parController;
  late TextEditingController _strokesController;
  late TextEditingController _puttsController;

  late FocusNode _parFocusNode;
  late FocusNode _strokesFocusNode;
  late FocusNode _puttsFocusNode;
  Timer? _debounce;

  String firValue = 'N/A';
  String girValue = 'N/A';

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

    _loadHoleData(widget.currentHoleIndex);
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
  }

  void _loadHoleData(int holeIndex) {
    final holeData = widget.roundData[holeIndex];
    _parController.text = holeData.par;
    _strokesController.text = holeData.strokes;
    _puttsController.text = holeData.putts;
    setState(() {
      firValue = holeData.fir;
      girValue = holeData.gir;
    });
  }

  void _nextHole() {
    if (widget.currentHoleIndex < 17) {
      _saveCurrentHoleData();
      widget.onHoleChanged(widget.currentHoleIndex + 1);
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
            onChanged: (value) {
              widget.onCourseNameChanged?.call(value);
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (widget.currentHoleIndex > 0)
                IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: _previousHole)
              else
                const SizedBox(width: 48),
              Text('Hole ${widget.currentHoleIndex + 1}',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              if (widget.currentHoleIndex < 17)
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
        ],
      ),
    );
  }

  // --- THIS IS THE SIMPLIFIED AND CORRECTED INDICATOR LOGIC ---
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
          SizedBox(
            width: 60,
            height: 48,
            child: (label == 'Strokes')
                ? _buildStrokesInput()
                : _buildRegularInput(controller, focusNode, label),
          ),
        ],
      ),
    );
  }

  // Build regular input field for Par and Putts
  Widget _buildRegularInput(
      TextEditingController controller, FocusNode focusNode, String label) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      keyboardType: TextInputType.number,
      inputFormatters: [
        if (label == 'Par') ParInputFormatter(),
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(label == 'Strokes' ? 2 : 1),
      ],
      onChanged: (value) {
        setState(() {});
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
                  color: Colors.transparent),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              onChanged: (value) {
                setState(() {});
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
                  color: Colors.black),
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
                        color: Colors.transparent),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    onChanged: (value) {
                      setState(() {});
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
                        color: Colors.black),
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

// --- SCORECARD VIEW (This part is correct and unchanged) ---
class ScorecardView extends StatelessWidget {
  final List<HoleData> roundData;
  final String courseName;
  const ScorecardView(
      {super.key, required this.roundData, this.courseName = ''});

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
            backgroundColor: Colors.grey.shade200),
        _buildCell(
            text: 'Par',
            width: 75,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.grey.shade100),
        _buildCell(
            text: 'Score',
            width: 75,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.grey.shade100),
        _buildCell(
            text: 'Putts',
            width: 75,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.grey.shade100),
        _buildCell(
            text: 'FIR',
            width: 75,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.grey.shade100),
        _buildCell(
            text: 'GIR',
            width: 75,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.grey.shade100),
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
              getValue: (hole) => hole.strokes, showScoreIndicator: true),
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
      cells.add(_buildCell(text: '$i', fontWeight: FontWeight.bold));
    }
    cells.add(_buildCell(
        text: 'Out',
        width: 60,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.grey.shade200));
    for (int i = 10; i <= 18; i++) {
      cells.add(_buildCell(text: '$i', fontWeight: FontWeight.bold));
    }
    cells.add(_buildCell(
        text: 'In',
        width: 60,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.grey.shade200));
    cells.add(_buildCell(
        text: 'Total',
        width: 70,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.grey.shade300));
    return Row(children: cells);
  }

  Widget _buildDataRow(
      {required String Function(HoleData) getValue,
      bool showScoreIndicator = false}) {
    List<Widget> cells = [];
    List<int> frontNine = [];
    List<int> backNine = [];

    for (int i = 0; i < 9; i++) {
      final par = int.tryParse(roundData[i].par) ?? 0;
      final value = int.tryParse(getValue(roundData[i])) ?? 0;
      cells.add(showScoreIndicator
          ? _buildScoreCell(par, value)
          : _buildCell(text: value == 0 ? '' : '$value'));
      if (value > 0) frontNine.add(value);
    }
    cells.add(_buildCell(
        text: '${frontNine.fold(0, (a, b) => a + b)}',
        width: 60,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.grey.shade200));

    for (int i = 9; i < 18; i++) {
      final par = int.tryParse(roundData[i].par) ?? 0;
      final value = int.tryParse(getValue(roundData[i])) ?? 0;
      cells.add(showScoreIndicator
          ? _buildScoreCell(par, value)
          : _buildCell(text: value == 0 ? '' : '$value'));
      if (value > 0) backNine.add(value);
    }
    cells.add(_buildCell(
        text: '${backNine.fold(0, (a, b) => a + b)}',
        width: 60,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.grey.shade200));
    cells.add(_buildCell(
        text:
            '${frontNine.fold(0, (a, b) => a + b) + backNine.fold(0, (a, b) => a + b)}',
        width: 70,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.grey.shade300));

    return Row(children: cells);
  }

  Widget _buildScoreCell(int par, int score) {
    if (score == 0) return _buildCell();

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
      child: Stack(
        alignment: Alignment.center,
        children: [
          scoreText,
          if (indicator != null) indicator,
        ],
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
      cells.add(_buildCell(
          text: value == 'Yes' ? '✓' : (value == 'No' ? 'X' : 'N/A')));
    }
    cells.add(_buildCell(
        text: '$frontNineCount',
        width: 60,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.grey.shade200));

    for (int i = 9; i < 18; i++) {
      final value = getValue(roundData[i]);
      if (value == 'Yes') backNineCount++;
      cells.add(_buildCell(
          text: value == 'Yes' ? '✓' : (value == 'No' ? 'X' : 'N/A')));
    }
    cells.add(_buildCell(
        text: '$backNineCount',
        width: 60,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.grey.shade200));
    cells.add(_buildCell(
        text: '${frontNineCount + backNineCount}',
        width: 70,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.grey.shade300));

    return Row(children: cells);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate running totals
    int outPar = 0, outScore = 0, inPar = 0, inScore = 0;

    // Front nine totals
    for (int i = 0; i < 9; i++) {
      final par = int.tryParse(roundData[i].par) ?? 0;
      final score = int.tryParse(roundData[i].strokes) ?? 0;
      if (par > 0) outPar += par;
      if (score > 0) outScore += score;
    }

    // Back nine totals
    for (int i = 9; i < 18; i++) {
      final par = int.tryParse(roundData[i].par) ?? 0;
      final score = int.tryParse(roundData[i].strokes) ?? 0;
      if (par > 0) inPar += par;
      if (score > 0) inScore += score;
    }

    final totalPar = outPar + inPar;
    final totalScore = outScore + inScore;
    final totalToPar = totalScore > 0 ? totalScore - totalPar : 0;

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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                const Text(
                  'Score Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const Text('Out',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                            '$outScore${outPar > 0 ? " (${outScore - outPar > 0 ? '+' : ''}${outScore - outPar})" : ""}'),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('In',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                            '$inScore${inPar > 0 ? " (${inScore - inPar > 0 ? '+' : ''}${inScore - inPar})" : ""}'),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Total',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '$totalScore${totalPar > 0 ? " (${totalToPar > 0 ? '+' : ''}$totalToPar)" : ""}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: totalToPar > 0
                                ? Colors.red
                                : (totalToPar < 0
                                    ? Colors.green
                                    : Colors.black),
                          ),
                        ),
                      ],
                    ),
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
