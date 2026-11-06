// Web Mercator 기반 헥스 그리드 변환 유틸리티
// 모바일 앱(lib/services/hex_service.dart)과 반드시 동일한 수식을 사용해야 합니다.

export const ORIGIN_LAT = 37.5665;
export const ORIGIN_LNG = 126.978;
export const HEX_SIZE = 100;

const EARTH_RADIUS = 6378137.0;
const ORIGIN_LAT_RAD = (ORIGIN_LAT * Math.PI) / 180;
const MERCATOR_SCALE = Math.cos(ORIGIN_LAT_RAD);

function hexToMeters(q, r, hexSize = HEX_SIZE) {
  const x = Math.sqrt(3) * q + (Math.sqrt(3) / 2) * r;
  const y = 1.5 * r;
  return [x * hexSize, y * hexSize];
}

function metersToLatLng(xMeters, yMeters) {
  const latRad =
    2 *
      Math.atan(
        Math.exp(yMeters / (EARTH_RADIUS * MERCATOR_SCALE)) *
          Math.tan(Math.PI / 4 + ORIGIN_LAT_RAD / 2)
      ) -
    Math.PI / 2;
  const lng =
    ORIGIN_LNG +
    (xMeters / (EARTH_RADIUS * MERCATOR_SCALE)) * (180 / Math.PI);
  return [(latRad * 180) / Math.PI, lng];
}

export function hexToLatLng(q, r, hexSize = HEX_SIZE) {
  const [xMeters, yMeters] = hexToMeters(q, r, hexSize);
  return metersToLatLng(xMeters, yMeters);
}

export function getHexCorners(q, r, hexSize = HEX_SIZE) {
  const [xMeters, yMeters] = hexToMeters(q, r, hexSize);
  const corners = [];

  for (let i = 0; i < 6; i += 1) {
    const angleDeg = 60.0 * i - 30.0;
    const angleRad = (Math.PI / 180.0) * angleDeg;
    corners.push(
      metersToLatLng(
        xMeters + Math.cos(angleRad) * hexSize,
        yMeters + Math.sin(angleRad) * hexSize
      )
    );
  }
  return corners;
}

function roundHalfAwayFromZero(value) {
  return Math.sign(value) * Math.round(Math.abs(value));
}

export function cubeRound(fracQ, fracR) {
  const fracS = -fracQ - fracR;
  let q = roundHalfAwayFromZero(fracQ);
  let r = roundHalfAwayFromZero(fracR);
  let s = roundHalfAwayFromZero(fracS);

  const qDiff = Math.abs(q - fracQ);
  const rDiff = Math.abs(r - fracR);
  const sDiff = Math.abs(s - fracS);

  if (qDiff > rDiff && qDiff > sDiff) {
    q = -r - s;
  } else if (rDiff > sDiff) {
    r = -q - s;
  }
  return { q, r };
}

export function latLngToHex(lat, lng, hexSize = HEX_SIZE) {
  const latRad = (lat * Math.PI) / 180;
  const xMeters =
    EARTH_RADIUS * ((lng - ORIGIN_LNG) * Math.PI) / 180 * MERCATOR_SCALE;
  const yMeters =
    EARTH_RADIUS *
    Math.log(
      Math.tan(Math.PI / 4 + latRad / 2) /
        Math.tan(Math.PI / 4 + ORIGIN_LAT_RAD / 2)
    ) *
    MERCATOR_SCALE;

  const x = xMeters / hexSize;
  const y = yMeters / hexSize;

  const q = (Math.sqrt(3) / 3) * x - (1 / 3) * y;
  const r = (2 / 3) * y;

  return cubeRound(q, r);
}
