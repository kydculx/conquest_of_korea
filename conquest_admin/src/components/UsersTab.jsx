import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { fetchUsers, updateUserGold, updateUserMainBase, deleteUser, fetchUserAchievements } from '../api';
import { Search, Edit2, RotateCcw, ShieldCheck, X, Trophy, Lock } from 'lucide-react';
import Pagination from './Pagination';

const PAGE_SIZE = 20;

export default function UsersTab() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [page, setPage] = useState(1);
  const navigate = useNavigate();
  
  // 편집(골드 조정) 모달 제어용 상태
  const [editingUser, setEditingUser] = useState(null);
  const [goldInput, setGoldInput] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const [editingBaseId, setEditingBaseId] = useState(null);
  const [baseInput, setBaseInput] = useState('');

  // 사용자 상세 및 업적 제어용 상태
  const [selectedUser, setSelectedUser] = useState(null);
  const [userAchievements, setUserAchievements] = useState([]);
  const [loadingAchievements, setLoadingAchievements] = useState(false);

  const handleGoToMainBase = (user) => {
    if (!user.main_base_tile_id) {
      alert('본진 기지가 설정되지 않은 사용자입니다.');
      return;
    }
    navigate(`/admin/dashboard?hq=${user.main_base_tile_id}`);
  };

  const handleGoToUserTiles = (user) => {
    navigate(`/admin/user-tiles?userId=${user.id}&nickname=${encodeURIComponent(user.nickname || '')}`);
  };

  const handleGoToFootprints = (user) => {
    navigate(`/admin/dashboard?footprints=${user.id}&nickname=${encodeURIComponent(user.nickname || '')}`);
  };

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

  const handleEditBase = (user) => {
    setEditingBaseId(user.id);
    setBaseInput(user.main_base_tile_id || '');
  };

  const handleSaveBase = async (user) => {
    try {
      setSubmitting(true);
      const value = baseInput.trim() === '' ? null : baseInput.trim();
      await updateUserMainBase(user.id, value);
      alert('성공적으로 본진 기지가 수정되었습니다.');
      setEditingBaseId(null);
      loadUsers();
    } catch (err) {
      console.error(err);
      alert('본진 기지 수정 중 에러가 발생했습니다.');
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

  const formatJoinedAt = (iso) => {
    const d = new Date(iso);
    const p = (n) => String(n).padStart(2, '0');
    return `${String(d.getFullYear()).slice(2)}.${p(d.getMonth() + 1)}.${p(d.getDate())}-${p(d.getHours())}:${p(d.getMinutes())}`;
  };

  const filteredUsers = users.filter(user =>
    user.nickname.toLowerCase().includes(searchTerm.toLowerCase()) ||
    user.id.toLowerCase().includes(searchTerm.toLowerCase())
  );
  const totalPages = Math.max(1, Math.ceil(filteredUsers.length / PAGE_SIZE));
  const safePage = Math.min(page, totalPages);
  const pagedUsers = filteredUsers.slice((safePage - 1) * PAGE_SIZE, safePage * PAGE_SIZE);

  if (loading && users.length === 0) {
    return <div className="tactical-spinner" />;
  }

  return (
    <div className="section-stack">

      <div className="tab-controls-header">
        <div className="tab-search-group" style={{ width: '100%', justifyContent: 'space-between' }}>
          <div className="tab-search-input-wrapper">
            <Search size={16} className="search-icon" />
            <input
              type="text"
              className="tactical-input"
              style={{ paddingLeft: '2.5rem' }}
              placeholder="사용자명 검색..."
              value={searchTerm}
              onChange={(e) => { setSearchTerm(e.target.value); setPage(1); }}
            />
          </div>
          <button className="tactical-btn" onClick={loadUsers}>
            <RotateCcw size={16} /> 새로고침
          </button>
        </div>
      </div>

      {error && <div style={{ color: 'var(--accent-red)' }}>{error}</div>}

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
                <td colSpan="6" className="empty-state">
                  조건에 일치하는 사용자가 존재하지 않습니다.
                </td>
              </tr>
            ) : (
              pagedUsers.map(user => (
                <tr key={user.id}>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', minWidth: 0 }}>
                      <div style={{ width: '10px', height: '10px', borderRadius: '50%', backgroundColor: user.color_hex || 'var(--accent-cyan)', flexShrink: 0 }} />
                      <div style={{ fontWeight: 600, fontSize: '0.88rem' }}>{user.nickname}</div>
                    </div>
                  </td>
                  <td style={{ fontFamily: 'var(--font-mono)', fontSize: '0.8rem', whiteSpace: 'nowrap' }}>
                    {formatJoinedAt(user.created_at)}
                  </td>
                  <td>
                    {editingBaseId === user.id ? (
                      <div style={{ display: 'flex', gap: '0.4rem', alignItems: 'center' }}>
                        <input
                          type="text"
                          className="tactical-input"
                          style={{ width: '150px', fontFamily: 'var(--font-mono)', fontSize: '0.78rem' }}
                          value={baseInput}
                          onChange={(e) => setBaseInput(e.target.value)}
                          placeholder="hex_q_r"
                        />
                        <button className="tactical-btn sm" onClick={() => handleSaveBase(user)} disabled={submitting}>
                          저장
                        </button>
                        <button className="tactical-btn sm danger" onClick={() => setEditingBaseId(null)}>
                          취소
                        </button>
                      </div>
                    ) : (
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                        {user.main_base_tile_id ? (
                          <span className="kv-value mono" style={{ color: '#8fb6ff' }}>
                            {user.main_base_tile_id.replace(/^hex_/, '')}
                          </span>
                        ) : (
                          <span style={{ color: 'var(--text-muted)', fontSize: '0.82rem' }}>설정되지 않음</span>
                        )}
                        <button className="tactical-btn sm" onClick={() => handleEditBase(user)} title="본진 기지 수정">
                          <Edit2 size={13} />
                        </button>
                      </div>
                    )}
                  </td>
                  <td>
                    <span className="table-numeric">{Math.round(user.gold * 10) / 10}</span>
                    <span className="table-unit">G</span>
                  </td>
                  <td>
                    <span className="table-numeric" style={{ color: 'var(--text-primary)' }}>{user.captured_tiles_count}</span>
                  </td>
                  <td>
                    <div className="row-actions">
                      <button className="tactical-btn sm" onClick={() => handleGoToMainBase(user)}>
                        본진
                      </button>
                      <button className="tactical-btn sm" onClick={() => handleGoToUserTiles(user)}>
                        점령
                      </button>
                      <button className="tactical-btn sm" onClick={() => handleGoToFootprints(user)}>
                        발자취
                      </button>
                      <button className="tactical-btn sm" onClick={() => handleViewDetails(user)}>
                        업적
                      </button>
                      <button className="tactical-btn sm" onClick={() => handleEditGold(user)}>
                        골드
                      </button>
                      <button
                        className="tactical-btn sm danger"
                        onClick={() => handleDeleteUser(user)}
                      >
                        계정삭제
                      </button>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
        <Pagination
          page={safePage}
          totalPages={totalPages}
          totalCount={filteredUsers.length}
          pageSize={PAGE_SIZE}
          onChange={setPage}
        />
      </div>

      {editingUser && (
        <div className="modal-overlay">
          <div className="tactical-card modal-card">
            <button
              className="modal-close"
              onClick={() => setEditingUser(null)}
              aria-label="닫기"
            >
              <X size={18} />
            </button>
            <h3 className="modal-title">
              <ShieldCheck size={19} />
              사용자 재화 조정
            </h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.8rem' }}>
              <div>
                <span className="field-label">사용자 닉네임</span>
                <div style={{ fontWeight: 700 }}>{editingUser.nickname}</div>
              </div>
              <div>
                <label className="field-label">
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
            <div style={{ display: 'flex', gap: '0.6rem', justifyContent: 'flex-end' }}>
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

      {selectedUser && (
        <div className="modal-overlay">
          <div className="tactical-card modal-card wide">
            <button
              className="modal-close"
              onClick={() => setSelectedUser(null)}
              aria-label="닫기"
            >
              <X size={18} />
            </button>
            <h3 className="modal-title">
              <Trophy size={19} />
              플레이어 업적 프로필
            </h3>

            <div className="kv-grid">
              <div>
                <span className="kv-label">플레이어명 (닉네임)</span>
                <div className="kv-value" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  <div style={{ width: '10px', height: '10px', borderRadius: '50%', backgroundColor: selectedUser.color_hex || 'var(--accent-cyan)' }} />
                  {selectedUser.nickname}
                </div>
              </div>
              <div>
                <span className="kv-label">플레이어 ID (고유키)</span>
                <div className="kv-value mono">{selectedUser.id}</div>
              </div>
              <div>
                <span className="kv-label">점령 구역</span>
                <div className="kv-value">{selectedUser.captured_tiles_count} 구역</div>
              </div>
              <div>
                <span className="kv-label">보유 골드</span>
                <div className="kv-value" style={{ color: '#8fb6ff' }}>{Math.round(selectedUser.gold * 10) / 10} G</div>
              </div>
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontWeight: 700, fontSize: '0.87rem' }}>업적 달성률</span>
              <span className="table-numeric" style={{ fontSize: '0.87rem' }}>
                {userAchievements.length} / {MASTER_ACHIEVEMENTS.length} 해금 ({Math.round((userAchievements.length / MASTER_ACHIEVEMENTS.length) * 100)}%)
              </span>
            </div>

            <div className="progress-track">
              <div
                className="progress-fill"
                style={{ width: `${(userAchievements.length / MASTER_ACHIEVEMENTS.length) * 100}%` }}
              />
            </div>

            {loadingAchievements ? (
              <div style={{ display: 'flex', justifyContent: 'center', padding: '2rem' }}>
                <div className="tactical-spinner" />
              </div>
            ) : (
              <div className="ach-grid">
                {MASTER_ACHIEVEMENTS.map(ach => {
                  const unlockRecord = userAchievements.find(ua => ua.achievement_id === ach.id);
                  const isUnlocked = !!unlockRecord;

                  let tierColor = '#b45309';
                  if (ach.tier === 2) tierColor = '#64748b';
                  if (ach.tier === 3) tierColor = '#ca8a04';
                  if (ach.tier === 4) tierColor = '#0d9488';

                  return (
                    <div
                      key={ach.id}
                      className={`ach-card ${isUnlocked ? 'unlocked' : ''}`}
                      style={isUnlocked ? { borderColor: `${tierColor}66` } : undefined}
                      title={`${ach.title} (Tier ${ach.tier}) - ${ach.desc}`}
                    >
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <span className="ach-tier" style={{ color: tierColor }}>T{ach.tier}</span>
                        {isUnlocked ? (
                          <Trophy size={13} style={{ color: tierColor }} />
                        ) : (
                          <Lock size={12} style={{ color: 'var(--text-muted)' }} />
                        )}
                      </div>
                      <div className="ach-title" style={{ color: isUnlocked ? 'var(--text-primary)' : 'var(--text-muted)' }}>
                        {ach.title}
                      </div>
                      <div className="ach-desc">
                        {ach.desc}
                      </div>
                      {isUnlocked && unlockRecord?.unlocked_at && (
                        <div style={{ fontSize: '0.62rem', color: 'var(--text-muted)', textAlign: 'right' }}>
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

            <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
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

// 전체 45종 업적 마스터 정보 상수 정의
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
  { id: 'ACH_GOLD_T4', title: '성간 연합 자산가', desc: '보유 골드 200,000 Gold 돌파', tier: 4, category: '보유 골드' },

  { id: 'ACH_BASE_MOV_T1', title: '첫 이사', desc: '본진 이동 1회 완료', tier: 1, category: '본진 이동' },
  { id: 'ACH_BASE_MOV_T2', title: '프로 이사러', desc: '본진 이동 3회 완료', tier: 2, category: '본진 이동' },
  { id: 'ACH_BASE_MOV_T3', title: '유목민', desc: '본진 이동 10회 완료', tier: 3, category: '본진 이동' },
  { id: 'ACH_BASE_MOV_T4', title: '역마살 모험가', desc: '본진 이동 30회 완료', tier: 4, category: '본진 이동' },

  { id: 'ACH_PHOTO_T1', title: '첫 찰칵', desc: '서로 다른 1개 구역에서 사진 촬영 등록', tier: 1, category: '사진 촬영' },
  { id: 'ACH_PHOTO_T2', title: '추억 기록자', desc: '서로 다른 5개 구역에서 사진 촬영 등록', tier: 2, category: '사진 촬영' },
  { id: 'ACH_PHOTO_T3', title: '풍경 탐험가', desc: '서로 다른 15개 구역에서 사진 촬영 등록', tier: 3, category: '사진 촬영' },
  { id: 'ACH_PHOTO_T4', title: '구역 포토그래퍼', desc: '서로 다른 50개 구역에서 사진 촬영 등록', tier: 4, category: '사진 촬영' },
  
  { id: 'ACH_PATTERN_A', title: '문자 패턴 A', desc: '지도 상에 헥사곤 타일로 알파벳 A 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_B', title: '문자 패턴 B', desc: '지도 상에 헥사곤 타일로 알파벳 B 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_C', title: '문자 패턴 C', desc: '지도 상에 헥사곤 타일로 알파벳 C 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_D', title: '문자 패턴 D', desc: '지도 상에 헥사곤 타일로 알파벳 D 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_E', title: '문자 패턴 E', desc: '지도 상에 헥사곤 타일로 알파벳 E 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_F', title: '문자 패턴 F', desc: '지도 상에 헥사곤 타일로 알파벳 F 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_G', title: '문자 패턴 G', desc: '지도 상에 헥사곤 타일로 알파벳 G 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_H', title: '문자 패턴 H', desc: '지도 상에 헥사곤 타일로 알파벳 H 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_I', title: '문자 패턴 I', desc: '지도 상에 헥사곤 타일로 알파벳 I 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_J', title: '문자 패턴 J', desc: '지도 상에 헥사곤 타일로 알파벳 J 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_K', title: '문자 패턴 K', desc: '지도 상에 헥사곤 타일로 알파벳 K 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_L', title: '문자 패턴 L', desc: '지도 상에 헥사곤 타일로 알파벳 L 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_M', title: '문자 패턴 M', desc: '지도 상에 헥사곤 타일로 알파벳 M 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_N', title: '문자 패턴 N', desc: '지도 상에 헥사곤 타일로 알파벳 N 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_O', title: '문자 패턴 O', desc: '지도 상에 헥사곤 타일로 알파벳 O 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_P', title: '문자 패턴 P', desc: '지도 상에 헥사곤 타일로 알파벳 P 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_Q', title: '문자 패턴 Q', desc: '지도 상에 헥사곤 타일로 알파벳 Q 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_R', title: '문자 패턴 R', desc: '지도 상에 헥사곤 타일로 알파벳 R 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_S', title: '문자 패턴 S', desc: '지도 상에 헥사곤 타일로 알파벳 S 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_T', title: '문자 패턴 T', desc: '지도 상에 헥사곤 타일로 알파벳 T 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_U', title: '문자 패턴 U', desc: '지도 상에 헥사곤 타일로 알파벳 U 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_V', title: '문자 패턴 V', desc: '지도 상에 헥사곤 타일로 알파벳 V 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_W', title: '문자 패턴 W', desc: '지도 상에 헥사곤 타일로 알파벳 W 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_X', title: '문자 패턴 X', desc: '지도 상에 헥사곤 타일로 알파벳 X 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_Y', title: '문자 패턴 Y', desc: '지도 상에 헥사곤 타일로 알파벳 Y 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_Z', title: '문자 패턴 Z', desc: '지도 상에 헥사곤 타일로 알파벳 Z 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_0', title: '숫자 패턴 0', desc: '지도 상에 헥사곤 타일로 숫자 0 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_1', title: '숫자 패턴 1', desc: '지도 상에 헥사곤 타일로 숫자 1 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_2', title: '숫자 패턴 2', desc: '지도 상에 헥사곤 타일로 숫자 2 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_3', title: '숫자 패턴 3', desc: '지도 상에 헥사곤 타일로 숫자 3 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_4', title: '숫자 패턴 4', desc: '지도 상에 헥사곤 타일로 숫자 4 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_5', title: '숫자 패턴 5', desc: '지도 상에 헥사곤 타일로 숫자 5 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_6', title: '숫자 패턴 6', desc: '지도 상에 헥사곤 타일로 숫자 6 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_7', title: '숫자 패턴 7', desc: '지도 상에 헥사곤 타일로 숫자 7 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_8', title: '숫자 패턴 8', desc: '지도 상에 헥사곤 타일로 숫자 8 모양 점령 달성', tier: 1, category: '패턴 매칭' },
  { id: 'ACH_PATTERN_9', title: '숫자 패턴 9', desc: '지도 상에 헥사곤 타일로 숫자 9 모양 점령 달성', tier: 1, category: '패턴 매칭' }
];

