import React from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { LocateFixed, RefreshCw } from 'lucide-react';
import { getHexCorners, hexToLatLng } from '../hexGrid';

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL;
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY;
const CACHE_KEY = 'public-captured-tiles-v1';
const CACHE_TTL = 5 * 60 * 1000;
const KOREA_BOUNDS = L.latLngBounds([[33.0, 124.0], [39.0, 132.0]]);
const DEFAULT_TILE_COLOR = '#00e5ff';

const authHeaders = {
  apikey: SUPABASE_ANON_KEY,
  Authorization: `Bearer ${SUPABASE_ANON_KEY}`
};

function normalizeColor(value) {
  return typeof value === 'string' && /^#[0-9a-fA-F]{6}$/.test(value) ? value : DEFAULT_TILE_COLOR;
}

function hexToRgba(hex, alpha) {
  const value = hex.replace('#', '');
  const r = parseInt(value.slice(0, 2), 16);
  const g = parseInt(value.slice(2, 4), 16);
  const b = parseInt(value.slice(4, 6), 16);
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

function groupTilesByColor(tiles) {
  const groups = new Map();
  tiles.forEach((tile) => {
    const color = normalizeColor(tile.color);
    if (!groups.has(color)) groups.set(color, []);
    groups.get(color).push(tile);
  });
  return groups;
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
  return rows.map(({ q, r, color }) => ({
    q,
    r,
    color,
    center: L.latLng(hexToLatLng(q, r))
  }));
}

const CapturedTilesLayer = L.Layer.extend({
  initialize(tiles) {
    this.setTiles(tiles);
  },

  setTiles(tiles) {
    this._tiles = tiles;
    this._groups = groupTilesByColor(tiles);
    if (this._map) this._reset();
  },

  onAdd(map) {
    this._map = map;
    const canvas = L.DomUtil.create('canvas', 'leaflet-zoom-animated');
    canvas.style.pointerEvents = 'none';
    this._canvas = canvas;
    map.getPanes().overlayPane.appendChild(canvas);
    map.on('moveend zoomend resize', this._reset, this);
    map.on('zoom', this._scheduleReset, this);
    map.on('zoomanim', this._animateZoom, this);
    this._reset();
  },

  onRemove(map) {
    map.off('moveend zoomend resize', this._reset, this);
    map.off('zoom', this._scheduleReset, this);
    map.off('zoomanim', this._animateZoom, this);
    if (this._raf) cancelAnimationFrame(this._raf);
    this._canvas.remove();
  },

  _animateZoom(event) {
    const map = this._map;
    const scale = map.getZoomScale(event.zoom);
    const offset = map._latLngBoundsToNewLayerBounds(map.getBounds(), event.zoom, event.center).min;
    L.DomUtil.setTransform(this._canvas, offset, scale);
  },

  _scheduleReset() {
    if (this._raf) return;
    this._raf = requestAnimationFrame(() => {
      this._raf = 0;
      if (this._map?._animatingZoom) return;
      this._reset();
    });
  },

  _reset() {
    const map = this._map;
    const size = map.getSize();
    const dpr = window.devicePixelRatio || 1;
    const topLeft = map.containerPointToLayerPoint([0, 0]);

    L.DomUtil.setPosition(this._canvas, topLeft);
    this._canvas.width = Math.round(size.x * dpr);
    this._canvas.height = Math.round(size.y * dpr);
    this._canvas.style.width = `${size.x}px`;
    this._canvas.style.height = `${size.y}px`;

    const ctx = this._canvas.getContext('2d');
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, size.x, size.y);
    this._draw(ctx);
  },

  _draw(ctx) {
    const map = this._map;
    const zoom = map.getZoom();
    const bounds = map.getBounds().pad(0.05);

    if (zoom < 7) {
      const radius = zoom <= 3 ? 1.4 : zoom <= 5 ? 1.8 : 2.2;
      this._groups.forEach((group, color) => {
        ctx.fillStyle = hexToRgba(color, 0.9);
        group.forEach((tile) => {
          if (!bounds.contains(tile.center)) return;
          const point = map.latLngToContainerPoint(tile.center);
          ctx.beginPath();
          ctx.arc(point.x, point.y, radius, 0, Math.PI * 2);
          ctx.fill();
        });
      });
      return;
    }

    this._groups.forEach((group, color) => {
      ctx.fillStyle = hexToRgba(color, 0.45);
      ctx.strokeStyle = hexToRgba(color, 0.95);
      ctx.lineWidth = zoom < 8 ? 0.8 : 1.5;
      ctx.beginPath();

      group.forEach((tile) => {
        if (!bounds.contains(tile.center)) return;
        const corners = getHexCorners(tile.q, tile.r);
        corners.forEach((corner, index) => {
          const point = map.latLngToContainerPoint(corner);
          if (index === 0) ctx.moveTo(point.x, point.y);
          else ctx.lineTo(point.x, point.y);
        });
        ctx.closePath();
      });

      ctx.fill();
      ctx.stroke();
    });
  }
});

export default function CapturedMap() {
  const containerRef = React.useRef(null);
  const mapRef = React.useRef(null);
  const layerRef = React.useRef(null);
  const locationMarkerRef = React.useRef(null);
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
    if (!containerRef.current || !tiles) return undefined;

    const map = L.map(containerRef.current, {
      zoomControl: true,
      attributionControl: true,
      minZoom: 2,
      maxZoom: 13,
      scrollWheelZoom: false,
      doubleClickZoom: false,
      boxZoom: false,
      keyboard: false,
      dragging: true,
      touchZoom: true
    });

    L.tileLayer(
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png?key=cb1_2pao_1_f708f02cfdb298af5ba94a21',
      {
        subdomains: 'abcd',
        maxZoom: 19,
        attribution: '&copy; OpenStreetMap &copy; CARTO'
      }
    ).addTo(map);

    const tileBounds = L.latLngBounds(tiles.map((tile) => tile.center));
    map.fitBounds(tileBounds.isValid() ? tileBounds : KOREA_BOUNDS, {
      padding: [24, 24],
      maxZoom: 8
    });
    mapRef.current = map;
    layerRef.current = new CapturedTilesLayer(tiles).addTo(map);

    let resizeObserver;
    if (typeof ResizeObserver !== 'undefined') {
      resizeObserver = new ResizeObserver(() => map.invalidateSize());
      resizeObserver.observe(containerRef.current);
    }
    const timer = setTimeout(() => map.invalidateSize(), 150);

    return () => {
      clearTimeout(timer);
      resizeObserver?.disconnect();
      map.remove();
      mapRef.current = null;
      layerRef.current = null;
      locationMarkerRef.current = null;
    };
  }, [tiles]);

  const handleRefresh = async () => {
    if (refreshing) return;
    setRefreshing(true);
    setError('');
    try {
      const prepared = await loadPreparedTiles(true);
      if (layerRef.current) {
        layerRef.current.setTiles(prepared);
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
    if (!navigator.geolocation) {
      setError('이 브라우저에서는 위치 기능을 사용할 수 없습니다.');
      return;
    }
    navigator.geolocation.getCurrentPosition(
      ({ coords }) => {
        const map = mapRef.current;
        if (!map) return;
        const point = [coords.latitude, coords.longitude];
        map.setView(point, Math.max(map.getZoom(), 13));
        if (locationMarkerRef.current) locationMarkerRef.current.remove();
        locationMarkerRef.current = L.circleMarker(point, {
          radius: 7,
          color: '#ffffff',
          weight: 2,
          fillColor: DEFAULT_TILE_COLOR,
          fillOpacity: 1
        }).addTo(map);
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
