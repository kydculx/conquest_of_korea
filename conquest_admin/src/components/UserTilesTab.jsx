import React, { useState, useEffect } from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, MapPin } from 'lucide-react';
import { fetchUserCapturedTiles } from '../api';

export default function UserTilesTab() {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const userId = searchParams.get('userId');
  const nickname = searchParams.get('nickname') || '';

  const [tiles, setTiles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (!userId) {
      navigate('/admin/users');
      return;
    }
    let active = true;
    const load = async () => {
      setLoading(true);
      setError(null);
      try {
        const data = await fetchUserCapturedTiles(userId);
        if (active) setTiles(data || []);
      } catch (err) {
        console.error(err);
        if (active) setError('점령 목록을 불러오지 못했습니다.');
      } finally {
        if (active) setLoading(false);
      }
    };
    load();
    return () => { active = false; };
  }, [userId, navigate]);

  return (
    <div className="tactical-card" style={{ width: '100%', maxWidth: '900px', margin: '1rem auto', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '0.8rem' }}>
        <button className="tactical-btn" onClick={() => navigate('/admin/users')}>
          <ArrowLeft size={14} /> 사용자 목록
        </button>
        <h2 style={{ margin: 0, fontSize: '1.1rem', color: 'var(--text-primary)' }}>
          점령 목록{nickname ? ` - ${nickname}` : ''}
        </h2>
      </div>

      <div style={{ color: 'var(--text-secondary)', fontSize: '0.85rem' }}>
        총 {tiles.length}개 타일
      </div>

      {loading && <div className="tactical-spinner" />}
      {error && <div style={{ color: 'var(--danger, #ff5c5c)' }}>{error}</div>}
      {!loading && !error && tiles.length === 0 && (
        <div style={{ color: 'var(--text-muted)' }}>점령한 타일이 없습니다.</div>
      )}

      {!loading && !error && tiles.length > 0 && (
        <div className="tactical-table-container">
          <table className="tactical-table">
            <thead>
              <tr>
                <th>타일 ID</th>
                <th>좌표 (q, r)</th>
                <th>색상</th>
                <th>상태</th>
                <th>점령 횟수</th>
                <th>점령 시각</th>
                <th>맵 보기</th>
              </tr>
            </thead>
            <tbody>
              {tiles.map((t) => (
                <tr key={t.id}>
                  <td style={{ fontFamily: 'monospace' }}>{t.id}</td>
                  <td style={{ fontFamily: 'monospace' }}>{t.q}, {t.r}</td>
                  <td>
                    <span
                      style={{
                        display: 'inline-block',
                        width: '14px',
                        height: '14px',
                        borderRadius: '3px',
                        backgroundColor: t.color_hex || 'transparent',
                        border: '1px solid var(--text-muted)',
                      }}
                    />
                  </td>
                  <td>{t.capture_status || 'captured'}</td>
                  <td>{t.capture_count ?? 1}</td>
                  <td>{t.captured_at ? new Date(t.captured_at).toLocaleString('ko-KR') : '-'}</td>
                  <td>
                    <button className="tactical-btn" onClick={() => navigate(`/admin/dashboard?hq=${t.id}`)}>
                      <MapPin size={14} /> 맵에서 보기
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
