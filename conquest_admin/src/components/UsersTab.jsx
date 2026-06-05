import React, { useEffect, useState } from 'react';
import { fetchUsers, updateUserGold, deleteUser } from '../api';
import { Search, Edit2, RotateCcw, AlertTriangle, ShieldCheck, X } from 'lucide-react';

export default function UsersTab() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  
  // 편집(골드 조정) 모달 제어용 상태
  const [editingUser, setEditingUser] = useState(null);
  const [goldInput, setGoldInput] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const loadUsers = async () => {
    try {
      setLoading(true);
      const data = await fetchUsers();
      setUsers(data);
    } catch (err) {
      setError('사용자 목록을 로드하는 중 에러가 발생했습니다.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadUsers();
  }, []);

  const handleEditGold = (user) => {
    setEditingUser(user);
    setGoldInput(user.gold.toString());
  };

  const handleSaveGold = async () => {
    if (!editingUser) return;
    const val = parseFloat(goldInput);
    if (isNaN(val) || val < 0) {
      alert('올바른 골드 값을 입력해 주세요.');
      return;
    }

    try {
      setSubmitting(true);
      await updateUserGold(editingUser.id, val);
      alert('성공적으로 사용자의 재화가 조정되었습니다.');
      setEditingUser(null);
      loadUsers();
    } catch (err) {
      console.error(err);
      alert('재화 조정 중 에러가 발생했습니다.');
    } finally {
      setSubmitting(false);
    }
  };

  const handleDeleteUser = async (user) => {
    const confirm = window.confirm(
      `⚠️ 경고: [${user.nickname}] 사용자의 계정을 완전히 삭제하시겠습니까?\n삭제된 계정 정보는 복구할 수 없습니다.`
    );
    if (!confirm) return;

    try {
      setLoading(true);
      await deleteUser(user.id);
      alert('성공적으로 사용자 계정이 삭제되었습니다.');
      loadUsers();
    } catch (err) {
      console.error(err);
      alert('사용자 계정 삭제 중 오류가 발생했습니다.');
    } finally {
      setLoading(false);
    }
  };

  // 검색 필터링
  const filteredUsers = users.filter(user => 
    user.nickname.toLowerCase().includes(searchTerm.toLowerCase()) ||
    user.id.toLowerCase().includes(searchTerm.toLowerCase())
  );

  if (loading && users.length === 0) {
    return <div className="tactical-spinner" />;
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
      
      {/* 상단 툴 바 */}
      <div className="tab-controls-header">
        <div className="tab-search-group" style={{ width: '100%', justifyContent: 'space-between' }}>
          <div className="tab-search-input-wrapper">
            <Search size={18} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)' }} />
            <input 
              type="text"
              className="tactical-input"
              style={{ paddingLeft: '2.5rem' }}
              placeholder="사용자명 또는 UUID 검색..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
          <button className="tactical-btn" onClick={loadUsers}>
            <RotateCcw size={16} /> 새로고침
          </button>
        </div>
      </div>

      {error && <div style={{ color: 'var(--accent-red)' }}>{error}</div>}

      {/* 사용자 목록 테이블 */}
      <div className="tactical-table-container">
        <table className="tactical-table">
          <thead>
            <tr>
              <th>사용자 정보</th>
              <th>가입 일시</th>
              <th>본진 기지 ID</th>
              <th>보유 골드</th>
              <th>점령 영토</th>
              <th style={{ textAlign: 'center' }}>조작 제어</th>
            </tr>
          </thead>
          <tbody>
            {filteredUsers.length === 0 ? (
              <tr>
                <td colSpan="6" style={{ textAlign: 'center', color: 'var(--text-muted)', padding: '2rem' }}>
                  조건에 일치하는 사용자가 존재하지 않습니다.
                </td>
              </tr>
            ) : (
              filteredUsers.map(user => (
                <tr key={user.id}>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.8rem' }}>
                      <div style={{ width: '12px', height: '12px', borderRadius: '50%', backgroundColor: user.color_hex || 'var(--accent-cyan)' }} />
                      <div>
                        <div style={{ fontWeight: 'bold' }}>{user.nickname}</div>
                        <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>UUID: {user.id}</div>
                      </div>
                    </div>
                  </td>
                  <td>
                    {new Date(user.created_at).toLocaleString('ko-KR', {
                      year: 'numeric',
                      month: '2-digit',
                      day: '2-digit',
                      hour: '2-digit',
                      minute: '2-digit'
                    })}
                  </td>
                  <td>
                    {user.main_base_tile_id ? (
                      <span style={{ color: 'var(--accent-cyan)', fontFamily: 'monospace' }}>
                        {user.main_base_tile_id}
                      </span>
                    ) : (
                      <span style={{ color: 'var(--text-muted)' }}>설정되지 않음</span>
                    )}
                  </td>
                  <td style={{ fontWeight: 'bold', color: 'var(--accent-cyan)' }}>
                    {Math.round(user.gold * 10) / 10} G
                  </td>
                  <td style={{ fontWeight: 'bold' }}>
                    {user.captured_tiles_count} 구역
                  </td>
                  <td>
                    <div style={{ display: 'flex', gap: '0.5rem', justifyContent: 'center' }}>
                      <button className="tactical-btn" onClick={() => handleEditGold(user)}>
                        <Edit2 size={14} /> 골드 수정
                      </button>
                      <button 
                        className="tactical-btn danger" 
                        onClick={() => handleDeleteUser(user)}
                      >
                        <AlertTriangle size={14} /> 계정 삭제
                      </button>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* 골드 수정 모달 */}
      {editingUser && (
        <div style={{
          position: 'fixed', top: 0, left: 0, width: '100%', height: '100%',
          background: 'rgba(0,0,0,0.7)', backdropFilter: 'blur(4px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000
        }}>
          <div className="tactical-card" style={{ width: '100%', maxWidth: '400px', margin: '0 1rem', display: 'flex', flexDirection: 'column', gap: '1.5rem', position: 'relative' }}>
            <button 
              style={{ position: 'absolute', top: '16px', right: '16px', background: 'none', border: 'none', color: 'var(--text-secondary)', cursor: 'pointer' }}
              onClick={() => setEditingUser(null)}
            >
              <X size={20} />
            </button>
            <h3 style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '1.2rem', color: 'var(--accent-cyan)' }}>
              <ShieldCheck size={20} />
              사용자 재화 조정 통제
            </h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.8rem' }}>
              <div>
                <span style={{ color: 'var(--text-secondary)', fontSize: '0.8rem' }}>사용자 닉네임</span>
                <div style={{ fontWeight: 'bold', marginTop: '0.2rem' }}>{editingUser.nickname}</div>
              </div>
              <div>
                <label style={{ color: 'var(--text-secondary)', fontSize: '0.8rem', display: 'block', marginBottom: '0.4rem' }}>
                  골드 수량 설정 (Gold)
                </label>
                <input 
                  type="number"
                  className="tactical-input"
                  value={goldInput}
                  onChange={(e) => setGoldInput(e.target.value)}
                  placeholder="지급/차감할 골드 입력"
                />
              </div>
            </div>
            <div style={{ display: 'flex', gap: '0.8rem', justifyContent: 'flex-end', marginTop: '0.5rem' }}>
              <button className="tactical-btn danger" onClick={() => setEditingUser(null)}>
                취소
              </button>
              <button className="tactical-btn" onClick={handleSaveGold} disabled={submitting}>
                {submitting ? '저장 중...' : '적용 완료'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
