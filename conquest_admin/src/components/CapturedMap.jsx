import React from 'react';
import { LocateFixed, RefreshCw } from 'lucide-react';
import { getHexCorners, hexToLatLng } from '../hexGrid';

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL;
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY;
const GOOGLE_MAPS_API_KEY = import.meta.env.VITE_GOOGLE_MAPS_API_KEY;
const CACHE_KEY = 'public-captured-tiles-v3';
const CACHE_TTL = 5 * 60 * 1000;
const DEFAULT_TILE_COLOR = '#00e5ff';

const DARK_MAP_STYLES = [
  { elementType: 'geometry', stylers: [{ color: '#151b26' }] },
  { elementType: 'labels.text.fill', stylers: [{ color: '#8b98a5' }] },
  { elementType: 'labels.text.stroke', stylers: [{ color: '#151b26' }] },
  { featureType: 'administrative', elementType: 'geometry', stylers: [{ color: '#2b3648' }] },
  { featureType: 'poi', elementType: 'labels.text.fill', stylers: [{ color: '#6b7a8c' }] },
  { featureType: 'poi.park', elementType: 'geometry', stylers: [{ color: '#1b2a2a' }] },
  { featureType: 'road', elementType: 'geometry', stylers: [{ color: '#263041' }] },
  { featureType: 'road', elementType: 'geometry.stroke', stylers: [{ color: '#1a2230' }] },
  { featureType: 'road', elementType: 'labels.text.fill', stylers: [{ color: '#94a3b8' }] },
  { featureType: 'transit', stylers: [{ visibility: 'off' }] },
  { featureType: 'water', elementType: 'geometry', stylers: [{ color: '#0b1220' }] },
  { featureType: 'water', elementType: 'labels.text.fill', stylers: [{ color: '#4b5e78' }] }
];

const LOCATION_ICON = `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(`
  <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 14 14">
    <circle cx="7" cy="7" r="6" fill="#00e5ff" stroke="#ffffff" stroke-width="2"/>
  </svg>
`)}`;

const authHeaders = {
  apikey: SUPABASE_ANON_KEY,
  Authorization: `Bearer ${SUPABASE_ANON_KEY}`
};

let googleMapsPromise = null;

function loadGoogleMaps() {
  if (window.google?.maps) return Promise.resolve(window.google.maps);
  if (googleMapsPromise) return googleMapsPromise;
  if (!GOOGLE_MAPS_API_KEY) return Promise.reject(new Error('Google Maps API key is missing'));

  googleMapsPromise = new Promise((resolve, reject) => {
    const callbackName = '__conquestHomeGoogleMapsReady';
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
      reject(new Error('Google Maps script failed'));
    };
    document.head.appendChild(script);
  });

  return googleMapsPromise;
}

function normalizeColor(value) {
  return typeof value === 'string' && /^#[0-9a-fA-F]{6}$/.test(value) ? value : DEFAULT_TILE_COLOR;
}

function readCache() {
  try {
    const raw = sessionStorage.getItem(CACHE_KEY);
    if (!raw) return null;
    const cached = JSON.parse(raw);
    if (!cached || Date.now() - cached.ts > CACHE_TTL || !Array.isArray(cached.tiles)) return null;
    return cached.tiles.map(({ q, r, color }) => ({ q, r, color: normalizeColor(color) }));
  } catch {
    return null;
  }
}

function writeCache(tiles) {
  try {
    sessionStorage.setItem(CACHE_KEY, JSON.stringify({ ts: Date.now(), tiles }));
  } catch {
    return;
  }
}

