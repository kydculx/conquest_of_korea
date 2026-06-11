import React, { useEffect, useState } from 'react';
import { supabase } from '../supabase';
import { Trophy, Coins, Compass, RotateCcw, Search, Award } from 'lucide-react';

export default function RankingTab() {
  const [agents, setAgents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [sortBy, setSortBy] = useState('captured_tiles_count'); // captured_tiles_count, gold
  const [searchTerm, setSearchTerm] = useState('');

  const loadRankings = async () => {
    try {
      setLoading(true);
      setError(null);
      
      const { data, error: err } = await supabase
        .from('profiles')
        .select('id, nickname, color_hex, captured_tiles_count, daily_moved_tiles_count, total_moved_tiles_count, gold, created_at')
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

  // 검색어 필터링
  const filteredAgents = agents.filter(agent =>
    (agent.nickname && agent.nickname.toLowerCase().includes(searchTerm.toLowerCase())) ||
    (agent.id && agent.id.toLowerCase().includes(searchTerm.toLowerCase()))
  );

  const getRankBadge = (index) => {
    if (index === 0) return { color: '#eab308', label: '1ST' };
    if (index === 1) return { color: '#64748b', label: '2ND' };
    if (index === 2) return { color: '#b45309', label: '3RD' };
    return { color: 'var(--text-secondary)', label: `${index + 1}` };
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
      {/* 랭킹 컨트롤 패널 */}
      <div className="tab-controls-header">
        {/* 정렬 필터 버튼 그룹 */}
        <div className="tab-filter-group">
          <button 
            onClick={() => setSortBy('captured_tiles_count')}
            className={`tactical-btn ${sortBy === 'captured_tiles_count' ? 'active' : ''}`}
          >
            <Trophy size={16} /> 점령 영토 순
          </button>
          <button 
            onClick={() => setSortBy('daily_moved_tiles_count')}
            className={`tactical-btn ${sortBy === 'daily_moved_tiles_count' ? 'active' : ''}`}
          >
            <Compass size={16} /> 일일 이동 순
          </button>
          <button 
            onClick={() => setSortBy('total_moved_tiles_count')}
            className={`tactical-btn ${sortBy === 'total_moved_tiles_count' ? 'active' : ''}`}
          >
            <Award size={16} /> 누적 이동 순
          </button>
        </div>

        {/* 검색 및 새로고침 */}
        <div className="tab-search-group">
          <div className="tab-search-input-wrapper">
            <Search size={16} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)' }} />
            <input 
              type="text"
              className="tactical-input"
              style={{ paddingLeft: '2.5rem' }}
              placeholder="사용자 검색..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
          <button className="tactical-btn" onClick={loadRankings} disabled={loading}>
            <RotateCcw size={16} className={loading ? 'spin' : ''} /> 새로고침
          </button>
        </div>
      </div>

      {error && <div style={{ color: 'var(--accent-red)', fontFamily: 'monospace' }}>{error}</div>}

      {/* 랭킹 뷰 보드 */}
      <div className="tactical-table-container">
        {loading ? (
          <div style={{ display: 'flex', justifyContent: 'center', padding: '4rem' }}>
            <div className="tactical-spinner" />
          </div>
        ) : (
          <table className="tactical-table">
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
                  <td colSpan="3" style={{ textAlign: 'center', color: 'var(--text-muted)', padding: '3rem' }}>
                    등록된 사용자 정보가 없거나 검색 결과가 존재하지 않습니다.
                  </td>
                </tr>
              ) : (
                filteredAgents.map((agent, index) => {
                  const rank = getRankBadge(index);
                  const isTop3 = index < 3;
                  return (
                    <tr 
                      key={agent.id}
                      style={{
                        background: isTop3 ? 'rgba(255, 255, 255, 0.01)' : 'transparent',
                        transition: 'background 0.2s ease'
                      }}
                    >
                      <td style={{ textAlign: 'center' }}>
                        {isTop3 ? (
                          <div style={{
                            display: 'inline-flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            gap: '4px',
                            fontWeight: '800',
                            color: rank.color,
                            fontFamily: 'var(--font-display)'
                          }}>
                            <Award size={16} />
                            {rank.label}
                          </div>
                        ) : (
                          <span style={{ fontFamily: 'monospace', fontWeight: 600, color: 'var(--text-muted)' }}>
                            {rank.label}
                          </span>
                        )}
                      </td>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.8rem' }}>
                          <div 
                            style={{ 
                              width: '12px', 
                              height: '12px', 
                              borderRadius: '50%', 
                              backgroundColor: agent.color_hex || 'var(--accent-cyan)'
                            }} 
                          />
                          <div>
                            <div style={{ fontWeight: 'bold' }}>
                              {agent.nickname || '미등록 사용자'}
                            </div>
                          </div>
                        </div>
                      </td>
                      <td style={{ 
                        textAlign: 'right', 
                        fontWeight: 'bold', 
                        color: 'var(--accent-cyan)',
                        fontSize: '1.05rem'
                      }}>
                        {sortBy === 'captured_tiles_count' ? (
                          <>
                            {agent.captured_tiles_count || 0} <span style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', fontWeight: 'normal' }}>구역</span>
                          </>
                        ) : sortBy === 'daily_moved_tiles_count' ? (
                          <>
                            {agent.daily_moved_tiles_count || 0} <span style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', fontWeight: 'normal' }}>타일</span>
                          </>
                        ) : (
                          <>
                            {agent.total_moved_tiles_count || 0} <span style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', fontWeight: 'normal' }}>타일</span>
                          </>
                        )}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
