import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/utils/tournament_engine.dart';
import '../models/group_model.dart';
import '../models/match_model.dart';
import '../models/team.dart';
import '../models/tournament_model.dart';

const _uuid = Uuid();

class TournamentNotifier extends StateNotifier<TournamentModel?> {
  TournamentNotifier() : super(null);

  // ─── Create ───────────────────────────────────────────────────────────────

  void createTournament({
    required String name,
    required List<Team> teams,
    required int numGroups,
  }) {
    final groups = TournamentEngine.distributeTeamsIntoGroups(teams, numGroups);
    state = TournamentModel(
      id: _uuid.v4(),
      name: name,
      allTeams: teams,
      groups: groups,
      stage: TournamentStage.groups,
    );
  }

  // ─── Group Phase ──────────────────────────────────────────────────────────

  void selectGroupMatchWinner({
    required String groupId,
    required String matchId,
    required Team winner,
  }) {
    if (state == null) return;

    final updatedGroups = state!.groups.map((group) {
      if (group.id != groupId) return group;
      return _applyWinnerToGroup(group, matchId, winner);
    }).toList();

    state = state!.copyWith(groups: updatedGroups);
  }

  GroupModel _applyWinnerToGroup(GroupModel group, String matchId, Team winner) {
    final updatedRounds = group.rounds.map((round) {
      return round.map((match) {
        if (match.id != matchId) return match;
        return match.withWinner(winner);
      }).toList();
    }).toList();
    return group.copyWith(rounds: updatedRounds);
  }

  /// Called when user taps "Next Round" after all matches in a group round finish.
  void advanceGroupRound(String groupId) {
    if (state == null) return;

    final updatedGroups = state!.groups.map((group) {
      if (group.id != groupId) return group;
      return _tryAdvanceGroup(group);
    }).toList();

    state = state!.copyWith(groups: updatedGroups);
  }

  GroupModel _tryAdvanceGroup(GroupModel group) {
    if (group.rounds.isEmpty) return group;
    final currentRound = group.rounds[group.activeRoundIndex];
    if (!TournamentEngine.isRoundComplete(currentRound)) return group;

    final winners = TournamentEngine.getWinners(currentRound);

    if (winners.length == 1) {
      // Group is done
      return group.copyWith(winner: winners.first);
    }

    final nextRound = TournamentEngine.generateRoundMatches(
      winners,
      group.rounds.length + 1,
    );
    return group.copyWith(rounds: [...group.rounds, nextRound]);
  }

  // ─── Knockout Phase ───────────────────────────────────────────────────────

  /// Transition from groups to knockout stage.
  void startKnockoutStage() {
    if (state == null || !state!.allGroupsComplete) return;

    final groupWinners = state!.groupWinners;
    if (groupWinners.isEmpty) return;

    if (groupWinners.length == 1) {
      // Only 1 group winner → instant champion
      state = state!.copyWith(
        champion: groupWinners.first,
        stage: TournamentStage.complete,
      );
      return;
    }

    final firstRound = TournamentEngine.generateRoundMatches(groupWinners, 1);
    state = state!.copyWith(
      knockoutRounds: [firstRound],
      stage: TournamentStage.knockout,
    );
  }

  void selectKnockoutMatchWinner({
    required String matchId,
    required Team winner,
  }) {
    if (state == null) return;

    final updatedRounds = state!.knockoutRounds.map((round) {
      return round.map((match) {
        if (match.id != matchId) return match;
        return match.withWinner(winner);
      }).toList();
    }).toList();

    state = state!.copyWith(knockoutRounds: updatedRounds);
  }

  /// Called when user taps "Next Round" after a knockout round is complete.
  void advanceKnockoutRound() {
    if (state == null || state!.knockoutRounds.isEmpty) return;

    final currentRound = state!.activeKnockoutRound;
    if (!TournamentEngine.isRoundComplete(currentRound)) return;

    final winners = TournamentEngine.getWinners(currentRound);

    if (winners.length == 1) {
      state = state!.copyWith(
        champion: winners.first,
        stage: TournamentStage.complete,
      );
      return;
    }

    final nextRound = TournamentEngine.generateRoundMatches(
      winners,
      state!.knockoutRounds.length + 1,
    );
    state = state!.copyWith(
      knockoutRounds: [...state!.knockoutRounds, nextRound],
    );
  }

  // ─── Reset ────────────────────────────────────────────────────────────────

  void resetTournament() {
    state = null;
  }
}

final tournamentProvider =
    StateNotifierProvider<TournamentNotifier, TournamentModel?>(
  (ref) => TournamentNotifier(),
);
