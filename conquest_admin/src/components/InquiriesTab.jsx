import { useEffect, useMemo, useState } from 'react';
import {
  Inbox,
  Search,
  RefreshCw,
  X,
  Send,
  CheckCircle2,
  Filter,
} from 'lucide-react';
import { fetchInquiries, answerInquiry, closeInquiry } from '../api';

const CATEGORY_LABELS = {
  bug: '버그 신고',
  feature: '기능 건의',
  account: '계정·데이터',
  etc: '기타',
};

const STATUS_META = {
  open: { label: '접수', className: 'inquiry-status open' },
  answered: { label: '답변 완료', className: 'inquiry-status answered' },
  closed: { label: '종료', className: 'inquiry-status closed' },
};

const FILTERS = [
  { value: 'all', label: '전체' },
  { value: 'open', label: '접수' },
  { value: 'answered', label: '답변 완료' },
  { value: 'closed', label: '종료' },
];

function formatDateTime(iso) {
  if (!iso) return '-';
  const d = new Date(iso);
  const p = (n) => String(n).padStart(2, '0');
  return `${d.getFullYear()}.${p(d.getMonth() + 1)}.${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}`;
}

function categoryLabel(category) {
  return CATEGORY_LABELS[category] ?? CATEGORY_LABELS.etc;
}

function statusMeta(status) {
  return STATUS_META[status] ?? STATUS_META.open;
}

function shortId(value) {
  return value ? String(value).slice(0, 8) : '-';
}

