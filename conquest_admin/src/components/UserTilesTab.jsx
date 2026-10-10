import React, { useState, useEffect } from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, MapPin } from 'lucide-react';
import { fetchUserCapturedTiles } from '../api';
import Pagination from './Pagination';

const PAGE_SIZE = 20;

export default function UserTilesTab() {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const userId = searchParams.get('userId');
  const nickname = searchParams.get('nickname') || '';

  const [tiles, setTiles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [page, setPage] = useState(1);

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

  const totalPages = Math.max(1, Math.ceil(tiles.length / PAGE_SIZE));
  const safePage = Math.min(page, totalPages);
  const pagedTiles = tiles.slice((safePage - 1) * PAGE_SIZE, safePage * PAGE_SIZE);

  return (
    <div className="tactical-card section-stack" style={{ width: '100%', maxWidth: '900px', margin: '0 auto' }}>
      <div className="card-head">
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.7rem', minWidth: 0 }}>
          <button className="tactical-btn sm" onClick={() => navigate('/admin/users')}>
            <ArrowLeft size={14} /> 사용자 목록
          </button>
          <h2 className="card-title" style={{ margin: 0 }}>
            점령 목록{nickname ? ` - ${nickname}` : ''}
          </h2>
        </div>
        <span className="card-sub">총 {tiles.length.toLocaleString()}개 타일</span>
        {!loading && !error && tiles.length > 0 && (
          <button
            className="tactical-btn sm"
            onClick={() => navigate(`/admin/dashboard?tiles=${userId}&nickname=${encodeURIComponent(nickname)}`)}
          >
            <MapPin size={13} /> 지도에서 전체 보기
          </button>
        )}
      </div>

      {loading && <div className="tactical-spinner" />}
      {error && <div style={{ color: 'var(--accent-red)' }}>{error}</div>}
      {!loading && !error && tiles.length === 0 && (
        <div className="empty-state">점령한 타일이 없습니다.</div>
      )}

      {!loading && !error && tiles.length > 0 && (
        <div className="tactical-table-container" style={{ marginTop: 0 }}>
          <table className="tactical-table">
            <thead>
              <tr>
                <th>타일 ID</th>
                <th>좌표 (q, r)</th>
                <th>색상</th>
                <th>상태</th>
                <th style={{ textAlign: 'right' }}>점령 횟수</th>
                <th>점령 시각</th>
                <th style={{ textAlign: 'center' }}>맵 보기</th>
              </tr>
            </thead>
            <tbody>
              {pagedTiles.map((t) => (
                <tr key={t.id}>
                  <td className="kv-value mono">{t.id}</td>
                  <td className="kv-value mono">{t.q}, {t.r}</td>
                  <td>
                    <span
                      style={{
                        display: 'inline-block',
                        width: '14px',
                        height: '14px',
                        borderRadius: '4px',
                        backgroundColor: t.color_hex || 'transparent',
                        border: '1px solid var(--border-hover)',
                        verticalAlign: 'middle',
                      }}
                    />
                  </td>
                  <td style={{ fontSize: '0.82rem', color: 'var(--text-secondary)' }}>{t.capture_status || 'captured'}</td>
                  <td style={{ textAlign: 'right' }}><span className="table-numeric" style={{ color: 'var(--text-primary)' }}>{t.capture_count ?? 1}</span></td>
                  <td style={{ fontSize: '0.82rem', color: 'var(--text-secondary)', whiteSpace: 'nowrap' }}>{t.captured_at ? new Date(t.captured_at).toLocaleString('ko-KR') : '-'}</td>
                  <td style={{ textAlign: 'center' }}>
                    <button className="tactical-btn sm" onClick={() => navigate(`/admin/dashboard?tiles=${userId}&nickname=${encodeURIComponent(nickname)}&hq=${t.id}`)}>
                      <MapPin size={13} /> 맵에서 보기
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          <Pagination
            page={safePage}
            totalPages={totalPages}
            totalCount={tiles.length}
            pageSize={PAGE_SIZE}
            onChange={setPage}
          />
        </div>
      )}
    </div>
  );
}
