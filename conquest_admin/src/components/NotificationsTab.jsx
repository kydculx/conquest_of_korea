import React, { useState, useEffect } from 'react';
import { sendFcmNotification, fetchUsers } from '../api';
import { Send, Bell, Info } from 'lucide-react';

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
      setBody('플레이어님, 타깃 구역에 대한 영토 점령이 성공적으로 완료되었습니다.');
    } else if (type === 'territory_attack') {
      setTitle('⚠️ 영토 피탈 감지');
      setBody('플레이어님, 소유하고 계신 영토가 적에게 공격받거나 피탈당했습니다. 즉시 상황을 파악하십시오.');
    } else if (type === 'system_notice') {
      setTitle('📢 시스템 공지사항');
      setBody('시스템 공지사항이 등록되었습니다. 최신 패치 및 공지 세부 사항을 파악하십시오.');
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
    
    // 최초 렌더링 시 system_notice 기본값 로드
    setTitle('📢 시스템 공지사항');
    setBody('시스템 공지사항이 등록되었습니다. 최신 패치 및 공지 세부 사항을 파악하십시오.');
  }, []);

  const handleSend = async (e) => {
    e.preventDefault();
    if (!title.trim() || !body.trim()) {
      alert('알림 제목과 본문 내용을 모두 입력해 주세요.');
      return;
    }

    let topic = 'system_notice';
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
    <div className="notifications-form-container">
      
      <div className="tactical-card" style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
        <h3 style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '1.2rem', color: 'var(--accent-cyan)' }}>
          <Bell size={20} />
          긴급 공지 발송 제어 (FCM)
        </h3>

        <form onSubmit={handleSend} style={{ display: 'flex', flexDirection: 'column', gap: '1.2rem' }}>
          
          {/* 발송 타겟 유형 라디오 */}
          <div className="notifications-radio-group">
            <label style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', cursor: 'pointer', fontWeight: 'bold', fontSize: '0.9rem' }}>
              <input 
                type="radio" 
                name="target" 
                checked={targetType === 'all'}
                onChange={() => setTargetType('all')}
                style={{ accentColor: 'var(--accent-cyan)' }}
              />
              모든 사용자 전역 공지
            </label>
            <label style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', cursor: 'pointer', fontWeight: 'bold', fontSize: '0.9rem' }}>
              <input 
                type="radio" 
                name="target" 
                checked={targetType === 'individual'}
                onChange={() => setTargetType('individual')}
                style={{ accentColor: 'var(--accent-cyan)' }}
              />
              특정 사용자 개별 공지
            </label>
          </div>

          {/* 개별 타겟 사용자 선택 드롭다운 */}
          {targetType === 'individual' && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
              <label style={{ color: 'var(--text-secondary)', fontSize: '0.85rem' }}>
                수신 사용자 선택
              </label>
              {loadingUsers ? (
                <div style={{ fontSize: '0.9rem', color: 'var(--text-muted)' }}>사용자 목록을 로드하는 중...</div>
              ) : (
                <select 
                  className="tactical-input"
                  value={userUuid}
                  onChange={(e) => setUserUuid(e.target.value)}
                  style={{
                    backgroundColor: 'var(--bg-secondary)',
                    color: 'var(--text-primary)',
                    cursor: 'pointer'
                  }}
                >
                  <option value="">-- 사용자를 선택하세요 --</option>
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
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }} className="tab-controls-header">
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
              <label style={{ color: 'var(--text-secondary)', fontSize: '0.85rem' }}>
                알림 타입 (Type)
              </label>
              <select 
                className="tactical-input"
                value={notifType}
                onChange={(e) => handleNotifTypeChange(e.target.value)}
                style={{
                  backgroundColor: 'var(--bg-secondary)',
                  color: 'var(--text-primary)',
                  cursor: 'pointer'
                }}
              >
                <option value="system_notice">공지사항 (system_notice)</option>
                <option value="satellite_complete">영토 점령 (satellite_complete)</option>
                <option value="territory_attack">영토 피탈 (territory_attack)</option>
              </select>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
              <label style={{ color: 'var(--text-secondary)', fontSize: '0.85rem' }}>
                임의 타일 ID (Tile ID)
              </label>
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
            <label style={{ color: 'var(--text-secondary)', fontSize: '0.85rem' }}>
              알림 제목 (Title)
            </label>
            <input 
              type="text" 
              className="tactical-input"
              placeholder="예: ⚠️ [작전 상황 전파] 본진 방어 보강 권고"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
            />
          </div>

          {/* 본문 */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
            <label style={{ color: 'var(--text-secondary)', fontSize: '0.85rem' }}>
              알림 본문 내용 (Body)
            </label>
            <textarea 
              className="tactical-input"
              style={{ minHeight: '120px', resize: 'vertical' }}
              placeholder="사용자들에게 전파할 내용을 입력해 주세요. 포그라운드 상태의 인게임 앱에 3초간 실시간 페이드 알림 배너로 표출됩니다."
              value={body}
              onChange={(e) => setBody(e.target.value)}
            />
          </div>

          {/* 알림 메시지 도움말 */}
          <div style={{ display: 'flex', gap: '0.4rem', alignItems: 'flex-start', color: 'var(--text-secondary)', fontSize: '0.75rem', padding: '0.8rem', background: 'rgba(0, 229, 255, 0.03)', borderRadius: '6px', border: '1px solid rgba(0, 229, 255, 0.1)' }}>
            <Info size={16} style={{ color: 'var(--accent-cyan)', flexShrink: 0, marginTop: '1px' }} />
            <p>
              이 공지 메시지는 Firebase Cloud Messaging 서비스를 경유하여 사용자의 기기에 직접 노출됩니다. 
              수신자 기기의 앱 알림 설정 및 OS 설정 권한 상태에 따라 푸시 수신 여부가 결정됩니다.
            </p>
          </div>

          {/* 전송 버튼 */}
          <div className="notifications-submit-wrapper">
            <button type="submit" className="tactical-btn" disabled={sending}>
              <Send size={16} /> {sending ? '공지 발송 중...' : '긴급 공지 발송'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
