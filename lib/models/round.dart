// lib/models/round.dart
// NEW FILE - Data model for saving golf rounds

class SavedHole {
  final String par;
  final String strokes;
  final String putts;
  final String fir;
  final String gir;

  SavedHole({
    required this.par,
    required this.strokes,
    required this.putts,
    required this.fir,
    required this.gir,
  });

  Map<String, dynamic> toJson() {
    return {
      'par': par,
      'strokes': strokes,
      'putts': putts,
      'fir': fir,
      'gir': gir,
    };
  }

  factory SavedHole.fromJson(Map<String, dynamic> json) {
    return SavedHole(
      par: json['par'] ?? '',
      strokes: json['strokes'] ?? '',
      putts: json['putts'] ?? '',
      fir: json['fir'] ?? 'N/A',
      gir: json['gir'] ?? 'N/A',
    );
  }
}

class SavedRound {
  final String id;
  final String courseName;
  final DateTime dateTime;
  final List<SavedHole> holes;

  SavedRound({
    required this.id,
    required this.courseName,
    required this.dateTime,
    required this.holes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseName': courseName,
      'dateTime': dateTime.toIso8601String(),
      'holes': holes.map((hole) => hole.toJson()).toList(),
    };
  }

  factory SavedRound.fromJson(Map<String, dynamic> json) {
    return SavedRound(
      id: json['id'],
      courseName: json['courseName'],
      dateTime: DateTime.parse(json['dateTime']),
      holes: (json['holes'] as List)
          .map((holeJson) => SavedHole.fromJson(holeJson))
          .toList(),
    );
  }

  // Helper methods for stats
  int get totalStrokes {
    return holes
        .where((hole) => hole.strokes.isNotEmpty)
        .map((hole) => int.tryParse(hole.strokes) ?? 0)
        .fold(0, (sum, strokes) => sum + strokes);
  }

  int get totalPutts {
    return holes
        .where((hole) => hole.putts.isNotEmpty)
        .map((hole) => int.tryParse(hole.putts) ?? 0)
        .fold(0, (sum, putts) => sum + putts);
  }

  int get fairwaysHit {
    return holes.where((hole) => hole.fir == 'Yes').length;
  }

  int get greensInRegulation {
    return holes.where((hole) => hole.gir == 'Yes').length;
  }
}

// NEW: Course data model for saving course layouts
class SavedCourse {
  final String id;
  final String name;
  final List<int> pars; // 18 hole pars
  final DateTime dateCreated;
  final DateTime lastPlayed;
  final int timesPlayed;

  SavedCourse({
    required this.id,
    required this.name,
    required this.pars,
    required this.dateCreated,
    required this.lastPlayed,
    this.timesPlayed = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'pars': pars,
      'dateCreated': dateCreated.toIso8601String(),
      'lastPlayed': lastPlayed.toIso8601String(),
      'timesPlayed': timesPlayed,
    };
  }

  factory SavedCourse.fromJson(Map<String, dynamic> json) {
    return SavedCourse(
      id: json['id'],
      name: json['name'],
      pars: List<int>.from(json['pars']),
      dateCreated: DateTime.parse(json['dateCreated']),
      lastPlayed: DateTime.parse(json['lastPlayed']),
      timesPlayed: json['timesPlayed'] ?? 1,
    );
  }

  // Helper methods
  int get totalPar => pars.fold(0, (sum, par) => sum + par);
  int get frontNinePar => pars.take(9).fold(0, (sum, par) => sum + par);
  int get backNinePar => pars.skip(9).fold(0, (sum, par) => sum + par);

  // Create a copy with updated fields
  SavedCourse copyWith({
    String? id,
    String? name,
    List<int>? pars,
    DateTime? dateCreated,
    DateTime? lastPlayed,
    int? timesPlayed,
  }) {
    return SavedCourse(
      id: id ?? this.id,
      name: name ?? this.name,
      pars: pars ?? this.pars,
      dateCreated: dateCreated ?? this.dateCreated,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      timesPlayed: timesPlayed ?? this.timesPlayed,
    );
  }
}
