import React, { useEffect, useState, useRef, useCallback } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import {
  fetchTileTypes,
  saveTileType,
  deleteTileType,
  fetchTileAttributes,
  saveTileAttributes,
  DEFAULT_TILE_TYPES,
} from '../api';
import {
  Layers,
  Save,
  Download,
  Upload,
  RotateCcw,
  Plus,
  Trash2,
  Edit2,
  MousePointer,
  Paintbrush,
  Eraser,
  HelpCircle,
  Compass,
  Check,
  AlertTriangle,
  X,
} from 'lucide-react';

const originLat = 37.5665;
const originLng = 126.9780;
const hexSize = 100.0; // 100m 정밀 타일 규격

// 헥스 그리드 좌표 -> 위경도 변환
function hexToLatLng(q, r) {
  const x = Math.sqrt(3) * q + (Math.sqrt(3) / 2) * r;
  const y = (3 / 2) * r;

  const latRad = (originLat * Math.PI) / 180;
  const lat = (y * hexSize) / 111320 + originLat;
  const lng = (x * hexSize) / (111320 * Math.cos(latRad)) + originLng;

  return [lat, lng];
}

// 헥스 꼭짓점 6개 경위도 배열 계산
function getHexCorners(q, r) {
  const center = hexToLatLng(q, r);
  const latRad = (originLat * Math.PI) / 180;
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

// 위경도 -> 가장 가까운 헥스 좌표 (q, r) 계산
function latLngToHex(lat, lng) {
  const latRad = (originLat * Math.PI) / 180;
  const y = ((lat - originLat) * 111320) / hexSize;
  const x = ((lng - originLng) * (111320 * Math.cos(latRad))) / hexSize;

  const r = (2 / 3) * y;
  const q = (Math.sqrt(3) / 3) * x - (1 / 3) * y;

  return cubeRound(q, r);
}

// 큐브 좌표계 반올림
function cubeRound(fracQ, fracR) {
  const fracS = -fracQ - fracR;
  let q = Math.round(fracQ);
  let r = Math.round(fracR);
  let s = Math.round(fracS);

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

export default function TileAttributeEditorTab() {
  // 타일 타입 목록
  const [types, setTypes] = useState(DEFAULT_TILE_TYPES);
  // 속성이 부여된 타일 맵: { "q_r": { id, q, r, type_id, memo } }
  const [attributes, setAttributes] = useState({});
  // 미저장 변경 플래그
  const [isDirty, setIsDirty] = useState(false);

  // 에디터 도구 상태: 기본 모드를 'inspect' (타일 선택 및 조회)로 설정하여 원치 않는 타일 변경 방지
  const [activeTool, setActiveTool] = useState('inspect');
  // 현재 선택된 브러시 타입 ID (기본값: 0)
  const [activeTypeId, setActiveTypeId] = useState(0);

  // 선택된 단일 타일 정보 (인스펙터용)
  const [selectedTile, setSelectedTile] = useState(null);

  // 신규/수정 타입 모달 상태
  const [showTypeModal, setShowTypeModal] = useState(false);
  const [editingType, setEditingType] = useState(null); // null이면 신규 추가
  const [typeForm, setTypeForm] = useState({
    id: 1,
    name: '',
    color_hex: '#00e5ff',
    description: '',
    is_blocked: false,
  });

  // 지도 관련 Ref
  const mapRef = useRef(null);
  const mapInstance = useRef(null);
  const gridLayerGroup = useRef(null);
  const attributesLayerGroup = useRef(null);
  const isDraggingMap = useRef(false);
  const mouseDownPosRef = useRef(null);
  const renderGuideGridRef = useRef(null);
  const fileInputRef = useRef(null);

  // 1. 초기 데이터 로드 (타입 및 속성)
  useEffect(() => {
    async function loadData() {
      const loadedTypes = await fetchTileTypes();
      setTypes(loadedTypes);
      const loadedAttrs = await fetchTileAttributes();
      setAttributes(loadedAttrs);
    }
    loadData();
  }, []);

  // 2. 지도 초기화
  useEffect(() => {
    if (!mapRef.current || mapInstance.current) return;

    const map = L.map(mapRef.current, {
      zoomControl: true,
      attributionControl: false,
    }).setView([originLat, originLng], 15);

    L.tileLayer(
      'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}{r}.png?key=cb1_2pao_1_f708f02cfdb298af5ba94a21',
      { maxZoom: 20 }
    ).addTo(map);

    gridLayerGroup.current = L.layerGroup().addTo(map);
    attributesLayerGroup.current = L.layerGroup().addTo(map);
    mapInstance.current = map;

    // 마우스 다운 좌표 기록 (드래그와 클릭을 정확히 구분하기 위함)
    const handleGlobalMouseDown = (e) => {
      mouseDownPosRef.current = { x: e.clientX, y: e.clientY };
    };
    window.addEventListener('mousedown', handleGlobalMouseDown);

    // 지도 드래그(이동) 감지 플래그
    map.on('movestart dragstart', () => {
      isDraggingMap.current = true;
    });

    map.on('moveend dragend zoomend', () => {
      setTimeout(() => {
        isDraggingMap.current = false;
      }, 150);
      renderGuideGridRef.current?.();
    });

    // 순수 클릭 시에만 타일 속성 적용 (지도 드래그 이동 시에는 절대 칠해지지 않음)
    map.on('click', (e) => {
      if (isDraggingMap.current) return;
      if (mouseDownPosRef.current && e.originalEvent) {
        const dx = e.originalEvent.clientX - mouseDownPosRef.current.x;
        const dy = e.originalEvent.clientY - mouseDownPosRef.current.y;
        if (Math.sqrt(dx * dx + dy * dy) > 5) return; // 5px 이상 이동했으면 드래그(이동)로 판정하여 무시
      }
      handleMapClick(e.latlng);
    });

    return () => {
      window.removeEventListener('mousedown', handleGlobalMouseDown);
    };
  }, []);

  // 3. 브러시/지우개 타일 속성 적용 함수
  const applyTileAttribute = useCallback(
    (q, r, toolOverride) => {
      const tool = toolOverride || activeTool;
      const tileId = `${q}_${r}`;

      if (tool === 'eraser') {
        // 지우개: 해당 타일의 속성을 제거(기본값 0으로 리셋)
        setAttributes((prev) => {
          if (!prev[tileId]) return prev;
          const next = { ...prev };
          delete next[tileId];
          setIsDirty(true);
          return next;
        });
        if (selectedTile?.id === tileId) {
          setSelectedTile(null);
        }
      } else if (tool === 'brush') {
        if (activeTypeId === 0) {
          // 0번(기본 타일)을 브러시로 칠할 경우 속성 레코드 제거 (기본값 0으로 복원)
          setAttributes((prev) => {
            if (!prev[tileId]) return prev;
            const next = { ...prev };
            delete next[tileId];
            setIsDirty(true);
            return next;
          });
          if (selectedTile?.id === tileId) {
            setSelectedTile((prev) => (prev ? { ...prev, type_id: 0, memo: '' } : null));
          }
        } else {
          // 브러시: 선택된 타입(1번 이상) 부여
          setAttributes((prev) => {
            const current = prev[tileId];
            if (current && current.type_id === activeTypeId) return prev; // 변경 없음

            const next = {
              ...prev,
              [tileId]: {
                id: tileId,
                q,
                r,
                type_id: activeTypeId,
                memo: current?.memo || '',
              },
            };
            setIsDirty(true);
            return next;
          });
        }
      } else if (tool === 'inspect') {
        // 단일 선택 인스펙터
        const attr = attributes[tileId];
        const center = hexToLatLng(q, r);
        setSelectedTile({
          id: tileId,
          q,
          r,
          type_id: attr ? attr.type_id : 0,
          memo: attr ? attr.memo : '',
          lat: center[0],
          lng: center[1],
        });
      }
    },
    [activeTool, activeTypeId, attributes, selectedTile]
  );

  const handleMapClick = (latlng) => {
    const { q, r } = latLngToHex(latlng.lat, latlng.lng);
    applyTileAttribute(q, r);
  };

  // 4-1. 속성이 부여된 타일 전용 렌더링 (attributes나 types가 변경될 때만 갱신)
  // 지도 확대/축소 시 clearLayers가 발생하지 않아 색상이 절대 깜빡이거나 사라지지 않습니다.
  const renderAttributesLayer = useCallback(() => {
    if (!attributesLayerGroup.current) return;

    attributesLayerGroup.current.clearLayers();

    const typeMap = {};
    types.forEach((t) => {
      typeMap[t.id] = t;
    });

    Object.values(attributes).forEach((attr) => {
      const typeInfo = typeMap[attr.type_id] || DEFAULT_TILE_TYPES[0];
      const corners = getHexCorners(attr.q, attr.r);

      const polygon = L.polygon(corners, {
        color: typeInfo.color_hex,
        weight: 2,
        fillColor: typeInfo.color_hex,
        fillOpacity: 0.5,
        interactive: true,
      });

      polygon.bindTooltip(
        `<b>${typeInfo.name}</b> (Type ${attr.type_id})<br/>ID: ${attr.id}${
          attr.memo ? `<br/>메모: ${attr.memo}` : ''
        }`,
        { permanent: false, direction: 'top', opacity: 0.9 }
      );

      polygon.on('click', (e) => {
        L.DomEvent.stopPropagation(e);
        if (isDraggingMap.current) return;
        if (mouseDownPosRef.current && e.originalEvent) {
          const dx = e.originalEvent.clientX - mouseDownPosRef.current.x;
          const dy = e.originalEvent.clientY - mouseDownPosRef.current.y;
          if (Math.sqrt(dx * dx + dy * dy) > 5) return;
        }
        applyTileAttribute(attr.q, attr.r);
      });

      attributesLayerGroup.current.addLayer(polygon);
    });
  }, [attributes, types, applyTileAttribute]);

  // 4-2. 빈 가이드 그리드 전용 렌더링 (뷰포트 이동/줌 완료 시 고배율에서만 갱신)
  const renderGuideGrid = useCallback(() => {
    if (!mapInstance.current || !gridLayerGroup.current) return;

    const map = mapInstance.current;
    const zoom = map.getZoom();

    gridLayerGroup.current.clearLayers();

    // 줌 레벨 14 미만에서는 성능을 위해 빈 가이드 그리드 생략
    if (zoom < 14) return;

    // 뷰포트 경계에 여유 마진(pad 0.2)을 주어 경계 부근 타일이 잘리는 현상 방지
    const bounds = map.getBounds().pad(0.2);
    const north = bounds.getNorth();
    const south = bounds.getSouth();
    const east = bounds.getEast();
    const west = bounds.getWest();

    const minHex = latLngToHex(south, west);
    const maxHex = latLngToHex(north, east);

    const qMin = Math.min(minHex.q, maxHex.q) - 2;
    const qMax = Math.max(minHex.q, maxHex.q) + 2;
    const rMin = Math.min(minHex.r, maxHex.r) - 2;
    const rMax = Math.max(minHex.r, maxHex.r) + 2;

    for (let q = qMin; q <= qMax; q++) {
      for (let r = rMin; r <= rMax; r++) {
        const tileId = `${q}_${r}`;
        // 이미 속성이 부여된 타일은 가이드 그리드에서 제외
        if (attributes[tileId]) continue;

        const center = hexToLatLng(q, r);
        if (
          center[0] >= south &&
          center[0] <= north &&
          center[1] >= west &&
          center[1] <= east
        ) {
          const corners = getHexCorners(q, r);
          const gridPoly = L.polygon(corners, {
            color: 'rgba(255, 255, 255, 0.08)',
            weight: 1,
            fillColor: 'transparent',
            fillOpacity: 0,
            interactive: true,
          });

          gridPoly.on('click', (e) => {
            L.DomEvent.stopPropagation(e);
            if (isDraggingMap.current) return;
            if (mouseDownPosRef.current && e.originalEvent) {
              const dx = e.originalEvent.clientX - mouseDownPosRef.current.x;
              const dy = e.originalEvent.clientY - mouseDownPosRef.current.y;
              if (Math.sqrt(dx * dx + dy * dy) > 5) return;
            }
            applyTileAttribute(q, r);
          });

          gridLayerGroup.current.addLayer(gridPoly);
        }
      }
    }
  }, [attributes, applyTileAttribute]);

  // 속성 타일 렌더링 갱신
  useEffect(() => {
    renderAttributesLayer();
  }, [renderAttributesLayer]);

  // 가이드 그리드 렌더링 갱신
  useEffect(() => {
    renderGuideGridRef.current = renderGuideGrid;
    renderGuideGrid();
  }, [renderGuideGrid]);

  // 5. DB 저장 처리
  const handleSaveToDb = async () => {
    try {
      await saveTileAttributes(attributes);
      setIsDirty(false);
      alert(
        `✅ 타일 속성 데이터 ${Object.keys(attributes).length}개가 성공적으로 저장되었습니다.`
      );
    } catch (err) {
      console.error(err);
      alert('⚠️ 타일 속성 저장 중 오류가 발생했습니다.');
    }
  };

  // 6. JSON 다운로드(Export)
  const handleExportJson = () => {
    const exportData = {
      version: '1.0.0',
      exportedAt: new Date().toISOString(),
      types,
      attributes,
    };
    const blob = new Blob([JSON.stringify(exportData, null, 2)], {
      type: 'application/json',
    });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `conquest_tile_attributes_${new Date()
      .toISOString()
      .slice(0, 10)}.json`;
    link.click();
    URL.revokeObjectURL(url);
  };

  // 7. JSON 불러오기(Import)
  const handleImportJson = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = async (event) => {
      try {
        const json = JSON.parse(event.target.result);
        if (json.types && Array.isArray(json.types)) {
          setTypes(json.types);
        }
        if (json.attributes && typeof json.attributes === 'object') {
          setAttributes(json.attributes);
          setIsDirty(true);
        }
        alert('✅ JSON 파일로부터 타일 속성을 성공적으로 불러왔습니다.');
      } catch (err) {
        console.error(err);
        alert('⚠️ 올바른 형식의 JSON 파일이 아닙니다.');
      }
    };
    reader.readAsText(file);
    e.target.value = '';
  };

  // 8. 신규/수정 타입 저장
  const handleSaveTypeForm = async (e) => {
    e.preventDefault();
    if (!typeForm.name.trim()) {
      alert('타입 이름을 입력해주세요.');
      return;
    }

    try {
      const updatedTypes = await saveTileType(typeForm);
      setTypes(updatedTypes);
      setShowTypeModal(false);
      alert(`✅ 타입 '${typeForm.name}'이(가) 등록/수정되었습니다.`);
    } catch (err) {
      console.error(err);
      alert('타입 저장에 실패했습니다.');
    }
  };

  // 9. 타입 삭제
  const handleDeleteType = async (typeId) => {
    if (typeId === 0) {
      alert('기본 타일(0번)은 삭제할 수 없습니다.');
      return;
    }
    if (
      !confirm(
        `정말로 타입 ${typeId}번을 삭제하시겠습니까?\n해당 타입이 적용된 타일은 0번(기본)으로 처리됩니다.`
      )
    ) {
      return;
    }

    try {
      const updatedTypes = await deleteTileType(typeId);
      setTypes(updatedTypes);
      if (activeTypeId === typeId) {
        setActiveTypeId(1);
      }
    } catch (err) {
      alert(err.message);
    }
  };

  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        height: 'calc(100vh - 120px)',
        position: 'relative',
        gap: '0.75rem',
      }}
    >
      {/* 1. 상단 글로벌 컨트롤 바 */}
      <div
        className="tactical-card"
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          padding: '0.75rem 1.25rem',
          flexWrap: 'wrap',
          gap: '1rem',
        }}
      >
        {/* 도구 선택기 */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <span
            style={{
              fontSize: '0.85rem',
              fontWeight: 700,
              color: 'var(--text-secondary)',
              marginRight: '0.5rem',
            }}
          >
            모드:
          </span>
          <button
            className={`btn-tactical ${activeTool === 'inspect' ? 'btn-primary' : ''}`}
            onClick={() => setActiveTool('inspect')}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.4rem',
              padding: '0.45rem 0.8rem',
              fontSize: '0.85rem',
              background: activeTool === 'inspect' ? 'var(--accent-cyan)' : 'transparent',
              color: activeTool === 'inspect' ? '#000' : 'var(--text-primary)',
              border: activeTool === 'inspect' ? '1px solid var(--accent-cyan)' : '1px solid var(--border-color)',
              fontWeight: activeTool === 'inspect' ? 800 : 500,
            }}
          >
            <MousePointer size={16} /> 단일 선택 (기본)
          </button>
          <button
            className={`btn-tactical ${activeTool === 'brush' ? 'btn-primary' : ''}`}
            onClick={() => setActiveTool('brush')}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.4rem',
              padding: '0.45rem 0.8rem',
              fontSize: '0.85rem',
              background: activeTool === 'brush' ? 'var(--accent-neon)' : 'transparent',
              color: activeTool === 'brush' ? '#fff' : 'var(--text-primary)',
              border: '1px solid var(--border-color)',
              fontWeight: activeTool === 'brush' ? 800 : 500,
            }}
          >
            <Paintbrush size={16} /> 브러시 칠하기
          </button>
          <button
            className={`btn-tactical ${activeTool === 'eraser' ? 'btn-primary' : ''}`}
            onClick={() => setActiveTool('eraser')}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.4rem',
              padding: '0.45rem 0.8rem',
              fontSize: '0.85rem',
              background: activeTool === 'eraser' ? '#ef4444' : 'transparent',
              color: activeTool === 'eraser' ? '#fff' : 'var(--text-primary)',
              border: '1px solid var(--border-color)',
              fontWeight: activeTool === 'eraser' ? 800 : 500,
            }}
          >
            <Eraser size={16} /> 지우개 (기본값 0)
          </button>
        </div>

        {/* 데이터 액션 버튼군 */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
          <button
            onClick={handleSaveToDb}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.4rem',
              padding: '0.5rem 1rem',
              borderRadius: '8px',
              border: 'none',
              background: isDirty ? 'var(--accent-cyan)' : 'rgba(59, 130, 246, 0.2)',
              color: isDirty ? '#000' : 'var(--accent-cyan)',
              fontWeight: 800,
              cursor: 'pointer',
              boxShadow: isDirty ? '0 0 12px rgba(0, 229, 255, 0.4)' : 'none',
            }}
          >
            <Save size={16} /> DB 저장 {isDirty && '(미저장)'}
          </button>

          <button
            onClick={handleExportJson}
            title="JSON 파일로 백업"
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.4rem',
              padding: '0.5rem 0.8rem',
              borderRadius: '8px',
              background: 'rgba(255,255,255,0.05)',
              border: '1px solid var(--border-color)',
              color: 'var(--text-primary)',
              cursor: 'pointer',
            }}
          >
            <Download size={16} /> 내보내기
          </button>

          <button
            onClick={() => fileInputRef.current?.click()}
            title="JSON 파일로부터 불러오기"
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.4rem',
              padding: '0.5rem 0.8rem',
              borderRadius: '8px',
              background: 'rgba(255,255,255,0.05)',
              border: '1px solid var(--border-color)',
              color: 'var(--text-primary)',
              cursor: 'pointer',
            }}
          >
            <Upload size={16} /> 불러오기
          </button>
          <input
            type="file"
            ref={fileInputRef}
            onChange={handleImportJson}
            accept=".json"
            style={{ display: 'none' }}
          />

          <button
            onClick={() => {
              if (
                confirm(
                  '모든 변경 사항을 초기화하시겠습니까? (저장되지 않은 작업은 삭제됩니다)'
                )
              ) {
                fetchTileAttributes().then((data) => {
                  setAttributes(data);
                  setIsDirty(false);
                });
              }
            }}
            title="작업 초기화"
            style={{
              padding: '0.5rem 0.6rem',
              borderRadius: '8px',
              background: 'rgba(255,255,255,0.05)',
              border: '1px solid var(--border-color)',
              color: 'var(--text-muted)',
              cursor: 'pointer',
            }}
          >
            <RotateCcw size={16} />
          </button>
        </div>
      </div>

      {/* 2. 타일 타입 팔레트 바 */}
      <div
        className="tactical-card"
        style={{
          display: 'flex',
          alignItems: 'center',
          padding: '0.6rem 1rem',
          gap: '0.6rem',
          overflowX: 'auto',
        }}
      >
        <span
          style={{
            fontSize: '0.8rem',
            fontWeight: 700,
            color: 'var(--text-muted)',
            whiteSpace: 'nowrap',
          }}
        >
          타입 팔레트:
        </span>

        {types.map((t) => {
          const isSelected = activeTypeId === t.id && activeTool === 'brush';
          return (
            <div
              key={t.id}
              onClick={() => {
                setActiveTypeId(t.id);
                setActiveTool('brush');
              }}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem',
                padding: '0.35rem 0.75rem',
                borderRadius: '6px',
                cursor: 'pointer',
                background: isSelected
                  ? 'rgba(255,255,255,0.12)'
                  : 'rgba(255,255,255,0.03)',
                border: isSelected
                  ? `2px solid ${t.color_hex}`
                  : '1px solid var(--border-color)',
                boxShadow: isSelected ? `0 0 8px ${t.color_hex}66` : 'none',
                whiteSpace: 'nowrap',
              }}
            >
              <div
                style={{
                  width: '12px',
                  height: '12px',
                  borderRadius: '3px',
                  backgroundColor: t.color_hex,
                }}
              />
              <span
                style={{
                  fontSize: '0.85rem',
                  fontWeight: isSelected ? 800 : 500,
                  color: isSelected ? '#fff' : 'var(--text-secondary)',
                }}
              >
                [{t.id}] {t.name}
              </span>
              {t.id !== 0 && (
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    handleDeleteType(t.id);
                  }}
                  style={{
                    background: 'none',
                    border: 'none',
                    color: 'var(--text-muted)',
                    cursor: 'pointer',
                    padding: 0,
                    display: 'flex',
                  }}
                  title="타입 삭제"
                >
                  <X size={13} />
                </button>
              )}
            </div>
          );
        })}

        {/* 타입 추가 버튼 */}
        <button
          onClick={() => {
            const nextId =
              types.length > 0 ? Math.max(...types.map((t) => Number(t.id))) + 1 : 1;
            setTypeForm({
              id: nextId,
              name: '',
              color_hex: '#00e5ff',
              description: '',
              is_blocked: false,
            });
            setShowTypeModal(true);
          }}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '0.3rem',
            padding: '0.35rem 0.65rem',
            borderRadius: '6px',
            background: 'rgba(0, 229, 255, 0.1)',
            border: '1px dashed var(--accent-cyan)',
            color: 'var(--accent-cyan)',
            fontSize: '0.8rem',
            fontWeight: 700,
            cursor: 'pointer',
            whiteSpace: 'nowrap',
          }}
        >
          <Plus size={14} /> 새 타입 추가
        </button>
      </div>

      {/* 3. 메인 맵 에디터 뷰포트 및 우측 인스펙터 */}
      <div style={{ flex: 1, position: 'relative', borderRadius: '12px', overflow: 'hidden' }}>
        <div ref={mapRef} style={{ width: '100%', height: '100%' }} />

        {/* 맵 좌하단 안내 정보 뱃지 */}
        <div
          style={{
            position: 'absolute',
            bottom: '16px',
            left: '16px',
            zIndex: 1000,
            background: 'rgba(15, 23, 42, 0.85)',
            backdropFilter: 'blur(8px)',
            padding: '0.5rem 0.9rem',
            borderRadius: '8px',
            border: '1px solid var(--border-color)',
            fontSize: '0.75rem',
            color: 'var(--text-secondary)',
            display: 'flex',
            alignItems: 'center',
            gap: '0.5rem',
            pointerEvents: 'none',
          }}
        >
          <Compass size={14} style={{ color: 'var(--accent-cyan)' }} />
          속성 부여된 타일: <b>{Object.keys(attributes).length}개</b> | 줌 14 이상에서 전체 그리드 노출
        </div>

        {/* 우측 타일 상세 인스펙터 패널 (단일 타일 선택 시 표시) */}
        {selectedTile && (
          <div
            className="tactical-card"
            style={{
              position: 'absolute',
              top: '16px',
              right: '16px',
              width: '280px',
              zIndex: 1000,
              padding: '1rem',
              backdropFilter: 'blur(12px)',
              boxShadow: '0 8px 32px rgba(0,0,0,0.5)',
            }}
          >
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                marginBottom: '0.8rem',
              }}
            >
              <h4
                style={{
                  margin: 0,
                  fontSize: '0.95rem',
                  color: 'var(--accent-cyan)',
                  fontWeight: 800,
                }}
              >
                타일 인스펙터
              </h4>
              <button
                onClick={() => setSelectedTile(null)}
                style={{
                  background: 'none',
                  border: 'none',
                  color: 'var(--text-muted)',
                  cursor: 'pointer',
                }}
              >
                <X size={16} />
              </button>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.6rem', fontSize: '0.8rem' }}>
              <div>
                <span style={{ color: 'var(--text-muted)' }}>타일 ID:</span>{' '}
                <b style={{ color: 'var(--text-primary)' }}>{selectedTile.id}</b>
              </div>
              <div>
                <span style={{ color: 'var(--text-muted)' }}>그리드 좌표:</span>{' '}
                <span>
                  q={selectedTile.q}, r={selectedTile.r}
                </span>
              </div>
              <div>
                <span style={{ color: 'var(--text-muted)' }}>위경도:</span>{' '}
                <span>
                  {selectedTile.lat.toFixed(5)}, {selectedTile.lng.toFixed(5)}
                </span>
              </div>

              <div style={{ marginTop: '0.4rem' }}>
                <label style={{ display: 'block', marginBottom: '0.2rem', color: 'var(--text-secondary)' }}>
                  부여 속성 타입:
                </label>
                <select
                  value={selectedTile.type_id}
                  onChange={(e) => {
                    const newTypeId = Number(e.target.value);
                    const tileId = selectedTile.id;
                    if (newTypeId === 0) {
                      // 0번은 속성 제거
                      setAttributes((prev) => {
                        const next = { ...prev };
                        delete next[tileId];
                        return next;
                      });
                    } else {
                      setAttributes((prev) => ({
                        ...prev,
                        [tileId]: {
                          id: tileId,
                          q: selectedTile.q,
                          r: selectedTile.r,
                          type_id: newTypeId,
                          memo: selectedTile.memo || '',
                        },
                      }));
                    }
                    setSelectedTile((prev) => ({ ...prev, type_id: newTypeId }));
                    setIsDirty(true);
                  }}
                  style={{
                    width: '100%',
                    padding: '0.45rem',
                    background: 'rgba(0,0,0,0.3)',
                    border: '1px solid var(--border-color)',
                    color: '#fff',
                    borderRadius: '6px',
                  }}
                >
                  {types.map((t) => (
                    <option key={t.id} value={t.id}>
                      [{t.id}] {t.name}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label style={{ display: 'block', marginBottom: '0.2rem', color: 'var(--text-secondary)' }}>
                  관리자 메모:
                </label>
                <input
                  type="text"
                  placeholder="예: 호수 공원 이벤트 타일"
                  value={selectedTile.memo || ''}
                  onChange={(e) => {
                    const memo = e.target.value;
                    setSelectedTile((prev) => ({ ...prev, memo }));
                    if (selectedTile.type_id !== 0) {
                      setAttributes((prev) => ({
                        ...prev,
                        [selectedTile.id]: {
                          ...prev[selectedTile.id],
                          memo,
                        },
                      }));
                      setIsDirty(true);
                    }
                  }}
                  style={{
                    width: '100%',
                    padding: '0.45rem',
                    background: 'rgba(0,0,0,0.3)',
                    border: '1px solid var(--border-color)',
                    color: '#fff',
                    borderRadius: '6px',
                  }}
                />
              </div>
            </div>
          </div>
        )}
      </div>

      {/* 4. 신규/수정 타입 생성 모달 */}
      {showTypeModal && (
        <div
          style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            background: 'rgba(0,0,0,0.75)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 9999,
          }}
        >
          <div
            className="tactical-card"
            style={{
              width: '380px',
              padding: '1.5rem',
              display: 'flex',
              flexDirection: 'column',
              gap: '1rem',
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h3 style={{ margin: 0, fontSize: '1.1rem', color: 'var(--accent-cyan)' }}>
                새 타일 타입 정의
              </h3>
              <button
                onClick={() => setShowTypeModal(false)}
                style={{
                  background: 'none',
                  border: 'none',
                  color: 'var(--text-muted)',
                  cursor: 'pointer',
                }}
              >
                <X size={18} />
              </button>
            </div>

            <form
              onSubmit={handleSaveTypeForm}
              style={{ display: 'flex', flexDirection: 'column', gap: '0.8rem' }}
            >
              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
                  타입 ID (숫자 식별자):
                </label>
                <input
                  type="number"
                  required
                  value={typeForm.id}
                  onChange={(e) => setTypeForm({ ...typeForm, id: Number(e.target.value) })}
                  style={{
                    width: '100%',
                    padding: '0.5rem',
                    background: 'rgba(0,0,0,0.3)',
                    border: '1px solid var(--border-color)',
                    color: '#fff',
                    borderRadius: '6px',
                  }}
                />
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
                  타입 이름:
                </label>
                <input
                  type="text"
                  required
                  placeholder="예: 늪지대, 이벤트존"
                  value={typeForm.name}
                  onChange={(e) => setTypeForm({ ...typeForm, name: e.target.value })}
                  style={{
                    width: '100%',
                    padding: '0.5rem',
                    background: 'rgba(0,0,0,0.3)',
                    border: '1px solid var(--border-color)',
                    color: '#fff',
                    borderRadius: '6px',
                  }}
                />
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
                  표시 색상:
                </label>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  <input
                    type="color"
                    value={typeForm.color_hex}
                    onChange={(e) => setTypeForm({ ...typeForm, color_hex: e.target.value })}
                    style={{
                      width: '40px',
                      height: '36px',
                      border: 'none',
                      background: 'none',
                      cursor: 'pointer',
                    }}
                  />
                  <input
                    type="text"
                    value={typeForm.color_hex}
                    onChange={(e) => setTypeForm({ ...typeForm, color_hex: e.target.value })}
                    style={{
                      flex: 1,
                      padding: '0.5rem',
                      background: 'rgba(0,0,0,0.3)',
                      border: '1px solid var(--border-color)',
                      color: '#fff',
                      borderRadius: '6px',
                    }}
                  />
                </div>
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
                  설명:
                </label>
                <input
                  type="text"
                  placeholder="속성에 대한 부가 설명"
                  value={typeForm.description}
                  onChange={(e) => setTypeForm({ ...typeForm, description: e.target.value })}
                  style={{
                    width: '100%',
                    padding: '0.5rem',
                    background: 'rgba(0,0,0,0.3)',
                    border: '1px solid var(--border-color)',
                    color: '#fff',
                    borderRadius: '6px',
                  }}
                />
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginTop: '0.3rem' }}>
                <input
                  type="checkbox"
                  id="is_blocked"
                  checked={typeForm.is_blocked}
                  onChange={(e) => setTypeForm({ ...typeForm, is_blocked: e.target.checked })}
                />
                <label htmlFor="is_blocked" style={{ fontSize: '0.85rem', color: 'var(--text-primary)' }}>
                  진입 불가(통행 차단) 속성 여부
                </label>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.5rem', marginTop: '1rem' }}>
                <button
                  type="button"
                  onClick={() => setShowTypeModal(false)}
                  style={{
                    padding: '0.5rem 0.8rem',
                    borderRadius: '6px',
                    background: 'transparent',
                    border: '1px solid var(--border-color)',
                    color: 'var(--text-muted)',
                    cursor: 'pointer',
                  }}
                >
                  취소
                </button>
                <button
                  type="submit"
                  style={{
                    padding: '0.5rem 1rem',
                    borderRadius: '6px',
                    background: 'var(--accent-cyan)',
                    border: 'none',
                    color: '#000',
                    fontWeight: 800,
                    cursor: 'pointer',
                  }}
                >
                  타입 등록
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
