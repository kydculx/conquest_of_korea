import { useEffect, useState, useRef } from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';
import {
  fetchTiles,
  fetchUsers,
  fetchUserFootprints,
  fetchUserCapturedTiles,
  formatTileCoords,
  adminCaptureTile,
  neutralizeTile,
} from '../api';
import { supabase } from '../supabase';
import { Radio, Compass, Layers, Users, Map as MapIcon, Zap, Camera, X } from 'lucide-react';

const originLat = 37.5665;
const originLng = 126.9780;
const hexSize = 100.0; // 100m 정밀 타일 규격

const GOOGLE_MAPS_API_KEY = import.meta.env.VITE_GOOGLE_MAPS_API_KEY;

const DARK_MAP_STYLES = [
  { elementType: 'geometry', stylers: [{ color: '#151b26' }] },
  { elementType: 'labels.text.fill', stylers: [{ color: '#8b98a5' }] },
  { elementType: 'labels.text.stroke', stylers: [{ color: '#151b26' }] },
  {
    featureType: 'administrative',
    elementType: 'geometry',
    stylers: [{ color: '#2b3648' }],
  },
  {
    featureType: 'poi',
    elementType: 'labels.text.fill',
    stylers: [{ color: '#6b7a8c' }],
  },
  {
    featureType: 'poi.park',
    elementType: 'geometry',
    stylers: [{ color: '#1b2a2a' }],
  },
  {
    featureType: 'road',
    elementType: 'geometry',
    stylers: [{ color: '#263041' }],
  },
  {
    featureType: 'road',
    elementType: 'geometry.stroke',
    stylers: [{ color: '#1a2230' }],
  },
  {
    featureType: 'road',
    elementType: 'labels.text.fill',
    stylers: [{ color: '#94a3b8' }],
  },
  { featureType: 'transit', stylers: [{ visibility: 'off' }] },
  {
    featureType: 'water',
    elementType: 'geometry',
    stylers: [{ color: '#0b1220' }],
  },
  {
    featureType: 'water',
    elementType: 'labels.text.fill',
    stylers: [{ color: '#4b5e78' }],
  },
];

function svgDataUri(svg) {
  return `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(svg)}`;
}

const CAMERA_ICON_URL = svgDataUri(`
  <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 22 22">
    <circle cx="11" cy="11" r="10.5" fill="rgba(0,0,0,0.55)" stroke="#00ffcc" stroke-width="1"/>
    <g transform="translate(5 5) scale(0.5)" fill="none" stroke="#ffffff" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2.5-3z"/>
      <circle cx="12" cy="13" r="3"/>
    </g>
  </svg>
`);

const HQ_ICON_URL = svgDataUri(`
  <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 18 18">
    <circle cx="9" cy="9" r="7" fill="#FFD700" stroke="#ffffff" stroke-width="2"/>
  </svg>
`);

const MY_LOCATION_ICON_URL = svgDataUri(`
  <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 14 14">
    <circle cx="7" cy="7" r="6" fill="#00e5ff" stroke="#ffffff" stroke-width="2"/>
  </svg>
`);

let googleMapsPromise = null;

function loadGoogleMaps() {
  if (window.google?.maps) return Promise.resolve(window.google.maps);
  if (googleMapsPromise) return googleMapsPromise;
  if (!GOOGLE_MAPS_API_KEY) {
    return Promise.reject(
      new Error(
        'Google Maps API 키가 없습니다. conquest_admin/.env에 VITE_GOOGLE_MAPS_API_KEY를 설정해 주세요.'
      )
    );
  }

  googleMapsPromise = new Promise((resolve, reject) => {
    const callbackName = '__conquestAdminGoogleMapsReady';
    window[callbackName] = () => {
      delete window[callbackName];
      resolve(window.google.maps);
    };

    const script = document.createElement('script');
    script.src = `https://maps.googleapis.com/maps/api/js?key=${encodeURIComponent(
      GOOGLE_MAPS_API_KEY
    )}&v=weekly&loading=async&callback=${callbackName}`;
    script.async = true;
    script.defer = true;
    script.onerror = () => {
      delete window[callbackName];
      googleMapsPromise = null;
      reject(new Error('Google Maps 스크립트를 불러오지 못했습니다. API 키와 네트워크를 확인해 주세요.'));
    };
    document.head.appendChild(script);
  });

  return googleMapsPromise;
}


// 헥스 그리드 좌표를 경위도로 변환
function hexToLatLng(q, r) {
  const x = Math.sqrt(3) * q + (Math.sqrt(3) / 2) * r;
  const y = (3 / 2) * r;

  const latRad = originLat * Math.PI / 180;
  const lat = (y * hexSize / 111320) + originLat;
  const lng = (x * hexSize / (111320 * Math.cos(latRad))) + originLng;

  return [lat, lng];
}

