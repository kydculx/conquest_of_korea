import React from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { getHexCorners, hexToLatLng } from '../hexGrid';

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL;
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY;
const CACHE_KEY = 'public-captured-tiles-v1';
const CACHE_TTL = 5 * 60 * 1000;
const KOREA_BOUNDS = [[33.0, 124.0], [39.0, 132.0]];

const authHeaders = {
  apikey: SUPABASE_ANON_KEY,
  Authorization: `Bearer ${SUPABASE_ANON_KEY}`
};

function readCache() {
  try {
    const raw = sessionStorage.getItem(CACHE_KEY);
    if (!raw) return null;
    const cached = JSON.parse(raw);
    if (!cached || Date.now() - cached.ts > CACHE_TTL || !Array.isArray(cached.tiles)) return null;
    return cached.tiles;
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
    .map(([q, r]) => ({ q, r }));
}

async function fetchViaRest() {
  const pageSize = 1000;
  const tiles = [];
  for (let offset = 0; ; offset += pageSize) {
    const res = await fetch(
      `${SUPABASE_URL}/rest/v1/captured_tiles?select=q,r&order=id.asc&limit=${pageSize}&offset=${offset}`,
      { headers: authHeaders }
    );
    if (!res.ok) throw new Error(`REST ${res.status}`);
    const page = await res.json();
    if (!Array.isArray(page)) throw new Error('Invalid REST payload');
    page.forEach((row) => {
      if (Number.isInteger(row.q) && Number.isInteger(row.r)) tiles.push({ q: row.q, r: row.r });
    });
    if (page.length < pageSize) break;
  }
  return tiles;
}

async function fetchTiles() {
  if (!SUPABASE_URL || !SUPABASE_ANON_KEY) throw new Error('Supabase env is missing');
  const cached = readCache();
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

const CapturedTilesLayer = L.Layer.extend({
  initialize(tiles) {
    this._tiles = tiles;
  },

  onAdd(map) {
    this._map = map;
    const canvas = L.DomUtil.create('canvas', 'leaflet-zoom-animated');
    canvas.style.pointerEvents = 'none';
    this._canvas = canvas;
    map.getPanes().overlayPane.appendChild(canvas);
    map.on('moveend zoomend resize', this._reset, this);
    this._reset();
  },

  onRemove(map) {
    map.off('moveend zoomend resize', this._reset, this);
    this._canvas.remove();
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

    if (zoom < 9) {
      const radius = zoom <= 5 ? 1 : zoom <= 7 ? 1.5 : 2;
      ctx.fillStyle = 'rgba(56, 189, 248, 0.65)';
      this._tiles.forEach((tile) => {
        if (!bounds.contains(tile.center)) return;
        const point = map.latLngToContainerPoint(tile.center);
        ctx.beginPath();
        ctx.arc(point.x, point.y, radius, 0, Math.PI * 2);
        ctx.fill();
      });
      return;
    }

    ctx.fillStyle = 'rgba(56, 189, 248, 0.55)';
    ctx.strokeStyle = 'rgba(125, 211, 252, 0.35)';
    ctx.lineWidth = 1;
    ctx.beginPath();

    this._tiles.forEach((tile) => {
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
    if (zoom >= 11) ctx.stroke();
  }
});

export default function CapturedMap() {
  const containerRef = React.useRef(null);
  const [tiles, setTiles] = React.useState(null);
  const [error, setError] = React.useState('');

  React.useEffect(() => {
    let cancelled = false;

    fetchTiles()
      .then((rows) => {
        if (cancelled) return;
        setTiles(rows.map(({ q, r }) => ({ q, r, center: L.latLng(hexToLatLng(q, r)) })));
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
      minZoom: 3,
      maxZoom: 13,
      scrollWheelZoom: false,
      doubleClickZoom: false,
      boxZoom: false,
      keyboard: false,
      dragging: !L.Browser.mobile,
      touchZoom: false
    });

    L.tileLayer(
      'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}{r}.png?key=cb1_2pao_1_f708f02cfdb298af5ba94a21',
      {
        subdomains: 'abcd',
        maxZoom: 19,
        attribution: '&copy; OpenStreetMap &copy; CARTO'
      }
    ).addTo(map);

    new CapturedTilesLayer(tiles).addTo(map);

    const koreaTiles = tiles.filter((tile) => L.latLngBounds(KOREA_BOUNDS).contains(tile.center));
    const fitBounds = koreaTiles.length
      ? L.latLngBounds(KOREA_BOUNDS)
      : L.latLngBounds(tiles.map((tile) => tile.center));
    map.fitBounds(fitBounds, { padding: [24, 24], maxZoom: 8 });

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
    };
  }, [tiles]);

  if (error) return <div className="territory-state">{error}</div>;
  if (!tiles) return <div className="territory-state">점령 지역을 불러오는 중...</div>;
  if (!tiles.length) return <div className="territory-state">아직 표시할 점령 지역이 없습니다.</div>;

  return (
    <>
      <div ref={containerRef} className="territory-map" aria-label="전체 점령 지역 지도" />
      <div className="territory-count">{tiles.length.toLocaleString('ko-KR')} 타일</div>
      <div className="territory-legend"><span className="territory-dot" />점령 지역</div>
    </>
  );
}
