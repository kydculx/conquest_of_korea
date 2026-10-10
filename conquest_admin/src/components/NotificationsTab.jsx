import React, { useState, useEffect } from 'react';
import { sendFcmNotification, fetchUsers } from '../api';
import { Send, Bell, Info, Smartphone, Users, User } from 'lucide-react';

export default function NotificationsTab() {
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [targetType, setTargetType] = useState('all'); // 'all' | 'individual'
  const [userUuid, setUserUuid] = useState('');
  const [users, setUsers] = useState([]);
  const [loadingUsers, setLoadingUsers] = useState(false);
  const [sending, setSending] = useState(false);
  const [notifType, setNotifType] = useState('system_notice');
  const [tileId, setTileId] = useState('');

  const handleNotifTypeChange = (type) => {
    setNotifType(type);
    if (type === 'satellite_complete') {
      setTitle('📡 영토 점령 완료');
      setBody('플레이어님, 지정 구역에 대한 영토 점령이 성공적으로 완료되었습니다.');
    } else if (type === 'territory_attack') {
      setTitle('⚠️ 영토 방어 알림');
      setBody('플레이어님의 영토가 다른 플레이어에게 점령되었습니다. 지도를 확인해 보세요.');
    } else if (type === 'system_notice') {
      setTitle('📢 시스템 공지사항');
      setBody('새로운 공지사항이 등록되었습니다. 최신 패치 및 이벤트 세부 사항을 확인해 보세요.');
    }
  };

  useEffect(() => {
    const loadUsers = async () => {
      try {
        setLoadingUsers(true);
        const data = await fetchUsers();
        setUsers(data);
        if (data.length > 0) {
          setUserUuid(data[0].id);
        }
      } catch (err) {
        console.error('사용자 목록 로드 에러:', err);
      } finally {
        setLoadingUsers(false);
      }
    };
    loadUsers();
  }, []);

  const handleSend = async (e) => {
    e.preventDefault();
    if (!title.trim() || !body.trim()) {
      alert('알림 제목과 본문을 모두 입력해 주세요.');
      return;
    }

    let topic = 'all';
    if (targetType === 'individual') {
      if (!userUuid.trim()) {
        alert('발송 대상 사용자를 선택해 주세요.');
        return;
      }
      topic = `user_${userUuid.trim()}`;
    }

    try {
      setSending(true);
      await sendFcmNotification(title, body, topic, notifType, tileId);
      alert(`[FCM 전송 성공]\n대상 토픽: ${topic}\n알림 타입: ${notifType}\n\n알림 메시지가 성공적으로 발송되었습니다.`);
      setTitle('');
      setBody('');
      setTileId('');
    } catch (err) {
      console.error(err);
      alert('푸시 알림 발송 중 에러가 발생했습니다.');
    } finally {
      setSending(false);
    }
  };

  return (
    <div className="section-stack">
      <div className="tactical-card" style={{ display: 'flex', flexDirection: 'column', gap: '1.4rem' }}>
        <div className="card-head">
          <h3 className="card-title">
            <Bell size={19} />
            푸시 알림 발송 센터
            <span className="card-sub">FCM 클라우드 메시징</span>
          </h3>
          <span className="status-pill">
            <span className="status-dot" />
            발송 대기 중
          </span>
        </div>

        <form onSubmit={handleSend} style={{ display: 'flex', flexDirection: 'column', gap: '1.4rem' }}>
          
          {/* 발송 대상 모드 선택 토글 */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
            <label className="field-label">발송 대상 범위</label>
            <div style={{ display: 'flex', gap: '0.6rem', maxWidth: '420px' }}>
              <button
                type="button"
                onClick={() => setTargetType('all')}
                className={`tactical-btn ${targetType === 'all' ? 'active' : ''}`}
                style={{ flex: 1 }}
              >
                <Users size={15} /> 전체 플레이어
              </button>
              <button
                type="button"
                onClick={() => setTargetType('individual')}
                className={`tactical-btn ${targetType === 'individual' ? 'active' : ''}`}
                style={{ flex: 1 }}
              >
                <User size={15} /> 특정 플레이어 지정
              </button>
            </div>
          </div>

          {/* 개별 타겟 사용자 선택 드롭다운 */}
          {targetType === 'individual' && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
              <label className="field-label">수신 대상 플레이어 선택</label>
              {loadingUsers ? (
                <div style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>플레이어 목록을 불러오는 중...</div>
              ) : (
                <select 
                  className="tactical-input"
                  value={userUuid}
                  onChange={(e) => setUserUuid(e.target.value)}
                >
                  <option value="">-- 플레이어를 선택하세요 --</option>
                  {users.map(user => (
                    <option key={user.id} value={user.id}>
                      {user.nickname || '미등록 사용자'} ({user.id.slice(0, 8)}...)
                    </option>
                  ))}
                </select>
              )}
            </div>
          )}

          {/* 알림 타입 및 타일 ID */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: '1rem' }}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
              <label className="field-label">알림 카테고리 (Type)</label>
              <select 
                className="tactical-input"
                value={notifType}
                onChange={(e) => handleNotifTypeChange(e.target.value)}
              >
                <option value="system_notice">📢 공지사항 (system_notice)</option>
                <option value="satellite_complete">📡 영토 점령 (satellite_complete)</option>
                <option value="territory_attack">⚠️ 영토 방어 알림 (territory_attack)</option>
              </select>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
              <label className="field-label">연동 타일 ID (선택 사항)</label>
              <input 
                type="text" 
                className="tactical-input"
                placeholder="예: hex_46_-123"
                value={tileId}
                onChange={(e) => setTileId(e.target.value)}
                disabled={notifType === 'system_notice'}
              />
            </div>
          </div>

          {/* 제목 */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
            <label className="field-label">알림 제목 (Title)</label>
            <input 
              type="text" 
              className="tactical-input"
              placeholder="예: [안내] 봄맞이 신규 이벤트 안내"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
            />
          </div>

          {/* 본문 */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
            <label className="field-label">알림 상세 내용 (Body)</label>
            <textarea 
              className="tactical-input"
              style={{ minHeight: '110px', resize: 'vertical' }}
              placeholder="플레이어들에게 발송할 메시지를 입력해 주세요."
              value={body}
              onChange={(e) => setBody(e.target.value)}
            />
          </div>

          {/* 실시간 미리보기 카드 */}
          {(title || body) && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
              <label className="field-label" style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                <Smartphone size={14} /> 기기 수신 미리보기 (Preview)
              </label>
              <div style={{
                background: 'rgba(15, 23, 42, 0.65)',
                border: '1px solid rgba(255, 255, 255, 0.08)',
                borderRadius: '14px',
                padding: '1rem 1.2rem',
                display: 'flex',
                gap: '0.8rem',
                alignItems: 'flex-start',
                backdropFilter: 'blur(10px)',
                maxWidth: '460px'
              }}>
                <div style={{
                  width: '36px', height: '36px', borderRadius: '10px',
                  background: 'var(--accent-gradient)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  color: '#fff', flexShrink: 0
                }}>
                  <Bell size={18} />
                </div>
                <div style={{ minWidth: 0, flex: 1 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ fontSize: '0.72rem', fontWeight: 700, color: 'var(--text-muted)' }}>찜! 모험</span>
                    <span style={{ fontSize: '0.68rem', color: 'var(--text-muted)' }}>지금</span>
                  </div>
                  <div style={{ fontWeight: 700, fontSize: '0.88rem', color: 'var(--text-primary)', marginTop: '0.15rem' }}>
                    {title || '알림 제목'}
                  </div>
                  <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', marginTop: '0.2rem', lineHeight: 1.4 }}>
                    {body || '알림 본문 내용이 여기에 표시됩니다.'}
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* 도움말 가이드 */}
          <div style={{
            display: 'flex', gap: '0.6rem', alignItems: 'flex-start',
            color: 'var(--text-secondary)', fontSize: '0.76rem',
            padding: '0.85rem 1rem', background: 'rgba(56, 189, 248, 0.04)',
            borderRadius: '10px', border: '1px solid rgba(56, 189, 248, 0.12)'
          }}>
            <Info size={16} style={{ color: 'var(--accent-cyan)', flexShrink: 0, marginTop: '2px' }} />
            <p style={{ margin: 0, lineHeight: 1.5 }}>
              본 메시지는 Firebase Cloud Messaging(FCM)을 통해 대상 기기에 실시간 전달됩니다.
              앱이 포그라운드 상태일 경우 인게임 상단 배너로 즉시 표출됩니다.
            </p>
          </div>

          {/* 발송 버튼 */}
          <div className="notifications-submit-wrapper">
            <button type="submit" className="tactical-btn primary" disabled={sending} style={{ minWidth: '140px' }}>
              <Send size={15} /> {sending ? '발송 중...' : '알림 발송'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
