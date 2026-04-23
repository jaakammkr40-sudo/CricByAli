import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/group_model.dart';
import '../../models/match_model.dart';
import '../../models/team.dart';
import '../../providers/tournament_provider.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/match_card.dart';
import '../../widgets/round_header.dart';
import '../../widgets/app_button.dart';

class GroupMatchesScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupMatchesScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupMatchesScreen> createState() => _GroupMatchesScreenState();
}

class _GroupMatchesScreenState extends ConsumerState<GroupMatchesScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _selectWinner(MatchModel match, Team winner) {
    ref.read(tournamentProvider.notifier).selectGroupMatchWinner(
          groupId: widget.groupId,
          matchId: match.id,
          winner: winner,
        );
  }

  void _advance() {
    ref.read(tournamentProvider.notifier).advanceGroupRound(widget.groupId);
    // Scroll to top to show new round
    if (_scroll.hasClients) {
      _scroll.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tournament = ref.watch(tournamentProvider);
    if (tournament == null) return const SizedBox.shrink();

    final groupIndex =
        tournament.groups.indexWhere((g) => g.id == widget.groupId);
    if (groupIndex < 0) return const SizedBox.shrink();

    final group = tournament.groups[groupIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          if (group.isComplete)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.winnerGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.winnerGreen),
                  ),
                  child: const Text(
                    'COMPLETE',
                    style: TextStyle(
                      color: AppColors.winnerGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: GradientBackground(
        child: Column(
          children: [
            // Group winner banner
            if (group.isComplete) _WinnerBanner(teamName: group.winner!.name),

            // Round progress pills
            if (!group.isComplete)
              _RoundProgressBar(
                totalRounds: group.rounds.length,
                activeIndex: group.activeRoundIndex,
              ),

            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  for (int ri = 0; ri < group.rounds.length; ri++) ...[
                    RoundHeader(
                      roundLabel: 'Round ${ri + 1}',
                      subtitle:
                          '${group.rounds[ri].where((m) => !m.isBye).length} match${group.rounds[ri].where((m) => !m.isBye).length == 1 ? '' : 'es'}',
                      isComplete: ri < group.activeRoundIndex ||
                          (ri == group.activeRoundIndex &&
                              group.isActiveRoundComplete),
                    ),
                    for (final match in group.rounds[ri])
                      MatchCard(
                        match: match,
                        onWinnerSelected: ri == group.activeRoundIndex &&
                                !group.isComplete
                            ? (w) => _selectWinner(match, w)
                            : null,
                        locked: ri != group.activeRoundIndex,
                      ),
                  ],
                ],
              ),
            ),

            // Bottom action area
            _BottomActions(
              group: group,
              onAdvance: _advance,
              onBack: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _WinnerBanner extends StatelessWidget {
  final String teamName;

  const _WinnerBanner({required this.teamName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppColors.winnerGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.winnerGreen),
        boxShadow: [
          BoxShadow(
            color: AppColors.winnerGreen.withOpacity(0.3),
            blurRadius: 14,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: AppColors.secondary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GROUP WINNER',
                  style: TextStyle(
                    color: AppColors.winnerGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  teamName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const Text(
                  'Advances to Knockout Stage',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundProgressBar extends StatelessWidget {
  final int totalRounds;
  final int activeIndex;

  const _RoundProgressBar(
      {required this.totalRounds, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: List.generate(
          totalRounds,
          (i) => Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < totalRounds - 1 ? 6 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: i <= activeIndex ? AppColors.primary : AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final GroupModel group;
  final VoidCallback onAdvance;
  final VoidCallback onBack;

  const _BottomActions({
    required this.group,
    required this.onAdvance,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    if (group.isComplete) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: AppButton(
          label: 'Back to Groups',
          icon: Icons.arrow_back,
          onPressed: onBack,
        ),
      );
    }

    if (group.isActiveRoundComplete) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.bgDeep,
          border: Border(
            top: BorderSide(color: AppColors.cardBorder),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle,
                    color: AppColors.winnerGreen, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Round ${group.activeRoundIndex + 1} complete',
                  style: const TextStyle(
                    color: AppColors.winnerGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Next Round →',
              icon: Icons.arrow_forward,
              isGold: true,
              onPressed: onAdvance,
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
