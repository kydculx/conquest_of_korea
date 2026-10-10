import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Search, RotateCcw, MapPin, Trash2, ChevronLeft, ChevronRight, X } from 'lucide-react';
import { fetchAllPhotos, deleteTilePhotoByAdmin } from '../api';
import Pagination from './Pagination';

const PAGE_SIZE = 20;

function formatDateTime(iso) {
  if (!iso) return '-';
  const d = new Date(iso);
  const p = (n) => String(n).padStart(2, '0');
  return `${d.getFullYear()}.${p(d.getMonth() + 1)}.${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}`;
}

export default function GalleryTab() {
  const navigate = useNavigate();
  const [photos, setPhotos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [page, setPage] = useState(1);
  const [deletingId, setDeletingId] = useState(null);
  const [viewerIndex, setViewerIndex] = useState(null);

  const load = async () => {
    setLoading(true);
    setError(null);
    try {
      const rows = await fetchAllPhotos();
      setPhotos(rows || []);
    } catch (err) {
      console.error(err);
      setError('갤러리 목록을 불러오지 못했습니다.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    let active = true;
    (async () => {
      setLoading(true);
      try {
        const rows = await fetchAllPhotos();
        if (active) setPhotos(rows || []);
      } catch (err) {
        console.error(err);
        if (active) setError('갤러리 목록을 불러오지 못했습니다.');
      } finally {
        if (active) setLoading(false);
      }
    })();
    return () => { active = false; };
  }, []);

  const handleDelete = async (photo) => {
    if (!window.confirm(`[${photo.user_nickname || ''}] 사진을 영구 삭제하시겠습니까? (스토리지 파일도 함께 정리됩니다.)`)) return;
    setDeletingId(photo.id);
    try {
      await deleteTilePhotoByAdmin(photo);
      alert('사진이 삭제되었습니다.');
      await load();
    } catch (e) {
      alert('삭제 중 오류 발생: ' + (e.message || JSON.stringify(e)));
    } finally {
      setDeletingId(null);
    }
  };

  const keyword = searchTerm.trim().toLowerCase();
  const filtered = keyword
    ? photos.filter((p) =>
        (p.user_nickname || '').toLowerCase().includes(keyword) ||
        (p.tile_id || '').toLowerCase().includes(keyword) ||
        (p.comment || '').toLowerCase().includes(keyword)
      )
    : photos;

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const safePage = Math.min(page, totalPages);
  const paged = filtered.slice((safePage - 1) * PAGE_SIZE, safePage * PAGE_SIZE);

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
              placeholder="닉네임·타일 ID·코멘트 검색..."
              value={searchTerm}
              onChange={(e) => { setSearchTerm(e.target.value); setPage(1); }}
            />
          </div>
          <button className="tactical-btn" onClick={load}>
            <RotateCcw size={16} /> 새로고침
          </button>
        </div>
      </div>

      {loading && <div className="tactical-spinner" />}
      {error && <div style={{ color: 'var(--accent-red)' }}>{error}</div>}
      {!loading && !error && filtered.length === 0 && (
        <div className="empty-state">등록된 사진이 없습니다.</div>
      )}

      {!loading && !error && filtered.length > 0 && (
        <div className="tactical-table-container" style={{ marginTop: 0 }}>
          <table className="tactical-table">
            <thead>
              <tr>
                <th>사진</th>
                <th>사용자</th>
                <th>타일 ID</th>
                <th>코멘트</th>
                <th>등록일</th>
                <th style={{ textAlign: 'center' }}>관리</th>
              </tr>
            </thead>
            <tbody>
              {paged.map((p) => (
                <tr key={p.id}>
                  <td>
                    <img
                      src={p.photo_url}
                      alt="현장 사진"
                      loading="lazy"
                      onClick={() => setViewerIndex(filtered.findIndex((f) => f.id === p.id))}
                      style={{ width: '64px', height: '64px', objectFit: 'cover', borderRadius: '8px', border: '1px solid var(--border-hover)', display: 'block', cursor: 'zoom-in' }}
                    />
                  </td>
                  <td>
                    <button
                      className="tactical-btn sm"
                      style={{ background: 'none', border: 'none', padding: 0, color: 'var(--text-primary)', fontWeight: 600, cursor: 'pointer' }}
                      onClick={() => navigate(`/admin/user-tiles?userId=${p.user_id}&nickname=${encodeURIComponent(p.user_nickname || '')}`)}
                      title="사용자 점령 목록으로 이동"
                    >
                      {p.user_nickname || '미등록 사용자'}
                    </button>
                  </td>
                  <td className="kv-value mono">{p.tile_id}</td>
                  <td style={{ fontSize: '0.82rem', color: 'var(--text-secondary)', maxWidth: '220px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }} title={p.comment || ''}>
                    {p.comment || '-'}
                  </td>
                  <td style={{ fontSize: '0.82rem', color: 'var(--text-secondary)', whiteSpace: 'nowrap' }}>{formatDateTime(p.created_at)}</td>
                  <td style={{ textAlign: 'center', whiteSpace: 'nowrap' }}>
                    <button className="tactical-btn sm" onClick={() => navigate(`/admin/dashboard?hq=${p.tile_id}`)} title="지도에서 해당 타일 보기">
                      <MapPin size={13} /> 맵
                    </button>
                    {' '}
                    <button
                      className="tactical-btn sm"
                      disabled={deletingId === p.id}
                      onClick={() => handleDelete(p)}
                      title="사진 영구 삭제"
                      style={{ color: 'var(--accent-red)' }}
                    >
                      <Trash2 size={13} /> {deletingId === p.id ? '삭제 중' : '삭제'}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          <Pagination
            page={safePage}
            totalPages={totalPages}
            totalCount={filtered.length}
            pageSize={PAGE_SIZE}
            onChange={setPage}
          />
        </div>
      )}

      {viewerIndex !== null && filtered[viewerIndex] && (
        <div
          style={{
            position: 'fixed', top: 0, left: 0, width: '100vw', height: '100vh',
            background: 'rgba(0, 0, 0, 0.88)', display: 'flex', alignItems: 'center',
            justifyContent: 'center', zIndex: 9999, padding: '1.5rem',
          }}
          onClick={() => setViewerIndex(null)}
        >
          <button
            className="tactical-btn sm"
            onClick={(e) => { e.stopPropagation(); setViewerIndex((i) => Math.max(0, i - 1)); }}
            disabled={viewerIndex <= 0}
            aria-label="이전 사진"
            style={{ marginRight: '0.75rem', flexShrink: 0 }}
          >
            <ChevronLeft size={18} />
          </button>
          <div
            style={{ flex: '1 1 auto', minWidth: 0, maxWidth: '720px', width: '100%', display: 'flex', flexDirection: 'column', gap: '0.6rem' }}
            onClick={(e) => e.stopPropagation()}
          >
            <img
              src={filtered[viewerIndex].photo_url}
              alt="현장 사진 원본"
              style={{ width: '100%', maxHeight: '70vh', objectFit: 'contain', borderRadius: '10px', background: 'rgba(255,255,255,0.04)' }}
            />
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
              <span>
                <strong style={{ color: 'var(--text-primary)' }}>{filtered[viewerIndex].user_nickname || '미등록 사용자'}</strong>
                {' · '}{filtered[viewerIndex].tile_id}
                {' · '}{formatDateTime(filtered[viewerIndex].created_at)}
              </span>
              <span>{viewerIndex + 1} / {filtered.length}</span>
            </div>
            {filtered[viewerIndex].comment && (
              <div style={{ color: '#fff', fontSize: '0.8rem', background: 'rgba(255,255,255,0.06)', padding: '6px 10px', borderRadius: '6px' }}>
                {filtered[viewerIndex].comment}
              </div>
            )}
          </div>
          <button
            className="tactical-btn sm"
            onClick={(e) => { e.stopPropagation(); setViewerIndex((i) => Math.min(filtered.length - 1, i + 1)); }}
            disabled={viewerIndex >= filtered.length - 1}
            aria-label="다음 사진"
            style={{ marginLeft: '0.75rem', flexShrink: 0 }}
          >
            <ChevronRight size={18} />
          </button>
          <button
            className="tactical-btn sm"
            onClick={() => setViewerIndex(null)}
            aria-label="닫기"
            style={{ position: 'absolute', top: '1.2rem', right: '1.2rem' }}
          >
            <X size={16} />
          </button>
        </div>
      )}
    </div>
  );
}
