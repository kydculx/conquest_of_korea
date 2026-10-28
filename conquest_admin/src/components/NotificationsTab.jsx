import { useState, useEffect } from 'react';
import { sendFcmNotification, sendLocalizedFcmNotification, fetchUsers } from '../api';
import { Send, Bell, Info, Smartphone, Users, User } from 'lucide-react';

const NOTICE_LANGUAGES = [
  { code: 'ko', label: '한국어' },
  { code: 'en', label: 'English' },
  { code: 'zh', label: '中文 (简体)' },
  { code: 'zh_TW', label: '中文 (繁體)' },
  { code: 'ja', label: '日本語' },
  { code: 'es', label: 'Español' },
  { code: 'fr', label: 'Français' },
  { code: 'de', label: 'Deutsch' },
  { code: 'pt', label: 'Português' },
];

// 앱 assets/translations/ko.json의 알림 문구와 동일하게 유지
const APP_NOTIFICATION_TEMPLATES = {
  satellite_complete: {
    title: '영토 확보 알림',
    body: '✓ 영토 확보 완료. 새로운 영토를 획득하였습니다.',
  },
  territory_attack: {
    title: '⚠️ 영토 변경 알림',
    body: '다른 플레이어가 해당 구역을 점령하였습니다.',
  },
};

