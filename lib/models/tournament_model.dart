import 'group_model.dart';
import 'match_model.dart';
import 'team.dart';

enum TournamentStage { setup, groups, knockout, complete }

class TournamentModel {
  final String id;
  final String name;
  final List<Team> allTeams;
  final List<GroupModel> groups;
  final List<List<MatchModel>> knockoutRounds;
  final TournamentStage stage;
  final Team? champion;

  const TournamentModel({
    required this.id,
    required this.name,
    required this.allTeams,
    required this.groups,
    this.knockoutRounds = const [],
    this.stage = TournamentStage.groups,
    this.champion,
  });

  bool get allGroupsComplete => groups.isNotEmpty && groups.every((g) => g.isComplete);

  List<Team> get groupWinners =>
      groups.where((g) => g.winner != null).map((g) => g.winner!).toList();

  List<MatchModel> get activeKnockoutRound {
    for (final round in knockoutRounds) {
      if (round.any((m) => !m.isComplete)) return round;
    }
    return knockoutRounds.isEmpty ? const [] : knockoutRounds.last;
  }

  bool get isActiveKnockoutRoundComplete {
    if (knockoutRounds.isEmpty) return false;
    return activeKnockoutRound.every((m) => m.isComplete);
  }

  int get activeKnockoutRoundIndex {
    for (int i = 0; i < knockoutRounds.length; i++) {
      if (knockoutRounds[i].any((m) => !m.isComplete)) return i;
    }
    return knockoutRounds.isEmpty ? -1 : knockoutRounds.length - 1;
  }

  TournamentModel copyWith({
    String? id,
    String? name,
    List<Team>? allTeams,
    List<GroupModel>? groups,
    List<List<MatchModel>>? knockoutRounds,
    TournamentStage? stage,
    Team? champion,
    bool clearChampion = false,
  }) {
    return TournamentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      allTeams: allTeams ?? this.allTeams,
      groups: groups ?? this.groups,
      knockoutRounds: knockoutRounds ?? this.knockoutRounds,
      stage: stage ?? this.stage,
      champion: clearChampion ? null : (champion ?? this.champion),
    );
  }
}
