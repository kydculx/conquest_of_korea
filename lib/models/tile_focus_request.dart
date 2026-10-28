import 'package:latlong2/latlong.dart';

/// 지도에서 특정 타일을 보여주고 잠시 강조하기 위한 요청 정보.
class TileFocusRequest {
  /// 화면 중앙에 배치할 타일 ID (예: hex_q_r)
  final String tileId;

  /// 타일 중심의 지리 좌표
  final LatLng destination;

  /// 타일을 깜빡이며 강조할 시간
  final Duration highlightDuration;

  const TileFocusRequest({
    required this.tileId,
    required this.destination,
    this.highlightDuration = const Duration(seconds: 2),
  });
}
