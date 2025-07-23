// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:golf_app_final/screens/new_game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMenuButton(
              context,
              text: 'New Game/Course',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NewGameScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildMenuButton(
              context,
              text: 'Resume Game',
              onPressed: () {
                // This now navigates to the game screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NewGameScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildMenuButton(
              context,
              text: 'Saved Courses',
              onPressed: () {},
            ),
            const SizedBox(height: 16),
            _buildMenuButton(
              context,
              text: 'Add/Edit Courses',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context,
      {required String text, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
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
