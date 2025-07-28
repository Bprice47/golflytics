# 🏌️ Golflytics - Professional Golf Tracking App

> **A comprehensive Flutter-based golf scorecard and statistics tracking application with advanced features for serious golfers.**

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![iOS](https://img.shields.io/badge/iOS-12.0+-silver.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 📱 Features

### 🎯 **Core Functionality**
- **Smart Round Resume** - Never lose your progress with automatic round saving and orange resume button
- **Saved Course Library** - Create and manage your favorite courses with 18-hole par layouts
- **One-Tap Course Selection** - Auto-populate all pars instantly from your saved courses
- **Real-Time Auto-Save** - Every stroke, putt, and stat automatically saved as you play

### 📊 **Advanced Statistics**
- **Current Round Stats** - Live scoring average, putting average, FIR/GIR percentages
- **Scorecard View** - Professional golf scorecard with visual score indicators (birdies, eagles, bogeys)
- **Historical Analysis** - Last 10 rounds and lifetime statistics with course-specific filtering
- **Performance Tracking** - Holes-in-one, eagles, birdies, pars, bogeys, and worse

### 🎨 **User Experience**
- **Swipe Navigation** - Intuitive hole-to-hole navigation with gesture controls
- **Visual Score Indicators** - Traditional golf scorecard symbols (circles for birdies, squares for bogeys)
- **Professional UI** - Clean 4-tab interface (Entry/Scorecard/Stats/Calendar)
- **Mobile Optimized** - Built for on-course use with offline functionality

## 🚀 Screenshots

*Screenshots coming soon...*

## 🛠️ Technical Stack

- **Framework:** Flutter 3.0+
- **Language:** Dart
- **Platform:** iOS (Android support ready)
- **Storage:** SharedPreferences (local device storage)
- **Architecture:** StatefulWidget with clean separation of concerns
- **Data Models:** JSON serialization for rounds and courses

## 📋 Installation

### Prerequisites
- Flutter SDK 3.0+
- Xcode 12+ (for iOS development)
- iOS 12.0+ device or simulator

### Development Setup
```bash
# Clone the repository
git clone https://github.com/Bprice47/golflytics.git
cd golflytics

# Install dependencies
flutter pub get

# Run on iOS simulator
flutter run

# Build for iOS device
flutter build ios --release
```

### iOS Deployment
```bash
# Create IPA for distribution
flutter build ipa

# Install directly to connected device
flutter install
```

## 🏌️ How to Use

### Starting a New Round
1. **New Round** - Enter course details manually and start tracking
2. **Play Saved Course** - Select from your course library for instant par setup
3. **Resume Round** - Continue any round in progress (appears as orange button)

### During Your Round
- **Navigate Holes** - Swipe left/right or use arrow buttons
- **Enter Scores** - Tap par, strokes, putts fields
- **Track Stats** - Mark Fairways in Regulation (FIR) and Greens in Regulation (GIR)
- **Auto-Save** - Everything saves automatically as you play

### After Your Round
- **Complete Round** - Finish button appears on hole 18
- **Save to History** - Add to your permanent record
- **View Stats** - Analyze performance in Stats tab

## 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── round.dart           # Data models (SavedRound, SavedCourse, HoleData)
├── screens/
│   ├── home_screen.dart     # Main navigation and resume functionality
│   ├── new_game_screen.dart # Core game interface with 4-tab navigation
│   ├── saved_courses_screen.dart  # Course management
│   └── saved_rounds_screen.dart   # Round history
└── services/
    └── storage_service.dart # Data persistence and management
```

## 🎯 Key Features Deep Dive

### Smart Course Management
- **One-Time Setup** - Create courses once, use forever
- **Auto-Population** - Select saved course → all 18 pars instantly filled
- **Usage Tracking** - Tracks play count and last played date
- **Easy Management** - Add, edit, delete courses with intuitive interface

### Advanced Round Resume
- **Crash Protection** - App crashes? Your round is safe
- **Cross-Session** - Start round, close app, resume later
- **Visual Indicators** - Orange resume button when round in progress
- **Smart Conflict Resolution** - Handles starting new rounds when one exists

### Professional Statistics
- **Real-Time Calculations** - Stats update as you play
- **Multiple Views** - Current round, last 10, lifetime stats
- **Course-Specific Analysis** - Filter stats by specific courses
- **Traditional Golf Metrics** - All standard golf statistics tracked

## 🔧 Configuration

### Course Setup
```dart
// Example saved course structure
SavedCourse(
  name: "Pebble Beach Golf Links",
  pars: [4, 5, 4, 4, 3, 5, 3, 4, 4, 4, 4, 3, 4, 5, 4, 4, 3, 5],
  dateCreated: DateTime.now(),
  lastPlayed: DateTime.now(),
);
```

### Round Data
```dart
// Example hole data structure
HoleData(
  par: "4",
  strokes: "5",
  putts: "2",
  fir: "Yes", // Fairway in Regulation
  gir: "No",  // Green in Regulation
);
```

## 🤝 Contributing

This is a personal project, but suggestions and feedback are welcome!

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📈 Development Roadmap

### Upcoming Features
- [ ] **Calendar Integration** - Round scheduling and history calendar
- [ ] **Cloud Sync** - Backup rounds to cloud storage
- [ ] **Course Database** - Public course database integration
- [ ] **Advanced Analytics** - Trend analysis and improvement suggestions
- [ ] **Social Features** - Share rounds with friends
- [ ] **Apple Watch Support** - Quick score entry from wrist

### Technical Improvements
- [ ] **Android Support** - Full Android compatibility
- [ ] **Performance Optimization** - Faster loading and smoother animations
- [ ] **Accessibility** - VoiceOver and accessibility improvements
- [ ] **Unit Tests** - Comprehensive test coverage

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Flutter](https://flutter.dev/) - Google's UI toolkit
- Inspired by traditional golf scorecards and modern mobile UX
- Developed for golfers who demand professional-grade tracking

---

## 💬 Contact

**Bprice47** - [@Bprice47](https://github.com/Bprice47)

**Project Link:** [https://github.com/Bprice47/golflytics](https://github.com/Bprice47/golflytics)

---

*Built with ❤️ for the golf community*

**⭐ Star this repo if you found it helpful!**
