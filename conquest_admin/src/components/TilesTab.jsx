import React, { useEffect, useState } from 'react';
import { fetchTiles, fetchUsers, neutralizeTile, transferTileOwnership, updateTileShield } from '../api';
import { Search, RotateCcw, Shield, Trash2, ArrowLeftRight, X, ShieldAlert } from 'lucide-react';

export default function TilesTab() {
  const [tiles, setTiles] = useState([]);
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  
  // 모달 제어 상태
  const [selectedTile, setSelectedTile] = useState(null);
  const [actionType, setActionType] = useState(null); // 'transfer' | 'shield'
  const [extraHours, setExtraHours] = useState('24');
  const [targetUserId, setTargetUserId] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const loadData = async () => {
    try {
      setLoading(true);
      const [tilesData, usersData] = await Promise.all([fetchTiles(), fetchUsers()]);
      setTiles(tilesData);
      setUsers(usersData);
      if (usersData.length > 0) {
        setTargetUserId(usersData[0].id);
      }
    } catch (err) {
      setError('영토 정보를 로드하는 중 에러가 발생했습니다.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleNeutralize = async (tileId) => {
    const confirm = window.confirm(`⚠️ 정말로 이 구역(${tileId})의 점령권을 강제 회수하여 중립지대로 만드시겠습니까?`);
    if (!confirm) return;

    try {
      setLoading(true);
      await neutralizeTile(tileId);
      alert('성공적으로 구역이 중립화되었습니다.');
      loadData();
    } catch (err) {
      console.error(err);
      alert('구역 중립화 처리 중 에러가 발생했습니다.');
    } finally {
      setLoading(false);
    }
  };

  const handleOpenTransfer = (tile) => {
    setSelectedTile(tile);
    setActionType('transfer');
    if (users.length > 0) {
      setTargetUserId(users.find(u => u.id !== tile.user_id)?.id || users[0].id);
    }
  };

  const handleTransfer = async () => {
    if (!selectedTile || !targetUserId) return;
    
    const targetUser = users.find(u => u.id === targetUserId);
    if (!targetUser) return;

    const confirm = window.confirm(
      `⚠️ 구역 [${selectedTile.id}]의 점령권을 사용자 [${targetUser.nickname}]에게 강제 양도하시겠습니까?`
    );
    if (!confirm) return;

    try {
      setSubmitting(true);
      await transferTileOwnership(selectedTile.id, targetUser.id, targetUser.color_hex);
      alert('소유권 강제 이전이 완료되었습니다.');
      setSelectedTile(null);
      setActionType(null);
      loadData();
    } catch (err) {
      console.error(err);
      alert('소유권 양도 중 오류가 발생했습니다.');
    } finally {
      setSubmitting(false);
    }
  };

  const handleOpenShield = (tile) => {
    setSelectedTile(tile);
    setActionType('shield');
    setExtraHours('24');
  };

  const handleUpdateShield = async () => {
    if (!selectedTile) return;
    const hours = parseInt(extraHours);
    if (isNaN(hours) || hours < 0) {
      alert('올바른 시간을 입력해 주세요.');
      return;
    }

    try {
      setSubmitting(true);
      await updateTileShield(selectedTile.id, hours);
      alert('보호막 유지 시간이 갱신되었습니다.');
      setSelectedTile(null);
      setActionType(null);
      loadData();
    } catch (err) {
      console.error(err);
      alert('보호막 업데이트 중 오류가 발생했습니다.');
    } finally {
      setSubmitting(false);
    }
  };

  const getUserNickname = (userId) => {
    const user = users.find(u => u.id === userId);
    return user ? user.nickname : '알 수 없는 사용자';
  };

  // 검색
  const filteredTiles = tiles.filter(tile => 
    tile.id.toLowerCase().includes(searchTerm.toLowerCase()) ||
    getUserNickname(tile.user_id).toLowerCase().includes(searchTerm.toLowerCase())
  );

  const isShieldActive = (expirationStr) => {
    if (!expirationStr) return false;
    const exp = new Date(expirationStr);
    return exp > new Date();
  };

  if (loading && tiles.length === 0) {
    return <div className="tactical-spinner" />;
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
      
      {/* 툴바 */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '1rem' }}>
        <div style={{ position: 'relative', width: '320px' }}>
          <Search size={18} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)' }} />
          <input 
            type="text"
            className="tactical-input"
            style={{ paddingLeft: '2.5rem' }}
            placeholder="타일 ID 또는 점령 사용자 검색..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
        <button className="tactical-btn" onClick={loadData}>
          <RotateCcw size={16} /> 새로고침
        </button>
      </div>

      {error && <div style={{ color: 'var(--accent-red)' }}>{error}</div>}

      {/* 영토 점령 현황 테이블 */}
      <div className="tactical-table-container">
        <table className="tactical-table">
          <thead>
            <tr>
              <th>영토(타일) ID</th>
              <th>좌표 (Q, R)</th>
              <th>점령 사용자</th>
              <th>확보 일시</th>
              <th>보호막 만료 시간</th>
              <th>점령 누적 횟수</th>
              <th style={{ textAlign: 'center' }}>전술 개입</th>
            </tr>
          </thead>
          <tbody>
            {filteredTiles.length === 0 ? (
              <tr>
                <td colSpan="7" style={{ textAlign: 'center', color: 'var(--text-muted)', padding: '2rem' }}>
                  점령된 영토 구역이 존재하지 않습니다.
                </td>
              </tr>
            ) : (
              filteredTiles.map(tile => {
                const shieldOn = isShieldActive(tile.shield_expiration);
                return (
                  <tr key={tile.id}>
                    <td style={{ fontFamily: 'monospace', fontWeight: 'bold' }}>
                      {tile.id}
                    </td>
                    <td style={{ color: 'var(--text-secondary)' }}>
                      Q: {tile.q}, R: {tile.r}
                    </td>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                        <div style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: tile.color_hex || '#00e5ff' }} />
                        <span style={{ fontWeight: 600 }}>{getUserNickname(tile.user_id)}</span>
                      </div>
                    </td>
                    <td>
                      {new Date(tile.captured_at).toLocaleString('ko-KR', {
                        month: '2-digit',
                        day: '2-digit',
                        hour: '2-digit',
                        minute: '2-digit'
                      })}
                    </td>
                    <td>
                      {shieldOn ? (
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', color: 'var(--accent-cyan)', fontWeight: 'bold' }}>
                          <Shield size={14} />
                          {new Date(tile.shield_expiration).toLocaleString('ko-KR', {
                            day: '2-digit',
                            hour: '2-digit',
                            minute: '2-digit'
                          })}
                        </div>
                      ) : (
                        <span style={{ color: 'var(--text-muted)' }}>보호막 만료됨</span>
                      )}
                    </td>
                    <td style={{ fontWeight: 'bold', color: 'var(--accent-gold)' }}>
                      {tile.capture_count} 회
                    </td>
                    <td>
                      <div style={{ display: 'flex', gap: '0.4rem', justifyContent: 'center' }}>
                        <button className="tactical-btn" onClick={() => handleOpenTransfer(tile)}>
                          <ArrowLeftRight size={14} /> 양도
                        </button>
                        <button className="tactical-btn" onClick={() => handleOpenShield(tile)}>
                          <Shield size={14} /> 보호막
                        </button>
                        <button className="tactical-btn danger" onClick={() => handleNeutralize(tile.id)}>
                          <Trash2 size={14} /> 회수
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>

      {/* 모달 레이아웃 */}
      {selectedTile && (
        <div style={{
          position: 'fixed', top: 0, left: 0, width: '100%', height: '100%',
          background: 'rgba(0,0,0,0.7)', backdropFilter: 'blur(4px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000
        }}>
          <div className="tactical-card" style={{ width: '420px', display: 'flex', flexDirection: 'column', gap: '1.5rem', position: 'relative' }}>
            <button 
              style={{ position: 'absolute', top: '16px', right: '16px', background: 'none', border: 'none', color: 'var(--text-secondary)', cursor: 'pointer' }}
              onClick={() => { setSelectedTile(null); setActionType(null); }}
            >
              <X size={20} />
            </button>

            {actionType === 'transfer' ? (
              <>
                <h3 style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '1.2rem', color: 'var(--accent-cyan)' }}>
                  <ArrowLeftRight size={20} />
                  영토 소유권 양도
                </h3>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                  <div>
                    <span style={{ color: 'var(--text-secondary)', fontSize: '0.8rem' }}>대상 타일 ID</span>
                    <div style={{ fontWeight: 'bold', fontFamily: 'monospace', marginTop: '0.2rem' }}>{selectedTile.id}</div>
                  </div>
                  <div>
                    <label style={{ color: 'var(--text-secondary)', fontSize: '0.8rem', display: 'block', marginBottom: '0.4rem' }}>
                      양도받을 사용자 지정
                    </label>
                    <select 
                      className="tactical-input" 
                      value={targetUserId} 
                      onChange={(e) => setTargetUserId(e.target.value)}
                      style={{ background: 'var(--bg-secondary)', border: '1px solid var(--border-color)' }}
                    >
                      {users.map(u => (
                        <option key={u.id} value={u.id}>
                          {u.nickname} ({u.id.slice(0, 8)}...)
                        </option>
                      ))}
                    </select>
                  </div>
                </div>
                <div style={{ display: 'flex', gap: '0.8rem', justifyContent: 'flex-end', marginTop: '0.5rem' }}>
                  <button className="tactical-btn danger" onClick={() => { setSelectedTile(null); setActionType(null); }}>
                    취소
                  </button>
                  <button className="tactical-btn" onClick={handleTransfer} disabled={submitting}>
                    {submitting ? '양도 중...' : '양도 실행'}
                  </button>
                </div>
              </>
            ) : actionType === 'shield' ? (
              <>
                <h3 style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '1.2rem', color: 'var(--accent-cyan)' }}>
                  <ShieldAlert size={20} />
                  영토 방어 보호막 설정
                </h3>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                  <div>
                    <span style={{ color: 'var(--text-secondary)', fontSize: '0.8rem' }}>대상 타일 ID</span>
                    <div style={{ fontWeight: 'bold', fontFamily: 'monospace', marginTop: '0.2rem' }}>{selectedTile.id}</div>
                  </div>
                  <div>
                    <label style={{ color: 'var(--text-secondary)', fontSize: '0.8rem', display: 'block', marginBottom: '0.4rem' }}>
                      추가 유지 시간 (시간 단위)
                    </label>
                    <input 
                      type="number"
                      className="tactical-input"
                      value={extraHours}
                      onChange={(e) => setExtraHours(e.target.value)}
                      placeholder="예: 24 (하루 연장), 0 (즉시 해제)"
                    />
                  </div>
                </div>
                <div style={{ display: 'flex', gap: '0.8rem', justifyContent: 'flex-end', marginTop: '0.5rem' }}>
                  <button className="tactical-btn danger" onClick={() => { setSelectedTile(null); setActionType(null); }}>
                    취소
                  </button>
                  <button className="tactical-btn" onClick={handleUpdateShield} disabled={submitting}>
                    {submitting ? '갱신 중...' : '적용 완료'}
                  </button>
                </div>
              </>
            ) : null}
          </div>
        </div>
      )}
    </div>
  );
}
