import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../models/group_model.dart';
import '../../models/match_model.dart';
import '../../models/team.dart';

class TournamentEngine {
  TournamentEngine._();

  static const _uuid = Uuid();
  static final _rng = Random();

  /// Distribute teams into groups as evenly as possible (round-robin).
  static List<GroupModel> distributeTeamsIntoGroups(
    List<Team> teams,
    int numGroups,
  ) {
    final shuffled = List<Team>.from(teams)..shuffle(_rng);
    final clampedGroups = numGroups.clamp(1, teams.length);

    // Randomly decide which groups get the extra team (when teams don't divide evenly)
    final base = shuffled.length ~/ clampedGroups;
    final extra = shuffled.length % clampedGroups;
    final groupIndices = List.generate(clampedGroups, (i) => i)..shuffle(_rng);
    final groupSizes = List.filled(clampedGroups, base);
    for (int i = 0; i < extra; i++) {
      groupSizes[groupIndices[i]]++;
    }

    final groups = List.generate(clampedGroups, (i) {
      return GroupModel(
        id: _uuid.v4(),
        name: 'Group ${String.fromCharCode(65 + i)}',
        teams: [],
      );
    });

    int teamIdx = 0;
    for (int g = 0; g < clampedGroups; g++) {
      final groupTeams = shuffled.sublist(teamIdx, teamIdx + groupSizes[g]);
      teamIdx += groupSizes[g];
      groups[g] = groups[g].copyWith(teams: groupTeams);
    }

    // Generate first round for each group
    final result = <GroupModel>[];
    for (final group in groups) {
      if (group.teams.isEmpty) continue;
      if (group.teams.length == 1) {
        // Single team auto-wins
        final byeMatch = MatchModel(
          id: _uuid.v4(),
          teamA: group.teams.first,
          teamB: null,
          winner: group.teams.first,
          round: 1,
        );
        result.add(group.copyWith(
          rounds: [[byeMatch]],
          winner: group.teams.first,
        ));
      } else {
        final firstRound = generateRoundMatches(group.teams, 1);
        result.add(group.copyWith(rounds: [firstRound]));
      }
    }
    return result;
  }

  /// Generate matches for a round. Bye teams auto-advance with winner set.
  static List<MatchModel> generateRoundMatches(
    List<Team> teams,
    int roundNumber,
  ) {
    if (teams.isEmpty) return const [];
    if (teams.length == 1) {
      return [
        MatchModel(
          id: _uuid.v4(),
          teamA: teams[0],
          teamB: null,
          winner: teams[0],
          round: roundNumber,
        ),
      ];
    }

    final shuffled = List<Team>.from(teams)..shuffle(_rng);
    final matches = <MatchModel>[];

    MatchModel? byeMatch;
    if (shuffled.length.isOdd) {
      final byeTeam = shuffled.removeAt(_rng.nextInt(shuffled.length));
      byeMatch = MatchModel(
        id: _uuid.v4(),
        teamA: byeTeam,
        teamB: null,
        winner: byeTeam, // auto-advance
        round: roundNumber,
      );
    }

    for (int i = 0; i < shuffled.length; i += 2) {
      matches.add(MatchModel(
        id: _uuid.v4(),
        teamA: shuffled[i],
        teamB: shuffled[i + 1],
        round: roundNumber,
      ));
    }

    if (byeMatch != null) matches.insert(0, byeMatch);
    return matches;
  }

  static bool isRoundComplete(List<MatchModel> matches) =>
      matches.isNotEmpty && matches.every((m) => m.isComplete);

  static List<Team> getWinners(List<MatchModel> matches) =>
      matches.where((m) => m.winner != null).map((m) => m.winner!).toList();

  /// Human-readable name for the knockout round based on remaining team count.
  static String knockoutRoundName(int teamCount) {
    if (teamCount <= 2) return 'Final';
    if (teamCount <= 4) return 'Semi Final';
    if (teamCount <= 8) return 'Quarter Final';
    if (teamCount <= 16) return 'Round of 16';
    if (teamCount <= 32) return 'Round of 32';
    return 'Round of $teamCount';
  }

  /// Generate a set of popular Pakistani cricket team names for demo.
  static List<Team> generateDummyTeams(int count) {
    const predefined = [
      'Lahore Lions', 'Karachi Kings', 'Multan Sultans', 'Islamabad United',
      'Peshawar Zalmi', 'Quetta Gladiators', 'Rawalpindi Rams', 'Faisalabad Wolves',
      'Sialkot Stallions', 'Gujranwala Giants', 'Burewala Bulls', 'Sahiwal Stars',
      'Vehari Vikings', 'Bahawalpur Bravos', 'Dera Warriors', 'Khanewal Knights',
      'Muzaffargarh Masters', 'Lodhran Lions', 'Pakpattan Panthers', 'Okara Owls',
      'Jhang Jaguars', 'Sargodha Strikers', 'Mianwali Monarchs', 'Bhakkar Blazers',
    ];
    return List.generate(count, (i) {
      final name = i < predefined.length
          ? predefined[i]
          : 'Team ${_alphabetLabel(i)}';
      return Team(id: _uuid.v4(), name: name);
    });
  }

  static String _alphabetLabel(int index) {
    final letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (index < 26) return letters[index];
    return '${letters[index ~/ 26 - 1]}${letters[index % 26]}';
  }
}