async function fetchViaRpc() {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/get_public_captured_tiles`, {
    method: 'POST',
    headers: { ...authHeaders, 'Content-Type': 'application/json' },
    body: '{}'
  });
  if (!res.ok) throw new Error(`RPC ${res.status}`);
  const data = await res.json();
  const rows = Array.isArray(data) ? data : data?.get_public_captured_tiles;
  if (!Array.isArray(rows)) throw new Error('Invalid RPC payload');
  return rows
    .filter((row) => Array.isArray(row) && Number.isInteger(row[0]) && Number.isInteger(row[1]))
    .map(([q, r, color]) => ({ q, r, color: normalizeColor(color) }));
}

async function fetchViaRest() {
  const pageSize = 1000;
  const tiles = [];
  for (let offset = 0; ; offset += pageSize) {
    const res = await fetch(
      `${SUPABASE_URL}/rest/v1/captured_tiles?select=q,r,color_hex&order=id.asc&limit=${pageSize}&offset=${offset}`,
      { headers: authHeaders }
    );
    if (!res.ok) throw new Error(`REST ${res.status}`);
    const page = await res.json();
    if (!Array.isArray(page)) throw new Error('Invalid REST payload');
    page.forEach((row) => {
      if (Number.isInteger(row.q) && Number.isInteger(row.r)) {
        tiles.push({ q: row.q, r: row.r, color: normalizeColor(row.color_hex) });
      }
    });
    if (page.length < pageSize) break;
  }
  return tiles;
}

async function fetchTiles(force = false) {
  if (!SUPABASE_URL || !SUPABASE_ANON_KEY) throw new Error('Supabase env is missing');
  const cached = force ? null : readCache();
  if (cached) return cached;

  let tiles;
  try {
    tiles = await fetchViaRpc();
  } catch {
    tiles = await fetchViaRest();
  }
  writeCache(tiles);
  return tiles;
}

async function loadPreparedTiles(force = false) {
  const rows = await fetchTiles(force);
  return rows.map(({ q, r, color }) => {
    const [lat, lng] = hexToLatLng(q, r);
    return { q, r, color, center: { lat, lng } };
  });
}

function clearPolygons(polygons) {
  polygons.forEach((polygon) => polygon.setMap(null));
  polygons.length = 0;
}

function renderPolygons(map, prepared, polygons) {
  const maps = window.google?.maps;
  if (!maps) return;
  clearPolygons(polygons);

  prepared.forEach((tile) => {
    const corners = getHexCorners(tile.q, tile.r);
    const polygon = new maps.Polygon({
      paths: corners.map(([lat, lng]) => ({ lat, lng })),
      strokeColor: tile.color,
      strokeOpacity: 0.95,
      strokeWeight: 2,
      fillColor: tile.color,
      fillOpacity: 0.45,
      map,
      clickable: false,
      zIndex: 1
    });
    polygons.push(polygon);
  });
}

function fitTiles(map, prepared) {
  const maps = window.google?.maps;
  if (!maps || !prepared.length) return;
  const bounds = new maps.LatLngBounds();
  prepared.forEach((tile) => bounds.extend(tile.center));
  if (!bounds.isEmpty()) map.fitBounds(bounds, 40);
}

export default function CapturedMap() {
  const containerRef = React.useRef(null);
  const mapRef = React.useRef(null);
  const polygonsRef = React.useRef([]);
  const markerRef = React.useRef(null);
  const [tiles, setTiles] = React.useState(null);
  const [count, setCount] = React.useState(0);
  const [error, setError] = React.useState('');
  const [refreshing, setRefreshing] = React.useState(false);

  React.useEffect(() => {
    let cancelled = false;

    loadPreparedTiles()
      .then((prepared) => {
        if (cancelled) return;
        setTiles(prepared);
        setCount(prepared.length);
      })
      .catch(() => {
        if (!cancelled) setError('점령 지역을 불러오지 못했습니다.');
      });

    return () => {
      cancelled = true;
    };
  }, []);

  React.useEffect(() => {
    const container = containerRef.current;
    const polygons = polygonsRef.current;
    if (!container || !tiles) return undefined;
    let cancelled = false;

    loadGoogleMaps()
      .then((maps) => {
        if (cancelled) return;

        const map = new maps.Map(container, {
          center: { lat: 36.3, lng: 127.8 },
          zoom: 7,
          mapTypeId: 'roadmap',
          styles: DARK_MAP_STYLES,
          backgroundColor: '#060911',
          zoomControl: false,
          mapTypeControl: false,
          streetViewControl: false,
          fullscreenControl: false,
          cameraControl: false,
          rotateControl: false,
          scaleControl: false,
          keyboardShortcuts: false,
          clickableIcons: false,
          gestureHandling: 'greedy'
        });

        mapRef.current = map;
        renderPolygons(map, tiles, polygons);
        fitTiles(map, tiles);
      })
      .catch(() => {
        if (!cancelled) setError('지도를 불러오지 못했습니다.');
      });

    return () => {
      cancelled = true;
      clearPolygons(polygons);
      markerRef.current?.setMap(null);
      markerRef.current = null;
      mapRef.current = null;
      container.replaceChildren();
    };
  }, [tiles]);

  const handleRefresh = async () => {
    if (refreshing) return;
    setRefreshing(true);
    setError('');
    try {
      const prepared = await loadPreparedTiles(true);
      if (mapRef.current) {
        renderPolygons(mapRef.current, prepared, polygonsRef.current);
      } else {
        setTiles(prepared);
      }
      setCount(prepared.length);
    } catch {
      setError('지도 새로고침에 실패했습니다.');
    } finally {
      setRefreshing(false);
    }
  };

  const handleLocate = () => {
    const maps = window.google?.maps;
    const map = mapRef.current;
    if (!maps || !map) return;
    if (!navigator.geolocation) {
      setError('이 브라우저에서는 위치 기능을 사용할 수 없습니다.');
      return;
    }

    navigator.geolocation.getCurrentPosition(
      ({ coords }) => {
        const position = { lat: coords.latitude, lng: coords.longitude };
        map.panTo(position);
        map.setZoom(13);
        markerRef.current?.setMap(null);
        markerRef.current = new maps.Marker({
          position,
          map,
          icon: {
            url: LOCATION_ICON,
            scaledSize: new maps.Size(14, 14),
            anchor: new maps.Point(7, 7)
          }
        });
        setError('');
      },
      () => setError('현재 위치를 가져오지 못했습니다. 위치 권한을 확인해 주세요.'),
      { enableHighAccuracy: true, timeout: 10000 }
    );
  };

  if (!tiles && error) return <div className="territory-state">{error}</div>;
  if (!tiles) return <div className="territory-state">점령 지역을 불러오는 중...</div>;
  if (!tiles.length) return <div className="territory-state">아직 표시할 점령 지역이 없습니다.</div>;

  return (
    <>
      <div ref={containerRef} className="territory-map" aria-label="전체 점령 지역 지도" />
      <div className="territory-live" aria-label="실시간 점령 현황">
        <span className="territory-live-dot" />
        <span>LIVE</span>
      </div>
      <div className="territory-actions">
        <button
          type="button"
          className={`territory-action-btn${refreshing ? ' is-spinning' : ''}`}
          onClick={handleRefresh}
          disabled={refreshing}
          aria-label="지도 새로고침"
          title="지도 새로고침"
        >
          <RefreshCw size={16} />
        </button>
        <button
          type="button"
          className="territory-action-btn"
          onClick={handleLocate}
          aria-label="내 위치로 이동"
          title="내 위치로 이동"
        >
          <LocateFixed size={16} />
        </button>
      </div>
      {(error || count === 0) && (
        <div className="territory-error">{error || '표시할 점령 지역이 없습니다.'}</div>
      )}
    </>
  );
}
