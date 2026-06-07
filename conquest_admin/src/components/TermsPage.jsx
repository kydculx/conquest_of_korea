import React from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, Shield } from 'lucide-react';

export default function TermsPage() {
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
            <Shield size={18} style={{ color: '#3b82f6' }} />
            <span style={{ fontSize: '0.85rem', color: '#64748b', fontWeight: 600, fontFamily: 'var(--font-display)' }}>
              CONQUEST OF WORLD
            </span>
          </div>
        </div>

        {/* 본문 콘텐츠 */}
        <article className="tactical-card" style={{ background: '#111827', borderColor: '#1f2937', padding: '2.5rem', lineHeight: 1.7 }}>
          <h1 style={{ fontSize: '2rem', fontWeight: 800, marginBottom: '1.5rem', fontFamily: 'var(--font-display)' }}>
            서비스 이용약관
          </h1>
          <p style={{ color: '#94a3b8', fontSize: '0.9rem', marginBottom: '2rem' }}>
            시행일자: 2026년 6월 7일
          </p>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '1.8rem', fontSize: '0.95rem' }}>
            <section>
              <h3 style={{ fontSize: '1.15rem', color: '#3b82f6', marginBottom: '0.6rem' }}>제 1 조 (목적)</h3>
              <p style={{ color: '#d1d5db' }}>
                본 약관은 "Conquest of World" 프로젝트(이하 "회사" 또는 "서비스")가 제공하는 위치 기반 실시간 점령 모바일 게임 및 제반 서비스의 이용에 관한 조건 및 절차, 회사와 회원 간의 권리, 의무 및 책임 사항을 규정함을 목적으로 합니다.
              </p>
            </section>

            <section>
              <h3 style={{ fontSize: '1.15rem', color: '#3b82f6', marginBottom: '0.6rem' }}>제 2 조 (용어의 정의)</h3>
              <ul style={{ paddingLeft: '1.2rem', color: '#d1d5db', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                <li><strong>서비스:</strong> 이용자가 모바일 기기를 통해 접속하여 이용하는 "찜! 대모험" 게임 콘텐츠 전체를 의미합니다.</li>
                <li><strong>회원:</strong> 본 약관에 동의하고 서비스를 이용하는 고객을 의미합니다.</li>
                <li><strong>위치정보:</strong> 회원이 소지한 모바일 기기로부터 수집되는 위도, 경도 좌표 정보로, 타일 점령 처리를 위한 핵심 데이터를 의미합니다.</li>
              </ul>
            </section>

            <section>
              <h3 style={{ fontSize: '1.15rem', color: '#3b82f6', marginBottom: '0.6rem' }}>제 3 조 (위치기반 서비스의 제공)</h3>
              <p style={{ color: '#d1d5db' }}>
                본 서비스는 실시간 위치 정보에 기반한 영토 점령 메커니즘을 사용합니다. 회원의 실시간 GPS 정보에 기초하여 회원이 도달한 좌표 영역의 소유권을 기록하고 업데이트합니다. 원활한 서비스 이용을 위해 모바일 기기의 위치 서비스 설정 허용이 요구됩니다.
              </p>
            </section>

            <section>
              <h3 style={{ fontSize: '1.15rem', color: '#3b82f6', marginBottom: '0.6rem' }}>제 4 조 (이용자의 의무 및 비정상 이용 제한)</h3>
              <p style={{ color: '#d1d5db', marginBottom: '0.5rem' }}>
                회원은 서비스의 공정한 경쟁 환경을 저해하는 다음 행위를 하여서는 안 되며, 적발 시 사전 고지 없이 계정 이용 제한 및 영토 소유권 박탈 조치가 취해질 수 있습니다.
              </p>
              <ul style={{ paddingLeft: '1.2rem', color: '#fca5a5', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                <li>GPS 변조 프로그램(GPS Spoofing) 등을 사용하여 비정상적인 위치 좌표를 전송하는 행위</li>
                <li>타인의 개인정보 또는 기기식별 정보(UUID)를 무단으로 위조 및 복제하여 가입하는 행위</li>
                <li>서비스의 클라이언트 데이터 조작 및 버그를 악용하는 행위</li>
              </ul>
            </section>

            <section>
              <h3 style={{ fontSize: '1.15rem', color: '#3b82f6', marginBottom: '0.6rem' }}>제 5 조 (책임의 한계)</h3>
              <p style={{ color: '#d1d5db' }}>
                회사는 천재지변, 통신망 장애 또는 GPS 위성 신호 장애 등 불가항력적인 사유로 위치 확인 서비스 제공이 일시 중단되거나 지연되는 경우 책임을 지지 않습니다. 또한, 실제 현장 환경의 위험성을 충분히 인지하고 안전사고 예방의 모든 주의 의무는 이용자 본인에게 귀속됩니다.
              </p>
            </section>
          </div>
        </article>
      </div>
    </div>
  );
}
