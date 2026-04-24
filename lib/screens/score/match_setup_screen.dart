import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/score_provider.dart';
import '../../widgets/gradient_background.dart';
import 'scoring_screen.dart';

class MatchSetupScreen extends ConsumerStatefulWidget {
  const MatchSetupScreen({super.key});

  @override
  ConsumerState<MatchSetupScreen> createState() => _MatchSetupScreenState();
}

class _MatchSetupScreenState extends ConsumerState<MatchSetupScreen> {
  final _teamACtrl = TextEditingController();
  final _teamBCtrl = TextEditingController();
  final _strikerCtrl = TextEditingController();
  final _nonStrikerCtrl = TextEditingController();
  final _bowlerCtrl = TextEditingController();
  int _overs = 6;

  @override
  void dispose() {
    _teamACtrl.dispose();
    _teamBCtrl.dispose();
    _strikerCtrl.dispose();
    _nonStrikerCtrl.dispose();
    _bowlerCtrl.dispose();
    super.dispose();
  }

  void _startMatch() {
    final teamA = _teamACtrl.text.trim();
    final teamB = _teamBCtrl.text.trim();
    final striker = _strikerCtrl.text.trim();
    final nonStriker = _nonStrikerCtrl.text.trim();
    final bowler = _bowlerCtrl.text.trim();

    if (teamA.isEmpty || teamB.isEmpty) {
      _err('Enter both team names');
      return;
    }
    if (striker.isEmpty || nonStriker.isEmpty) {
      _err('Enter both opening batsmen');
      return;
    }
    if (striker == nonStriker) {
      _err('Batsmen names must be different');
      return;
    }
    if (bowler.isEmpty) {
      _err('Enter opening bowler name');
      return;
    }

    ref.read(scoreProvider.notifier).startMatch(
          teamA: teamA,
          teamB: teamB,
          overs: _overs,
          striker: striker,
          nonStriker: nonStriker,
          bowler: bowler,
        );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ScoringScreen()),
    );
  }

  void _err(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Match')),
      body: GradientBackground(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            _section('Teams'),
            const SizedBox(height: 10),
            _field(_teamACtrl, 'Team A (Batting First)', 'e.g. Al Fatah XI'),
            const SizedBox(height: 10),
            _field(_teamBCtrl, 'Team B (Batting Second)', 'e.g. Burewala XI'),

            const SizedBox(height: 24),
            _section('Overs'),
            const SizedBox(height: 10),
            _oversSelector(),

            const SizedBox(height: 24),
            _section('Opening Batsmen  (Team A)'),
            const SizedBox(height: 10),
            _field(_strikerCtrl, 'Striker (On strike)', 'e.g. Sajid'),
            const SizedBox(height: 10),
            _field(_nonStrikerCtrl, 'Non-Striker', 'e.g. Kamran'),

            const SizedBox(height: 24),
            _section('Opening Bowler  (Team B)'),
            const SizedBox(height: 10),
            _field(_bowlerCtrl, 'Bowler Name', 'e.g. Ahmed'),

            const SizedBox(height: 36),
            _startBtn(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section(String label) => Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      );

  Widget _field(TextEditingController ctrl, String label, String hint) =>
      TextField(
        controller: ctrl,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(labelText: label, hintText: hint),
      );

  Widget _oversSelector() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [4, 5, 6].map((o) {
            final selected = _overs == o;
            return GestureDetector(
              onTap: () => setState(() => _overs = o),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: selected ? AppColors.goldGradient : null,
                  color: selected ? null : AppColors.bgMid,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? AppColors.secondary : AppColors.cardBorder,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '$o',
                      style: TextStyle(
                        color: selected ? Colors.black87 : AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'overs',
                      style: TextStyle(
                        color: selected ? Colors.black54 : AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _startBtn() => GestureDetector(
        onTap: _startMatch,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sports_cricket, color: Colors.black87, size: 22),
              SizedBox(width: 10),
              Text(
                'Start Match',
                style: TextStyle(
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
