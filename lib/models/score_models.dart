import 'dart:convert';

enum BallType { normal, wide, noBall, wicket }

class BatsmanStats {
  final String name;
  final int runs, balls;
  final bool isOut;

  const BatsmanStats({
    required this.name,
    this.runs = 0,
    this.balls = 0,
    this.isOut = false,
  });

  BatsmanStats copyWith({int? runs, int? balls, bool? isOut}) => BatsmanStats(
        name: name,
        runs: runs ?? this.runs,
        balls: balls ?? this.balls,
        isOut: isOut ?? this.isOut,
      );

  Map<String, dynamic> toJson() =>
      {'name': name, 'runs': runs, 'balls': balls, 'isOut': isOut};

  factory BatsmanStats.fromJson(Map<String, dynamic> j) => BatsmanStats(
        name: j['name'],
        runs: j['runs'],
        balls: j['balls'],
        isOut: j['isOut'] ?? false,
      );
}

class BowlerStats {
  final String name;
  final int runs, balls, wickets;

  const BowlerStats({
    required this.name,
    this.runs = 0,
    this.balls = 0,
    this.wickets = 0,
  });

  BowlerStats copyWith({int? runs, int? balls, int? wickets}) => BowlerStats(
        name: name,
        runs: runs ?? this.runs,
        balls: balls ?? this.balls,
        wickets: wickets ?? this.wickets,
      );

  String get overStr => '${balls ~/ 6}.${balls % 6}';

  Map<String, dynamic> toJson() =>
      {'name': name, 'runs': runs, 'balls': balls, 'wickets': wickets};

  factory BowlerStats.fromJson(Map<String, dynamic> j) => BowlerStats(
        name: j['name'],
        runs: j['runs'],
        balls: j['balls'],
        wickets: j['wickets'],
      );
}

class InningsData {
  final String battingTeam;
  final int totalRuns, wickets, legalBalls, totalOvers;
  final List<BatsmanStats> batsmen;
  final List<BowlerStats> bowlers;

  const InningsData({
    required this.battingTeam,
    required this.totalRuns,
    required this.wickets,
    required this.legalBalls,
    required this.totalOvers,
    required this.batsmen,
    required this.bowlers,
  });

  String get overStr => '${legalBalls ~/ 6}.${legalBalls % 6}';

  BatsmanStats? get topBatsman => batsmen.isEmpty
      ? null
      : batsmen.reduce((a, b) => a.runs >= b.runs ? a : b);

  BowlerStats? get topBowler => bowlers.isEmpty
      ? null
      : bowlers.reduce((a, b) {
          if (a.wickets != b.wickets) return a.wickets > b.wickets ? a : b;
          return a.runs <= b.runs ? a : b;
        });

  Map<String, dynamic> toJson() => {
        'battingTeam': battingTeam,
        'totalRuns': totalRuns,
        'wickets': wickets,
        'legalBalls': legalBalls,
        'totalOvers': totalOvers,
        'batsmen': batsmen.map((b) => b.toJson()).toList(),
        'bowlers': bowlers.map((b) => b.toJson()).toList(),
      };

  factory InningsData.fromJson(Map<String, dynamic> j) => InningsData(
        battingTeam: j['battingTeam'],
        totalRuns: j['totalRuns'],
        wickets: j['wickets'],
        legalBalls: j['legalBalls'],
        totalOvers: j['totalOvers'],
        batsmen:
            (j['batsmen'] as List).map((b) => BatsmanStats.fromJson(b)).toList(),
        bowlers:
            (j['bowlers'] as List).map((b) => BowlerStats.fromJson(b)).toList(),
      );
}

class ScoreMatch {
  final String id, teamA, teamB;
  final int overs;
  final InningsData firstInnings;
  final InningsData? secondInnings;
  final String? winner;
  final DateTime createdAt;

  const ScoreMatch({
    required this.id,
    required this.teamA,
    required this.teamB,
    required this.overs,
    required this.firstInnings,
    this.secondInnings,
    this.winner,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'teamA': teamA,
        'teamB': teamB,
        'overs': overs,
        'firstInnings': firstInnings.toJson(),
        'secondInnings': secondInnings?.toJson(),
        'winner': winner,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ScoreMatch.fromJson(Map<String, dynamic> j) => ScoreMatch(
        id: j['id'],
        teamA: j['teamA'],
        teamB: j['teamB'],
        overs: j['overs'],
        firstInnings: InningsData.fromJson(j['firstInnings']),
        secondInnings: j['secondInnings'] != null
            ? InningsData.fromJson(j['secondInnings'])
            : null,
        winner: j['winner'],
        createdAt: DateTime.parse(j['createdAt']),
      );

  ScoreMatch copyWith({InningsData? secondInnings, String? winner}) =>
      ScoreMatch(
        id: id,
        teamA: teamA,
        teamB: teamB,
        overs: overs,
        firstInnings: firstInnings,
        secondInnings: secondInnings ?? this.secondInnings,
        winner: winner ?? this.winner,
        createdAt: createdAt,
      );
}
