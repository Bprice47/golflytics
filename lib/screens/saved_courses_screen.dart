// lib/screens/saved_courses_screen.dart

import 'package:flutter/material.dart';
import '../models/round.dart';
import '../services/storage_service.dart';

class SavedCoursesScreen extends StatefulWidget {
  const SavedCoursesScreen({super.key});

  @override
  State<SavedCoursesScreen> createState() => _SavedCoursesScreenState();
}

class _SavedCoursesScreenState extends State<SavedCoursesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        title: const Text('My Courses'),
        actions: [
          IconButton(
            onPressed: () => _showAddCourseDialog(),
            icon: const Icon(Icons.add),
            tooltip: 'Add Course',
          ),
        ],
      ),
      body: FutureBuilder<List<SavedCourse>>(
        future: StorageService.getSavedCourses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading courses: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final courses = snapshot.data ?? [];

          if (courses.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {}); // Refresh the FutureBuilder
            },
            child: ListView.builder(
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      child: Text(
                        course.name.isNotEmpty
                            ? course.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      course.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Par ${course.totalPar}'),
                        Text(
                          'Front 9: ${course.frontNinePar} | Back 9: ${course.backNinePar}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        if (course.timesPlayed > 0)
                          Text(
                            'Played ${course.timesPlayed} time${course.timesPlayed == 1 ? '' : 's'}',
                            style: TextStyle(
                              color: Colors.green[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showEditCourseDialog(course);
                            break;
                          case 'delete':
                            _showDeleteCourseDialog(course);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _selectCourse(course),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.golf_course,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Courses Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add your first course to get started.\nYou can enter the par for each hole to save time on future rounds.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showAddCourseDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Course'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectCourse(SavedCourse course) {
    // When a course is selected, navigate back to home and start a new game with this course
    Navigator.of(context).pop(); // Go back to home screen
    // TODO: We'll need to pass the course data to the new game screen
    // For now, just show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Selected "${course.name}" - Course loading coming soon!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showAddCourseDialog() {
    _showCourseDialog();
  }

  void _showEditCourseDialog(SavedCourse course) {
    _showCourseDialog(existingCourse: course);
  }

  void _showCourseDialog({SavedCourse? existingCourse}) {
    final nameController =
        TextEditingController(text: existingCourse?.name ?? '');
    final parControllers = List.generate(
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
                'Enter Par for Each Hole:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Front 9
                      const Text(
                        'Front 9',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: 9,
                        itemBuilder: (context, index) {
                          return TextField(
                            controller: parControllers[index],
                            decoration: InputDecoration(
                              labelText: 'Hole ${index + 1}',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Back 9
                      const Text(
                        'Back 9',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: 9,
                        itemBuilder: (context, index) {
                          final holeNumber = index + 10;
                          return TextField(
                            controller: parControllers[index + 9],
                            decoration: InputDecoration(
                              labelText: 'Hole $holeNumber',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                          );
                        },
                      ),
                    ],
                  ),
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
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a course name'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final pars = <int>[];
              for (final controller in parControllers) {
                final par = int.tryParse(controller.text);
                if (par == null || par < 3 || par > 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Please enter valid par values (3-6) for all holes'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                pars.add(par);
              }

              final course = SavedCourse(
                id: existingCourse?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                name: name,
                pars: pars,
                dateCreated: existingCourse?.dateCreated ?? DateTime.now(),
                lastPlayed: existingCourse?.lastPlayed ?? DateTime.now(),
                timesPlayed: existingCourse?.timesPlayed ?? 0,
              );

              final success = await StorageService.saveCourse(course);

              if (mounted) {
                Navigator.of(context).pop();
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
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
            child:
                Text(existingCourse == null ? 'Add Course' : 'Update Course'),
          ),
        ],
      ),
    );
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
              final success = await StorageService.deleteCourse(course.id);
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
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
