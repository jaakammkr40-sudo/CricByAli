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
  final _customCtrl = TextEditingController();

  int _overs = 6;
  bool _customOvers = false;

  @override
  void dispose() {
    _teamACtrl.dispose();
    _teamBCtrl.dispose();
    _strikerCtrl.dispose();
    _nonStrikerCtrl.dispose();
    _bowlerCtrl.dispose();
    _customCtrl.dispose();
    super.dispose();
  }

  void _startMatch() {
    final teamA = _teamACtrl.text.trim();
    final teamB = _teamBCtrl.text.trim();
    final striker = _strikerCtrl.text.trim();
    final nonStriker = _nonStrikerCtrl.text.trim();
    final bowler = _bowlerCtrl.text.trim();

    if (teamA.isEmpty || teamB.isEmpty) { _err('Enter both team names'); return; }
    if (striker.isEmpty || nonStriker.isEmpty) { _err('Enter both opening batsmen'); return; }
    if (striker == nonStriker) { _err('Batsmen names must be different'); return; }
    if (bowler.isEmpty) { _err('Enter opening bowler name'); return; }
    if (_overs < 1) { _err('Overs must be at least 1'); return; }

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

  void _err(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Match')),
      body: GradientBackground(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            _label('Teams'),
            const SizedBox(height: 10),
            _field(_teamACtrl, 'Team A (Batting First)', 'e.g. Al Fatah XI'),
            const SizedBox(height: 10),
            _field(_teamBCtrl, 'Team B (Batting Second)', 'e.g. Burewala XI'),

            const SizedBox(height: 24),
            _label('Overs'),
            const SizedBox(height: 10),
            _oversSelector(),

            const SizedBox(height: 24),
            _label('Opening Batsmen  (Team A)'),
            const SizedBox(height: 10),
            _field(_strikerCtrl, 'Striker (On strike)', 'e.g. Sajid'),
            const SizedBox(height: 10),
            _field(_nonStrikerCtrl, 'Non-Striker', 'e.g. Kamran'),

            const SizedBox(height: 24),
            _label('Opening Bowler  (Team B)'),
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

  Widget _label(String text) => Text(
        text.toUpperCase(),
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

  Widget _oversSelector() {
    const quickValues = [1, 2, 3, 4, 5, 6, 8, 10, 12, 15, 20];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick select grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickValues.map((o) {
              final selected = _overs == o && !_customOvers;
              return GestureDetector(
                onTap: () => setState(() {
                  _overs = o;
                  _customOvers = false;
                  _customCtrl.clear();
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: selected ? AppColors.goldGradient : null,
                    color: selected ? null : AppColors.bgMid,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? AppColors.secondary : AppColors.cardBorder,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$o',
                      style: TextStyle(
                        color: selected ? Colors.black87 : AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Custom input
          TextField(
            controller: _customCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Or type any overs (e.g. 7, 25, 50...)',
              filled: true,
              fillColor: _customOvers
                  ? AppColors.primary.withOpacity(0.08)
                  : AppColors.bgMid,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: _customOvers ? AppColors.secondary : AppColors.cardBorder,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: _customOvers ? AppColors.secondary : AppColors.cardBorder,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (v) {
              final n = int.tryParse(v.trim());
              if (n != null && n >= 1) {
                setState(() {
                  _overs = n;
                  _customOvers = true;
                });
              }
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Selected: $_overs over${_overs == 1 ? '' : 's'}',
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

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
