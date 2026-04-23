import 'match_model.dart';
import 'team.dart';

class GroupModel {
  final String id;
  final String name;
  final List<Team> teams;
  final List<List<MatchModel>> rounds;
  final Team? winner;

  const GroupModel({
    required this.id,
    required this.name,
    required this.teams,
    this.rounds = const [],
    this.winner,
  });

  bool get isComplete => winner != null;

  int get activeRoundIndex {
    for (int i = 0; i < rounds.length; i++) {
      if (rounds[i].any((m) => !m.isComplete)) return i;
    }
    return rounds.isEmpty ? -1 : rounds.length - 1;
  }

  List<MatchModel> get activeRoundMatches {
    if (rounds.isEmpty) return const [];
    final idx = activeRoundIndex;
    return idx < 0 ? const [] : rounds[idx];
  }

  bool get isActiveRoundComplete {
    if (rounds.isEmpty) return false;
    final idx = activeRoundIndex;
    if (idx < 0) return false;
    return rounds[idx].every((m) => m.isComplete);
  }

  GroupModel copyWith({
    String? id,
    String? name,
    List<Team>? teams,
    List<List<MatchModel>>? rounds,
    Team? winner,
    bool clearWinner = false,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      teams: teams ?? this.teams,
      rounds: rounds ?? this.rounds,
      winner: clearWinner ? null : (winner ?? this.winner),
    );
  }
}
