// lib/screens/saved_rounds_screen.dart
// NEW FILE - Screen to view saved rounds

import 'package:flutter/material.dart';
import '../models/round.dart';
import '../services/storage_service.dart';

class SavedRoundsScreen extends StatefulWidget {
  const SavedRoundsScreen({super.key});

  @override
  State<SavedRoundsScreen> createState() => _SavedRoundsScreenState();
}

class _SavedRoundsScreenState extends State<SavedRoundsScreen> {
  List<SavedRound> _savedRounds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRounds();
  }

  Future<void> _loadRounds() async {
    setState(() => _isLoading = true);
    final rounds = await StorageService.getSavedRounds();
    setState(() {
      _savedRounds = rounds.reversed.toList(); // Most recent first
      _isLoading = false;
    });
  }

  Future<void> _deleteRound(String roundId) async {
    final success = await StorageService.deleteRound(roundId);
    if (success) {
      _loadRounds(); // Refresh the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Round deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Rounds'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedRounds.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.golf_course, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No saved rounds yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Complete a round and save it to see it here',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _savedRounds.length,
                  itemBuilder: (context, index) {
                    final round = _savedRounds[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(round.courseName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${round.dateTime.month}/${round.dateTime.day}/${round.dateTime.year}',
                            ),
                            Text('Total Strokes: ${round.totalStrokes}'),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Text('View Details'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'view') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      RoundDetailScreen(round: round),
                                ),
                              );
                            } else if (value == 'delete') {
                              _showDeleteDialog(round);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showDeleteDialog(SavedRound round) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Round'),
        content: Text('Delete round at ${round.courseName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRound(round.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class RoundDetailScreen extends StatelessWidget {
  final SavedRound round;

  const RoundDetailScreen({super.key, required this.round});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(round.courseName),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Round Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Round Summary',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                        'Date: ${round.dateTime.month}/${round.dateTime.day}/${round.dateTime.year}'),
                    Text('Total Strokes: ${round.totalStrokes}'),
                    Text('Total Putts: ${round.totalPutts}'),
                    Text('Fairways Hit: ${round.fairwaysHit}/18'),
                    Text(
                        'Greens in Regulation: ${round.greensInRegulation}/18'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Hole by Hole
            Text(
              'Hole by Hole',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: round.holes.length,
              itemBuilder: (context, index) {
                final hole = round.holes[index];
                return Card(
                  child: ListTile(
                    title: Text('Hole ${index + 1}'),
                    subtitle: Text(
                      'Par: ${hole.par}, Strokes: ${hole.strokes}, Putts: ${hole.putts}',
                    ),
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('FIR: ${hole.fir}'),
                        Text('GIR: ${hole.gir}'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