// 헥스 꼭짓점 6개 경위도 배열 계산
function getHexCorners(q, r) {
  const center = hexToLatLng(q, r);
  const latRad = originLat * Math.PI / 180;
  const latScale = hexSize / 111320;
  const lngScale = hexSize / (111320 * Math.cos(latRad));
  const corners = [];

  for (let i = 0; i < 6; i++) {
    const angleDeg = 60.0 * i - 30.0;
    const angleRad = (Math.PI / 180.0) * angleDeg;
    const lat = center[0] + latScale * Math.sin(angleRad);
    const lng = center[1] + lngScale * Math.cos(angleRad);
    corners.push([lat, lng]);
  }
  return corners;
}

function parseTileId(tileId) {
  const parts = String(tileId).split('_');
  if (parts.length < 3) return null;

  const q = Number(parts[parts.length - 2]);
  const r = Number(parts[parts.length - 1]);
  if (!Number.isFinite(q) || !Number.isFinite(r)) return null;

  return { q, r };
}

export default function DashboardTab() {

  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const hqParam = searchParams.get('hq');
  const footprintsUserId = searchParams.get('footprints');
  const footprintNickname = searchParams.get('nickname') || '';
  const tilesUserId = searchParams.get('tiles');
  const tilesNickname = (footprintsUserId ? '' : searchParams.get('nickname')) || '';

  const [tiles, setTiles] = useState([]);
  const [users, setUsers] = useState([]);
  const [photos, setPhotos] = useState([]);
  const [photoCounts, setPhotoCounts] = useState({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const [footprintTiles, setFootprintTiles] = useState([]);
  const [footprintLoadedId, setFootprintLoadedId] = useState(null);
  const [footprintError, setFootprintError] = useState(null);
  const footprintLoading = !!footprintsUserId && footprintLoadedId !== footprintsUserId;

  const [userTiles, setUserTiles] = useState([]);
  const [userTilesLoadedId, setUserTilesLoadedId] = useState(null);
  const [userTilesError, setUserTilesError] = useState(null);
  const userTilesLoading = !!tilesUserId && userTilesLoadedId !== tilesUserId;

  const [selectedTileId, setSelectedTileId] = useState(null);
  const [isGalleryOpen, setIsGalleryOpen] = useState(false);

  // 글로벌 윈도우 객체에 사진첩 모달 호출 핸들러 등록
  useEffect(() => {
    window.openAdminGallery = (tileId) => {
      setSelectedTileId(tileId);
      setIsGalleryOpen(true);
    };
    return () => {
      delete window.openAdminGallery;
    };
  }, []);

  const mapRef = useRef(null);
  const mapInstance = useRef(null);
  const polygonsRef = useRef([]);
  const photoMarkersRef = useRef([]);
  const myLocationMarker = useRef(null);
  const hqMarker = useRef(null);
  const infoWindowRef = useRef(null);
  const [isSatellite, setIsSatellite] = useState(false);
  const [mapReady, setMapReady] = useState(false);
  const [mapError, setMapError] = useState(null);
  const [showPhotoMarkers, setShowPhotoMarkers] = useState(true);
  const initialFitDone = useRef(false);
  const actionInFlightRef = useRef(false);
  const adminActionRef = useRef({ capture: null, neutralize: null });

  const handleGoToMyLocation = () => {
    if (!mapInstance.current || !window.google?.maps) return;

    if (!navigator.geolocation) {
      alert('이 브라우저는 위치 정보를 지원하지 않습니다.');
      return;
    }

    navigator.geolocation.getCurrentPosition(
      (position) => {
        const { latitude, longitude } = position.coords;
        const maps = window.google.maps;
        const map = mapInstance.current;
        const location = { lat: latitude, lng: longitude };

        map.setCenter(location);
        map.setZoom(15);

        if (myLocationMarker.current) {
          myLocationMarker.current.setMap(null);
        }

        myLocationMarker.current = new maps.Marker({
          position: location,
          map,
          icon: {
            url: MY_LOCATION_ICON_URL,
            scaledSize: new maps.Size(14, 14),
            anchor: new maps.Point(7, 7),
          },
          zIndex: 700,
        });
      },
      (error) => {
        console.error(error);
        alert('현재 위치 정보를 가져올 수 없습니다. 위치 권한 허용 여부를 확인해 주세요.');
      },
      { enableHighAccuracy: true }
    );
  };

  // 데이터 통합 로딩 함수
  const loadData = async () => {
    try {
      const fetchAllPhotos = async () => {
        const PAGE_SIZE = 1000;
        let allRows = [];
        let from = 0;
        for (let guard = 0; guard < 10; guard++) {
          const { data, error } = await supabase
            .from('tile_photos')
            .select('*')
            .order('created_at', { ascending: false })
            .range(from, from + PAGE_SIZE - 1);
          if (error) throw error;
          const rows = data || [];
          allRows = allRows.concat(rows);
          if (rows.length < PAGE_SIZE) break;
          from += PAGE_SIZE;
        }
        return allRows;
      };
      const [tilesData, usersData, photosRows] = await Promise.all([
        fetchTiles(),
        fetchUsers(),
        fetchAllPhotos(),
      ]);
      setTiles(tilesData);
      setUsers(usersData);
      setPhotos(photosRows || []);

      const counts = {};
      if (photosRows) {
        photosRows.forEach(p => {
          const tid = p.tile_id;
          counts[tid] = (counts[tid] || 0) + 1;
        });
      }
      setPhotoCounts(counts);
    } catch (err) {
      console.error(err);
      setError('실시간 지도 데이터를 불러오는 중 에러가 발생했습니다.');
    } finally {
      setLoading(false);
    }
  };

  const refreshAfterAction = async () => {
    await loadData();
    if (!tilesUserId) return;

    try {
      const rows = await fetchUserCapturedTiles(tilesUserId);
      setUserTiles(rows || []);
      setUserTilesLoadedId(tilesUserId);
    } catch (err) {
      console.error(err);
    }
  };

  const handleAdminCapture = async (tileId, q, r) => {
    if (actionInFlightRef.current) return;

    const confirmed = window.confirm(
      `이 타일(${formatTileCoords(tileId)})을 관리자 계정으로 점령할까요?`
    );
    if (!confirmed) return;

    actionInFlightRef.current = true;
    try {
      const captured = await adminCaptureTile(tileId, q, r);
      if (!captured) throw new Error('점령 처리 결과를 확인할 수 없습니다.');
      await refreshAfterAction();
      alert('관리자 계정으로 점령했습니다.');
    } catch (err) {
      console.error(err);
      alert(err?.message || '타일 점령 처리 중 오류가 발생했습니다.');
    } finally {
      actionInFlightRef.current = false;
    }
  };

  const handleAdminNeutralize = async (tileId) => {
    if (actionInFlightRef.current) return;

    const confirmed = window.confirm(
      `이 타일(${formatTileCoords(tileId)})을 중립으로 만들까요?`
    );
    if (!confirmed) return;

    actionInFlightRef.current = true;
    try {
      const removed = await neutralizeTile(tileId);
      if (!removed) throw new Error('이미 중립 상태이거나 타일을 찾을 수 없습니다.');
      await refreshAfterAction();
      alert('타일을 중립으로 만들었습니다.');
    } catch (err) {
      console.error(err);
      alert(err?.message || '타일 중립화 처리 중 오류가 발생했습니다.');
    } finally {
      actionInFlightRef.current = false;
    }
  };

  useEffect(() => {
    adminActionRef.current = {
      capture: handleAdminCapture,
      neutralize: handleAdminNeutralize,
    };
  });

  useEffect(() => {
    window.adminCaptureTile = (tileId, q, r) =>
      adminActionRef.current.capture?.(tileId, q, r);
    window.adminNeutralizeTile = (tileId) =>
      adminActionRef.current.neutralize?.(tileId);

    return () => {
      delete window.adminCaptureTile;
      delete window.adminNeutralizeTile;
    };
  }, []);

  // Supabase 실시간 구독 및 폴링 바인딩
  useEffect(() => {
    loadData();

    const channel = supabase
      .channel('schema-db-changes')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'captured_tiles' },
        () => {
          loadData();
        }
      )
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'tile_photos' },
        () => {
          loadData();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  // 1-3. 발자취 조회
  useEffect(() => {
    if (!footprintsUserId) return;
    let active = true;
    const applyRows = (rows) => {
      if (!active) return;
      setFootprintTiles(rows || []);
      setFootprintError(null);
      setFootprintLoadedId(footprintsUserId);
    };
    const failLoad = (err) => {
      console.error(err);
      if (!active) return;
      setFootprintTiles([]);
      setFootprintError('발자취를 불러오지 못했습니다. 관리자 조회 권한(RLS)을 확인해 주세요.');
      setFootprintLoadedId(footprintsUserId);
    };
    fetchUserFootprints(footprintsUserId).then(applyRows).catch(failLoad);

    const fpChannel = supabase
      .channel(`footprints-${footprintsUserId}`)
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'user_footprints', filter: `user_id=eq.${footprintsUserId}` },
        () => {
          fetchUserFootprints(footprintsUserId).then(applyRows).catch(failLoad);
        }
      )
      .subscribe();

    return () => {
      active = false;
      supabase.removeChannel(fpChannel);
    };
  }, [footprintsUserId]);

  // 1-3b. 특정 사용자 점령지 조회 (타 사용자 제외하고 해당 사용자만 표시)
  useEffect(() => {
    if (!tilesUserId) return;
    let active = true;
    const applyRows = (rows) => {
      if (!active) return;
      setUserTiles(rows || []);
      setUserTilesError(null);
      setUserTilesLoadedId(tilesUserId);
    };
    const failLoad = (err) => {
      console.error(err);
      if (!active) return;
      setUserTiles([]);
      setUserTilesError('점령지를 불러오지 못했습니다. 관리자 조회 권한(RLS)을 확인해 주세요.');
      setUserTilesLoadedId(tilesUserId);
    };
    fetchUserCapturedTiles(tilesUserId).then(applyRows).catch(failLoad);

    const tilesChannel = supabase
      .channel(`user-tiles-${tilesUserId}`)
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'captured_tiles', filter: `user_id=eq.${tilesUserId}` },
        () => {
          fetchUserCapturedTiles(tilesUserId).then(applyRows).catch(failLoad);
        }
      )
      .subscribe();

    return () => {
      active = false;
      supabase.removeChannel(tilesChannel);
    };
  }, [tilesUserId]);

  // 1. Google Maps 초기화
  useEffect(() => {
    const mapElement = mapRef.current;
    let cancelled = false;
    if (!mapElement || mapInstance.current) return;

    const mapContainer = document.createElement('div');
    mapContainer.style.width = '100%';
    mapContainer.style.height = '100%';
    mapElement.replaceChildren(mapContainer);

    setMapError(null);

    loadGoogleMaps()
      .then((maps) => {
        if (cancelled) return;

        const map = new maps.Map(mapContainer, {
          center: { lat: originLat, lng: originLng },
          zoom: 14,
          mapTypeId: 'roadmap',
          styles: DARK_MAP_STYLES,
          backgroundColor: '#060911',
          zoomControl: true,
          mapTypeControl: false,
          streetViewControl: false,
          fullscreenControl: false,
          clickableIcons: false,
        });

        mapInstance.current = map;
        infoWindowRef.current = new maps.InfoWindow();
        map.addListener('click', () => infoWindowRef.current?.close());
        setMapReady(true);
      })
      .catch((err) => {
        if (cancelled) return;
        console.error(err);
        setMapError(err?.message || 'Google Maps를 초기화하지 못했습니다.');
      });

    return () => {
      cancelled = true;

      polygonsRef.current.forEach((polygon) => polygon.setMap(null));
      polygonsRef.current = [];
      photoMarkersRef.current.forEach((marker) => marker.setMap(null));
      photoMarkersRef.current = [];
      myLocationMarker.current?.setMap(null);
      myLocationMarker.current = null;
      hqMarker.current?.setMap(null);
      hqMarker.current = null;
      infoWindowRef.current?.close();
      infoWindowRef.current = null;

      if (mapInstance.current && window.google?.maps) {
        window.google.maps.event.clearInstanceListeners(mapInstance.current);
      }
      mapInstance.current = null;

      if (mapElement) {
        mapElement.replaceChildren();
      }
    };
  }, []);

  useEffect(() => {
    if (!mapReady || !mapInstance.current || !window.google?.maps) return;

    const map = mapInstance.current;
    const handleZoom = () => setShowPhotoMarkers(map.getZoom() >= 11);
    handleZoom();
    const listener = map.addListener('zoom_changed', handleZoom);

    return () => {
      window.google?.maps?.event.removeListener(listener);
    };
  }, [mapReady]);

  // 1-2. 위성/일반 지도 전환
  useEffect(() => {
    if (!mapReady || !mapInstance.current) return;
    mapInstance.current.setMapTypeId(isSatellite ? 'hybrid' : 'roadmap');
  }, [isSatellite, mapReady]);

  // 2. 점령지 데이터 수신 시 헥사곤 폴리곤 실시간 렌더링
  useEffect(() => {
    if (!mapReady || !mapInstance.current || !window.google?.maps) return;

    const maps = window.google.maps;
    const map = mapInstance.current;
    polygonsRef.current.forEach((polygon) => polygon.setMap(null));
    polygonsRef.current = [];
    infoWindowRef.current?.close();

    const footprintMode = !!footprintsUserId;
    const userTilesMode = !!tilesUserId && !footprintsUserId;
    const sourceTiles = footprintMode
      ? footprintTiles.map(f => ({
          id: f.tile_id,
          user_id: footprintsUserId,
          color_hex: '#00FFCC',
          recorded_at: f.recorded_at,
        }))
      : userTilesMode
        ? userTiles
        : tiles;

    if (sourceTiles.length === 0) return;

    const points = [];
    const bounds = new maps.LatLngBounds();
    let renderedCount = 0;

    sourceTiles.forEach(tile => {
      let q = Number(tile.q);
      let r = Number(tile.r);
      if (Number.isNaN(q) || Number.isNaN(r)) {
        const parts = String(tile.id || '').split('_');
        if (parts.length >= 3) {
          q = parseInt(parts[parts.length - 2], 10);
          r = parseInt(parts[parts.length - 1], 10);
        }
        if (Number.isNaN(q) || Number.isNaN(r)) return;
      }
      let corners;
      try {
        corners = getHexCorners(q, r);
      } catch {
        return;
      }
      if (!corners || corners.length !== 6) return;
      const center = hexToLatLng(q, r);
      const user = users.find(u => u.id === tile.user_id);
      const ownerName = footprintNickname || tilesNickname || (user ? (user.nickname || '미등록 사용자') : '미등록 사용자');
      const rawColor = tile.color_hex || user?.color_hex || '#00e5ff';
      const color = /^#[0-9a-fA-F]{6}$/.test(rawColor) ? rawColor : '#00e5ff';
      const tileId = tile.id || `hex_${q}_${r}`;
      const isHQ = hqParam === tileId;

      const polygon = new maps.Polygon({
        paths: corners.map(([lat, lng]) => ({ lat, lng })),
        strokeColor: color,
        strokeOpacity: 0.95,
        strokeWeight: isHQ ? 4 : 2,
        fillColor: color,
        fillOpacity: isHQ ? 0.55 : 0.45,
        map,
        zIndex: isHQ ? 10 : 1,
      });

      const count = photoCounts[tileId] || 0;
      const galleryText = count > 0
        ? `<button onclick="window.openAdminGallery('${tileId}')" style="background: #3b82f6; color: white; border: none; padding: 2px 6px; border-radius: 4px; font-size: 0.7rem; cursor: pointer; font-weight: bold; margin-top: 2px;">사진 ${count}장 보기</button>`
        : '<span style="color: var(--text-secondary);">없음</span>';

      const capturedAt = (footprintMode ? tile.recorded_at : tile.captured_at)
        ? new Date(footprintMode ? tile.recorded_at : tile.captured_at).toLocaleString('ko-KR')
        : '-';

      const adminActions = footprintMode ? '' : `
        <div style="display: flex; gap: 6px; margin-top: 8px; flex-wrap: wrap;">
          <button onclick="window.adminCaptureTile('${tileId}', ${q}, ${r})" style="background: #0ea5e9; color: white; border: none; padding: 4px 8px; border-radius: 5px; font-size: 0.72rem; font-weight: 700; cursor: pointer;">관리자로 점령</button>
          <button onclick="window.adminNeutralizeTile('${tileId}')" style="background: #ef4444; color: white; border: none; padding: 4px 8px; border-radius: 5px; font-size: 0.72rem; font-weight: 700; cursor: pointer;">중립으로</button>
        </div>
      `;

      const popupContent = `
        <div style="font-family: monospace; color: var(--text-primary); line-height: 1.4; font-size: 0.8rem;">
          <strong style="color: ${color}">[사용자]</strong> ${ownerName}<br/>
          <strong>[타일]</strong> ${formatTileCoords(tileId)}<br/>
          ${footprintMode
            ? `<strong>[발자취]</strong> ${capturedAt}<br/>`
            : `<strong>[점령]</strong> ${tile.capture_count ?? 1}회 중첩<br/>
          <strong>[점령날짜]</strong> ${capturedAt}<br/>`}
          <strong>[갤러리]</strong> ${galleryText}<br/>
          ${adminActions}
          <strong>[좌표]</strong> Q:${q}, R:${r}
        </div>
      `;

      polygon.addListener('click', () => {
        const infoWindow = infoWindowRef.current;
        if (!infoWindow) return;
        infoWindow.setContent(popupContent);
        infoWindow.setPosition({ lat: center[0], lng: center[1] });
        infoWindow.open(map);
      });

      polygonsRef.current.push(polygon);
      renderedCount += 1;
      points.push(center);
      bounds.extend({ lat: center[0], lng: center[1] });
    });

    if (renderedCount === 0) return;

    const focusPoint = (point, zoom) => {
      map.setCenter({ lat: point[0], lng: point[1] });
      map.setZoom(zoom);
    };

    if (footprintMode || userTilesMode) {
      if (points.length === 1) {
        focusPoint(points[0], 14);
      } else if (points.length > 1) {
        map.fitBounds(bounds, 40);
      }
      if (footprintMode) return;
    }

    if (hqParam) {
      const hqTile = tiles.find(t => t.id === hqParam || `hex_${t.q}_${t.r}` === hqParam);
      if (hqTile) {
        const hqQ = Number(hqTile.q);
        const hqR = Number(hqTile.r);
        if (!Number.isNaN(hqQ) && !Number.isNaN(hqR)) {
          focusPoint(hexToLatLng(hqQ, hqR), 15);
          return;
        }
      }
      const parts = hqParam.split('_');
      if (parts.length >= 3) {
        const q = parseInt(parts[parts.length - 2], 10);
        const r = parseInt(parts[parts.length - 1], 10);
        if (!Number.isNaN(q) && !Number.isNaN(r)) {
          focusPoint(hexToLatLng(q, r), 15);
          return;
        }
      }
    }

    if (!initialFitDone.current && points.length > 0) {
      initialFitDone.current = true;
      if (points.length === 1) {
        focusPoint(points[0], 14);
      } else {
        map.fitBounds(bounds, 40);
      }
    }
  }, [tiles, users, photoCounts, hqParam, mapReady, footprintTiles, footprintsUserId, footprintNickname, userTiles, tilesUserId, tilesNickname]);

  // 2-1. 사진이 등록된 타일에 카메라 아이콘 마커 표시
  useEffect(() => {
    if (!mapReady || !mapInstance.current || !window.google?.maps) return;

    const maps = window.google.maps;
    const map = mapInstance.current;
    photoMarkersRef.current.forEach((marker) => marker.setMap(null));
    photoMarkersRef.current = [];

    if (footprintsUserId) return;

    const userTilesMode = !!tilesUserId && !footprintsUserId;
    if (!userTilesMode && !showPhotoMarkers) return;

    const allowedTileIds = userTilesMode
      ? new Set(userTiles.map((tile) => tile.id || `hex_${tile.q}_${tile.r}`))
      : null;

    Object.entries(photoCounts).forEach(([tileId, count]) => {
      if (!count) return;
      if (allowedTileIds && !allowedTileIds.has(tileId)) return;

      const coords = parseTileId(tileId);
      if (!coords) return;

      const [lat, lng] = hexToLatLng(coords.q, coords.r);
      const marker = new maps.Marker({
        position: { lat, lng },
        map,
        icon: {
          url: CAMERA_ICON_URL,
          scaledSize: new maps.Size(22, 22),
          anchor: new maps.Point(11, 11),
        },
        title: `사진 ${count}장`,
        zIndex: 600,
      });

      marker.addListener('click', () => {
        if (typeof window.openAdminGallery === 'function') {
          window.openAdminGallery(tileId);
        }
      });

      photoMarkersRef.current.push(marker);
    });

    return () => {
      photoMarkersRef.current.forEach((marker) => marker.setMap(null));
      photoMarkersRef.current = [];
    };
  }, [mapReady, showPhotoMarkers, photoCounts, tilesUserId, footprintsUserId, userTiles]);

  // 2-2. 본진 이동(hq) 파라미터 시 지도 포커스 + 하이라이트 마커 표시
  useEffect(() => {
    if (hqMarker.current) {
      hqMarker.current.setMap(null);
      hqMarker.current = null;
    }

    if (!mapReady || !mapInstance.current || !hqParam || footprintsUserId || !window.google?.maps) return;

    const parts = hqParam.split('_');
    if (parts.length < 3) return;
    const q = parseInt(parts[parts.length - 2], 10);
    const r = parseInt(parts[parts.length - 1], 10);
    if (Number.isNaN(q) || Number.isNaN(r)) return;

    const maps = window.google.maps;
    const center = hexToLatLng(q, r);
    mapInstance.current.setCenter({ lat: center[0], lng: center[1] });
    mapInstance.current.setZoom(15);

    hqMarker.current = new maps.Marker({
      position: { lat: center[0], lng: center[1] },
      map: mapInstance.current,
      icon: {
        url: HQ_ICON_URL,
        scaledSize: new maps.Size(18, 18),
        anchor: new maps.Point(9, 9),
      },
      zIndex: 700,
    });
  }, [hqParam, mapReady, footprintsUserId]);

  if (error) {
    return <div style={{ color: 'var(--accent-red)', padding: '2rem' }}>{error}</div>;
  }

  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);
  const todayCaptureCount = tiles.filter((t) => {
    if (!t.captured_at) return false;
    return new Date(t.captured_at) >= todayStart;
  }).length;

  const kpiCards = [
    { label: '가입 사용자', value: users.length, sub: '누적 가입', tone: 'tone-blue', Icon: Users },
    { label: '누적 점령 타일', value: tiles.length, sub: '지도에 표시 중', tone: 'tone-green', Icon: MapIcon },
    { label: '오늘 점령', value: todayCaptureCount, sub: '자정 이후 집계', tone: 'tone-amber', Icon: Zap },
    { label: '현장 사진', value: photos.length, sub: '등록됨', tone: 'tone-rose', Icon: Camera },
  ];

  // 데이터 로드 완료 전 가드 정의
  return (
    <div className="section-stack">

      <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '1.2rem' }}>

        {footprintsUserId && (
          <div className="tactical-card banner-info">
            <span style={{ width: '12px', height: '12px', borderRadius: '3px', backgroundColor: '#00FFCC', display: 'inline-block' }} />
            <span style={{ fontWeight: 'bold', color: 'var(--text-primary)' }}>
              {footprintNickname ? `${footprintNickname}님의 발자취만 표시 중` : '선택한 사용자의 발자취만 표시 중'}
            </span>
            {!footprintLoading && !footprintError && (
              <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
                총 {footprintTiles.length.toLocaleString()}개
              </span>
            )}
            {footprintLoading && (
              <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>불러오는 중...</span>
            )}
            {footprintError && (
              <span style={{ fontSize: '0.8rem', color: 'var(--accent-red)' }}>{footprintError}</span>
            )}
            <button className="tactical-btn" onClick={() => navigate('/admin/dashboard')} style={{ marginLeft: 'auto' }}>
              전체 보기로 돌아가기
            </button>
          </div>
        )}

        {tilesUserId && !footprintsUserId && (
          <div className="tactical-card banner-info">
            <span style={{ width: '12px', height: '12px', borderRadius: '3px', backgroundColor: '#00e5ff', display: 'inline-block' }} />
            <span style={{ fontWeight: 'bold', color: 'var(--text-primary)' }}>
              {tilesNickname ? `${tilesNickname}님의 점령지만 표시 중` : '선택한 사용자의 점령지만 표시 중'}
            </span>
            {!userTilesLoading && !userTilesError && (
              <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
                총 {userTiles.length.toLocaleString()}개
              </span>
            )}
            {userTilesLoading && (
              <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>불러오는 중...</span>
            )}
            {userTilesError && (
              <span style={{ fontSize: '0.8rem', color: 'var(--accent-red)' }}>{userTilesError}</span>
            )}
            <button className="tactical-btn" onClick={() => navigate('/admin/dashboard')} style={{ marginLeft: 'auto' }}>
              전체 보기로 돌아가기
            </button>
          </div>
        )}

        <div className="stat-grid">
          {kpiCards.map((s) => (
            <div key={s.label} className="stat-card">
              <div className={`stat-icon ${s.tone}`}>
                <s.Icon size={18} />
              </div>
              <div style={{ minWidth: 0 }}>
                <div className="stat-label">{s.label}</div>
                <div className="stat-value">{s.value.toLocaleString()}</div>
                <div className="stat-sub">{s.sub}</div>
              </div>
            </div>
          ))}
        </div>

        {/* Google Maps 실시간 점령 지도 */}
        <div className="tactical-card map-card">
          <div className="card-head">
            <h3 className="card-title">
              <Radio size={17} />
              맵 모니터
              {!loading && !footprintsUserId && !tilesUserId && (
                <span className="card-sub">
                  {tiles.length.toLocaleString()}개 타일 표시 중
                </span>
              )}
              {footprintsUserId && !footprintLoading && !footprintError && (
                <span className="card-sub">
                  {footprintTiles.length.toLocaleString()}개 발자취 표시 중
                </span>
              )}
              {tilesUserId && !footprintsUserId && !userTilesLoading && !userTilesError && (
                <span className="card-sub">
                  {userTiles.length.toLocaleString()}개 점령지 표시 중
                </span>
              )}
            </h3>
            <span className="status-pill">
              <span className="status-dot" />
              실시간 연동 중
            </span>
          </div>
          <div className="map-wrapper">
            <button 
              onClick={() => setIsSatellite(!isSatellite)}
              className={`map-overlay-btn-satellite ${isSatellite ? 'active' : ''}`}
            >
              <Layers size={14} /> {isSatellite ? '일반 맵' : '위성 맵'}
            </button>
            <button
              onClick={handleGoToMyLocation}
              className="map-overlay-btn-location"
            >
              <Compass size={14} /> 내 위치로
            </button>
            <div
              ref={mapRef}
              className="map-element"
            />
            {mapError && (
              <div style={{
                position: 'absolute', top: 0, left: 0, width: '100%', height: '100%',
                background: 'rgba(10, 12, 16, 0.9)', backdropFilter: 'blur(4px)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                padding: '2rem', textAlign: 'center', zIndex: 20, borderRadius: '8px'
              }}>
                <div>
                  <div style={{ color: 'var(--accent-amber)', fontWeight: 'bold', marginBottom: '0.5rem' }}>
                    Google Maps를 불러올 수 없습니다
                  </div>
                  <div style={{ color: 'var(--text-secondary)', fontSize: '0.85rem', lineHeight: 1.6 }}>
                    {mapError}
                  </div>
                </div>
              </div>
            )}
            {loading && (
              <div style={{
                position: 'absolute', top: 0, left: 0, width: '100%', height: '100%',
                background: 'rgba(10, 12, 16, 0.6)', backdropFilter: 'blur(4px)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                zIndex: 10, borderRadius: '8px'
              }}>
                <div className="tactical-spinner" style={{ margin: 0 }} />
              </div>
            )}
            {!loading && tiles.length === 0 && !error && !footprintsUserId && (
              <div style={{
                position: 'absolute', top: 0, left: 0, width: '100%', height: '100%',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                zIndex: 5, pointerEvents: 'none'
              }}>
                <span style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>
                  표시할 점령 타일이 없습니다
                </span>
              </div>
            )}
            {footprintsUserId && !footprintLoading && footprintTiles.length === 0 && !footprintError && (
              <div style={{
                position: 'absolute', top: 0, left: 0, width: '100%', height: '100%',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                zIndex: 5, pointerEvents: 'none'
              }}>
                <span style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>
                  해당 사용자의 발자취가 없습니다
                </span>
              </div>
            )}
            {tilesUserId && !footprintsUserId && !userTilesLoading && userTiles.length === 0 && !userTilesError && (
              <div style={{
                position: 'absolute', top: 0, left: 0, width: '100%', height: '100%',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                zIndex: 5, pointerEvents: 'none'
              }}>
                <span style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>
                  해당 사용자의 점령 타일이 없습니다
                </span>
              </div>
            )}
          </div>
        </div>

      {/* 📸 관리자 전용 사진 갤러리 팝업 모달 */}
      {isGalleryOpen && (
        <div className="modal-overlay" onClick={() => setIsGalleryOpen(false)}>
          <div className="modal-card wide" onClick={(e) => e.stopPropagation()}>
            <button
              className="modal-close"
              onClick={() => setIsGalleryOpen(false)}
              aria-label="닫기"
            >
              <X size={18} />
            </button>
            <div className="modal-title">
              <Camera size={19} />
              <span>현장 사진 갤러리</span>
              <span className="card-sub">({formatTileCoords(selectedTileId)})</span>
            </div>

            {/* 사진 리스트 컨테이너 */}
            <div style={{
              maxHeight: '400px', overflowY: 'auto', display: 'flex', flexDirection: 'column',
              gap: '1.2rem', paddingRight: '0.25rem'
            }} className="custom-scrollbar">
              {photos.filter(p => p.tile_id === selectedTileId).length === 0 ? (
                <div style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>
                  등록된 사진이 없습니다.
                </div>
              ) : (
                photos.filter(p => p.tile_id === selectedTileId).map(photo => {
                  const dt = new Date(photo.created_at);
                  const dateStr = `${dt.getFullYear()}.${String(dt.getMonth() + 1).padStart(2, '0')}.${String(dt.getDate()).padStart(2, '0')} ${String(dt.getHours()).padStart(2, '0')}:${String(dt.getMinutes()).padStart(2, '0')}`;

                  return (
                    <div key={photo.id} style={{
                      display: 'flex', flexDirection: 'column', gap: '0.5rem',
                      background: 'rgba(15, 23, 42, 0.3)', borderRadius: '8px',
                      padding: '0.75rem', border: '1px solid rgba(255,255,255,0.05)'
                    }}>
                      <img 
                        src={photo.photo_url} 
                        alt="타일 사진" 
                        style={{
                          width: '100%', height: 'auto', maxHeight: '320px', objectFit: 'contain',
                          background: 'rgba(0, 0, 0, 0.3)',
                          borderRadius: '6px', border: '1px solid rgba(255,255,255,0.1)'
                        }}
                      />
                      {photo.comment && (
                        <div style={{ 
                          color: '#fff', fontSize: '0.75rem', marginBottom: '0.4rem', 
                          background: 'rgba(0, 255, 204, 0.05)', padding: '4px 8px', 
                          borderRadius: '4px', border: '1px solid rgba(0, 255, 204, 0.1)'
                        }}>
                          {photo.comment}
                        </div>
                      )}
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '0.75rem' }}>
                        <div>
                          <span style={{ color: 'var(--accent-cyan)', fontWeight: 'bold' }}>{photo.user_nickname}</span>
                          <span style={{ color: 'var(--text-muted)', marginLeft: '0.5rem' }}>{dateStr}</span>
                        </div>
                        {/* 관리자 직권 삭제 권한 */}
                        <button
                          onClick={async () => {
                            if (window.confirm('관리자 권한으로 이 사진을 영구 삭제하시겠습니까? (스토리지 물리 파일도 함께 정리됩니다.)')) {
                              try {
                                // 1. 스토리지 파일 삭제 시도 (실패해도 DB 삭제는 계속되도록 예외 격리)
                                try {
                                  const bucketMarker = 'tile-photos/';
                                  const markerIdx = photo.photo_url.indexOf(bucketMarker);
                                  if (markerIdx !== -1) {
                                    const storagePath = photo.photo_url.substring(markerIdx + bucketMarker.length);
                                    await supabase.storage.from('tile-photos').remove([storagePath]);
                                  }
                                } catch (storageErr) {
                                  console.warn('⚠️ 스토리지 파일 물리 삭제 실패:', storageErr);
                                }

                                // 2. RPC를 통한 RLS 우회 삭제 시도
                                const { error: rpcErr } = await supabase.rpc('delete_photo_by_admin', {
                                  p_photo_id: photo.id
                                });

                                if (rpcErr) {
                                  console.warn('⚠️ RPC 함수가 없어 일반 DELETE 쿼리로 대체합니다:', rpcErr);
                                  const { error: delErr } = await supabase.from('tile_photos').delete().eq('id', photo.id);
                                  if (delErr) throw delErr;
                                }

                                alert('사진이 성공적으로 강제 삭제되었습니다.');
                                loadData();
                              } catch (e) {
                                alert('삭제 중 오류 발생: ' + (e.message || JSON.stringify(e)));
                              }
                            }
                          }}
                          style={{
                            background: 'rgba(239, 68, 68, 0.1)', color: 'var(--accent-red)',
                            border: '1px solid rgba(239, 68, 68, 0.2)', padding: '2px 8px',
                            borderRadius: '4px', cursor: 'pointer', fontSize: '0.7rem'
                          }}
                        >
                          강제 삭제
                        </button>
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          </div>
        </div>
      )}
      </div>
    </div>
  );
}
