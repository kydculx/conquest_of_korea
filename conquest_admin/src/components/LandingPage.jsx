import React from 'react';
import { useNavigate } from 'react-router-dom';
import {
  MapPin,
  Zap,
  Shield,
  Globe,
  Coins,
  Navigation
} from 'lucide-react';

export default function LandingPage() {
  const navigate = useNavigate();

  return (
    <div style={{
      backgroundColor: '#0b0f19',
      color: '#f8fafc',
      minHeight: '100vh',
      fontFamily: 'var(--font-main)',
      display: 'flex',
      flexDirection: 'column',
      position: 'relative',
      overflowX: 'hidden'
    }}>
      {/* 백그라운드 네온 오라 효과 */}
      <div style={{
        position: 'absolute',
        top: 0,
        left: '50%',
        transform: 'translateX(-50%)',
        width: '100vw',
        height: '600px',
        background: 'radial-gradient(circle at 50% 0%, rgba(59, 130, 246, 0.15) 0%, rgba(139, 92, 246, 0.05) 50%, transparent 100%)',
        pointerEvents: 'none',
        zIndex: 0
      }} />

      {/* 헤더 내비게이션 */}
      <header style={{
        position: 'relative',
        zIndex: 10,
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        padding: '1.5rem 2rem',
        maxWidth: '1200px',
        width: '100%',
        margin: '0 auto',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
          <MapPin size={26} style={{ color: '#3b82f6', filter: 'drop-shadow(0 0 8px rgba(59, 130, 246, 0.6))' }} />
          <span style={{
            fontFamily: 'var(--font-display)',
            fontWeight: 800,
            fontSize: '1.4rem',
            letterSpacing: '0.05em',
            background: 'linear-gradient(to right, #3b82f6, #8b5cf6)',
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent'
          }}>
            찜! 대모험
          </span>
        </div>
        <nav style={{ display: 'flex', alignItems: 'center', gap: '1.5rem' }}>
          <button
            onClick={() => navigate('/admin')}
            style={{
              background: 'rgba(255, 255, 255, 0.03)',
              border: '1px solid rgba(255, 255, 255, 0.08)',
              padding: '0.5rem 1rem',
              borderRadius: '20px',
              color: '#94a3b8',
              fontSize: '0.85rem',
              fontWeight: 600,
              cursor: 'pointer',
              transition: 'all 0.3s ease',
              display: 'flex',
              alignItems: 'center',
              gap: '0.4rem'
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
            <Shield size={14} />
            관리자 시스템
          </button>
        </nav>
      </header>

      {/* 히어로 섹션 */}
      <section style={{
        position: 'relative',
        zIndex: 5,
        maxWidth: '1200px',
        width: '100%',
        margin: '0 auto',
        padding: '4rem 2rem 6rem 2rem',
        display: 'grid',
        gridTemplateColumns: '1.2fr 0.8fr',
        gap: '4rem',
        alignItems: 'center',
      }} className="hero-grid">
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
          <div style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '0.5rem',
            background: 'rgba(59, 130, 246, 0.1)',
            border: '1px solid rgba(59, 130, 246, 0.2)',
            color: '#60a5fa',
            padding: '0.4rem 1rem',
            borderRadius: '30px',
            fontSize: '0.85rem',
            fontWeight: 700,
            width: 'fit-content'
          }}>
            <Zap size={14} /> Real-time Location Game
          </div>
          <h1 style={{
            fontSize: '3.5rem',
            fontWeight: 800,
            fontFamily: 'var(--font-display)',
            lineHeight: 1.15,
            letterSpacing: '-0.02em',
            margin: 0
          }}>
            세계 방방곡곡,<br />
            <span style={{
              background: 'linear-gradient(to right, #60a5fa, #a78bfa)',
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent'
            }}>내 영토로</span> 물들이다!
          </h1>
          <p style={{
            fontSize: '1.15rem',
            lineHeight: 1.6,
            color: '#94a3b8',
            maxWidth: '540px',
            margin: 0
          }}>
            '찜! 대모험'은 전 세계 실제 지도 기반의 실시간 점령 전술 게임입니다.
            내가 딛는 실제 발자국이 영토가 되고, 실시간 지도에서 다른 플레이어들과
            영토를 빼앗고 지키는 긴박한 전투를 경험하세요.
          </p>

          {/* 앱 다운로드 배지 시뮬레이션 */}
          <div style={{ display: 'flex', gap: '1rem', marginTop: '1.5rem', flexWrap: 'wrap', alignItems: 'center' }}>
            <a
              href="#googleplay"
              onClick={(e) => e.preventDefault()}
              style={{ display: 'inline-block', transition: 'transform 0.2s ease' }}
              onMouseEnter={(e) => e.currentTarget.style.transform = 'scale(1.04)'}
              onMouseLeave={(e) => e.currentTarget.style.transform = 'scale(1)'}
            >
              <img
                src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg"
                alt="Get it on Google Play"
                style={{ height: '48px', display: 'block' }}
              />
            </a>

            <a
              href="#appstore"
              onClick={(e) => e.preventDefault()}
              style={{ display: 'inline-block', transition: 'transform 0.2s ease' }}
              onMouseEnter={(e) => e.currentTarget.style.transform = 'scale(1.04)'}
              onMouseLeave={(e) => e.currentTarget.style.transform = 'scale(1)'}
            >
              <img
                src="https://upload.wikimedia.org/wikipedia/commons/3/3c/Download_on_the_App_Store_Badge.svg"
                alt="Download on the App Store"
                style={{ height: '48px', display: 'block' }}
              />
            </a>
          </div>
        </div>

        {/* 폰 목업 디자인 */}
        <div style={{
          display: 'flex',
          justifyContent: 'center',
          position: 'relative'
        }} className="hero-mockup">
          {/* 오라 글로우 배경 */}
          <div style={{
            position: 'absolute',
            width: '300px',
            height: '300px',
            background: 'radial-gradient(circle, rgba(96, 165, 250, 0.2) 0%, transparent 70%)',
            zIndex: 1,
            pointerEvents: 'none'
          }} />

          {/* 목업 기기 외관 */}
          <div style={{
            width: '280px',
            height: '560px',
            borderRadius: '40px',
            border: '8px solid #334155',
            backgroundColor: '#090d16',
            boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.7), 0 0 30px rgba(59, 130, 246, 0.2)',
            position: 'relative',
            overflow: 'hidden',
            zIndex: 2,
            display: 'flex',
            flexDirection: 'column'
          }}>
            {/* 노치 */}
            <div style={{
              width: '120px',
              height: '22px',
              backgroundColor: '#334155',
              borderRadius: '0 0 15px 15px',
              position: 'absolute',
              top: 0,
              left: '50%',
              transform: 'translateX(-50%)',
              zIndex: 10
            }} />

            {/* 인게임 화면 실제 렌더링 */}
            <div style={{
              flex: 1,
              position: 'relative',
              background: '#090d16',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center'
            }}>
              <img
                src="/game_screen.png"
                alt="Conquest Ingame Screen"
                style={{
                  width: '100%',
                  height: '100%',
                  objectFit: 'cover'
                }}
              />
            </div>
          </div>
        </div>
      </section>


      {/* 게임 기능 소개 섹션 */}
      <section style={{
        background: '#0e1322',
        borderTop: '1px solid #1e293b',
        borderBottom: '1px solid #1e293b',
        padding: '5rem 2rem',
      }}>
        <div style={{ maxWidth: '1200px', width: '100%', margin: '0 auto' }}>
          <div style={{ textAlign: 'center', marginBottom: '4rem' }}>
            <h2 style={{
              fontSize: '2.2rem',
              fontWeight: 800,
              fontFamily: 'var(--font-display)',
              marginBottom: '1rem'
            }}>
              주요 게임 기능
            </h2>
            <p style={{ color: '#94a3b8', fontSize: '1.05rem', maxWidth: '600px', margin: '0 auto' }}>
              전 세계 실제 지도 위에서 나만의 영토를 구축하세요.
              실시간 전술 플레이와 전략 자원 관리로 세계 최정상 랭킹에 오를 수 있습니다.
            </p>
          </div>

          <div style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))',
            gap: '2rem'
          }}>
            {/* 카드 1 */}
            <div className="tactical-card" style={{ display: 'flex', flexDirection: 'column', gap: '1rem', background: '#161d30' }}>
              <div style={{
                width: '44px',
                height: '44px',
                borderRadius: '10px',
                background: 'rgba(59, 130, 246, 0.15)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#60a5fa'
              }}>
                <MapPin size={22} />
              </div>
              <h3 style={{ fontSize: '1.25rem', fontWeight: 700 }}>실시간 지도 점령</h3>
              <p style={{ color: '#94a3b8', fontSize: '0.9rem', lineHeight: 1.6, margin: 0 }}>
                실제 지도 시스템과 연동되어 내가 서 있는 장소를 즉각 내 땅으로 점령합니다. 내 발자국이 지도를 뒤덮는 재미를 느껴보세요.
              </p>
            </div>

            {/* 카드 2 */}
            <div className="tactical-card" style={{ display: 'flex', flexDirection: 'column', gap: '1rem', background: '#161d30' }}>
              <div style={{
                width: '44px',
                height: '44px',
                borderRadius: '10px',
                background: 'rgba(167, 139, 250, 0.15)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#a78bfa'
              }}>
                <Globe size={22} />
              </div>
              <h3 style={{ fontSize: '1.25rem', fontWeight: 700 }}>글로벌 영토 확장</h3>
              <p style={{ color: '#94a3b8', fontSize: '0.9rem', lineHeight: 1.6, margin: 0 }}>
                전 세계 플레이어들과 실시간으로 땅을 뺏고 빼앗기는 점령전이 벌어집니다. 방어선을 구축하고 아군 영역을 굳건히 지키십시오.
              </p>
            </div>

            {/* 카드 3 */}
            <div className="tactical-card" style={{ display: 'flex', flexDirection: 'column', gap: '1rem', background: '#161d30' }}>
              <div style={{
                width: '44px',
                height: '44px',
                borderRadius: '10px',
                background: 'rgba(251, 191, 36, 0.15)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#fbbf24'
              }}>
                <Coins size={22} />
              </div>
              <h3 style={{ fontSize: '1.25rem', fontWeight: 700 }}>점령 경제와 자원 전략</h3>
              <p style={{ color: '#94a3b8', fontSize: '0.9rem', lineHeight: 1.6, margin: 0 }}>
                소유한 영토의 가치에 따라 골드가 계속 누적됩니다. 모은 자원을 효율적으로 투자해 한 차원 높은 영역을 지배할 수 있습니다.
              </p>
            </div>

            {/* 카드 4 */}
            <div className="tactical-card" style={{ display: 'flex', flexDirection: 'column', gap: '1rem', background: '#161d30' }}>
              <div style={{
                width: '44px',
                height: '44px',
                borderRadius: '10px',
                background: 'rgba(239, 68, 68, 0.15)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#ef4444'
              }}>
                <Navigation size={22} style={{ transform: 'rotate(45deg)' }} />
              </div>
              <h3 style={{ fontSize: '1.25rem', fontWeight: 700 }}>원격 타일 점령</h3>
              <p style={{ color: '#94a3b8', fontSize: '0.9rem', lineHeight: 1.6, margin: 0 }}>
                직접 방문하지 않고도 게임에서 획득한 골드를 사용해 원거리 타일을 즉각 지배할 수 있습니다. 전술의 기동성과 커버리지를 대폭 확장해 보세요.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* 푸터 영역 */}
      <footer style={{
        marginTop: 'auto',
        borderTop: '1px solid #1e293b',
        padding: '3rem 2rem',
        background: '#0b0f19'
      }}>
        <div style={{
          maxWidth: '1200px',
          width: '100%',
          margin: '0 auto',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '1.5rem'
        }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.6rem' }}>
              <MapPin size={20} style={{ color: '#3b82f6' }} />
              <span style={{ fontWeight: 800, fontSize: '1.1rem', fontFamily: 'var(--font-display)' }}>찜! 대모험</span>
            </div>
            <p style={{ fontSize: '0.8rem', color: '#64748b', margin: 0 }}>
              &copy; {new Date().getFullYear()} 찜! 대모험 Project. All rights reserved.
            </p>
          </div>
          <div style={{ display: 'flex', gap: '1.5rem', flexWrap: 'wrap' }}>
            <span
              onClick={() => navigate('/terms')}
              style={{
                fontSize: '0.85rem',
                color: '#64748b',
                cursor: 'pointer',
                transition: 'color 0.2s ease',
              }}
              onMouseEnter={(e) => e.currentTarget.style.color = '#3b82f6'}
              onMouseLeave={(e) => e.currentTarget.style.color = '#64748b'}
            >
              서비스 이용약관
            </span>
            <span
              onClick={() => navigate('/privacy')}
              style={{
                fontSize: '0.85rem',
                color: '#64748b',
                cursor: 'pointer',
                transition: 'color 0.2s ease',
              }}
              onMouseEnter={(e) => e.currentTarget.style.color = '#3b82f6'}
              onMouseLeave={(e) => e.currentTarget.style.color = '#64748b'}
            >
              개인정보 처리방침
            </span>
            <span
              onClick={() => navigate('/admin')}
              style={{
                fontSize: '0.85rem',
                color: '#64748b',
                cursor: 'pointer',
                transition: 'color 0.2s ease',
              }}
              onMouseEnter={(e) => e.currentTarget.style.color = '#3b82f6'}
              onMouseLeave={(e) => e.currentTarget.style.color = '#64748b'}
            >
              어드민 게이트웨이
            </span>
          </div>
        </div>
      </footer>

      {/* 애니메이션용 가상 스타일 태그 삽입 */}
      <style dangerouslySetInnerHTML={{
        __html: `
        @keyframes pulseGlow {
          0% { transform: scale(0.9); opacity: 0.2; }
          50% { opacity: 0.6; }
          100% { transform: scale(1.3); opacity: 0; }
        }
        @keyframes pulseGlowReverse {
          0% { transform: scale(1.2); opacity: 0.1; }
          50% { opacity: 0.5; }
          100% { transform: scale(0.8); opacity: 0; }
        }
        @media (max-width: 768px) {
          .hero-grid {
            grid-template-columns: 1fr !important;
            text-align: center;
            padding: 2rem 1rem 4rem 1rem !important;
            gap: 2rem !important;
          }
          .hero-grid div {
            align-items: center !important;
          }
          .hero-grid h1 {
            font-size: 2.3rem !important;
          }
          .hero-grid p {
            max-width: 100% !important;
          }
          .hero-mockup {
            margin-top: 2rem;
          }
        }
      `}} />
    </div>
  );
}
