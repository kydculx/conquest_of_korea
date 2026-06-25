import React, { useEffect, useState, useRef } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { 
  Download, 
  Upload, 
  Trash2, 
  RotateCcw, 
  X,
  Map as MapIcon
} from 'lucide-react';


const originLat = 37.5665;
const originLng = 126.9780;
const hexSize = 100.0; // 100m 정밀 타일 규격
const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'.split('');

// 브러시 컬러 (기본 시안색 고정)
const brushColor = '#00e5ff';


// 헥스 그리드 좌표를 경위도로 변환
function hexToLatLng(q, r, centerLat, centerLng) {
  const x = Math.sqrt(3) * q + (Math.sqrt(3) / 2) * r;
  const y = (3 / 2) * r;

  const latRad = centerLat * Math.PI / 180;
  const lat = (y * hexSize / 111320) + centerLat;
  const lng = (x * hexSize / (111320 * Math.cos(latRad))) + centerLng;

  return [lat, lng];
}

// 헥스 꼭짓점 6개 경위도 배열 계산
function getHexCorners(q, r, centerLat, centerLng) {
  const center = hexToLatLng(q, r, centerLat, centerLng);
  const latRad = centerLat * Math.PI / 180;
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

export default function MapEditorTab() {
  // 데이터 모델: letters는 각각 gridTiles 오브젝트를 내장함.
  // [ { id, lat, lng, char, gridTiles: { "q,r": "#hexColor" } } ]
  const [letters, setLetters] = useState([]);
  
  // 현재 포커스(선택)된 문자 마커 ID
  const [selectedLetterId, setSelectedLetterId] = useState(null);
  
  // 신규 문자 등록을 위한 임시 좌표 및 모달 제어 상태
  const [selectedCoords, setSelectedCoords] = useState(null);
  const [showCharSelectModal, setShowCharSelectModal] = useState(false);

  // 저장 파일명 입력 모달 제어 상태 (React 모달 대체)
  const [showSaveModal, setShowSaveModal] = useState(false);
  const [saveFileName, setSaveFileName] = useState('');


  const mapRef = useRef(null);
  const mapInstance = useRef(null);
  const markersGroup = useRef(null);
  const gridTilesGroup = useRef(null);
  const fileInputRef = useRef(null);

  // 현재 포커스된 문자 마커 객체 계산
  const activeLetter = letters.find(item => item.id === selectedLetterId) || null;

  // 1. Leaflet 지도 초기화
  useEffect(() => {
    if (!mapRef.current) return;
    if (mapInstance.current) return;

    // 다크 테마 지도 셋업
    const map = L.map(mapRef.current, {
      zoomControl: true,
      attributionControl: false
    }).setView([originLat, originLng], 14);

    L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}{r}.png', {
      maxZoom: 20
    }).addTo(map);

    markersGroup.current = L.layerGroup().addTo(map);
    gridTilesGroup.current = L.layerGroup().addTo(map);
    mapInstance.current = map;

    // 지도를 클릭했을 때 처리
    map.on('click', (e) => {
      // 맵 배경 클릭 시 문자 추가 팝업을 연다.
      const { lat, lng } = e.latlng;
      setSelectedCoords([lat, lng]);
      setShowCharSelectModal(true);
    });

    // 레이아웃 왜곡 방지
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

  // 2. letters 상태 변경 시 지도 위의 문자 마커 동기화
  useEffect(() => {
    if (!mapInstance.current || !markersGroup.current) return;

    markersGroup.current.clearLayers();

    letters.forEach(letter => {
      const isFocused = letter.id === selectedLetterId;
      const customIcon = L.divIcon({
        className: 'leaflet-div-icon',
        html: `<div class="editor-letter-badge ${isFocused ? 'focused' : ''}">${letter.char}</div>`,
        iconSize: [30, 30],
        iconAnchor: [15, 15]
      });

      // 마커를 그리드 최상단 외곽(q: 0, r: -8) 좌표에 생성하여 타일 가림 방지
      const markerLatLng = hexToLatLng(0, -8, letter.lat, letter.lng);
      const marker = L.marker(markerLatLng, { icon: customIcon });

      // 문자 마커 클릭 시 해당 문자를 포커스하고 그 15x15 그리드를 띄운다.
      marker.on('click', (e) => {
        L.DomEvent.stopPropagation(e);
        setSelectedLetterId(letter.id);
      });

      markersGroup.current.addLayer(marker);
    });
  }, [letters, selectedLetterId]);

  // 3. 포커스된 마커 좌표를 기준으로 15x15 헥사 그리드 및 페인팅 타일 렌더링 동기화
  useEffect(() => {
    if (!mapInstance.current || !gridTilesGroup.current) return;

    gridTilesGroup.current.clearLayers();

    // 포커스된 문자가 없을 때는 15x15 타일 그리드를 그리지 않는다.
    if (!activeLetter) return;

    const centerLat = activeLetter.lat;
    const centerLng = activeLetter.lng;
    const gridTiles = activeLetter.gridTiles || {};

    // 15x15 그리드 렌더링 (q: -7 ~ 7, r: -7 ~ 7)
    for (let q = -7; q <= 7; q++) {
      for (let r = -7; r <= 7; r++) {
        const key = `${q},${r}`;
        const color = gridTiles[key];
        const isPainted = !!color;
        
        const corners = getHexCorners(q, r, centerLat, centerLng);
        
        const polygonOptions = {
          color: isPainted ? color : 'rgba(0, 229, 255, 0.35)', // 칠해지지 않은 빈 타일은 연한 네온 민트 점선
          weight: isPainted ? 1.5 : 1,
          fillColor: color || 'transparent',
          fillOpacity: isPainted ? 0.45 : 0.0,
          dashArray: isPainted ? null : '4, 4',
          interactive: true
        };

        const polygon = L.polygon(corners, polygonOptions);

        // 그리드 타일 클릭 시 선택된 문자의 gridTiles 데이터 갱신
        polygon.on('click', (e) => {
          L.DomEvent.stopPropagation(e);
          
          setLetters(prev => prev.map(letter => {
            if (letter.id === activeLetter.id) {
              const nextTiles = { ...letter.gridTiles };
              
              if (nextTiles[key]) {
                // 이미 색상이 칠해져 있다면 색칠 해제 (토글 방식)
                delete nextTiles[key];
              } else if (brushColor) {
                // 색칠되어 있지 않고 브러시 색상이 지정되어 있다면 색칠하기
                nextTiles[key] = brushColor;
              }
              
              return { ...letter, gridTiles: nextTiles };
            }
            return letter;
          }));
        });

        gridTilesGroup.current.addLayer(polygon);
      }
    }
  }, [selectedLetterId, letters, brushColor, activeLetter]);

  // 4. 새 문자 선택 완료 및 생성 (자동 포커스 적용)
  const handleSelectChar = (char) => {
    if (!selectedCoords) return;

    const newLetterId = Date.now().toString() + Math.random().toString(36).substr(2, 5);
    const newLetter = {
      id: newLetterId,
      lat: selectedCoords[0],
      lng: selectedCoords[1],
      char: char.toUpperCase(),
      gridTiles: {} // 빈 15x15 맵으로 초기화
    };

    setLetters(prev => [...prev, newLetter]);
    setSelectedLetterId(newLetterId); // 배치 후 즉시 포커스
    setShowCharSelectModal(false);
    setSelectedCoords(null);
  };

  // 5. 포커스된 마커의 문자 변경
  const handleUpdateActiveChar = (char) => {
    if (!selectedLetterId) return;

    setLetters(prev => prev.map(item => 
      item.id === selectedLetterId ? { ...item, char: char.toUpperCase() } : item
    ));
  };

  // 6. 포커스된 마커 삭제
  const handleDeleteActiveMarker = () => {
    if (!selectedLetterId) return;

    if (window.confirm('이 문자 마커 및 이 문자에 칠해진 타일 맵을 삭제하시겠습니까?')) {
      setLetters(prev => prev.filter(item => item.id !== selectedLetterId));
      setSelectedLetterId(null);
    }
  };

  // 7. 특정 좌표로 지도 이동
  const handleFocusLocation = (lat, lng) => {
    if (mapInstance.current) {
      mapInstance.current.setView([lat, lng], 15, { animate: true });
    }
  };

  // 8. 전체 초기화
  const handleClearAll = () => {
    if (window.confirm('모든 문자 마커 및 개별 타일 페인팅 내역을 초기화하시겠습니까?')) {
      setLetters([]);
      setSelectedLetterId(null);
    }
  };

  // 9. 통합 저장 (Export JSON v1.3 - 선택한 문자 단 1개만 색상 없이 파일로 저장)
  const handleExportJSON = (e) => {
    if (e) {
      e.preventDefault();
      e.stopPropagation();
    }

    if (!activeLetter) {
      alert('저장할 문자 마커를 먼저 지도에서 선택(클릭)해 주세요.');
      return;
    }

    setSaveFileName(activeLetter.char);
    setShowSaveModal(true);
  };

  // 실제 JSON 파일 저장 실행 (React 모달 내 저장 액션)
  const handleConfirmSave = async () => {
    if (!activeLetter) return;

    const defaultFileName = activeLetter.char;
    let finalFileName = saveFileName.trim() !== '' ? saveFileName.trim() : defaultFileName;

    // 사용자가 입력란에 확장자(.json)까지 기입한 경우 중복 확장자(A.json.json) 방지를 위해 제거
    if (finalFileName.toLowerCase().endsWith('.json')) {
      finalFileName = finalFileName.substring(0, finalFileName.length - 5);
    }

    // 선택된 1개 마커에 귀속된 타일들의 q, r 좌표 배열만 추출
    const tilesArray = Object.keys(activeLetter.gridTiles || {}).map(key => {
      const [q, r] = key.split(',').map(Number);
      return { q, r };
    });

    const exportData = {
      char: activeLetter.char,
      lat: activeLetter.lat,
      lng: activeLetter.lng,
      tiles: tilesArray
    };

    const dataStr = JSON.stringify(exportData, null, 2);

    // 1. 브라우저가 File System Access API를 지원할 경우 (크롬, 엣지 등): 시스템 저장 다이얼로그로 저장 경로와 이름 직접 지정
    if (window.showSaveFilePicker) {
      try {
        const options = {
          suggestedName: `${finalFileName}.json`,
          types: [{
            description: 'JSON Files',
            accept: {
              'application/json': ['.json'],
            },
          }],
        };
        const handle = await window.showSaveFilePicker(options);
        const writable = await handle.createWritable();
        await writable.write(dataStr);
        await writable.close();
        
        setShowSaveModal(false);
        return; // 파일 저장 창에서 성공적으로 기동되어 프로세스 종료
      } catch (err) {
        // 사용자가 취소했거나 저장 다이얼로그를 기각한 경우
        if (err.name === 'AbortError') {
          return;
        }
        console.warn('showSaveFilePicker API 에러, 일반 다운로드로 전환합니다:', err);
      }
    }

    // 2. API 미지원 시 Fallback: Classic 가상 링크 다운로드 방식 (기본 Downloads 폴더행)
    const blob = new Blob([dataStr], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    
    const link = document.createElement('a');
    link.href = url;
    link.download = `${finalFileName}.json`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    
    // 다운로드 창이 열리거나 파일 스트림이 기동되는 시간을 확보하기 위해 메모리 해제를 1초 지연시킵니다.
    setTimeout(() => {
      URL.revokeObjectURL(url);
    }, 1000);

    setShowSaveModal(false);
  };

  // 10. 통합 불러오기 (Import JSON - 단일 마커 병합 및 레거시 포맷 하위 호환)
  const handleImportJSON = (e) => {
    const file = e.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (event) => {
      try {
        const parsedData = JSON.parse(event.target.result);
        
        // 1. 단일 마커 파일인 경우 (v1.3 표준)
        if (parsedData && typeof parsedData === 'object' && !Array.isArray(parsedData) && parsedData.char) {
          const gridTiles = {};
          if (Array.isArray(parsedData.tiles)) {
            parsedData.tiles.forEach(t => {
              gridTiles[`${t.q},${t.r}`] = '#00e5ff';
            });
          }

          const newLetter = {
            id: `loaded-${parsedData.char}-${Date.now()}`,
            lat: parsedData.lat,
            lng: parsedData.lng,
            char: parsedData.char.toUpperCase(),
            gridTiles: gridTiles
          };

          // 불러오기 시 기존의 문자 리스트를 완전히 지우고(초기화), 새로 불러온 1개의 마커만 지도에 적재합니다.
          setLetters([newLetter]);

          setSelectedLetterId(newLetter.id);
          handleFocusLocation(newLetter.lat, newLetter.lng);
        }
        // 2. 레거시 포맷 (배열 형태)
        else if (Array.isArray(parsedData)) {
          const isValid = parsedData.every(item => 
            typeof item.lat === 'number' &&
            typeof item.lng === 'number' &&
            typeof item.char === 'string' &&
            item.char.length === 1
          );

          if (isValid) {
            const normalized = parsedData.map((item, idx) => ({
              id: item.id || `loaded-${idx}-${Date.now()}`,
              lat: item.lat,
              lng: item.lng,
              char: item.char.toUpperCase(),
              gridTiles: {}
            }));
            setLetters(normalized);
            setSelectedLetterId(null);
            if (normalized.length > 0) {
              handleFocusLocation(normalized[0].lat, normalized[0].lng);
            }
          } else {
            alert('JSON 데이터 형식이 올바르지 않습니다.');
          }
        } 
        // 3. 레거시 오브젝트 포맷 (전체 letters를 감싸던 형태)
        else if (parsedData && typeof parsedData === 'object' && parsedData.letters) {
          let loadedLetters = parsedData.letters || [];

          // v1.1/1.2 호환 변환
          const normalized = loadedLetters.map((item, idx) => {
            const gridTiles = {};
            if (Array.isArray(item.tiles)) {
              item.tiles.forEach(t => {
                gridTiles[`${t.q},${t.r}`] = '#00e5ff';
              });
            } else if (item.gridTiles && typeof item.gridTiles === 'object') {
              Object.keys(item.gridTiles).forEach(key => {
                gridTiles[key] = '#00e5ff';
              });
            }

            return {
              id: item.id || `loaded-${idx}-${Date.now()}`,
              lat: item.lat,
              lng: item.lng,
              char: item.char.toUpperCase(),
              gridTiles
            };
          });

          setLetters(normalized);
          setSelectedLetterId(null);

          if (normalized.length > 0) {
            handleFocusLocation(normalized[0].lat, normalized[0].lng);
          }
        } else {
          alert('가져오기에 실패했습니다. 지원하지 않는 파일 형식입니다.');
        }
      } catch (err) {
        console.error(err);
        alert('파일 파싱 중 오류가 발생했습니다.');
      }
    };
    reader.readAsText(file);
    e.target.value = '';
  };

  return (
    <div className="editor-layout">
      
      {/* 1. 에디터 제어 및 설정 사이드 패널 */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '1.2rem' }}>
        
        {/* 파일 관리 및 공통 설정 카드 */}
        <div className="tactical-card" style={{ padding: '1.2rem' }}>
          <h3 style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', fontSize: '1.0rem', color: 'var(--text-primary)', marginBottom: '1.0rem' }}>
            <MapIcon size={16} style={{ color: 'var(--accent-cyan)' }} />
            맵 에디터 데이터
          </h3>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.6rem' }}>
            <input 
              type="file" 
              ref={fileInputRef} 
              onChange={handleImportJSON} 
              accept=".json" 
              style={{ display: 'none' }} 
            />

            <button 
              onClick={() => fileInputRef.current && fileInputRef.current.click()} 
              className="tactical-btn active"
              style={{ width: '100%', justifyContent: 'center', padding: '0.5rem 1rem', fontSize: '0.85rem' }}
            >
              <Upload size={14} /> 디자인 불러오기
            </button>

            <button 
              onClick={handleExportJSON} 
              className="tactical-btn"
              style={{ width: '100%', justifyContent: 'center', padding: '0.5rem 1rem', fontSize: '0.85rem' }}
            >
              <Download size={14} /> 디자인 저장하기
            </button>

            <button 
              onClick={handleClearAll} 
              className="tactical-btn danger"
              style={{ width: '100%', justifyContent: 'center', padding: '0.5rem 1rem', fontSize: '0.85rem' }}
            >
              <RotateCcw size={14} /> 전체 초기화
            </button>
          </div>
        </div>

        {/* 선택된 문자 및 개별 15x15 타일 페인팅 카드 */}
        {activeLetter && (
          <div className="tactical-card" style={{ padding: '1.2rem', display: 'flex', flexDirection: 'column', gap: '0.8rem' }}>
            {/* 문자 변경 툴 */}
            <div>
              <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', display: 'block', marginBottom: '0.4rem' }}>
                🔤 문자 변경 ({activeLetter.char})
              </span>
              <div className="editor-char-grid" style={{ maxHeight: '120px', overflowY: 'auto', border: '1px solid var(--border-color)', borderRadius: '6px', padding: '0.3rem' }}>
                {characters.map(char => (
                  <button
                    key={char}
                    onClick={() => handleUpdateActiveChar(char)}
                    className={`editor-char-btn ${activeLetter.char === char ? 'active' : ''}`}
                    style={{ height: '30px', fontSize: '0.85rem' }}
                  >
                    {char}
                  </button>
                ))}
              </div>
            </div>
            {/* 마커 조작 도구 */}
            <div style={{ display: 'flex', gap: '0.4rem', marginTop: '0.4rem' }}>
              <button 
                onClick={() => setSelectedLetterId(null)}
                className="tactical-btn"
                style={{ flex: 1, justifyContent: 'center', padding: '0.4rem', fontSize: '0.8rem' }}
              >
                포커스 해제
              </button>
              <button 
                onClick={handleDeleteActiveMarker}
                className="tactical-btn danger"
                style={{ flex: 1, justifyContent: 'center', padding: '0.4rem', fontSize: '0.8rem' }}
              >
                <Trash2 size={12} /> 마커 삭제
              </button>
            </div>
          </div>
        )}


        {/* 도움말 안내 카드 */}
        <div className="tactical-card" style={{ padding: '1.2rem' }}>
          <h4 style={{ fontSize: '0.85rem', color: 'var(--text-primary)', marginBottom: '0.4rem' }}>💡 사용법 가이드</h4>
          <ul style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', paddingLeft: '1rem', lineHeight: '1.6' }}>
            <li>지도 위의 빈 곳을 <strong>클릭</strong>해 신규 문자 마커를 생성합니다. (자동 선택됨)</li>
            <li>마커가 선택되면 마커 주변에 **15x15 헥사 타일 그리드**가 뜹니다.</li>
            <li>그리드 안을 탭해 색을 칠하면 **해당 문자에만 타일 맵이 바인딩**됩니다.</li>
            <li>다른 문자를 선택하면 해당 문자만의 개별 타일 맵으로 교체됩니다.</li>
          </ul>
        </div>


      </div>

      {/* 2. 메인 지도 캔버스 영역 */}
      <div className="tactical-card map-card" style={{ padding: 0, overflow: 'hidden', flex: 1 }}>
        <div className="map-wrapper" style={{ height: '100%' }}>
          <div 
            ref={mapRef} 
            className="map-element" 
            style={{ height: '100%', border: 'none', borderRadius: 'var(--glow-radius)' }} 
          />
        </div>
      </div>

      {/* 3. 문자 선택 모달 (신규 등록) */}
      {showCharSelectModal && (
        <div className="editor-modal-overlay" onClick={() => { setShowCharSelectModal(false); setSelectedCoords(null); }}>
          <div className="editor-modal-content" onClick={(e) => e.stopPropagation()}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
              <h3 style={{ fontSize: '1.1rem', color: 'var(--text-primary)' }}>문자 생성</h3>
              <button 
                onClick={() => { setShowCharSelectModal(false); setSelectedCoords(null); }}
                style={{ background: 'none', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}
              >
                <X size={20} />
              </button>
            </div>
            
            <p style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
              이 위치에 배치하고 타일을 개별적으로 칠할 문자(A~Z, 0~9)를 골라주세요.
            </p>

            <div className="editor-char-grid">
              {characters.map(char => (
                <button
                  key={char}
                  onClick={() => handleSelectChar(char)}
                  className="editor-char-btn"
                >
                  {char}
                </button>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* 5. 파일 저장명 입력 모달 (React 내장 모달로 브라우저 prompt 대체) */}
      {showSaveModal && (
        <div className="editor-modal-overlay" onClick={() => setShowSaveModal(false)}>
          <div className="editor-modal-content" onClick={(e) => e.stopPropagation()}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.2rem' }}>
              <h3 style={{ fontSize: '1.1rem', color: 'var(--text-primary)', display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                <Download size={18} style={{ color: 'var(--accent-cyan)' }} />
                디자인 저장하기
              </h3>
              <button 
                onClick={() => setShowSaveModal(false)}
                style={{ background: 'none', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}
              >
                <X size={20} />
              </button>
            </div>
            
            <p style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', marginBottom: '1rem' }}>
              저장할 파일 이름을 입력해 주세요 (확장자 제외).
            </p>

            <div style={{ marginBottom: '1.5rem' }}>
              <input 
                type="text" 
                className="tactical-input" 
                value={saveFileName} 
                onChange={(e) => setSaveFileName(e.target.value)}
                placeholder="예: A"
                style={{ fontSize: '0.95rem' }}
                autoFocus
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    handleConfirmSave();
                  }
                }}
              />
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.6rem' }}>
              <button 
                onClick={() => setShowSaveModal(false)}
                className="tactical-btn"
                style={{ padding: '0.5rem 1rem', fontSize: '0.8rem' }}
              >
                취소
              </button>
              <button 
                onClick={handleConfirmSave}
                className="tactical-btn active"
                style={{ padding: '0.5rem 1rem', fontSize: '0.8rem' }}
              >
                저장
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}
