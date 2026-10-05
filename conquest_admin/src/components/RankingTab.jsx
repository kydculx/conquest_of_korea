import React, { useEffect, useState } from 'react';
import { supabase } from '../supabase';
import { Trophy, Compass, RotateCcw, Search, Award } from 'lucide-react';
import Pagination from './Pagination';

const PAGE_SIZE = 20;

export default function RankingTab() {
  const [agents, setAgents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [sortBy, setSortBy] = useState('captured_tiles_count'); // captured_tiles_count, gold
  const [searchTerm, setSearchTerm] = useState('');
  const [page, setPage] = useState(1);

  const loadRankings = async () => {
    try {
      setLoading(true);
      setError(null);
      
      const { data, error: err } = await supabase
        .from('profiles')
        .select('id, nickname, color_hex, captured_tiles_count, daily_moved_tiles_count, total_moved_tiles_count, gold, created_at')
        .neq('role', 'admin')
        .order(sortBy, { ascending: false });

      if (err) throw err;
      setAgents(data || []);
    } catch (err) {
      console.error(err);
      setError('사용자 랭킹 데이터를 로드하는 중 에러가 발생했습니다.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadRankings();
  }, [sortBy]);

  const filteredAgents = agents.filter(agent =>
    (agent.nickname && agent.nickname.toLowerCase().includes(searchTerm.toLowerCase())) ||
    (agent.id && agent.id.toLowerCase().includes(searchTerm.toLowerCase()))
  );
  const totalPages = Math.max(1, Math.ceil(filteredAgents.length / PAGE_SIZE));
  const safePage = Math.min(page, totalPages);
  const pagedAgents = filteredAgents.slice((safePage - 1) * PAGE_SIZE, safePage * PAGE_SIZE);
  const rankOffset = (safePage - 1) * PAGE_SIZE;

  const getRankBadge = (index) => {
    if (index === 0) return { className: 'gold', label: '1위' };
    if (index === 1) return { className: 'silver', label: '2위' };
    if (index === 2) return { className: 'bronze', label: '3위' };
    return { className: 'plain', label: `${index + 1}` };
  };

  return (
    <div className="section-stack">
      {/* 랭킹 컨트롤 패널 */}
      <div className="tab-controls-header">
        {/* 정렬 필터 버튼 그룹 */}
        <div className="tab-filter-group">
          <button
            onClick={() => { setSortBy('captured_tiles_count'); setPage(1); }}
            className={`tactical-btn ${sortBy === 'captured_tiles_count' ? 'active' : ''}`}
          >
            <Trophy size={16} /> 점령 영토 순
          </button>
          <button
            onClick={() => { setSortBy('daily_moved_tiles_count'); setPage(1); }}
            className={`tactical-btn ${sortBy === 'daily_moved_tiles_count' ? 'active' : ''}`}
          >
            <Compass size={16} /> 일일 이동 순
          </button>
          <button
            onClick={() => { setSortBy('total_moved_tiles_count'); setPage(1); }}
            className={`tactical-btn ${sortBy === 'total_moved_tiles_count' ? 'active' : ''}`}
          >
            <Award size={16} /> 누적 이동 순
          </button>
        </div>

        {/* 검색 및 새로고침 */}
        <div className="tab-search-group">
          <div className="tab-search-input-wrapper">
            <Search size={16} className="search-icon" />
            <input
              type="text"
              className="tactical-input"
              style={{ paddingLeft: '2.5rem' }}
              placeholder="사용자 검색..."
              value={searchTerm}
              onChange={(e) => { setSearchTerm(e.target.value); setPage(1); }}
            />
          </div>
          <button className="tactical-btn" onClick={loadRankings} disabled={loading}>
            <RotateCcw size={16} className={loading ? 'spin' : ''} /> 새로고침
          </button>
        </div>
      </div>

      {error && <div style={{ color: 'var(--accent-red)', fontFamily: 'monospace' }}>{error}</div>}

      {/* 랭킹 뷰 보드 */}
      <div className="tactical-table-container ranking-container">
        {loading ? (
          <div style={{ display: 'flex', justifyContent: 'center', padding: '4rem' }}>
            <div className="tactical-spinner" />
          </div>
        ) : (
          <table className="tactical-table ranking-table">
            <thead>
              <tr>
                <th style={{ width: '80px', textAlign: 'center' }}>순위</th>
                <th>사용자</th>
                <th style={{ textAlign: 'right' }}>
                  {sortBy === 'captured_tiles_count' ? '점령 영토' : 
                   sortBy === 'daily_moved_tiles_count' ? '일일 이동' : '누적 이동'}
                </th>
              </tr>
            </thead>
            <tbody>
              {filteredAgents.length === 0 ? (
                <tr>
                  <td colSpan="3" className="empty-state">
                    등록된 사용자 정보가 없거나 검색 결과가 존재하지 않습니다.
                  </td>
                </tr>
              ) : (
                pagedAgents.map((agent, idx) => {
                  const index = rankOffset + idx;
                  const rank = getRankBadge(index);
                  const isTop3 = index < 3;
                  return (
                    <tr
                      key={agent.id}
                    >
                      <td style={{ textAlign: 'center', width: '90px' }}>
                        {isTop3 ? (
                          <span className={`rank-badge ${rank.className}`}>
                            <Award size={13} />
                            {rank.label}
                          </span>
                        ) : (
                          <span className="rank-badge plain">
                            {rank.label}
                          </span>
                        )}
                      </td>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.7rem', minWidth: 0 }}>
                          <div
                            style={{
                              width: '10px',
                              height: '10px',
                              borderRadius: '50%',
                              backgroundColor: agent.color_hex || 'var(--accent-cyan)',
                              flexShrink: 0
                            }}
                          />
                          <div style={{
                            fontWeight: 600,
                            fontSize: '0.88rem',
                            textOverflow: 'ellipsis',
                            overflow: 'hidden',
                            whiteSpace: 'nowrap'
                          }}>
                            {agent.nickname || '미등록 사용자'}
                          </div>
                        </div>
                      </td>
                      <td style={{
                        textAlign: 'right',
                        whiteSpace: 'nowrap'
                      }}>
                        <span className="table-numeric">
                          {sortBy === 'captured_tiles_count'
                            ? (agent.captured_tiles_count || 0)
                            : sortBy === 'daily_moved_tiles_count'
                              ? (agent.daily_moved_tiles_count || 0)
                              : (agent.total_moved_tiles_count || 0)}
                        </span>
                        <span className="table-unit">
                          {sortBy === 'captured_tiles_count' ? '구역' : '타일'}
                        </span>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        )}
          {!loading && (
            <Pagination
              page={safePage}
              totalPages={totalPages}
              totalCount={filteredAgents.length}
              pageSize={PAGE_SIZE}
              onChange={setPage}
            />
          )}
      </div>
    </div>
  );
}
