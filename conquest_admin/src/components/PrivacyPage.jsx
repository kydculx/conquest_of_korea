import React from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, Shield } from 'lucide-react';

export default function PrivacyPage() {
  const navigate = useNavigate();

  return (
    <div style={{
      backgroundColor: '#0b0f19',
      color: '#f8fafc',
      minHeight: '100vh',
      fontFamily: 'var(--font-main)',
      display: 'flex',
      flexDirection: 'column',
      padding: '2rem 1rem'
    }}>
      <div style={{ maxWidth: '800px', width: '100%', margin: '0 auto' }}>
        {/* 상단 네비게이션 */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '3rem' }}>
          <button 
            onClick={() => navigate('/')}
            style={{
              background: 'rgba(255, 255, 255, 0.03)',
              border: '1px solid rgba(255, 255, 255, 0.08)',
              padding: '0.6rem 1.2rem',
              borderRadius: '20px',
              color: '#94a3b8',
              fontSize: '0.85rem',
              fontWeight: 600,
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '0.5rem',
              transition: 'all 0.2s ease'
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.background = 'rgba(255, 255, 255, 0.08)';
              e.currentTarget.style.color = '#f8fafc';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.background = 'rgba(255, 255, 255, 0.03)';
              e.currentTarget.style.color = '#94a3b8';
            }}
          >
            <ArrowLeft size={16} />
            홈으로 이동
          </button>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <Shield size={18} style={{ color: '#8b5cf6' }} />
            <span style={{ fontSize: '0.85rem', color: '#64748b', fontWeight: 600, fontFamily: 'var(--font-display)' }}>
              CONQUEST OF WORLD
            </span>
          </div>
        </div>

        {/* 본문 콘텐츠 */}
        <article className="tactical-card" style={{ background: '#111827', borderColor: '#1f2937', padding: '2.5rem', lineHeight: 1.7 }}>
          <h1 style={{ fontSize: '2rem', fontWeight: 800, marginBottom: '1.5rem', fontFamily: 'var(--font-display)' }}>
            개인정보 처리방침
          </h1>
          <p style={{ color: '#94a3b8', fontSize: '0.9rem', marginBottom: '2rem' }}>
            시행일자: 2026년 6월 7일
          </p>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '1.8rem', fontSize: '0.95rem' }}>
            <section>
              <h3 style={{ fontSize: '1.15rem', color: '#8b5cf6', marginBottom: '0.6rem' }}>1. 개인정보의 수집 항목</h3>
              <p style={{ color: '#d1d5db', marginBottom: '0.5rem' }}>
                서비스는 회원의 가입 및 영토 점령 처리, 원활한 서비스 제공을 위해 아래와 같은 정보를 수집하고 있습니다.
              </p>
              <ul style={{ paddingLeft: '1.2rem', color: '#d1d5db', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                <li><strong>필수 수집 정보:</strong> 모바일 기기 식별정보(UUID), 사용자 프로필 닉네임</li>
                <li><strong>위치 정보:</strong> 실시간 지도 기반 타일 점령 처리를 위한 회원의 단말기 GPS 위경도 정보</li>
                <li><strong>자동 생성 수집 정보:</strong> 서비스 이용 기록, 접속 로그, 쿠키, 기기 OS 버전 정보</li>
              </ul>
            </section>

            <section>
              <h3 style={{ fontSize: '1.15rem', color: '#8b5cf6', marginBottom: '0.6rem' }}>2. 개인정보의 이용 목적</h3>
              <ul style={{ paddingLeft: '1.2rem', color: '#d1d5db', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                <li><strong>영토 지배 연산:</strong> 사용자 GPS 위치를 기준으로 해당 타일 영역의 점령 처리 수행</li>
                <li><strong>순위 및 스탯 연산:</strong> 점령 랭킹 계산 및 인게임 재화(골드) 상태 동기화</li>
                <li><strong>보안 및 시스템 제어:</strong> 불법 GPS 조작 등 어뷰징 회원 탐지 및 비정상 접근 제어</li>
                <li><strong>알림 발송:</strong> Firebase Cloud Messaging을 통한 실시간 영토 피침공 푸시 알림 제공</li>
              </ul>
            </section>

            <section>
              <h3 style={{ fontSize: '1.15rem', color: '#8b5cf6', marginBottom: '0.6rem' }}>3. 개인정보의 보유 및 파기</h3>
              <p style={{ color: '#d1d5db' }}>
                회원의 개인정보는 회원 탈퇴 요청 시 또는 수집 및 이용목적이 달성된 후 지체 없이 파기하는 것을 원칙으로 합니다. 단, 불법 이용자의 재가입 및 악용 방지를 위해 일부 식별값은 탈퇴 후 최대 6개월 동안 보안 목적으로 암호화하여 보관할 수 있습니다.
              </p>
            </section>

            <section>
              <h3 style={{ fontSize: '1.15rem', color: '#8b5cf6', marginBottom: '0.6rem' }}>4. 개인정보의 제3자 제공 및 위탁</h3>
              <p style={{ color: '#d1d5db', marginBottom: '0.5rem' }}>
                서비스는 원활한 서버 데이터 처리 및 푸시 통신을 위해 신뢰할 수 있는 다음 플랫폼에 정보를 위탁하여 처리하고 있습니다.
              </p>
              <ul style={{ paddingLeft: '1.2rem', color: '#d1d5db', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                <li><strong>Supabase:</strong> 실시간 게임 데이터베이스 및 계정 정보 처리 위탁</li>
                <li><strong>Firebase Cloud Messaging (Google LLC):</strong> 실시간 푸시 서비스 전송 위탁</li>
              </ul>
            </section>
          </div>
        </article>
      </div>
    </div>
  );
}
