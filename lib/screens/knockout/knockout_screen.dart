import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/tournament_engine.dart';
import '../../models/match_model.dart';
import '../../models/team.dart';
import '../../models/tournament_model.dart';
import '../../providers/tournament_provider.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/match_card.dart';
import '../../widgets/round_header.dart';
import '../../widgets/app_button.dart';
import '../winner/winner_screen.dart';

class KnockoutScreen extends ConsumerStatefulWidget {
  const KnockoutScreen({super.key});

  @override
  ConsumerState<KnockoutScreen> createState() => _KnockoutScreenState();
}

class _KnockoutScreenState extends ConsumerState<KnockoutScreen> {
  final ScrollController _scroll = ScrollController();

  void _selectWinner(MatchModel match, Team winner) {
    ref.read(tournamentProvider.notifier).selectKnockoutMatchWinner(
          matchId: match.id,
          winner: winner,
        );
  }

  void _advance() {
    final notifier = ref.read(tournamentProvider.notifier);
    notifier.advanceKnockoutRound();

    final tournament = ref.read(tournamentProvider);
    if (tournament?.stage == TournamentStage.complete) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const WinnerScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } else {
      if (_scroll.hasClients) {
        _scroll.animateTo(0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tournament = ref.watch(tournamentProvider);
    if (tournament == null) return const SizedBox.shrink();

    if (tournament.stage == TournamentStage.complete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WinnerScreen()),
          );
        }
      });
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final activeRoundIndex = tournament.activeKnockoutRoundIndex;
    final activeRound = tournament.activeKnockoutRound;
    final isRoundComplete = tournament.isActiveKnockoutRoundComplete;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Knockout Stage'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.secondary.withOpacity(0.5)),
                ),
                child: Text(
                  TournamentEngine.knockoutRoundName(activeRound.length * 2),
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 11,
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
            // Progress bar across rounds
            _RoundProgressBar(
              totalRounds: tournament.knockoutRounds.length,
              activeIndex: activeRoundIndex,
            ),

            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  for (int ri = 0; ri < tournament.knockoutRounds.length; ri++) ...[
                    RoundHeader(
                      roundLabel: TournamentEngine.knockoutRoundName(
                          tournament.knockoutRounds[ri].length * 2),
                      subtitle:
                          '${tournament.knockoutRounds[ri].where((m) => !m.isBye).length} match${tournament.knockoutRounds[ri].where((m) => !m.isBye).length == 1 ? '' : 'es'}',
                      isComplete: ri < activeRoundIndex ||
                          (ri == activeRoundIndex && isRoundComplete),
                    ),
                    for (final match in tournament.knockoutRounds[ri])
                      MatchCard(
                        match: match,
                        onWinnerSelected:
                            ri == activeRoundIndex && !isRoundComplete
                                ? (w) => _selectWinner(match, w)
                                : null,
                        locked: ri != activeRoundIndex,
                      ),
                  ],
                ],
              ),
            ),

            if (isRoundComplete) _AdvanceBar(onAdvance: _advance),
          ],
        ),
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
          totalRounds.clamp(1, 20),
          (i) => Expanded(
            child: Container(
              margin:
                  EdgeInsets.only(right: i < totalRounds - 1 ? 6 : 0),
              height: 4,
              decoration: BoxDecoration(
                gradient: i <= activeIndex ? AppColors.goldGradient : null,
                color: i <= activeIndex ? null : AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdvanceBar extends StatelessWidget {
  final VoidCallback onAdvance;

  const _AdvanceBar({required this.onAdvance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.bgDeep,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.check_circle, color: AppColors.winnerGreen, size: 16),
              SizedBox(width: 6),
              Text(
                'Round complete! All winners selected.',
                style: TextStyle(
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
}
