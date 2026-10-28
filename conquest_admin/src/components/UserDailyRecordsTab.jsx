import { useEffect, useMemo, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import {
  Activity,
  ArrowLeft,
  Award,
  CalendarCheck,
  CalendarDays,
  ChevronLeft,
  ChevronRight,
  Gauge,
} from 'lucide-react';
import { fetchUserDailyMovedTiles } from '../api';

const toDateKey = (date) => date.toISOString().slice(0, 10);

const monthStart = (date) =>
  new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), 1));

const addMonths = (date, delta) =>
  new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth() + delta, 1));

const formatMonth = (date) =>
  new Intl.DateTimeFormat('ko-KR', {
    year: 'numeric',
    month: 'long',
    timeZone: 'UTC',
  }).format(date);

const formatWeekday = (dateKey) =>
  new Intl.DateTimeFormat('ko-KR', {
    weekday: 'short',
    timeZone: 'UTC',
  }).format(new Date(`${dateKey}T00:00:00Z`));

const formatUpdatedAt = (iso) => {
  if (!iso) return '-';
  return new Intl.DateTimeFormat('ko-KR', {
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
    timeZone: 'UTC',
  }).format(new Date(iso));
};

const formatCount = (value) =>
  Number(value || 0).toLocaleString('ko-KR');

