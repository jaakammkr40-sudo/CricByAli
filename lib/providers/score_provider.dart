import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/score_models.dart';

const _uuid = Uuid();

class LiveMatchState {
  final String id, teamA, teamB;
  final int totalOvers, currentInnings;
  final int runs, wickets, legalBalls;
  final String striker, nonStriker, currentBowler;
  final Map<String, BatsmanStats> batsmanStats;
  final Map<String, BowlerStats> bowlerStats;
  final List<String> overDisplay;
  final InningsData? firstInnings;

  final bool needsNewBatsman;
  final bool needsNewBowler;
  final bool inningsComplete;
  final bool matchComplete;

  const LiveMatchState({
    required this.id,
    required this.teamA,
    required this.teamB,
    required this.totalOvers,
    this.currentInnings = 1,
    this.runs = 0,
    this.wickets = 0,
    this.legalBalls = 0,
    required this.striker,
    required this.nonStriker,
    required this.currentBowler,
    required this.batsmanStats,
    required this.bowlerStats,
    this.overDisplay = const [],
    this.firstInnings,
    this.needsNewBatsman = false,
    this.needsNewBowler = false,
    this.inningsComplete = false,
    this.matchComplete = false,
  });

  int get currentOverNumber => legalBalls ~/ 6;
  int get ballsInOver => legalBalls % 6;
  String get oversStr => '$currentOverNumber.$ballsInOver';
  int get target => (firstInnings?.totalRuns ?? 0) + 1;
  String get battingTeam => currentInnings == 1 ? teamA : teamB;
  String get bowlingTeam => currentInnings == 1 ? teamB : teamA;

  LiveMatchState copyWith({
    int? runs,
    int? wickets,
    int? legalBalls,
    int? currentInnings,
    String? striker,
    String? nonStriker,
    String? currentBowler,
    Map<String, BatsmanStats>? batsmanStats,
    Map<String, BowlerStats>? bowlerStats,
    List<String>? overDisplay,
    InningsData? firstInnings,
    bool? needsNewBatsman,
    bool? needsNewBowler,
    bool? inningsComplete,
    bool? matchComplete,
  }) =>
      LiveMatchState(
        id: id,
        teamA: teamA,
        teamB: teamB,
        totalOvers: totalOvers,
        currentInnings: currentInnings ?? this.currentInnings,
        runs: runs ?? this.runs,
        wickets: wickets ?? this.wickets,
        legalBalls: legalBalls ?? this.legalBalls,
        striker: striker ?? this.striker,
        nonStriker: nonStriker ?? this.nonStriker,
        currentBowler: currentBowler ?? this.currentBowler,
        batsmanStats: batsmanStats ?? this.batsmanStats,
        bowlerStats: bowlerStats ?? this.bowlerStats,
        overDisplay: overDisplay ?? this.overDisplay,
        firstInnings: firstInnings ?? this.firstInnings,
        needsNewBatsman: needsNewBatsman ?? this.needsNewBatsman,
        needsNewBowler: needsNewBowler ?? this.needsNewBowler,
        inningsComplete: inningsComplete ?? this.inningsComplete,
        matchComplete: matchComplete ?? this.matchComplete,
      );
}

class ScoreState {
  final LiveMatchState? live;
  final List<ScoreMatch> matches;

  const ScoreState({this.live, required this.matches});

  ScoreState copyWith({
    LiveMatchState? live,
    bool clearLive = false,
    List<ScoreMatch>? matches,
  }) =>
      ScoreState(
        live: clearLive ? null : (live ?? this.live),
        matches: matches ?? this.matches,
      );
}

