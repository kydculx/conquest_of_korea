import React, { useEffect, useState, useRef } from 'react';
import { useSearchParams } from 'react-router-dom';
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

  const [searchParams] = useSearchParams();
  const hqParam = searchParams.get('hq');

  const [tiles, setTiles] = useState([]);
  const [users, setUsers] = useState([]);
  const [photos, setPhotos] = useState([]);
  const [photoCounts, setPhotoCounts] = useState({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

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
  const polygonsGroup = useRef(null);
  const myLocationMarker = useRef(null);
  const hqMarker = useRef(null);
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
      const [tilesData, usersData, photosData] = await Promise.all([
        fetchTiles(),
        fetchUsers(),
        supabase.from('tile_photos').select('*').order('created_at', { ascending: false })
      ]);
      setTiles(tilesData);
      setUsers(usersData);
      setPhotos(photosData.data || []);

      const counts = {};
      if (photosData.data) {
        photosData.data.forEach(p => {
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
      const tileId = `hex_${tile.q}_${tile.r}`;
      const isHQ = hqParam === tileId;

      const polygon = L.polygon(corners, {
        color: color,
        weight: isHQ ? 4 : 1.5,
        fillColor: color,
        fillOpacity: isHQ ? 0.5 : 0.2,
        dashArray: isHQ ? null : '2, 2'
      });

      const count = photoCounts[tileId] || 0;
      const galleryText = count > 0 
        ? `<button onclick="window.openAdminGallery('${tileId}')" style="background: #3b82f6; color: white; border: none; padding: 2px 6px; border-radius: 4px; font-size: 0.7rem; cursor: pointer; font-weight: bold; margin-top: 2px;">사진 ${count}장 보기</button>`
        : '<span style="color: var(--text-secondary);">없음</span>';

      const capturedAt = tile.captured_at
        ? new Date(tile.captured_at).toLocaleString('ko-KR')
        : '-';

      const popupContent = `
        <div style="font-family: monospace; color: var(--text-primary); line-height: 1.4; font-size: 0.8rem;">
          <strong style="color: ${color}">[사용자]</strong> ${ownerName}<br/>
          <strong>[점령]</strong> ${tile.capture_count}회 중첩<br/>
          <strong>[점령날짜]</strong> ${capturedAt}<br/>
          <strong>[갤러리]</strong> ${galleryText}<br/>
          <strong>[좌표]</strong> Q:${tile.q}, R:${tile.r}
        </div>
      `;

      // 클릭 시 단일 팝업 연동 (마우스 오버레이 툴팁 없음)
      polygon.bindPopup(popupContent, {
        minWidth: 130
      });

      polygonsGroup.current.addLayer(polygon);

      // 카메라 맞춤: 본진 이동(hq) 요청이 있으면 해당 타일 우선, 없으면 첫 타일 (최초 1회만)
      if (!centerSet) {
        const hqTile = hqParam
          ? tiles.find(t => `hex_${t.q}_${t.r}` === hqParam)
          : null;
        if (hqTile) {
          mapInstance.current.setView(hexToLatLng(hqTile.q, hqTile.r), 15);
        } else {
          mapInstance.current.setView(hexToLatLng(tile.q, tile.r), 14);
        }
        centerSet = true;
      }
    });
  }, [tiles, users, photoCounts, hqParam]);

  // 2-1. 본진 이동(hq) 파라미터 시 지도 포커스 + 하이라이트 마커 표시
  useEffect(() => {
    if (hqMarker.current) {
      hqMarker.current.remove();
      hqMarker.current = null;
    }

    if (!mapInstance.current || !hqParam) return;

    const parts = hqParam.split('_');
    if (parts.length !== 3) return;
    const q = parseInt(parts[1], 10);
    const r = parseInt(parts[2], 10);
    if (Number.isNaN(q) || Number.isNaN(r)) return;

    const center = hexToLatLng(q, r);
    mapInstance.current.setView(center, 15);

    const hqIcon = L.divIcon({
      className: 'custom-hq-marker',
      html: `<div style="width: 18px; height: 18px; background: #FFD700; border: 2px solid white; border-radius: 50%; box-shadow: 0 0 12px rgba(255, 215, 0, 0.6);"></div>`,
      iconSize: [18, 18],
      iconAnchor: [9, 9]
    });
    hqMarker.current = L.marker(center, { icon: hqIcon }).addTo(mapInstance.current);
  }, [hqParam]);

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

      {/* 📸 관리자 전용 사진 갤러리 팝업 모달 */}
      {isGalleryOpen && (
        <div style={{
          position: 'fixed', top: 0, left: 0, width: '100vw', height: '100vh',
          background: 'rgba(15, 23, 42, 0.85)', backdropFilter: 'blur(8px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          zIndex: 9999, padding: '1.5rem'
        }}>
          <div className="tactical-card" style={{
            width: '100%', maxWidth: '520px', background: 'var(--bg-secondary)',
            border: '1px solid var(--border-color)', borderRadius: '12px',
            boxShadow: 'var(--shadow-card)', padding: '1.5rem', position: 'relative',
            display: 'flex', flexDirection: 'column', gap: '1rem'
          }}>
            {/* 헤더 */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h3 style={{ fontSize: '1.1rem', color: 'var(--text-primary)', fontFamily: 'var(--font-display)', fontWeight: 'bold' }}>
                내 주변 현장 사진 갤러리 <span style={{ fontSize: '0.85rem', color: 'var(--accent-cyan)', marginLeft: '0.5rem' }}>({selectedTileId})</span>
              </h3>
              <button 
                onClick={() => setIsGalleryOpen(false)}
                style={{
                  background: 'none', border: 'none', color: 'var(--text-secondary)',
                  fontSize: '1.5rem', cursor: 'pointer', outline: 'none'
                }}
              >
                &times;
              </button>
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
