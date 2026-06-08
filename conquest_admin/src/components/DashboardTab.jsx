import React, { useEffect, useState, useRef } from 'react';
import { fetchTiles, fetchUsers } from '../api';
import { supabase } from '../supabase';
import { Radio, Compass, Layers } from 'lucide-react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css'; // Leaflet 기본 레이아웃 스타일 직접 로드

const originLat = 37.5665;
const originLng = 126.9780;
const hexSize = 100.0; // 100m 정밀 타일 규격

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

export default function DashboardTab() {

  const [tiles, setTiles] = useState([]);
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const mapRef = useRef(null);
  const mapInstance = useRef(null);
  const polygonsGroup = useRef(null);
  const myLocationMarker = useRef(null);
  const darkTileLayer = useRef(null);
  const satelliteTileLayer = useRef(null);
  const [isSatellite, setIsSatellite] = useState(false);

  const handleGoToMyLocation = () => {
    if (!mapInstance.current) return;

    if (!navigator.geolocation) {
      alert('이 브라우저는 위치 정보를 지원하지 않습니다.');
      return;
    }

    navigator.geolocation.getCurrentPosition(
      (position) => {
        const { latitude, longitude } = position.coords;
        mapInstance.current.setView([latitude, longitude], 15);

        // 이전 마커 제거 후 신규 생성
        if (myLocationMarker.current) {
          myLocationMarker.current.remove();
        }

        const myIcon = L.divIcon({
          className: 'custom-my-location-marker',
          html: `<div style="width: 14px; height: 14px; background-color: var(--accent-cyan); border: 2px solid white; border-radius: 50%; box-shadow: 0 0 8px rgba(59, 130, 246, 0.4);"></div>`,
          iconSize: [14, 14],
          iconAnchor: [7, 7]
        });

        myLocationMarker.current = L.marker([latitude, longitude], { icon: myIcon }).addTo(mapInstance.current);
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
      const [tilesData, usersData] = await Promise.all([
        fetchTiles(),
        fetchUsers()
      ]);
      setTiles(tilesData);
      setUsers(usersData);
    } catch (err) {
      console.error(err);
      setError('실시간 전술 맵 데이터를 불러오는 중 에러가 발생했습니다.');
    } finally {
      setLoading(false);
    }
  };

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
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  // 1. Leaflet 맵 초기화
  useEffect(() => {
    if (!mapRef.current) return;
    if (mapInstance.current) return;

    // 하이테크 스타일 다크 맵 구축
    const map = L.map(mapRef.current, {
      zoomControl: true,
      attributionControl: false
    }).setView([originLat, originLng], 14);

    const darkLayer = L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}{r}.png', {
      maxZoom: 20
    });

    const satelliteLayer = L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', {
      maxZoom: 19
    });

    darkTileLayer.current = darkLayer;
    satelliteTileLayer.current = satelliteLayer;

    // 기본적으로 다크 레이어 적재
    darkLayer.addTo(map);

    polygonsGroup.current = L.layerGroup().addTo(map);
    mapInstance.current = map;

    // 리액트 마운트 시 컨테이너 크기 왜곡 현상을 방지하기 위해 맵 레이아웃 갱신 강제 기동
    setTimeout(() => {
      if (map) map.invalidateSize();
    }, 150);

    return () => {
      if (mapInstance.current) {
        mapInstance.current.remove();
        mapInstance.current = null;
      }
    };
  }, []);

  // 1-2. 위성 맵 토글에 따른 레이어 탈착 효과
  useEffect(() => {
    if (!mapInstance.current || !darkTileLayer.current || !satelliteTileLayer.current) return;

    if (isSatellite) {
      mapInstance.current.removeLayer(darkTileLayer.current);
      mapInstance.current.addLayer(satelliteTileLayer.current);
    } else {
      mapInstance.current.removeLayer(satelliteTileLayer.current);
      mapInstance.current.addLayer(darkTileLayer.current);
    }
  }, [isSatellite]);

  // 2. 점령지 데이터 수신 시 헥사곤 폴리곤 실시간 렌더링
  useEffect(() => {
    if (!mapInstance.current || !polygonsGroup.current) return;

    polygonsGroup.current.clearLayers();

    if (tiles.length === 0) return;

    let centerSet = false;

    tiles.forEach(tile => {
      const corners = getHexCorners(tile.q, tile.r);
      const user = users.find(u => u.id === tile.user_id);
      const ownerName = user ? user.nickname : '미등록 사용자';
      const color = '#00e5ff';

      const polygon = L.polygon(corners, {
        color: color,
        weight: 1.5,
        fillColor: color,
        fillOpacity: 0.2,
        dashArray: '2, 2'
      });

      const popupContent = `
        <div style="font-family: monospace; color: var(--text-primary); line-height: 1.4; font-size: 0.8rem;">
          <strong style="color: ${color}">[사용자]</strong> ${ownerName}<br/>
          <strong>[점령]</strong> ${tile.capture_count}회 중첩<br/>
          <strong>[좌표]</strong> Q:${tile.q}, R:${tile.r}
        </div>
      `;

      // 클릭 시 단일 팝업 연동 (마우스 오버레이 툴팁 없음)
      polygon.bindPopup(popupContent, {
        minWidth: 120
      });

      polygonsGroup.current.addLayer(polygon);

      // 첫 번째 활성 점령 타일로 카메라 맞춤 (최초 1회만)
      if (!centerSet) {
        const center = hexToLatLng(tile.q, tile.r);
        mapInstance.current.setView(center, 14);
        centerSet = true;
      }
    });
  }, [tiles, users]);

  if (error) {
    return <div style={{ color: 'var(--accent-red)', padding: '2rem' }}>{error}</div>;
  }

  // 데이터 로드 완료 전 가드 정의
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>

      {/* 상황판 맵 모니터 그리드 */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '1.5rem' }}>

        {/* Leaflet 실시간 점령 지도 */}
        <div className="tactical-card map-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <h3 style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '1.1rem', color: 'var(--text-primary)' }}>
              <Radio size={18} style={{ color: 'var(--accent-cyan)' }} />
              맵 모니터
            </h3>
            <span style={{ fontSize: '0.75rem', color: 'var(--accent-cyan)', background: 'rgba(59, 130, 246, 0.05)', padding: '0.2rem 0.5rem', borderRadius: '4px', border: '1px solid rgba(59, 130, 246, 0.15)' }}>
              REALTIME DATA FEED
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
          </div>
        </div>

      </div>
    </div>
  );
}