class ScoreNotifier extends StateNotifier<ScoreState> {
  ScoreNotifier() : super(const ScoreState(matches: [])) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('score_matches') ?? '[]';
    final list = jsonDecode(raw) as List;
    final matches =
        list.map((j) => ScoreMatch.fromJson(j as Map<String, dynamic>)).toList();
    state = state.copyWith(matches: matches);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'score_matches',
      jsonEncode(state.matches.map((m) => m.toJson()).toList()),
    );
  }

  void startMatch({
    required String teamA,
    required String teamB,
    required int overs,
    required String striker,
    required String nonStriker,
    required String bowler,
  }) {
    state = state.copyWith(
      live: LiveMatchState(
        id: _uuid.v4(),
        teamA: teamA,
        teamB: teamB,
        totalOvers: overs,
        striker: striker,
        nonStriker: nonStriker,
        currentBowler: bowler,
        batsmanStats: {
          striker: BatsmanStats(name: striker),
          nonStriker: BatsmanStats(name: nonStriker),
        },
        bowlerStats: {bowler: BowlerStats(name: bowler)},
      ),
    );
  }

  void recordBall({required BallType type, required int runs}) {
    var live = state.live!;
    final isExtra = type == BallType.wide || type == BallType.noBall;
    final isLegal = !isExtra;
    final totalRuns = runs + (isExtra ? 1 : 0);

    int newRuns = live.runs + totalRuns;
    int newLegalBalls = live.legalBalls + (isLegal ? 1 : 0);
    int newWickets = live.wickets + (type == BallType.wicket ? 1 : 0);

    // Update batsman stats (wides don't count against batsman)
    var bStats = Map<String, BatsmanStats>.from(live.batsmanStats);
    if (type != BallType.wide && live.striker.isNotEmpty) {
      final cur = bStats[live.striker] ?? BatsmanStats(name: live.striker);
      bStats[live.striker] = type == BallType.wicket
          ? cur.copyWith(balls: cur.balls + 1, isOut: true)
          : cur.copyWith(runs: cur.runs + runs, balls: cur.balls + 1);
    }

    // Update bowler stats
    var wStats = Map<String, BowlerStats>.from(live.bowlerStats);
    final bow = wStats[live.currentBowler] ?? BowlerStats(name: live.currentBowler);
    wStats[live.currentBowler] = bow.copyWith(
      runs: bow.runs + totalRuns,
      balls: bow.balls + (isLegal ? 1 : 0),
      wickets: bow.wickets + (type == BallType.wicket ? 1 : 0),
    );

    // Strike rotation on odd runs (not on wicket, not on wide)
    String striker = live.striker;
    String nonStriker = live.nonStriker;
    if (type != BallType.wicket && type != BallType.wide && runs.isOdd) {
      final tmp = striker;
      striker = nonStriker;
      nonStriker = tmp;
    }

    // Over display
    final ballDisplay = switch (type) {
      BallType.wide => 'Wd',
      BallType.noBall => runs > 0 ? 'NB+$runs' : 'NB',
      BallType.wicket => 'W',
      _ => runs == 0 ? '.' : '$runs',
    };
    var overDisplay = List<String>.from(live.overDisplay)..add(ballDisplay);

    // Check over complete (after legal ball)
    bool overComplete = isLegal && (newLegalBalls % 6 == 0) && newLegalBalls > 0;
    if (overComplete) {
      // Swap strike at end of over
      final tmp = striker;
      striker = nonStriker;
      nonStriker = tmp;
      overDisplay = [];
    }

    // Check innings complete
    bool inningsOver =
        newWickets >= 10 || newLegalBalls >= live.totalOvers * 6;

    // Second innings chase win
    bool matchComplete = false;
    if (live.currentInnings == 2 && newRuns >= live.target) {
      inningsOver = true;
      matchComplete = true;
    }

    // If wicket and innings not over: striker leaves (will be replaced)
    if (type == BallType.wicket && !inningsOver) {
      striker = '';
    }

    live = live.copyWith(
      runs: newRuns,
      wickets: newWickets,
      legalBalls: newLegalBalls,
      striker: striker,
      nonStriker: nonStriker,
      batsmanStats: bStats,
      bowlerStats: wStats,
      overDisplay: overDisplay,
      needsNewBatsman: type == BallType.wicket && !inningsOver,
      needsNewBowler: overComplete && !inningsOver,
      inningsComplete: inningsOver,
      matchComplete: live.currentInnings == 2 && inningsOver,
    );
    state = state.copyWith(live: live);
  }

  void newBatsman(String name) {
    var live = state.live!;
    final bStats = Map<String, BatsmanStats>.from(live.batsmanStats);
    bStats[name] = BatsmanStats(name: name);
    state = state.copyWith(
      live: live.copyWith(
        striker: name,
        batsmanStats: bStats,
        needsNewBatsman: false,
      ),
    );
  }

  void newBowler(String name) {
    var live = state.live!;
    final wStats = Map<String, BowlerStats>.from(live.bowlerStats);
    if (!wStats.containsKey(name)) {
      wStats[name] = BowlerStats(name: name);
    }
    state = state.copyWith(
      live: live.copyWith(
        currentBowler: name,
        bowlerStats: wStats,
        needsNewBowler: false,
      ),
    );
  }

  void startSecondInnings({
    required String striker,
    required String nonStriker,
    required String bowler,
  }) {
    final live = state.live!;
    final firstInnings = _buildInnings(live, live.teamA);
    state = state.copyWith(
      live: live.copyWith(
        currentInnings: 2,
        runs: 0,
        wickets: 0,
        legalBalls: 0,
        striker: striker,
        nonStriker: nonStriker,
        currentBowler: bowler,
        batsmanStats: {
          striker: BatsmanStats(name: striker),
          nonStriker: BatsmanStats(name: nonStriker),
        },
        bowlerStats: {bowler: BowlerStats(name: bowler)},
        overDisplay: [],
        firstInnings: firstInnings,
        needsNewBatsman: false,
        needsNewBowler: false,
        inningsComplete: false,
        matchComplete: false,
      ),
    );
  }

  InningsData _buildInnings(LiveMatchState live, String team) => InningsData(
        battingTeam: team,
        totalRuns: live.runs,
        wickets: live.wickets,
        legalBalls: live.legalBalls,
        totalOvers: live.totalOvers,
        batsmen: live.batsmanStats.values.toList(),
        bowlers: live.bowlerStats.values.toList(),
      );

  void saveMatch() {
    final live = state.live!;
    final first = live.firstInnings!;
    final second = _buildInnings(live, live.teamB);

    String? winner;
    if (second.totalRuns >= first.totalRuns + 1) {
      winner = live.teamB;
    } else if (second.totalRuns == first.totalRuns) {
      winner = null; // tie
    } else {
      winner = live.teamA;
    }

    final match = ScoreMatch(
      id: live.id,
      teamA: live.teamA,
      teamB: live.teamB,
      overs: live.totalOvers,
      firstInnings: first,
      secondInnings: second,
      winner: winner,
      createdAt: DateTime.now(),
    );

    final updated = [match, ...state.matches];
    state = state.copyWith(clearLive: true, matches: updated);
    _save();
  }

  void discardMatch() => state = state.copyWith(clearLive: true);

  void deleteMatch(String id) {
    final updated = state.matches.where((m) => m.id != id).toList();
    state = state.copyWith(matches: updated);
    _save();
  }

  void editMatchWinner(String id, String? winner) {
    final updated = state.matches.map((m) {
      if (m.id != id) return m;
      return m.copyWith(winner: winner);
    }).toList();
    state = state.copyWith(matches: updated);
    _save();
  }
}

final scoreProvider =
    StateNotifierProvider<ScoreNotifier, ScoreState>((ref) => ScoreNotifier());
