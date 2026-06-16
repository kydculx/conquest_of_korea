import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/achievement_provider.dart';
import '../../core/constants/strings.dart';
import '../../core/constants/colors.dart';
import '../widgets/tactical_app_bar.dart';

/// Flat-top 헥사곤 그리드 상대 좌표를 화면 크기에 맞게 픽셀아트로 시각화해주는 커스텀 페인터
class HexPatternPainter extends CustomPainter {
  final List<Map<String, int>> tiles;
  
  HexPatternPainter({required this.tiles});

  @override
  void paint(Canvas canvas, Size size) {
    if (tiles.isEmpty) return;

    // 1. 모든 타일의 논리적 2D 데카르트 좌표 계산 및 실제 경계(Bounding Box) 수집
    final List<math.Point<double>> points = [];
    double minX = 999999;
    double maxX = -999999;
    double minY = 999999;
    double maxY = -999999;

    for (final tile in tiles) {
      final int q = tile['q']!;
      final int r = tile['r']!;
      final double x = math.sqrt(3) * q + (math.sqrt(3) / 2) * r;
      final double y = -1.5 * r;
      points.add(math.Point(x, y));

      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    // 2. 15x15 그리드 고정 한계 범위 정의 (q: -7 ~ 7, r: -7 ~ 7)
    // 모든 알파벳 문자의 타일 크기를 일관성 있게 유지하고 캔버스 밖으로 나가지 않도록 고정 스펙 사용
    final double layoutWidth = 21.0 * math.sqrt(3);
    const double layoutHeight = 21.0;

    // 3. 캔버스 영역 내 여백(Padding)을 고려한 동적 스케일 크기(Hex Radius) 계산
    const double padding = 24.0; // 박스 테두리를 최대한 안 넘어가도록 조율된 여백
    final double viewWidth = size.width - padding;
    final double viewHeight = size.height - padding;

    // 단일 헥사곤 반지름 스케일 산출
    final double scaleX = viewWidth / (layoutWidth + 2.0);
    final double scaleY = viewHeight / (layoutHeight + 2.0);
    
    // 알파벳 종류에 상관없이 동일한 타일 크기를 갖도록 캔버스 크기 대비 고정 스케일 획득
    final double hexRadius = math.max(10.0, math.min(scaleX, scaleY));

    // 4. 실제 칠해진 타일들의 바운딩 박스 중심을 캔버스 중앙에 매칭하여 정중앙 배치
    final double layoutCenterX = (minX + maxX) / 2;
    final double layoutCenterY = (minY + maxY) / 2;
    final double canvasCenterX = size.width / 2;
    final double canvasCenterY = size.height / 2;

    // 5. 드로잉 스타일 브러시 설정
    // 일반 패턴 타일 네온 민트 그라데이션
    final Paint fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        colors: [Color(0xFF00FFCC), Color(0xFF00BFFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));



    // 헥사곤 검은색 음영 입체 테두리
    final Paint borderPaint = Paint()
      ..color = const Color(0xFF0F1626)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 외곽 네온 글로우 테두리
    final Paint glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 6. 각 헥사곤 그리기
    for (int i = 0; i < tiles.length; i++) {
      final pt = points[i];

      // 중심점에서 캔버스 좌표로 변환 및 스케일 적용
      final double cx = (pt.x - layoutCenterX) * hexRadius + canvasCenterX;
      final double cy = (pt.y - layoutCenterY) * hexRadius + canvasCenterY;

      // Flat-top 6각형 패스 빌드
      final Path hexPath = Path();
      for (int k = 0; k < 6; k++) {
        final double angleRad = (math.pi / 180.0) * (60.0 * k - 30.0);
        final double px = cx + hexRadius * math.cos(angleRad);
        final double py = cy + hexRadius * math.sin(angleRad);
        if (k == 0) {
          hexPath.moveTo(px, py);
        } else {
          hexPath.lineTo(px, py);
        }
      }
      hexPath.close();

      // 칠하기
      canvas.drawPath(hexPath, fillPaint);
      // 입체 테두리
      canvas.drawPath(hexPath, borderPaint);
      canvas.drawPath(hexPath, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant HexPatternPainter oldDelegate) {
    return oldDelegate.tiles != tiles;
  }
}

/// 패턴 매칭 도감 메인 UI 스크린 위젯 클래스
class PatternGuideScreen extends StatefulWidget {
  const PatternGuideScreen({super.key});

  @override
  State<PatternGuideScreen> createState() => _PatternGuideScreenState();
}

class _PatternGuideScreenState extends State<PatternGuideScreen> {
  // 도감 지원 대상 문자 리스트 (A ~ M)
  final List<String> _alphabetList = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M'
  ];
  
  // 현재 선택된 문자 인덱스
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final achProvider = Provider.of<AchievementProvider>(context);
    final String selectedChar = _alphabetList[_selectedIndex];

    return Scaffold(
      appBar: TacticalAppBar(
        titleText: GameStrings.patternGuideTitle,
        showBackButton: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: GameColors.cozyDarkGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. 타이틀 서브 설명 패널
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Text(
                  GameStrings.patternGuideSubtitle,
                  style: TextStyle(
                    color: GameColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // 2. 가로 스크롤 형태의 알파벳 칩 리스트뷰
              Container(
                height: 54,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _alphabetList.length,
                  itemBuilder: (context, index) {
                    final char = _alphabetList[index];
                    final isSelected = index == _selectedIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        width: 46,
                        alignment: Alignment.center,
                        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? GameColors.accentNeon.withValues(alpha: 0.15)
                              : GameColors.backgroundMedium.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? GameColors.accentNeon : GameColors.borderLight,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: GameColors.accentNeon.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          char,
                          style: GoogleFonts.outfit(
                            color: isSelected ? GameColors.accentNeon : GameColors.textSecondary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // 3. 메인 프리뷰 캔버스 영역 (3D 아크릴 느낌 데코 적용)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1626).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: GameColors.borderNeon,
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: GameColors.accentNeon.withValues(alpha: 0.04),
                        blurRadius: 16,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: FutureBuilder<List<Map<String, int>>>(
                    future: achProvider.getPatternCoordinates(selectedChar),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(GameColors.accentNeon),
                          ),
                        );
                      }

                      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            '패턴 형상을 로드할 수 없습니다.',
                            style: TextStyle(color: Colors.white60),
                          ),
                        );
                      }

                      final tiles = snapshot.data!;
                      return Column(
                        children: [
                          // 헥사곤 페인팅 캔버스
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return CustomPaint(
                                  size: Size(constraints.maxWidth, constraints.maxHeight),
                                  painter: HexPatternPainter(tiles: tiles),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          // 필요 수량 표기
                          Text(
                            GameStrings.requiredTilesCount(tiles.length),
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