export default function UserDailyRecordsTab() {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const userId = searchParams.get('userId');
  const nickname = searchParams.get('nickname') || '';

  const [visibleMonth, setVisibleMonth] = useState(() => monthStart(new Date()));
  const [records, setRecords] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const currentMonth = useMemo(() => monthStart(new Date()), []);
  const todayKey = useMemo(() => toDateKey(new Date()), []);
  const isCurrentMonth =
    visibleMonth.getUTCFullYear() === currentMonth.getUTCFullYear() &&
    visibleMonth.getUTCMonth() === currentMonth.getUTCMonth();

  useEffect(() => {
    if (!userId) {
      navigate('/admin/users');
    }
  }, [userId, navigate]);

  useEffect(() => {
    if (!userId) return undefined;
    let active = true;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoading(true);
    setError(null);

    const startDate = toDateKey(visibleMonth);
    const endDate = toDateKey(addMonths(visibleMonth, 1));

    fetchUserDailyMovedTiles(userId, startDate, endDate)
      .then((data) => {
        if (active) setRecords(data || []);
      })
      .catch((err) => {
        console.error(err);
        if (active) {
          setRecords([]);
          setError(
            '이동 기록을 불러오지 못했습니다. 관리자 조회 권한(RLS)을 확인해 주세요.'
          );
        }
      })
      .finally(() => {
        if (active) setLoading(false);
      });

    return () => {
      active = false;
    };
  }, [userId, visibleMonth]);

  const totals = useMemo(() => {
    const total = records.reduce(
      (sum, row) => sum + Number(row.moved_tiles_count || 0),
      0
    );
    const max = records.reduce(
      (value, row) => Math.max(value, Number(row.moved_tiles_count || 0)),
      0
    );
    return {
      total,
      max,
      average: records.length > 0 ? total / records.length : 0,
    };
  }, [records]);

  if (!userId) return null;

  const statCards = [
    {
      label: '월간 이동 타일',
      value: formatCount(totals.total),
      sub: `${formatMonth(visibleMonth)} · 타일`,
      tone: 'tone-blue',
      Icon: Activity,
    },
    {
      label: '기록 일수',
      value: `${formatCount(records.length)}일`,
      sub: '이동 기록이 있는 날',
      tone: 'tone-green',
      Icon: CalendarCheck,
    },
    {
      label: '일평균',
      value: formatCount(
        Math.round(totals.average * 10) / 10
      ),
      sub: '기록 일수 기준',
      tone: 'tone-amber',
      Icon: Gauge,
    },
    {
      label: '최고 기록',
      value: formatCount(totals.max),
      sub: '하루 최대 이동 타일',
      tone: 'tone-rose',
      Icon: Award,
    },
  ];

  return (
    <div
      className="section-stack"
      style={{ width: '100%', maxWidth: '1040px', margin: '0 auto' }}
    >
      <div className="tactical-card section-stack">
        <div className="card-head">
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.7rem', minWidth: 0 }}>
            <button className="tactical-btn sm" onClick={() => navigate('/admin/users')}>
              <ArrowLeft size={14} /> 사용자 목록
            </button>
            <h2 className="card-title" style={{ margin: 0 }}>
              <CalendarDays size={18} />
              일일 이동 기록
            </h2>
            {nickname && <span className="card-sub">{nickname}</span>}
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', flexWrap: 'wrap' }}>
            <button
              className="tactical-btn sm"
              onClick={() => setVisibleMonth((month) => addMonths(month, -1))}
              aria-label="이전 달"
            >
              <ChevronLeft size={14} />
            </button>
            <span
              style={{
                minWidth: '120px',
                textAlign: 'center',
                fontWeight: 700,
                fontSize: '0.88rem',
              }}
            >
              {formatMonth(visibleMonth)}
            </span>
            <button
              className="tactical-btn sm"
              onClick={() => setVisibleMonth((month) => addMonths(month, 1))}
              disabled={isCurrentMonth}
              aria-label="다음 달"
            >
              <ChevronRight size={14} />
            </button>
            <button
              className="tactical-btn sm"
              onClick={() => setVisibleMonth(currentMonth)}
              disabled={isCurrentMonth}
            >
              이번 달
            </button>
          </div>
        </div>

        <div style={{ display: 'flex', justifyContent: 'space-between', gap: '1rem', flexWrap: 'wrap' }}>
          <span style={{ fontSize: '0.76rem', color: 'var(--text-muted)' }}>
            UTC 기준 · 랭킹의 일일 이동 타일과 동일한 기록입니다.
          </span>
          <span style={{ fontSize: '0.76rem', color: 'var(--text-muted)', fontFamily: 'var(--font-mono)' }}>
            사용자 ID: {userId}
          </span>
        </div>

        {loading ? (
          <div className="tactical-spinner" />
        ) : error ? (
          <div className="empty-state" style={{ color: 'var(--accent-red)' }}>
            {error}
          </div>
        ) : (
          <>
            <div className="stat-grid">
              {statCards.map(({ label, value, sub, tone, Icon }) => (
                <div key={label} className="stat-card">
                  <div className={`stat-icon ${tone}`}>
                    <Icon size={18} />
                  </div>
                  <div style={{ minWidth: 0 }}>
                    <div className="stat-label">{label}</div>
                    <div className="stat-value">{value}</div>
                    <div className="stat-sub">{sub}</div>
                  </div>
                </div>
              ))}
            </div>

            <div className="tactical-table-container">
              <table className="tactical-table">
                <thead>
                  <tr>
                    <th>날짜 (UTC)</th>
                    <th>요일</th>
                    <th style={{ textAlign: 'right' }}>이동 타일</th>
                    <th>비율</th>
                    <th>마지막 갱신 (UTC)</th>
                  </tr>
                </thead>
                <tbody>
                  {records.length === 0 ? (
                    <tr>
                      <td colSpan="5" className="empty-state">
                        이 달의 이동 기록이 없습니다.
                      </td>
                    </tr>
                  ) : (
                    records.map((row) => {
                      const count = Number(row.moved_tiles_count || 0);
                      const ratio = totals.max > 0 ? (count / totals.max) * 100 : 0;
                      const isToday = row.stat_date === todayKey;

                      return (
                        <tr key={row.stat_date}>
                          <td>
                            <span className="kv-value mono">{row.stat_date}</span>
                            {isToday && (
                              <span
                                style={{
                                  marginLeft: '0.45rem',
                                  padding: '0.16rem 0.4rem',
                                  borderRadius: '999px',
                                  fontSize: '0.62rem',
                                  fontWeight: 700,
                                  color: 'var(--accent-cyan)',
                                  background: 'rgba(56, 189, 248, 0.12)',
                                  border: '1px solid rgba(56, 189, 248, 0.3)',
                                }}
                              >
                                오늘
                              </span>
                            )}
                          </td>
                          <td style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
                            {formatWeekday(row.stat_date)}
                          </td>
                          <td style={{ textAlign: 'right', whiteSpace: 'nowrap' }}>
                            <span className="table-numeric">{formatCount(count)}</span>
                            <span className="table-unit">타일</span>
                          </td>
                          <td>
                            <div
                              style={{
                                height: '6px',
                                minWidth: '80px',
                                background: 'rgba(255, 255, 255, 0.06)',
                                borderRadius: '999px',
                                overflow: 'hidden',
                              }}
                            >
                              <div
                                style={{
                                  width: `${ratio}%`,
                                  height: '100%',
                                  borderRadius: '999px',
                                  background: 'var(--accent-gradient)',
                                }}
                              />
                            </div>
                          </td>
                          <td style={{ fontSize: '0.78rem', color: 'var(--text-secondary)' }}>
                            {formatUpdatedAt(row.updated_at)}
                          </td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
