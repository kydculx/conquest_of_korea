import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
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

    // 2. 실제 타일들이 차지하는 2D 영역의 폭과 높이 산출 (최소 1.0 방어)
    final double contentWidth = math.max(1.0, maxX - minX);
    final double contentHeight = math.max(1.0, maxY - minY);

    // 3. 캔버스 영역 내 여백(Padding)을 고려한 동적 스케일 크기(Hex Radius) 계산
    const double padding = 48.0; // 박스 테두리를 안전하게 안 넘어가도록 여유 마진 확보
    final double viewWidth = size.width - padding;
    final double viewHeight = size.height - padding;

    // 단일 헥사곤 반지름 스케일 산출 (좌우 여백 안전을 위해 분모에 2.5 가산)
    final double scaleX = viewWidth / (contentWidth + 2.5);
    final double scaleY = viewHeight / (contentHeight + 2.5);
    
    // 타일이 화면 밖으로 나가지 않도록 두 축 중 최소 스케일을 취하고, 
    // 타일이 지나치게 커져서 상하좌우를 넘지 않도록 최대 반지름 18.0으로 제한
    final double hexRadius = math.min(18.0, math.max(6.0, math.min(scaleX, scaleY)));

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
  // 도감 지원 대상 문자 리스트 (A ~ V)
  final List<String> _alphabetList = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
    'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V'
  ];
  
  // 현재 선택된 문자 인덱스
  int _selectedIndex = 0;

  // 캐러셀 슬라이더용 컨트롤러
  final CarouselSliderController _carouselController = CarouselSliderController();

  // 상단 칩 리스트 뷰용 스크롤 컨트롤러
  final ScrollController _chipScrollController = ScrollController();

  // 비동기 동시 프리로딩 데이터 보관 맵
  Map<String, List<Map<String, int>>> _patternTilesMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _preloadAllPatterns();
  }

  @override
  void dispose() {
    _chipScrollController.dispose();
    super.dispose();
  }

  /// 모든 지원 대상 알파벳 패턴 데이터를 미리 로딩(Pre-fetch)하여 캐싱
  Future<void> _preloadAllPatterns() async {
    final achProvider = Provider.of<AchievementProvider>(context, listen: false);
    try {
      Future.microtask(() async {
        final Map<String, List<Map<String, int>>> tempMap = {};

        // A ~ M 패턴 동시 병렬 비동기 조회
        await Future.wait(
          _alphabetList.map((char) async {
            final tiles = await achProvider.getPatternCoordinates(char);
            tempMap[char] = tiles;
          }),
        );

        if (mounted) {
          setState(() {
            _patternTilesMap = tempMap;
            _isLoading = false;
          });
          // 초기 선택 칩 위치로 스크롤 이동
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _scrollToSelectedChip(_selectedIndex);
            }
          });
        }
      });
    } catch (e) {
      debugPrint('⚠️ 도감 패턴 프리로딩 실패: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 활성화된 칩이 화면 안에 완전히 정렬되도록 스크롤링 위치 자동 보정
  void _scrollToSelectedChip(int index) {
    if (!mounted) return;
    if (!_chipScrollController.hasClients) return;
    
    // 개별 칩 너비(46) + 좌우 여백 마진 합(12) = 58
    final double offset = (index * 58.0) - (MediaQuery.of(context).size.width / 2) + 29.0;
    final double clampedOffset = offset.clamp(
      0.0,
      _chipScrollController.position.maxScrollExtent,
    );
    
    _chipScrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: TacticalAppBar(
          titleText: GameStrings.patternGuideTitle,
          showBackButton: true,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: GameColors.cozyDarkGradient,
          ),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(GameColors.accentNeon),
            ),
          ),
        ),
      );
    }

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
                  controller: _chipScrollController,
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
                        _carouselController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                        _scrollToSelectedChip(index);
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

              // 3. 메인 캐러셀 슬라이더 영역
              Expanded(
                child: CarouselSlider.builder(
                  carouselController: _carouselController,
                  itemCount: _alphabetList.length,
                  options: CarouselOptions(
                    height: double.infinity,
                    viewportFraction: 0.82,
                    initialPage: _selectedIndex,
                    enableInfiniteScroll: false,
                    enlargeCenterPage: true,
                    enlargeFactor: 0.25,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _selectedIndex = index;
                      });
                      _scrollToSelectedChip(index);
                    },
                  ),
                  itemBuilder: (context, index, realIndex) {
                    final char = _alphabetList[index];
                    final tiles = _patternTilesMap[char] ?? [];

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      child: Column(
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
                      ),
                    );
                  },
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