export default function InquiriesTab() {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [statusFilter, setStatusFilter] = useState('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [selected, setSelected] = useState(null);
  const [answerDraft, setAnswerDraft] = useState('');
  const [draftDirty, setDraftDirty] = useState(false);
  const [saving, setSaving] = useState(false);
  const [notice, setNotice] = useState(null);

  const load = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await fetchInquiries({ limit: 200 });
      setRows(data || []);
    } catch (err) {
      console.error(err);
      setError('문의 목록을 불러오지 못했습니다.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    let active = true;
    (async () => {
      setLoading(true);
      try {
        const data = await fetchInquiries({ limit: 200 });
        if (active) setRows(data || []);
      } catch (err) {
        console.error(err);
        if (active) setError('문의 목록을 불러오지 못했습니다.');
      } finally {
        if (active) setLoading(false);
      }
    })();
    return () => {
      active = false;
    };
  }, []);

  useEffect(() => {
    if (!selected) return undefined;
    const onKeyDown = (event) => {
      if (event.key === 'Escape') {
        setSelected(null);
      }
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [selected]);

  const counts = useMemo(() => {
    return rows.reduce(
      (acc, row) => {
        acc.total += 1;
        if (row.status === 'answered') acc.answered += 1;
        else if (row.status === 'closed') acc.closed += 1;
        else acc.open += 1;
        return acc;
      },
      { total: 0, open: 0, answered: 0, closed: 0 },
    );
  }, [rows]);

  const visibleRows = useMemo(() => {
    const keyword = searchTerm.trim().toLowerCase();
    return rows.filter((row) => {
      if (statusFilter !== 'all' && row.status !== statusFilter) return false;
      if (!keyword) return true;
      const haystack = [
        row.title,
        row.content,
        row.nickname,
        row.category,
        categoryLabel(row.category),
      ]
        .filter(Boolean)
        .join(' ')
        .toLowerCase();
      return haystack.includes(keyword);
    });
  }, [rows, statusFilter, searchTerm]);

  const patchRow = (updated) => {
    setRows((prev) => prev.map((row) => (row.id === updated.id ? updated : row)));
  };

  const openDetail = (row) => {
    setSelected(row);
    setAnswerDraft(row.answer ?? '');
    setDraftDirty(false);
    setNotice(null);
  };

  const closeDetail = () => {
    setSelected(null);
    setAnswerDraft('');
    setDraftDirty(false);
    setNotice(null);
  };

  const handleSaveAnswer = async () => {
    if (!selected) return;
    const answer = answerDraft.trim();
    if (!answer) {
      setNotice({ type: 'error', text: '답변 내용을 입력해 주세요.' });
      return;
    }
    setSaving(true);
    setNotice(null);
    try {
      const updated = await answerInquiry({
        id: selected.id,
        answer,
        status: 'answered',
      });
      patchRow(updated);
      setSelected(updated);
      setDraftDirty(false);
      setNotice({ type: 'success', text: '답변이 저장되었습니다.' });
    } catch (err) {
      console.error(err);
      setNotice({ type: 'error', text: '답변 저장에 실패했습니다.' });
    } finally {
      setSaving(false);
    }
  };

  const handleCloseInquiry = async () => {
    if (!selected) return;
    setSaving(true);
    setNotice(null);
    try {
      const updated = await closeInquiry(selected.id);
      patchRow(updated);
      setSelected(updated);
      setNotice({ type: 'success', text: '문의를 종료 처리했습니다.' });
    } catch (err) {
      console.error(err);
      setNotice({ type: 'error', text: '문의 종료 처리에 실패했습니다.' });
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="section-stack">
      <div className="stat-grid">
        <div className="stat-card">
          <div>
            <span className="stat-label">전체 문의</span>
            <div className="stat-value">{counts.total}</div>
          </div>
        </div>
        <div className="stat-card">
          <div>
            <span className="stat-label">접수</span>
            <div className="stat-value" style={{ color: 'var(--warning)' }}>
              {counts.open}
            </div>
          </div>
        </div>
        <div className="stat-card">
          <div>
            <span className="stat-label">답변 완료</span>
            <div className="stat-value" style={{ color: 'var(--success)' }}>
              {counts.answered}
            </div>
          </div>
        </div>
        <div className="stat-card">
          <div>
            <span className="stat-label">종료</span>
            <div className="stat-value" style={{ color: 'var(--text-muted)' }}>
              {counts.closed}
            </div>
          </div>
        </div>
      </div>

      <div className="tab-controls-header">
        <div
          className="tab-search-group"
          style={{ width: '100%', justifyContent: 'space-between', flexWrap: 'wrap', gap: '0.6rem' }}
        >
          <div className="tab-search-input-wrapper">
            <Search size={16} className="search-icon" />
            <input
              type="text"
              className="tactical-input"
              style={{ paddingLeft: '2.5rem' }}
              placeholder="제목·내용·닉네임 검색..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', flexWrap: 'wrap' }}>
            <Filter size={15} style={{ color: 'var(--text-muted)' }} />
            {FILTERS.map((filter) => (
              <button
                key={filter.value}
                type="button"
                className={`tactical-btn sm ${statusFilter === filter.value ? 'active' : ''}`}
                onClick={() => setStatusFilter(filter.value)}
              >
                {filter.label}
              </button>
            ))}
            <button type="button" className="tactical-btn sm" onClick={load} disabled={loading}>
              <RefreshCw size={14} />
              새로고침
            </button>
          </div>
        </div>
      </div>

      {loading && <div className="tactical-spinner" />}
      {!loading && error && (
        <div className="tactical-card inquiry-error">
          <span>{error}</span>
          <button type="button" className="tactical-btn sm" onClick={load}>
            <RefreshCw size={14} />
            다시 시도
          </button>
        </div>
      )}

      {!loading && !error && visibleRows.length === 0 && (
        <div className="tactical-card inquiry-empty">
          <Inbox size={26} />
          <span>표시할 문의가 없습니다.</span>
        </div>
      )}

      {!loading &&
        !error &&
        visibleRows.map((row) => {
          const meta = statusMeta(row.status);
          return (
            <button
              key={row.id}
              type="button"
              className="tactical-card inquiry-card"
              onClick={() => openDetail(row)}
            >
              <div className="inquiry-card-head">
                <span className="inquiry-category">{categoryLabel(row.category)}</span>
                <span className={meta.className}>{meta.label}</span>
                <span className="inquiry-card-date">{formatDateTime(row.created_at)}</span>
              </div>
              <div className="inquiry-card-title">{row.title}</div>
              <div className="inquiry-card-preview">{row.content}</div>
              <div className="inquiry-card-meta">
                <span>작성자 {row.nickname || shortId(row.user_id)}</span>
                <span>언어 {row.locale || '-'}</span>
                <span>버전 {row.app_version || '-'}</span>
                <span>플랫폼 {row.platform || '-'}</span>
              </div>
            </button>
          );
        })}

      {selected && (
        <div className="modal-overlay" onClick={closeDetail}>
          <div
            className="tactical-card modal-card wide"
            onClick={(event) => event.stopPropagation()}
          >
            <button className="modal-close" onClick={closeDetail} aria-label="닫기">
              <X size={18} />
            </button>
            <h3 className="modal-title">
              <Inbox size={19} />
              {selected.title}
            </h3>

            <div className="inquiry-detail-head">
              <span className="inquiry-category">{categoryLabel(selected.category)}</span>
              <span className={statusMeta(selected.status).className}>
                {statusMeta(selected.status).label}
              </span>
              <span className="inquiry-card-date">{formatDateTime(selected.created_at)}</span>
            </div>

            <div className="kv-grid inquiry-meta-grid">
              <div>
                <span className="kv-label">작성자</span>
                <div className="kv-value">{selected.nickname || '알 수 없음'}</div>
              </div>
              <div>
                <span className="kv-label">사용자 ID</span>
                <div className="kv-value mono">{shortId(selected.user_id)}</div>
              </div>
              <div>
                <span className="kv-label">앱 버전</span>
                <div className="kv-value">{selected.app_version || '-'}</div>
              </div>
              <div>
                <span className="kv-label">플랫폼</span>
                <div className="kv-value">{selected.platform || '-'}</div>
              </div>
              <div>
                <span className="kv-label">앱 언어</span>
                <div className="kv-value">{selected.locale || '-'}</div>
              </div>
              <div>
                <span className="kv-label">답변 일시</span>
                <div className="kv-value">{formatDateTime(selected.answered_at)}</div>
              </div>
            </div>

            <div className="inquiry-detail-body">
              <span className="field-label">문의 내용</span>
              <p className="inquiry-detail-text">{selected.content}</p>
            </div>

            <div className="inquiry-answer-form">
              <label className="field-label" htmlFor="inquiry-answer">
                답변
              </label>
              <textarea
                id="inquiry-answer"
                className="tactical-input"
                style={{ minHeight: '130px', resize: 'vertical' }}
                placeholder="앱 문의 화면에 표시할 답변을 작성하세요."
                value={answerDraft}
                onChange={(e) => {
                  setAnswerDraft(e.target.value);
                  setDraftDirty(true);
                  setNotice(null);
                }}
              />
              <div className="inquiry-answer-actions">
                <span className="inquiry-draft-state">
                  {draftDirty ? '저장되지 않은 변경 사항이 있습니다.' : '변경 사항 없음'}
                </span>
                <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
                  <button
                    type="button"
                    className="tactical-btn"
                    onClick={handleCloseInquiry}
                    disabled={saving || selected.status === 'closed'}
                  >
                    <X size={15} />
                    종료 처리
                  </button>
                  <button
                    type="button"
                    className="tactical-btn primary"
                    onClick={handleSaveAnswer}
                    disabled={saving}
                  >
                    <Send size={15} />
                    {saving ? '저장 중...' : '답변 저장'}
                  </button>
                </div>
              </div>
              {notice && (
                <div className={`inquiry-notice ${notice.type}`}>
                  {notice.type === 'success' ? (
                    <CheckCircle2 size={15} />
                  ) : (
                    <X size={15} />
                  )}
                  <span>{notice.text}</span>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
