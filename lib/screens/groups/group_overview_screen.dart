import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/group_model.dart';
import '../../providers/tournament_provider.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/app_button.dart';
import 'group_matches_screen.dart';
import '../knockout/knockout_screen.dart';

class GroupOverviewScreen extends ConsumerWidget {
  const GroupOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournament = ref.watch(tournamentProvider);
    if (tournament == null) {
      return const Scaffold(body: Center(child: Text('No tournament')));
    }

    final allDone = tournament.allGroupsComplete;

    return Scaffold(
      appBar: AppBar(
        title: Text(tournament.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: AppColors.primary.withOpacity(0.5)),
                ),
                child: Text(
                  'Group Stage',
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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
            _statsRow(tournament.groups),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 120),
                itemCount: tournament.groups.length,
                itemBuilder: (ctx, i) =>
                    _GroupCard(group: tournament.groups[i]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: allDone
          ? _KnockoutFAB(onTap: () {
              ref.read(tournamentProvider.notifier).startKnockoutStage();
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const KnockoutScreen(),
                  transitionsBuilder: (_, anim, __, child) =>
                      FadeTransition(opacity: anim, child: child),
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
            })
          : null,
    );
  }

  Widget _statsRow(List<GroupModel> groups) {
    final done = groups.where((g) => g.isComplete).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          _StatChip(
            label: '${groups.length}',
            sub: 'Groups',
            icon: Icons.grid_view,
          ),
          const SizedBox(width: 10),
          _StatChip(
            label: '$done / ${groups.length}',
            sub: 'Complete',
            icon: Icons.check_circle_outline,
            highlight: done == groups.length,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String sub;
  final IconData icon;
  final bool highlight;

  const _StatChip({
    required this.label,
    required this.sub,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.winnerGreen.withOpacity(0.12)
              : AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlight ? AppColors.winnerGreen : AppColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: highlight ? AppColors.winnerGreen : AppColors.textMuted),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: highlight
                        ? AppColors.winnerGreen
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(sub,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupCard extends ConsumerWidget {
  final GroupModel group;

  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount =
        group.activeRoundMatches.where((m) => !m.isComplete && !m.isBye).length;

    return GestureDetector(
      onTap: group.isComplete
          ? null
          : () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) =>
                      GroupMatchesScreen(groupId: group.id),
                  transitionsBuilder: (_, anim, __, child) => SlideTransition(
                    position:
                        Tween(begin: const Offset(1, 0), end: Offset.zero)
                            .animate(anim),
                    child: child,
                  ),
                  transitionDuration: const Duration(milliseconds: 280),
                ),
              );
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          gradient: group.isComplete
              ? AppColors.winnerGradient
              : AppColors.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: group.isComplete
                ? AppColors.winnerGreen
                : AppColors.cardBorder,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: group.isComplete
                  ? AppColors.winnerGreen.withOpacity(0.15)
                  : Colors.black26,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _groupBadge(group.name),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      group.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _statusBadge(),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: group.teams
                    .map((t) => _teamChip(
                          t.name,
                          highlight: group.winner == t,
                        ))
                    .toList(),
              ),
              if (!group.isComplete) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.sports_cricket,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Round ${group.activeRoundIndex + 1}  •  $pendingCount match${pendingCount == 1 ? '' : 'es'} pending',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Tap to play →',
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              if (group.isComplete) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.emoji_events,
                        size: 14, color: AppColors.secondary),
                    const SizedBox(width: 6),
                    Text(
                      'Winner: ${group.winner!.name}',
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _groupBadge(String name) {
    final letter = name.split(' ').last;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _statusBadge() {
    if (group.isComplete) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.winnerGreen.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.winnerGreen),
        ),
        child: const Text(
          'DONE',
          style: TextStyle(
            color: AppColors.winnerGreen,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.secondary.withOpacity(0.5)),
      ),
      child: const Text(
        'LIVE',
        style: TextStyle(
          color: AppColors.secondary,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _teamChip(String name, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.winnerGreen.withOpacity(0.2)
            : AppColors.bgMid,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: highlight
              ? AppColors.winnerGreen
              : AppColors.cardBorder.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (highlight) ...[
            const Icon(Icons.emoji_events,
                size: 10, color: AppColors.secondary),
            const SizedBox(width: 3),
          ],
          Text(
            name,
            style: TextStyle(
              color: highlight ? AppColors.winnerGreen : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _KnockoutFAB extends StatelessWidget {
  final VoidCallback onTap;

  const _KnockoutFAB({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, color: Colors.black87, size: 22),
            SizedBox(width: 10),
            Text(
              'Start Knockout Stage',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
