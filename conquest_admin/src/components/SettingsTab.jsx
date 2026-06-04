import React, { useEffect, useState } from 'react';
import { fetchSystemSettings, updateGoldRate } from '../api';
import { Sliders, Save, RefreshCw, HelpCircle } from 'lucide-react';

export default function SettingsTab() {
  const [settings, setSettings] = useState([]);
  const [goldRate, setGoldRate] = useState(1.0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [saving, setSaving] = useState(false);

  const loadSettings = async () => {
    try {
      setLoading(true);
      const data = await fetchSystemSettings();
      setSettings(data);
      const rateSetting = data.find(s => s.key === 'gold_rate');
      if (rateSetting) {
        setGoldRate(parseFloat(rateSetting.value));
      }
    } catch (err) {
      setError('시스템 설정을 불러오는 중 에러가 발생했습니다.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadSettings();
  }, []);

  const handleSave = async () => {
    if (goldRate < 0.1 || goldRate > 10.0) {
      alert('골드 획득 배율은 0.1배에서 10.0배 사이로 설정해 주세요.');
      return;
    }

    try {
      setSaving(true);
      await updateGoldRate(goldRate);
      alert('글로벌 골드 획득 배율이 갱신되었습니다.');
      loadSettings();
    } catch (err) {
      console.error(err);
      alert('설정 저장 중 오류가 발생했습니다.');
    } finally {
      setSaving(false);
    }
  };

  if (loading && settings.length === 0) {
    return <div className="tactical-spinner" />;
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem', maxWidth: '600px' }}>
      
      {error && <div style={{ color: 'var(--accent-red)' }}>{error}</div>}

      <div className="tactical-card" style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
        <h3 style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '1.2rem', color: 'var(--accent-cyan)' }}>
          <Sliders size={20} />
          글로벌 게임 밸런스 조정
        </h3>

        {/* 골드 획득율 조정 섹션 */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem', padding: '1rem', background: 'rgba(255,255,255,0.02)', borderRadius: '8px', border: '1px solid var(--border-color)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontWeight: 'bold', fontSize: '0.95rem' }}>기본 골드 생산율 배율 (gold_rate)</span>
            <span style={{ fontSize: '1.1rem', fontWeight: 'bold', color: 'var(--accent-cyan)', fontFamily: 'monospace' }}>
              {goldRate.toFixed(1)}x
            </span>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
            <input 
              type="range" 
              min="0.1" 
              max="5.0" 
              step="0.1" 
              value={goldRate}
              onChange={(e) => setGoldRate(parseFloat(e.target.value))}
              style={{
                flex: 1,
                accentColor: 'var(--accent-cyan)',
                height: '6px',
                background: 'rgba(255,255,255,0.1)',
                borderRadius: '4px',
                outline: 'none'
              }}
            />
            <input 
              type="number" 
              className="tactical-input" 
              style={{ width: '80px', textAlign: 'center', fontWeight: 'bold' }}
              value={goldRate}
              min="0.1"
              max="10.0"
              step="0.1"
              onChange={(e) => setGoldRate(parseFloat(e.target.value) || 0.1)}
            />
          </div>

          <div style={{ display: 'flex', gap: '0.4rem', alignItems: 'flex-start', color: 'var(--text-secondary)', fontSize: '0.75rem', marginTop: '0.5rem' }}>
            <HelpCircle size={14} style={{ marginTop: '1px', flexShrink: 0 }} />
            <p>
              이 배율은 전체 사용자들의 기본 초당 골드 생산 속도에 직접 곱해집니다. 배율을 높이면 모든 사용자의 재화 확보가 빨라집니다.
              (예: 2.0x 설정 시 기본 생산량의 2배 지급)
            </p>
          </div>
        </div>

        {/* 기타 가상 설정 목록 표시 (확장성) */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.8rem', opacity: 0.6 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0.8rem', background: 'rgba(255,255,255,0.01)', borderRadius: '6px' }}>
            <div>
              <div style={{ fontSize: '0.85rem', fontWeight: 'bold' }}>초기 점령 소요 시간 설정 (seconds)</div>
              <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>기본 15초 (점령 횟수에 비례하여 가속 배가)</div>
            </div>
            <span style={{ fontSize: '0.9rem', fontFamily: 'monospace', fontWeight: 'bold' }}>15s</span>
          </div>

          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0.8rem', background: 'rgba(255,255,255,0.01)', borderRadius: '6px' }}>
            <div>
              <div style={{ fontSize: '0.85rem', fontWeight: 'bold' }}>위성 정밀 점령 쿨타임 (cooltime)</div>
              <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>기본 24시간 (로컬 SharedPreferences 캐싱 처리)</div>
            </div>
            <span style={{ fontSize: '0.9rem', fontFamily: 'monospace', fontWeight: 'bold' }}>24h</span>
          </div>
        </div>

        {/* 조작 버튼 */}
        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.8rem', marginTop: '1rem' }}>
          <button className="tactical-btn" onClick={loadSettings} disabled={saving}>
            <RefreshCw size={16} /> 새로고침
          </button>
          <button className="tactical-btn" onClick={handleSave} disabled={saving}>
            <Save size={16} /> {saving ? '저장 중...' : '설정 저장'}
          </button>
        </div>
      </div>
    </div>
  );
}
