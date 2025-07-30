// lib/services/storage_service.dart
// NEW FILE - Service for saving and loading golf rounds

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/round.dart';
import '../screens/new_game_screen.dart';

class StorageService {
  static const String _roundsKey = 'saved_golf_rounds';
  static const String _coursesKey = 'saved_golf_courses';
  static const String _currentRoundKey = 'current_round_in_progress';

  // Convert existing game data to saveable format
  static SavedRound convertToSavedRound(
    List<HoleData> roundData,
    String courseName,
  ) {
    final holes = roundData
        .map((holeData) => SavedHole(
              par: holeData.par,
              strokes: holeData.strokes,
              putts: holeData.putts,
              fir: holeData.fir,
              gir: holeData.gir,
            ))
        .toList();

    return SavedRound(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      courseName: courseName.isEmpty ? 'Unnamed Course' : courseName,
      dateTime: DateTime.now(),
      holes: holes,
    );
  }

  // COURSE MANAGEMENT METHODS

  // Save a course layout
  static Future<bool> saveCourse(SavedCourse course) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingCourses = await getSavedCourses();

      // Check if course with same name exists
      final existingIndex = existingCourses
          .indexWhere((c) => c.name.toLowerCase() == course.name.toLowerCase());

      if (existingIndex >= 0) {
        // Update existing course
        existingCourses[existingIndex] = course;
      } else {
        // Add new course
        existingCourses.add(course);
      }

