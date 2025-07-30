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
    _initializeDefaultCourses(); // NEW: Create sample courses on first run
  }

  Future<void> _checkForRoundInProgress() async {
    final hasRound = await StorageService.hasRoundInProgress();
    setState(() {
      _hasRoundInProgress = hasRound;
      _isLoading = false;
    });
  }

  // NEW: Create default courses on first app launch
  Future<void> _initializeDefaultCourses() async {
    try {
      await StorageService.createDefaultCourses();
    } catch (e) {
      // Removed debug print for production
    }
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
        title: const Text('Golflytics'),
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
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.green[700]!),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Loading Golflytics...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Preparing your golf data',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
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
                  _buildMenuButton(
                    context,
                    text: 'Saved Stats',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SavedStatsScreen(),
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
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No saved courses available. Create a course first!',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    if (mounted) {
      final selectedCourse = await showDialog<SavedCourse>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.golf_course, color: Colors.green[700]),
              const SizedBox(width: 12),
              const Text(
                'Select a Course',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
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
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.golf_course,
            color: Colors.green[700],
            size: 24,
          ),
        ),
        title: Text(
          course.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(Icons.flag, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Par ${course.totalPar}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _formatDate(course.lastPlayed),
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[700],
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 20,
          ),
        ),
        onTap: () => Navigator.of(context).pop(course),
      ),
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.green[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
          elevation: 3,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (text.contains('🏌️')) ...[
              const Icon(Icons.play_arrow, size: 24),
              const SizedBox(width: 8),
            ] else if (text.contains('New')) ...[
              const Icon(Icons.add_circle_outline, size: 24),
              const SizedBox(width: 8),
            ] else if (text.contains('Play Saved')) ...[
              const Icon(Icons.golf_course, size: 24),
              const SizedBox(width: 8),
            ] else if (text.contains('Manage')) ...[
              const Icon(Icons.settings_outlined, size: 24),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                text.replaceAll('🏌️ ', ''),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
