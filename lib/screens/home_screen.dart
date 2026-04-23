import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../models/tournament_model.dart';
import '../providers/tournament_provider.dart';
import '../widgets/gradient_background.dart';
import '../widgets/app_button.dart';
import 'setup/tournament_setup_screen.dart';
import 'groups/group_overview_screen.dart';
import 'knockout/knockout_screen.dart';
import 'winner/winner_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournament = ref.watch(tournamentProvider);

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 40),
                _buildHeroCard(),
                const SizedBox(height: 32),
                if (tournament != null) ...[
                  _buildActiveTournamentCard(context, ref, tournament),
                  const SizedBox(height: 16),
                ],
                AppButton(
                  label: 'Create New Tournament',
                  icon: Icons.add_circle_outline,
                  onPressed: () {
                    if (tournament != null) {
                      _confirmNewTournament(context, ref);
                    } else {
                      Navigator.push(
                        context,
                        _slide(const TournamentSetupScreen()),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (tournament != null)
                  AppButton(
                    label: _resumeLabel(tournament.stage),
                    icon: Icons.play_arrow_rounded,
                    isGold: true,
                    onPressed: () => _resumeTournament(context, tournament),
                  ),
                const Spacer(),
                _buildSponsors(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 12,
              ),
            ],
          ),
          child: const Icon(Icons.sports_cricket, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (b) => AppColors.goldGradient.createShader(b),
              child: const Text(
                'CricByAli',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            const Text(
              'Cricket Tournament Manager',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '🏏 Manage Your\nCricket Tournament',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Groups • Knockouts • Champions',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.emoji_events,
                color: AppColors.secondary, size: 64),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTournamentCard(
    BuildContext context,
    WidgetRef ref,
    TournamentModel tournament,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.circle, color: AppColors.winnerGreen, size: 10),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Active Tournament',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  tournament.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  _stageLabel(tournament.stage),
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.errorRed, size: 22),
            onPressed: () => _confirmNewTournament(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildSponsors() {
    return Column(
      children: const [
        Text(
          'POWERED BY',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Al Fatah Cricket Club 429EB  •  Burewala Union Cricket',
          style: TextStyle(
            color: AppColors.secondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _resumeLabel(TournamentStage stage) => switch (stage) {
        TournamentStage.groups => 'Resume Group Stage',
        TournamentStage.knockout => 'Resume Knockout Stage',
        TournamentStage.complete => 'View Champion',
        _ => 'Resume Tournament',
      };

  String _stageLabel(TournamentStage stage) => switch (stage) {
        TournamentStage.groups => 'Group Stage in progress',
        TournamentStage.knockout => 'Knockout Stage in progress',
        TournamentStage.complete => 'Completed',
        _ => 'Setting up',
      };

  void _resumeTournament(BuildContext context, TournamentModel tournament) {
    switch (tournament.stage) {
      case TournamentStage.groups:
        Navigator.push(context, _slide(const GroupOverviewScreen()));
      case TournamentStage.knockout:
        Navigator.push(context, _slide(const KnockoutScreen()));
      case TournamentStage.complete:
        Navigator.push(context, _slide(const WinnerScreen()));
      default:
        break;
    }
  }

  Future<void> _confirmNewTournament(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Start New Tournament?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'This will reset the current tournament. Are you sure?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset & Create',
                style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ref.read(tournamentProvider.notifier).resetTournament();
      Navigator.push(context, _slide(const TournamentSetupScreen()));
    }
  }

  PageRoute _slide(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position:
              Tween(begin: const Offset(1, 0), end: Offset.zero).animate(anim),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      );
}
