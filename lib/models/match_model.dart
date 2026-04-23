import 'team.dart';

class MatchModel {
  final String id;
  final Team? teamA;
  final Team? teamB;
  final Team? winner;
  final int round;

  const MatchModel({
    required this.id,
    this.teamA,
    this.teamB,
    this.winner,
    required this.round,
  });

  bool get isBye => teamA == null || teamB == null;
  Team? get byeTeam => isBye ? (teamA ?? teamB) : null;
  bool get isComplete => winner != null;

  MatchModel withWinner(Team w) => MatchModel(
        id: id,
        teamA: teamA,
        teamB: teamB,
        winner: w,
        round: round,
      );

  @override
  bool operator ==(Object other) => other is MatchModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