export default function NotificationsTab() {
  const [targetType, setTargetType] = useState('all'); // 'all' | 'individual'
  const [userUuid, setUserUuid] = useState('');
  const [users, setUsers] = useState([]);
  const [loadingUsers, setLoadingUsers] = useState(false);
  const [sending, setSending] = useState(false);
  const [notifType, setNotifType] = useState('system_notice');
  const [tileId, setTileId] = useState('');
  const [localizedTitle, setLocalizedTitle] = useState(() => ({
    ...Object.fromEntries(NOTICE_LANGUAGES.map(({ code }) => [code, ''])),
    ko: '📢 시스템 공지사항',
  }));
  const [localizedBody, setLocalizedBody] = useState(() => ({
    ...Object.fromEntries(NOTICE_LANGUAGES.map(({ code }) => [code, ''])),
    ko: '새로운 공지사항이 등록되었습니다. 최신 패치 및 이벤트 세부 사항을 확인해 보세요.',
  }));
  const [previewLanguage, setPreviewLanguage] = useState('ko');

  const handleNotifTypeChange = (type) => {
    setNotifType(type);
    if (type !== 'system_notice') return;

    setTileId('');
    setLocalizedTitle((prev) => ({
      ...prev,
      ko: prev.ko.trim() ? prev.ko : '📢 시스템 공지사항',
    }));
    setLocalizedBody((prev) => ({
      ...prev,
      ko: prev.ko.trim()
        ? prev.ko
        : '새로운 공지사항이 등록되었습니다. 최신 패치 및 이벤트 세부 사항을 확인해 보세요.',
    }));
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

    if (notifType === 'system_notice') {
      const localized = {};
      const incomplete = [];

      NOTICE_LANGUAGES.forEach(({ code, label }) => {
        const localizedTitleText = localizedTitle[code]?.trim() || '';
        const localizedBodyText = localizedBody[code]?.trim() || '';

        if (!localizedTitleText && !localizedBodyText) return;
        if (!localizedTitleText || !localizedBodyText) {
          incomplete.push(label);
          return;
        }

        localized[code] = {
          title: localizedTitleText,
          body: localizedBodyText,
        };
      });

      if (incomplete.length > 0) {
        alert(`${incomplete.join(', ')}의 제목과 본문을 모두 입력해 주세요.`);
        return;
      }
      if (Object.keys(localized).length === 0) {
        alert('최소 한 개 언어의 제목과 본문을 입력해 주세요.');
        return;
      }

      try {
        setSending(true);
        const result = await sendLocalizedFcmNotification(localized, notifType, '');
        const failed = (result?.results || []).filter((item) => !item.ok);
        const failureText = failed.length > 0
          ? `\n실패 언어: ${failed.map((item) => item.lang).join(', ')}`
          : '';

        alert(`[다국어 공지 전송 완료]\n언어 수: ${Object.keys(localized).length}\n발송 성공: ${result?.sent_count ?? 0}${failureText}`);
        setLocalizedTitle(Object.fromEntries(NOTICE_LANGUAGES.map(({ code }) => [code, ''])));
        setLocalizedBody(Object.fromEntries(NOTICE_LANGUAGES.map(({ code }) => [code, ''])));
      } catch (err) {
        console.error(err);
        alert(err?.message || '다국어 공지 발송 중 오류가 발생했습니다.');
      } finally {
        setSending(false);
      }
      return;
    }

    if (!APP_NOTIFICATION_TEMPLATES[notifType]) {
      alert('지원하지 않는 알림 타입입니다.');
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
      await sendFcmNotification('', '', topic, notifType, tileId, notifType);
      alert(`[FCM 전송 성공]\n대상 토픽: ${topic}\n알림 타입: ${notifType}\n\n수신자 언어로 발송되었습니다.`);
      setTileId('');
    } catch (err) {
      console.error(err);
      alert('푸시 알림 발송 중 에러가 발생했습니다.');
    } finally {
      setSending(false);
    }
  };

  const previewTitle = notifType === 'system_notice'
    ? localizedTitle[previewLanguage] || ''
    : APP_NOTIFICATION_TEMPLATES[notifType]?.title || '';
  const previewBody = notifType === 'system_notice'
    ? localizedBody[previewLanguage] || ''
    : APP_NOTIFICATION_TEMPLATES[notifType]?.body || '';

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
          
          {notifType === 'system_notice' ? (
            <div style={{
              display: 'flex', gap: '0.6rem', alignItems: 'flex-start',
              color: 'var(--text-secondary)', fontSize: '0.76rem',
              padding: '0.85rem 1rem', background: 'rgba(56, 189, 248, 0.04)',
              borderRadius: '10px', border: '1px solid rgba(56, 189, 248, 0.12)'
            }}>
              <Info size={16} style={{ color: 'var(--accent-cyan)', flexShrink: 0, marginTop: '2px' }} />
              <p style={{ margin: 0, lineHeight: 1.5 }}>
                공지사항은 전체 플레이어를 대상으로 언어별 발송됩니다.
                앱에서 알림을 켜고 해당 언어를 사용하는 플레이어에게만 전달됩니다.
              </p>
            </div>
          ) : (
            <>
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
            </>
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

          {notifType === 'system_notice' ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.8rem' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '0.8rem', flexWrap: 'wrap' }}>
                <label className="field-label" style={{ margin: 0 }}>언어별 공지사항</label>
                <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>제목과 본문을 모두 입력한 언어만 발송됩니다.</span>
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '0.8rem' }}>
                {NOTICE_LANGUAGES.map((language) => (
                  <div
                    key={language.code}
                    style={{
                      display: 'flex', flexDirection: 'column', gap: '0.5rem',
                      padding: '0.9rem', borderRadius: '12px',
                      border: '1px solid var(--border-color)',
                      background: 'rgba(15, 23, 42, 0.35)'
                    }}
                  >
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <strong style={{ fontSize: '0.85rem', color: 'var(--text-primary)' }}>{language.label}</strong>
                      <span style={{ fontSize: '0.68rem', color: 'var(--text-muted)', fontFamily: 'monospace' }}>{language.code}</span>
                    </div>
                    <input
                      type="text"
                      className="tactical-input"
                      placeholder={`${language.label} 제목`}
                      value={localizedTitle[language.code]}
                      onChange={(e) => setLocalizedTitle((prev) => ({ ...prev, [language.code]: e.target.value }))}
                    />
                    <textarea
                      className="tactical-input"
                      style={{ minHeight: '74px', resize: 'vertical' }}
                      placeholder={`${language.label} 본문`}
                      value={localizedBody[language.code]}
                      onChange={(e) => setLocalizedBody((prev) => ({ ...prev, [language.code]: e.target.value }))}
                    />
                  </div>
                ))}
              </div>
            </div>
          ) : (
            <div style={{
              display: 'flex', gap: '0.6rem', alignItems: 'flex-start',
              color: 'var(--text-secondary)', fontSize: '0.76rem',
              padding: '0.85rem 1rem', background: 'rgba(56, 189, 248, 0.04)',
              borderRadius: '10px', border: '1px solid rgba(56, 189, 248, 0.12)'
            }}>
              <Info size={16} style={{ color: 'var(--accent-cyan)', flexShrink: 0, marginTop: '2px' }} />
              <p style={{ margin: 0, lineHeight: 1.5 }}>
                영토 점령·영토 방어 알림의 제목과 내용은 앱에 등록된 기본 문구로,
                수신자 언어에 맞춰 자동 발송됩니다. 별도로 입력할 필요가 없습니다.
              </p>
            </div>
          )}

          {/* 실시간 미리보기 카드 */}
          {(previewTitle || previewBody) && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '0.8rem', flexWrap: 'wrap' }}>
                <label className="field-label" style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', margin: 0 }}>
                  <Smartphone size={14} /> 기기 수신 미리보기 (Preview)
                </label>
                {notifType === 'system_notice' && (
                  <select
                    className="tactical-input"
                    value={previewLanguage}
                    onChange={(e) => setPreviewLanguage(e.target.value)}
                    style={{ maxWidth: '180px' }}
                  >
                    {NOTICE_LANGUAGES.map((language) => (
                      <option key={language.code} value={language.code}>{language.label}</option>
                    ))}
                  </select>
                )}
              </div>
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
                    {previewTitle || '알림 제목'}
                  </div>
                  <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', marginTop: '0.2rem', lineHeight: 1.4 }}>
                    {previewBody || '알림 본문 내용이 여기에 표시됩니다.'}
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
