import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/tile_model.dart';
import '../../providers/game_provider.dart';

/// 팀 선택 화면
class TeamSelectionScreen extends StatelessWidget {
  const TeamSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Colors.blueGrey.shade900],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('세력 선택',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4)),
              const SizedBox(height: 10),
              const Text('한국 정복 작전 가담',
                  style: TextStyle(
                      color: GameConstants.accentNeon,
                      fontSize: 14,
                      letterSpacing: 2)),
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _TeamCard(
                    team: TileOwner.blue,
                    teamName: '블루 연합',
                    color: GameConstants.colorBlue,
                    icon: Icons.shield,
                  ),
                  _TeamCard(
                    team: TileOwner.red,
                    teamName: '레드 군단',
                    color: GameConstants.colorRed,
                    icon: Icons.local_fire_department,
                  ),
                ],
              ),
              const SizedBox(height: 60),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  '한 번 선택한 세력은 시즌이 종료될 때까지 변경할 수 없습니다. 소속 팀을 신중하게 선택하십시오.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white54, fontSize: 13, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final TileOwner team;
  final String teamName;
  final Color color;
  final IconData icon;

  const _TeamCard({
    required this.team,
    required this.teamName,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<GameProvider>().setSelectedTeam(team);
      },
      child: Container(
        width: 150,
        height: 200,
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(150), width: 2),
          boxShadow: [
            BoxShadow(
                color: color.withAlpha(50), blurRadius: 15, spreadRadius: 2)
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 60),
            const SizedBox(height: 20),
            Text(teamName,
                style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
