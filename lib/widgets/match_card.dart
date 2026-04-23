import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/match_model.dart';
import '../models/team.dart';

class MatchCard extends StatelessWidget {
  final MatchModel match;
  final void Function(Team winner)? onWinnerSelected;
  final bool locked;

  const MatchCard({
    super.key,
    required this.match,
    this.onWinnerSelected,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    if (match.isBye) return _ByeMatchCard(match: match);
    return _NormalMatchCard(
      match: match,
      onWinnerSelected: locked ? null : onWinnerSelected,
    );
  }
}

class _NormalMatchCard extends StatelessWidget {
  final MatchModel match;
  final void Function(Team winner)? onWinnerSelected;

  const _NormalMatchCard({required this.match, this.onWinnerSelected});

  @override
  Widget build(BuildContext context) {
    final teamA = match.teamA!;
    final teamB = match.teamB!;
    final winner = match.winner;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: winner != null
            ? AppColors.winnerGradient
            : AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: winner != null ? AppColors.winnerGreen : AppColors.cardBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: winner != null
                ? AppColors.winnerGreen.withOpacity(0.15)
                : Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: _TeamTile(
                team: teamA,
                isWinner: winner == teamA,
                onTap: onWinnerSelected == null || winner != null
                    ? null
                    : () => onWinnerSelected!(teamA),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  Text(
                    'VS',
                    style: TextStyle(
                      color: winner != null
                          ? AppColors.winnerGreen
                          : AppColors.textMuted,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 2,
                    ),
                  ),
                  if (winner != null) ...[
                    const SizedBox(height: 4),
                    const Icon(Icons.check_circle,
                        color: AppColors.winnerGreen, size: 16),
                  ],
                ],
              ),
            ),
            Expanded(
              child: _TeamTile(
                team: teamB,
                isWinner: winner == teamB,
                alignRight: true,
                onTap: onWinnerSelected == null || winner != null
                    ? null
                    : () => onWinnerSelected!(teamB),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamTile extends StatelessWidget {
  final Team team;
  final bool isWinner;
  final bool alignRight;
  final VoidCallback? onTap;

  const _TeamTile({
    required this.team,
    this.isWinner = false,
    this.alignRight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isWinner
              ? AppColors.winnerGreen.withOpacity(0.2)
              : (onTap != null
                  ? AppColors.primary.withOpacity(0.12)
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
          border: isWinner
              ? Border.all(color: AppColors.winnerGreen, width: 2)
              : (onTap != null
                  ? Border.all(color: AppColors.primary.withOpacity(0.4))
                  : null),
          boxShadow: isWinner
              ? [
                  BoxShadow(
                    color: AppColors.winnerGreen.withOpacity(0.3),
                    blurRadius: 8,
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment:
              alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (isWinner)
              Align(
                alignment:
                    alignRight ? Alignment.centerRight : Alignment.centerLeft,
                child: const Icon(Icons.emoji_events,
                    color: AppColors.secondary, size: 14),
              ),
            Text(
              team.name,
              textAlign: alignRight ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                color: isWinner ? AppColors.winnerGreen : AppColors.textPrimary,
                fontWeight:
                    isWinner ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (onTap != null && !isWinner)
              Text(
                'Tap to win',
                style: TextStyle(
                  color: AppColors.primary.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ByeMatchCard extends StatelessWidget {
  final MatchModel match;

  const _ByeMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final team = match.byeTeam!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C1A4A), Color(0xFF1A0F35)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.byePurple.withOpacity(0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.byePurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.byePurple),
              ),
              child: const Text(
                'BYE',
                style: TextStyle(
                  color: AppColors.byePurple,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const Text(
                    'Auto-advances to next round',
                    style: TextStyle(
                      color: AppColors.byePurple,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded,
                color: AppColors.byePurple, size: 18),
          ],
        ),
      ),
    );
  }
}