      final coursesJson = existingCourses.map((c) => c.toJson()).toList();
      await prefs.setString(_coursesKey, jsonEncode(coursesJson));
      return true;
    } catch (e) {
      // Log error for debugging, but don't print in production
      // // Removed debug print: 'Error saving course: $e'
      return false;
    }
  }

  // Get all saved courses
  static Future<List<SavedCourse>> getSavedCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final coursesString = prefs.getString(_coursesKey);

      if (coursesString == null) return [];

      final coursesList = jsonDecode(coursesString) as List;
      return coursesList.map((json) => SavedCourse.fromJson(json)).toList();
    } catch (e) {
      // Removed debug print: 'Error loading courses: $e'
      return [];
    }
  }

  // Create course from round data
  static SavedCourse createCourseFromRoundData(
    String courseName,
    List<HoleData> roundData,
  ) {
    final pars = roundData.map((hole) => int.tryParse(hole.par) ?? 4).toList();

    return SavedCourse(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: courseName.isEmpty ? 'Unnamed Course' : courseName,
      pars: pars,
      dateCreated: DateTime.now(),
      lastPlayed: DateTime.now(),
    );
  }

  // Auto-save course when completing a round
  static Future<bool> autoSaveCourseFromRound(
    String courseName,
    List<HoleData> roundData,
  ) async {
    if (courseName.isEmpty) return false;

    // Check if all pars are filled
    final hasAllPars = roundData
        .every((hole) => hole.par.isNotEmpty && int.tryParse(hole.par) != null);

    if (!hasAllPars) return false;

    try {
      final existingCourses = await getSavedCourses();
      final existingCourse = existingCourses.firstWhere(
        (course) => course.name.toLowerCase() == courseName.toLowerCase(),
        orElse: () => SavedCourse(
          id: '',
          name: '',
          pars: [],
          dateCreated: DateTime.now(),
          lastPlayed: DateTime.now(),
        ),
      );

      if (existingCourse.id.isEmpty) {
        // New course - save it
        final newCourse = createCourseFromRoundData(courseName, roundData);
        return await saveCourse(newCourse);
      } else {
        // Existing course - update last played and times played
        final updatedCourse = existingCourse.copyWith(
          lastPlayed: DateTime.now(),
          timesPlayed: existingCourse.timesPlayed + 1,
        );
        return await saveCourse(updatedCourse);
      }
    } catch (e) {
      // Removed debug print: 'Error auto-saving course: $e'
      return false;
    }
  }

  // Delete a course
  static Future<bool> deleteCourse(String courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingCourses = await getSavedCourses();
      existingCourses.removeWhere((course) => course.id == courseId);

      final coursesJson = existingCourses.map((c) => c.toJson()).toList();
      await prefs.setString(_coursesKey, jsonEncode(coursesJson));
      return true;
    } catch (e) {
      // Removed debug print: 'Error deleting course: $e'
      return false;
    }
  }

  // Save a round
  static Future<bool> saveRound(SavedRound round) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingRounds = await getSavedRounds();
      existingRounds.add(round);

      final roundsJson = existingRounds.map((r) => r.toJson()).toList();
      await prefs.setString(_roundsKey, jsonEncode(roundsJson));

      // Auto-save the course layout if it has valid pars
      if (round.holes.isNotEmpty) {
        // Create HoleData objects for course saving
        final List<HoleData> holeDataList = round.holes.map((hole) {
          final holeData = HoleData();
          holeData.par = hole.par;
          holeData.strokes = hole.strokes;
          holeData.putts = hole.putts;
          holeData.fir = hole.fir;
          holeData.gir = hole.gir;
          return holeData;
        }).toList();

        await autoSaveCourseFromRound(round.courseName, holeDataList);
      }

      return true;
    } catch (e) {
      // Removed debug print: 'Error saving round: $e'
      return false;
    }
  }

  // Get all saved rounds
  static Future<List<SavedRound>> getSavedRounds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roundsString = prefs.getString(_roundsKey);

      if (roundsString == null) return [];

      final roundsList = jsonDecode(roundsString) as List;
      return roundsList.map((json) => SavedRound.fromJson(json)).toList();
    } catch (e) {
      // Removed debug print: 'Error loading rounds: $e'
      return [];
    }
  }

  // Delete a round
  static Future<bool> deleteRound(String roundId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingRounds = await getSavedRounds();
      existingRounds.removeWhere((round) => round.id == roundId);

      final roundsJson = existingRounds.map((r) => r.toJson()).toList();
      await prefs.setString(_roundsKey, jsonEncode(roundsJson));
      return true;
    } catch (e) {
      // Removed debug print: 'Error deleting round: $e'
      return false;
    }
  }

  // Clear all rounds (for testing)
  static Future<bool> clearAllRounds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_roundsKey);
      return true;
    } catch (e) {
      // Removed debug print: 'Error clearing rounds: $e'
      return false;
    }
  }

  // RESUME GAME FUNCTIONALITY

  // Save current round in progress
  static Future<bool> saveCurrentRound(
    List<HoleData> roundData,
    String courseName,
    int currentHoleIndex,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final currentRoundData = {
        'roundData': roundData
            .map((hole) => {
                  'par': hole.par,
                  'strokes': hole.strokes,
                  'putts': hole.putts,
                  'fir': hole.fir,
                  'gir': hole.gir,
                })
            .toList(),
        'courseName': courseName,
        'currentHoleIndex': currentHoleIndex,
        'lastSaved': DateTime.now().toIso8601String(),
      };

      await prefs.setString(_currentRoundKey, jsonEncode(currentRoundData));
      return true;
    } catch (e) {
      // Removed debug print: 'Error saving current round: $e'
      return false;
    }
  }

  // Load current round in progress
  static Future<Map<String, dynamic>?> getCurrentRound() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentRoundString = prefs.getString(_currentRoundKey);

      if (currentRoundString == null) return null;

      final currentRoundData = jsonDecode(currentRoundString);

      // Convert round data back to HoleData objects
      final List<dynamic> roundDataJson = currentRoundData['roundData'];
      final List<HoleData> roundData = roundDataJson.map((holeJson) {
        final hole = HoleData();
        hole.par = holeJson['par'] ?? '';
        hole.strokes = holeJson['strokes'] ?? '';
        hole.putts = holeJson['putts'] ?? '';
        hole.fir = holeJson['fir'] ?? 'N/A';
        hole.gir = holeJson['gir'] ?? 'N/A';
        return hole;
      }).toList();

      return {
        'roundData': roundData,
        'courseName': currentRoundData['courseName'] ?? '',
        'currentHoleIndex': currentRoundData['currentHoleIndex'] ?? 0,
        'lastSaved': currentRoundData['lastSaved'] ?? '',
      };
    } catch (e) {
      // Removed debug print: 'Error loading current round: $e'
      return null;
    }
  }

  // Check if there's a round in progress
  static Future<bool> hasRoundInProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_currentRoundKey);
    } catch (e) {
      // Removed debug print: 'Error checking for round in progress: $e'
      return false;
    }
  }

  // Clear current round (when round is completed or deliberately discarded)
  static Future<bool> clearCurrentRound() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentRoundKey);
      return true;
    } catch (e) {
      // Removed debug print: 'Error clearing current round: $e'
      return false;
    }
  }

  // NEW: Export all courses to JSON string for backup
  static Future<String?> exportCourses() async {
    try {
      final courses = await getSavedCourses();
      if (courses.isEmpty) return null;

      final exportData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'courses': courses.map((c) => c.toJson()).toList(),
      };

      return jsonEncode(exportData);
    } catch (e) {
      // Removed debug print: 'Error exporting courses: $e'
      return null;
    }
  }

  // NEW: Import courses from JSON string
  static Future<bool> importCourses(String jsonData) async {
    try {
      final importData = jsonDecode(jsonData) as Map<String, dynamic>;
      final coursesList = importData['courses'] as List;
      final courses =
          coursesList.map((json) => SavedCourse.fromJson(json)).toList();

      // Get existing courses
      final existingCourses = await getSavedCourses();

      // Merge courses (keep existing, add new ones)
      for (final newCourse in courses) {
        final existsIndex = existingCourses.indexWhere((existing) =>
            existing.name.toLowerCase() == newCourse.name.toLowerCase());

        if (existsIndex >= 0) {
          // Update existing course with newer data
          existingCourses[existsIndex] = newCourse;
        } else {
          // Add new course
          existingCourses.add(newCourse);
        }
      }

      // Save merged courses
      final prefs = await SharedPreferences.getInstance();
      final coursesJson = existingCourses.map((c) => c.toJson()).toList();
      await prefs.setString(_coursesKey, jsonEncode(coursesJson));

      return true;
    } catch (e) {
      // Removed debug print: 'Error importing courses: $e'
      return false;
    }
  }

  // NEW: Create default courses for first-time users
  static Future<bool> createDefaultCourses() async {
    try {
      final existingCourses = await getSavedCourses();
      if (existingCourses.isNotEmpty) return false; // Already has courses

      final defaultCourses = [
        SavedCourse(
          id: 'default_1',
          name: 'Sample Course - Easy',
          pars: [4, 4, 3, 5, 4, 3, 4, 5, 4, 4, 4, 3, 5, 4, 3, 4, 5, 4],
          dateCreated: DateTime.now(),
          lastPlayed: DateTime.now(),
          timesPlayed: 0,
        ),
        SavedCourse(
          id: 'default_2',
          name: 'Sample Course - Championship',
          pars: [4, 5, 3, 4, 4, 3, 5, 4, 4, 4, 5, 3, 4, 4, 3, 5, 4, 4],
          dateCreated: DateTime.now(),
          lastPlayed: DateTime.now(),
          timesPlayed: 0,
        ),
      ];

      for (final course in defaultCourses) {
        await saveCourse(course);
      }

      return true;
    } catch (e) {
      // Removed debug print: 'Error creating default courses: $e'
      return false;
    }
  }
}
