// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:golf_app_final/screens/new_game_screen.dart';
import 'package:golf_app_final/screens/saved_courses_screen.dart';
import '../services/storage_service.dart';
import '../models/round.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasRoundInProgress = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkForRoundInProgress();
  }

  Future<void> _checkForRoundInProgress() async {
    final hasRound = await StorageService.hasRoundInProgress();
    print('DEBUG: hasRoundInProgress = $hasRound'); // Debug line
    setState(() {
      _hasRoundInProgress = hasRound;
      _isLoading = false;
    });
  }

  Future<void> _startNewRound() async {
    // If there's a round in progress, ask user if they want to discard it
    if (_hasRoundInProgress) {
      final shouldDiscard = await _showDiscardRoundDialog();
      if (shouldDiscard == true) {
        await StorageService.clearCurrentRound();
        setState(() {
          _hasRoundInProgress = false;
        });
      } else {
        return; // User cancelled
      }
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NewGameScreen()),
      );
    }
  }

  Future<void> _resumeRound() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NewGameScreen(resumeRound: true),
      ),
    );
  }

  Future<bool?> _showDiscardRoundDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Round in Progress'),
        content: const Text(
          'You have a round in progress. Starting a new round will discard your current round data.\n\nAre you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Discard & Start New'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {},
        ),
        title: const Text('Golf App'),
        centerTitle: true,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Show Resume Game button if there's a round in progress
                  if (_hasRoundInProgress) ...[
                    _buildMenuButton(
                      context,
                      text: '🏌️ Resume Round',
                      backgroundColor: Colors.orange,
                      onPressed: _resumeRound,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildMenuButton(
                    context,
                    text: _hasRoundInProgress
                        ? 'Start New Round'
                        : 'New Round/Course',
                    onPressed: _startNewRound,
                  ),
                  const SizedBox(height: 16),
                  _buildMenuButton(
                    context,
                    text: 'Play Saved Course',
                    onPressed: _showCourseSelectionDialog,
                  ),
                  const SizedBox(height: 16),
                  _buildMenuButton(
                    context,
                    text: 'Manage Courses',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SavedCoursesScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Future<void> _showCourseSelectionDialog() async {
    final courses = await StorageService.getSavedCourses();

    if (courses.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No saved courses available. Create a course first!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (mounted) {
      final selectedCourse = await showDialog<SavedCourse>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select a Course'),
          content: SizedBox(
            width: double.maxFinite,
            child: courses.length > 5
                ? SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: courses.length,
                      itemBuilder: (context, index) =>
                          _buildCourseListTile(courses[index]),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: courses
                        .map((course) => _buildCourseListTile(course))
                        .toList(),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (selectedCourse != null) {
        await _startRoundWithCourse(selectedCourse);
      }
    }
  }

  Widget _buildCourseListTile(SavedCourse course) {
    return ListTile(
      title: Text(course.name),
      subtitle: Text(
          'Par ${course.totalPar} • Last played: ${_formatDate(course.lastPlayed)}'),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () => Navigator.of(context).pop(course),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _startRoundWithCourse(SavedCourse course) async {
    // If there's a round in progress, ask user if they want to discard it
    if (_hasRoundInProgress) {
      final shouldDiscard = await _showDiscardRoundDialog();
      if (shouldDiscard == true) {
        await StorageService.clearCurrentRound();
        setState(() {
          _hasRoundInProgress = false;
        });
      } else {
        return; // User cancelled
      }
    }

    // Update the course's last played date and times played
    final updatedCourse = course.copyWith(
      lastPlayed: DateTime.now(),
      timesPlayed: course.timesPlayed + 1,
    );
    await StorageService.saveCourse(updatedCourse);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewGameScreen(savedCourse: updatedCourse),
        ),
      );
    }
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required String text,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      child: Text(text),
    );
  }
}
