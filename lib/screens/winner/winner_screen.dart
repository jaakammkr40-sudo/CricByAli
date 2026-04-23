import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/tournament_model.dart';
import '../../providers/tournament_provider.dart';
import '../../widgets/gradient_background.dart';
import '../home_screen.dart';

class WinnerScreen extends ConsumerStatefulWidget {
  const WinnerScreen({super.key});

  @override
  ConsumerState<WinnerScreen> createState() => _WinnerScreenState();
}

class _WinnerScreenState extends ConsumerState<WinnerScreen>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confetti;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 12));
    _confetti.play();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _newTournament() {
    ref.read(tournamentProvider.notifier).resetTournament();
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tournament = ref.watch(tournamentProvider);
    final champion = tournament?.champion;

    return Scaffold(
      body: GradientBackground(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Confetti
            ConfettiWidget(
              confettiController: _confetti,
              blastDirection: pi / 2,
              maxBlastForce: 25,
              minBlastForce: 8,
              emissionFrequency: 0.08,
              numberOfParticles: 20,
              gravity: 0.3,
              colors: const [
                AppColors.secondary,
                AppColors.primary,
                AppColors.primaryLight,
                Colors.white,
                AppColors.winnerGreen,
              ],
            ),

            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Trophy
                      ScaleTransition(
                        scale: _scaleAnim,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.goldGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary.withOpacity(0.6),
                                blurRadius: 40,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.emoji_events,
                            color: Colors.white,
                            size: 80,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Tournament Champion label
                      ShaderMask(
                        shaderCallback: (b) =>
                            AppColors.goldGradient.createShader(b),
                        child: const Text(
                          '🏆 TOURNAMENT CHAMPION',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Winner name
                      ScaleTransition(
                        scale: _scaleAnim,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 20),
                          decoration: BoxDecoration(
                            gradient: AppColors.winnerGradient,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.winnerGreen, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.winnerGreen.withOpacity(0.4),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Text(
                            champion?.name ?? '—',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (tournament != null)
                        Text(
                          tournament.name,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),

                      const SizedBox(height: 48),

                      // Stats row
                      if (tournament != null)
                        _StatsRow(tournament: tournament),

                      const SizedBox(height: 48),

                      // New Tournament button
                      _GoldButton(
                        label: 'New Tournament',
                        icon: Icons.add_circle_outline,
                        onTap: _newTournament,
                      ),
                      const SizedBox(height: 16),

                      GestureDetector(
                        onTap: () => _confetti.play(),
                        child: const Text(
                          '🎉 Tap to celebrate again!',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),
                      const Text(
                        'Al Fatah Cricket Club 429EB\n& Burewala Union Cricket',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final TournamentModel tournament;

  const _StatsRow({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final groups = tournament.groups;
    final knockoutRounds = tournament.knockoutRounds;
    final totalTeams = tournament.allTeams.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Stat(value: '$totalTeams', label: 'Teams'),
        _divider(),
        _Stat(value: '${groups.length}', label: 'Groups'),
        _divider(),
        _Stat(value: '${knockoutRounds.length}', label: 'KO Rounds'),
      ],
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: AppColors.cardBorder,
      );
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.secondary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _GoldButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GoldButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black87, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
