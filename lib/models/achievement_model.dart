enum AchievementCategory {
  capturedTiles,
  enemyCapturedTiles,
  totalMovedTiles,
  dailyMovedTiles,
  satelliteCapture,
  satelliteInfo,
  hqFortification,
  goldAmount,
  mainBaseMove,
}

/// 인게임 전체 업적 정보의 정적 규격을 정의하는 마스터 모델 클래스
class Achievement {
  final String id;
  final String titleKey;
  final String descriptionKey;
  final AchievementCategory category;
  final double threshold;
  final int tier; // 1 ~ 4

  const Achievement({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.category,
    required this.threshold,
    required this.tier,
  });

  /// 8개 카테고리, 각 4단계로 구성된 총 28종의 정적 마스터 업적 데이터 리스트
  static const List<Achievement> masterAchievements = [
    // 1. 누적 점령 타일
    Achievement(id: 'ACH_CAP_T1', titleKey: 'achCapT1Title', descriptionKey: 'achCapT1Desc', category: AchievementCategory.capturedTiles, threshold: 10, tier: 1),
    Achievement(id: 'ACH_CAP_T2', titleKey: 'achCapT2Title', descriptionKey: 'achCapT2Desc', category: AchievementCategory.capturedTiles, threshold: 100, tier: 2),
    Achievement(id: 'ACH_CAP_T3', titleKey: 'achCapT3Title', descriptionKey: 'achCapT3Desc', category: AchievementCategory.capturedTiles, threshold: 500, tier: 3),
    Achievement(id: 'ACH_CAP_T4', titleKey: 'achCapT4Title', descriptionKey: 'achCapT4Desc', category: AchievementCategory.capturedTiles, threshold: 2000, tier: 4),

    // 2. 적 진영 점령 타일
    Achievement(id: 'ACH_INV_T1', titleKey: 'achInvT1Title', descriptionKey: 'achInvT1Desc', category: AchievementCategory.enemyCapturedTiles, threshold: 5, tier: 1),
    Achievement(id: 'ACH_INV_T2', titleKey: 'achInvT2Title', descriptionKey: 'achInvT2Desc', category: AchievementCategory.enemyCapturedTiles, threshold: 30, tier: 2),
    Achievement(id: 'ACH_INV_T3', titleKey: 'achInvT3Title', descriptionKey: 'achInvT3Desc', category: AchievementCategory.enemyCapturedTiles, threshold: 150, tier: 3),
    Achievement(id: 'ACH_INV_T4', titleKey: 'achInvT4Title', descriptionKey: 'achInvT4Desc', category: AchievementCategory.enemyCapturedTiles, threshold: 500, tier: 4),

    // 3. 누적 이동 타일 수
    Achievement(id: 'ACH_MOV_T1', titleKey: 'achMovT1Title', descriptionKey: 'achMovT1Desc', category: AchievementCategory.totalMovedTiles, threshold: 50, tier: 1),
    Achievement(id: 'ACH_MOV_T2', titleKey: 'achMovT2Title', descriptionKey: 'achMovT2Desc', category: AchievementCategory.totalMovedTiles, threshold: 500, tier: 2),
    Achievement(id: 'ACH_MOV_T3', titleKey: 'achMovT3Title', descriptionKey: 'achMovT3Desc', category: AchievementCategory.totalMovedTiles, threshold: 3000, tier: 3),
    Achievement(id: 'ACH_MOV_T4', titleKey: 'achMovT4Title', descriptionKey: 'achMovT4Desc', category: AchievementCategory.totalMovedTiles, threshold: 10000, tier: 4),

    // 4. 일일 최고 이동 타일 수
    Achievement(id: 'ACH_DMOV_T1', titleKey: 'achDmovT1Title', descriptionKey: 'achDmovT1Desc', category: AchievementCategory.dailyMovedTiles, threshold: 30, tier: 1),
    Achievement(id: 'ACH_DMOV_T2', titleKey: 'achDmovT2Title', descriptionKey: 'achDmovT2Desc', category: AchievementCategory.dailyMovedTiles, threshold: 100, tier: 2),
    Achievement(id: 'ACH_DMOV_T3', titleKey: 'achDmovT3Title', descriptionKey: 'achDmovT3Desc', category: AchievementCategory.dailyMovedTiles, threshold: 300, tier: 3),
    Achievement(id: 'ACH_DMOV_T4', titleKey: 'achDmovT4Title', descriptionKey: 'achDmovT4Desc', category: AchievementCategory.dailyMovedTiles, threshold: 1000, tier: 4),

    // 5. 위성 스캔 점령
    Achievement(id: 'ACH_SAT_CAP_T1', titleKey: 'achSatCapT1Title', descriptionKey: 'achSatCapT1Desc', category: AchievementCategory.satelliteCapture, threshold: 3, tier: 1),
    Achievement(id: 'ACH_SAT_CAP_T2', titleKey: 'achSatCapT2Title', descriptionKey: 'achSatCapT2Desc', category: AchievementCategory.satelliteCapture, threshold: 20, tier: 2),
    Achievement(id: 'ACH_SAT_CAP_T3', titleKey: 'achSatCapT3Title', descriptionKey: 'achSatCapT3Desc', category: AchievementCategory.satelliteCapture, threshold: 100, tier: 3),
    Achievement(id: 'ACH_SAT_CAP_T4', titleKey: 'achSatCapT4Title', descriptionKey: 'achSatCapT4Desc', category: AchievementCategory.satelliteCapture, threshold: 300, tier: 4),

    // 6. 위성 스캔 정보 조회
    Achievement(id: 'ACH_SAT_INF_T1', titleKey: 'achSatInfT1Title', descriptionKey: 'achSatInfT1Desc', category: AchievementCategory.satelliteInfo, threshold: 5, tier: 1),
    Achievement(id: 'ACH_SAT_INF_T2', titleKey: 'achSatInfT2Title', descriptionKey: 'achSatInfT2Desc', category: AchievementCategory.satelliteInfo, threshold: 30, tier: 2),
    Achievement(id: 'ACH_SAT_INF_T3', titleKey: 'achSatInfT3Title', descriptionKey: 'achSatInfT3Desc', category: AchievementCategory.satelliteInfo, threshold: 150, tier: 3),
    Achievement(id: 'ACH_SAT_INF_T4', titleKey: 'achSatInfT4Title', descriptionKey: 'achSatInfT4Desc', category: AchievementCategory.satelliteInfo, threshold: 500, tier: 4),

    // 7. 본부 기지 요새화 (threshold는 충족해야 할 H3 Ring 링 깊이를 가리킵니다)
    Achievement(id: 'ACH_HQ_FORT_T1', titleKey: 'achHqFortT1Title', descriptionKey: 'achHqFortT1Desc', category: AchievementCategory.hqFortification, threshold: 1, tier: 1),
    Achievement(id: 'ACH_HQ_FORT_T2', titleKey: 'achHqFortT2Title', descriptionKey: 'achHqFortT2Desc', category: AchievementCategory.hqFortification, threshold: 2, tier: 2),
    Achievement(id: 'ACH_HQ_FORT_T3', titleKey: 'achHqFortT3Title', descriptionKey: 'achHqFortT3Desc', category: AchievementCategory.hqFortification, threshold: 3, tier: 3),
    Achievement(id: 'ACH_HQ_FORT_T4', titleKey: 'achHqFortT4Title', descriptionKey: 'achHqFortT4Desc', category: AchievementCategory.hqFortification, threshold: 4, tier: 4),

    // 8. 보유 골드 재화량
    Achievement(id: 'ACH_GOLD_T1', titleKey: 'achGoldT1Title', descriptionKey: 'achGoldT1Desc', category: AchievementCategory.goldAmount, threshold: 1000, tier: 1),
    Achievement(id: 'ACH_GOLD_T2', titleKey: 'achGoldT2Title', descriptionKey: 'achGoldT2Desc', category: AchievementCategory.goldAmount, threshold: 10000, tier: 2),
    Achievement(id: 'ACH_GOLD_T3', titleKey: 'achGoldT3Title', descriptionKey: 'achGoldT3Desc', category: AchievementCategory.goldAmount, threshold: 50000, tier: 3),
    Achievement(id: 'ACH_GOLD_T4', titleKey: 'achGoldT4Title', descriptionKey: 'achGoldT4Desc', category: AchievementCategory.goldAmount, threshold: 200000, tier: 4),

    // 9. 본진 이동 횟수
    Achievement(id: 'ACH_BASE_MOV_T1', titleKey: 'achBaseMovT1Title', descriptionKey: 'achBaseMovT1Desc', category: AchievementCategory.mainBaseMove, threshold: 1, tier: 1),
    Achievement(id: 'ACH_BASE_MOV_T2', titleKey: 'achBaseMovT2Title', descriptionKey: 'achBaseMovT2Desc', category: AchievementCategory.mainBaseMove, threshold: 3, tier: 2),
    Achievement(id: 'ACH_BASE_MOV_T3', titleKey: 'achBaseMovT3Title', descriptionKey: 'achBaseMovT3Desc', category: AchievementCategory.mainBaseMove, threshold: 10, tier: 3),
    Achievement(id: 'ACH_BASE_MOV_T4', titleKey: 'achBaseMovT4Title', descriptionKey: 'achBaseMovT4Desc', category: AchievementCategory.mainBaseMove, threshold: 30, tier: 4),
  ];
}

/// 플레이어가 획득하여 해금 완료된 개별 업적 상태 정보를 담는 데이터 모델 클래스
class UserAchievement {
  final String userId;
  final String achievementId;
  final DateTime unlockedAt;

  UserAchievement({
    required this.userId,
    required this.achievementId,
    required this.unlockedAt,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      userId: json['user_id'] as String,
      achievementId: json['achievement_id'] as String,
      unlockedAt: DateTime.parse(json['unlocked_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'achievement_id': achievementId,
      'unlocked_at': unlockedAt.toIso8601String(),
    };
  }
}
