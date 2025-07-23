// lib/screens/new_game_screen.dart

import 'package:flutter/material.dart';

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
      // We add resizeToAvoidBottomInset: false to prevent the UI from resizing when the keyboard appears.
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
  int _currentHole = 1;
  String? girValue = 'N/A';
  String? firValue = 'N/A';

  void _nextHole() {
    if (_currentHole < 18) {
      setState(() {
        _currentHole++;
      });
    }
  }

  void _previousHole() {
    if (_currentHole > 1) {
      setState(() {
        _currentHole--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // We removed the SingleChildScrollView to create a fixed layout
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
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
              if (_currentHole > 1)
                IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: _previousHole)
              else
                const SizedBox(width: 48),
              Text('Hole $_currentHole',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              if (_currentHole < 18)
                IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: _nextHole)
              else
                const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          _buildInputRow(label: 'Par'),
          _buildInputRow(label: 'Strokes'),
          _buildInputRow(label: 'Putts'),
          const SizedBox(height: 16),

          // Redesigned FIR/GIR controls
          _buildSegmentedControl('FIR', ['Yes', 'N/A', 'No'], firValue,
              (newValue) {
            setState(() => firValue = newValue);
          }),
          const SizedBox(height: 8),
          _buildSegmentedControl('GIR', ['Yes', 'N/A', 'No'], girValue,
              (newValue) {
            setState(() => girValue = newValue);
          }),

          // Spacer pushes the ad to the bottom
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

  Widget _buildInputRow({required String label}) {
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
            child: const TextField(
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
    );
  }

  // Helper for the segmented controls is now a more compact Row
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
