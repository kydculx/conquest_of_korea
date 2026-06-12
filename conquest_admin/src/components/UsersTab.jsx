import React, { useEffect, useState } from 'react';
import { fetchUsers, updateUserGold, deleteUser, fetchUserAchievements } from '../api';
import { Search, Edit2, RotateCcw, AlertTriangle, ShieldCheck, X, Trophy, Lock, Award } from 'lucide-react';

export default function UsersTab() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  
  // 편집(골드 조정) 모달 제어용 상태
  const [editingUser, setEditingUser] = useState(null);
  const [goldInput, setGoldInput] = useState('');
  const [submitting, setSubmitting] = useState(false);

  // 사용자 상세 및 업적 제어용 상태
  const [selectedUser, setSelectedUser] = useState(null);
  const [userAchievements, setUserAchievements] = useState([]);
  const [loadingAchievements, setLoadingAchievements] = useState(false);

  const handleViewDetails = async (user) => {
    setSelectedUser(user);
    setLoadingAchievements(true);
    try {
      const data = await fetchUserAchievements(user.id);
      setUserAchievements(data);
    } catch (err) {
      console.error(err);
      alert('업적 목록을 로드하는 중 에러가 발생했습니다.');
    } finally {
      setLoadingAchievements(false);
    }
  };

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
              placeholder="사용자명 검색..."
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
                      <button className="tactical-btn" onClick={() => handleViewDetails(user)}>
                        <Award size={14} /> 업적 상세
                      </button>
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

      {/* 사용자 상세 정보 & 업적 배지 모달 */}
      {selectedUser && (
        <div style={{
          position: 'fixed', top: 0, left: 0, width: '100%', height: '100%',
          background: 'rgba(0,0,0,0.7)', backdropFilter: 'blur(4px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000
        }}>
          <div className="tactical-card" style={{ width: '100%', maxWidth: '650px', maxHeight: '85vh', overflowY: 'auto', margin: '1rem', display: 'flex', flexDirection: 'column', gap: '1.2rem', position: 'relative' }}>
            <button 
              style={{ position: 'absolute', top: '16px', right: '16px', background: 'none', border: 'none', color: 'var(--text-secondary)', cursor: 'pointer' }}
              onClick={() => setSelectedUser(null)}
            >
              <X size={20} />
            </button>
            <h3 style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '1.2rem', color: 'var(--accent-cyan)' }}>
              <Trophy size={20} />
              플레이어 업적 프로필
            </h3>
            
            {/* 플레이어 기본 정보 요약 */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '0.8rem', background: 'rgba(255,255,255,0.03)', padding: '1rem', borderRadius: '8px', border: '1px solid rgba(255,255,255,0.05)' }}>
              <div>
                <span style={{ color: 'var(--text-secondary)', fontSize: '0.75rem' }}>플레이어명 (닉네임)</span>
                <div style={{ fontWeight: 'bold', fontSize: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem', marginTop: '0.2rem' }}>
                  <div style={{ width: '10px', height: '10px', borderRadius: '50%', backgroundColor: selectedUser.color_hex || 'var(--accent-cyan)' }} />
                  {selectedUser.nickname}
                </div>
              </div>
              <div>
                <span style={{ color: 'var(--text-secondary)', fontSize: '0.75rem' }}>플레이어 ID (고유키)</span>
                <div style={{ fontFamily: 'monospace', fontSize: '0.8rem', marginTop: '0.2rem', wordBreak: 'break-all' }}>{selectedUser.id}</div>
              </div>
              <div>
                <span style={{ color: 'var(--text-secondary)', fontSize: '0.75rem' }}>점령 구역</span>
                <div style={{ fontWeight: 'bold', color: 'var(--text-primary)', marginTop: '0.2rem' }}>{selectedUser.captured_tiles_count} 구역</div>
              </div>
              <div>
                <span style={{ color: 'var(--text-secondary)', fontSize: '0.75rem' }}>보유 골드</span>
                <div style={{ fontWeight: 'bold', color: 'var(--accent-cyan)', marginTop: '0.2rem' }}>{Math.round(selectedUser.gold * 10) / 10} G</div>
              </div>
            </div>

            {/* 업적 현황 통계 */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontWeight: 'bold', fontSize: '0.9rem' }}>업적 달성률</span>
              <span style={{ fontWeight: 'bold', color: 'var(--accent-cyan)', fontSize: '0.9rem' }}>
                {userAchievements.length} / {MASTER_ACHIEVEMENTS.length} 해금 ({Math.round((userAchievements.length / MASTER_ACHIEVEMENTS.length) * 100)}%)
              </span>
            </div>
            
            <div style={{ width: '100%', height: '8px', background: 'rgba(255,255,255,0.05)', borderRadius: '4px', overflow: 'hidden' }}>
              <div style={{ 
                width: `${(userAchievements.length / MASTER_ACHIEVEMENTS.length) * 100}%`, 
                height: '100%', 
                background: 'linear-gradient(90deg, var(--accent-cyan), #00FF99)',
                transition: 'width 0.4s ease'
              }} />
            </div>

            {/* 업적 그리드 */}
            {loadingAchievements ? (
              <div style={{ display: 'flex', justifyContent: 'center', padding: '2rem' }}>
                <div className="tactical-spinner" />
              </div>
            ) : (
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(130px, 1fr))', gap: '0.8rem', maxHeight: '350px', overflowY: 'auto', paddingRight: '0.3rem' }}>
                {MASTER_ACHIEVEMENTS.map(ach => {
                  const unlockRecord = userAchievements.find(ua => ua.achievement_id === ach.id);
                  const isUnlocked = !!unlockRecord;
                  
                  // 티어별 테마 색상 설정
                  let tierColor = '#CD7F32'; // Bronze
                  if (ach.tier === 2) tierColor = '#C0C0C0'; // Silver
                  if (ach.tier === 3) tierColor = '#FFD700'; // Gold
                  if (ach.tier === 4) tierColor = '#00FFCC'; // Platinum Neon
                  
                  return (
                    <div 
                      key={ach.id} 
                      style={{
                        background: isUnlocked ? 'rgba(15, 22, 38, 0.9)' : 'rgba(255,255,255,0.02)',
                        border: `1.5px solid ${isUnlocked ? tierColor : 'rgba(255,255,255,0.05)'}`,
                        borderRadius: '12px',
                        padding: '0.8rem',
                        display: 'flex',
                        flexDirection: 'column',
                        gap: '0.3rem',
                        opacity: isUnlocked ? 1.0 : 0.4,
                        position: 'relative',
                        boxShadow: isUnlocked ? `0 0 8px ${tierColor}33` : 'none'
                      }}
                      title={`${ach.title} (Tier ${ach.tier}) - ${ach.desc}`}
                    >
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <span style={{ fontSize: '0.65rem', fontWeight: 'bold', color: tierColor }}>T{ach.tier}</span>
                        {isUnlocked ? (
                          <Trophy size={14} style={{ color: tierColor }} />
                        ) : (
                          <Lock size={12} style={{ color: 'rgba(255,255,255,0.3)' }} />
                        )}
                      </div>
                      <div style={{ fontWeight: 'bold', fontSize: '0.8rem', color: isUnlocked ? 'white' : 'var(--text-muted)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', marginTop: '0.2rem' }}>
                        {ach.title}
                      </div>
                      <div style={{ fontSize: '0.65rem', color: 'var(--text-secondary)', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden', height: '22px' }}>
                        {ach.desc}
                      </div>
                      {isUnlocked && unlockRecord?.unlocked_at && (
                        <div style={{ fontSize: '0.55rem', color: 'rgba(255,255,255,0.3)', textAlign: 'right', marginTop: '0.2rem' }}>
                          {new Date(unlockRecord.unlocked_at).toLocaleDateString('ko-KR', {
                            month: '2-digit',
                            day: '2-digit'
                          })} 해금
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            )}
            
            <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '0.5rem' }}>
              <button className="tactical-btn" onClick={() => setSelectedUser(null)}>
                닫기
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// 전체 28종 업적 마스터 정보 상수 정의
const MASTER_ACHIEVEMENTS = [
  { id: 'ACH_CAP_T1', title: '개척 플레이어', desc: '누적 점령 타일 10개 돌파', tier: 1, category: '누적 점령' },
  { id: 'ACH_CAP_T2', title: '지역 지배자', desc: '누적 점령 타일 100개 돌파', tier: 2, category: '누적 점령' },
  { id: 'ACH_CAP_T3', title: '정복 군주', desc: '누적 점령 타일 500개 돌파', tier: 3, category: '누적 점령' },
  { id: 'ACH_CAP_T4', title: '한반도 통치자', desc: '누적 점령 타일 2,000개 돌파', tier: 4, category: '누적 점령' },

  { id: 'ACH_INV_T1', title: '불청객', desc: '상대 영토 점령 5회 달성', tier: 1, category: '상대 영토 점령' },
  { id: 'ACH_INV_T2', title: '라인 브레이커', desc: '상대 영토 점령 30회 달성', tier: 2, category: '상대 영토 점령' },
  { id: 'ACH_INV_T3', title: '영토 획득자', desc: '상대 영토 점령 150회 달성', tier: 3, category: '상대 영토 점령' },
  { id: 'ACH_INV_T4', title: '무법의 플레이어', desc: '상대 영토 점령 500회 달성', tier: 4, category: '상대 영토 점령' },

  { id: 'ACH_MOV_T1', title: '이동 개시', desc: '누적 이동 타일 50개 돌파', tier: 1, category: '누적 이동' },
  { id: 'ACH_MOV_T2', title: '베테랑 모험가', desc: '누적 이동 타일 500개 돌파', tier: 2, category: '누적 이동' },
  { id: 'ACH_MOV_T3', title: '야전 정복자', desc: '누적 이동 타일 3,000개 돌파', tier: 3, category: '누적 이동' },
  { id: 'ACH_MOV_T4', title: '국토 완주자', desc: '누적 이동 타일 10,000개 돌파', tier: 4, category: '누적 이동' },

  { id: 'ACH_DMOV_T1', title: '바쁜 하루', desc: '하루 동안 타일 이동 30개 달성', tier: 1, category: '일일 이동' },
  { id: 'ACH_DMOV_T2', title: '이동 강행군', desc: '하루 동안 타일 이동 100개 달성', tier: 2, category: '일일 이동' },
  { id: 'ACH_DMOV_T3', title: '멈추지 않는 엔진', desc: '하루 동안 타일 이동 300개 달성', tier: 3, category: '일일 이동' },
  { id: 'ACH_DMOV_T4', title: '철인 플레이어', desc: '하루 동안 타일 이동 1,000개 달성', tier: 4, category: '일일 이동' },

  { id: 'ACH_SAT_CAP_T1', title: '우주의 눈', desc: '위성 원격 점령 3회 달성', tier: 1, category: '위성 점령' },
  { id: 'ACH_SAT_CAP_T2', title: '궤도 타격자', desc: '위성 원격 점령 20회 달성', tier: 2, category: '위성 점령' },
  { id: 'ACH_SAT_CAP_T3', title: '위성 폭격기', desc: '위성 원격 점령 100회 달성', tier: 3, category: '위성 점령' },
  { id: 'ACH_SAT_CAP_T4', title: '성간 작전 마스터', desc: '위성 원격 점령 300회 달성', tier: 4, category: '위성 점령' },

  { id: 'ACH_SAT_INF_T1', title: '정보 수집가', desc: '위성 상세 정보 스캔 5회 달성', tier: 1, category: '위성 정보' },
  { id: 'ACH_SAT_INF_T2', title: '도청 장치', desc: '위성 상세 정보 스캔 30회 달성', tier: 2, category: '위성 정보' },
  { id: 'ACH_SAT_INF_T3', title: '프로 파일러', desc: '위성 상세 정보 스캔 150회 달성', tier: 3, category: '위성 정보' },
  { id: 'ACH_SAT_INF_T4', title: '숙련된 관찰자', desc: '위성 상세 정보 스캔 500회 달성', tier: 4, category: '위성 정보' },

  { id: 'ACH_HQ_FORT_T1', title: '본진 초소', desc: '본진 기준 1링 완전 획득', tier: 1, category: '본진 요새화' },
  { id: 'ACH_HQ_FORT_T2', title: '안전 지대', desc: '본진 기준 2링 완전 획득', tier: 2, category: '본진 요새화' },
  { id: 'ACH_HQ_FORT_T3', title: '철벽 지대', desc: '본진 기준 3링 완전 획득', tier: 3, category: '본진 요새화' },
  { id: 'ACH_HQ_FORT_T4', title: '철옹성 지대', desc: '본진 기준 4링 완전 획득', tier: 4, category: '본진 요새화' },

  { id: 'ACH_GOLD_T1', title: '기초 보급 완료', desc: '보유 골드 1,000 Gold 돌파', tier: 1, category: '보유 골드' },
  { id: 'ACH_GOLD_T2', title: '자급자족 플레이어', desc: '보유 골드 10,000 Gold 돌파', tier: 2, category: '보유 골드' },
  { id: 'ACH_GOLD_T3', title: '자산가', desc: '보유 골드 50,000 Gold 돌파', tier: 3, category: '보유 골드' },
  { id: 'ACH_GOLD_T4', title: '성간 연합 자산가', desc: '보유 골드 200,000 Gold 돌파', tier: 4, category: '보유 골드' }
];

