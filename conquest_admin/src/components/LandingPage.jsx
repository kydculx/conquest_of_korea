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
    <div className="premium-landing-root">
      {/* 구글 폰트 로드 및 글로벌 스타일 정의 */}
      <link rel="preconnect" href="https://fonts.googleapis.com" />
      <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="true" />
      <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;800&family=Plus+Jakarta+Sans:wght@300;400;600;700&display=swap" rel="stylesheet" />

      {/* 백그라운드 빛무리 오라 데코레이션 */}
      <div className="bg-glow-orb orb-1" />
      <div className="bg-glow-orb orb-2" />
      <div className="bg-glow-orb orb-3" />

      {/* 헤더 */}
      <header className="glass-header">
        <div className="header-container">
          <div className="logo-group">
            <div className="logo-glow-icon" style={{ display: 'flex', alignItems: 'center' }}>
              <img src="/app_icon.png" alt="Logo" style={{ width: '32px', height: '32px', objectFit: 'contain', borderRadius: '6px' }} />
            </div>
            <span className="logo-text">찜! 대모험</span>
          </div>
          <button onClick={() => navigate('/admin')} className="admin-gate-btn">
            <Shield size={14} />
            <span>어드민 시스템</span>
          </button>
        </div>
      </header>

      {/* 히어로 섹션 */}
      <section className="hero-section">
        <div className="hero-content">
          <div className="tag-badge animate-fade-in">
            <Zap size={14} className="glow-icon" />
            <span>실시간 실제 지도 기반 영토 점령</span>
          </div>
          <h1 className="hero-title animate-slide-up">
            지루했던 일상을<br />
            <span className="gradient-text">나만의 전장</span>으로!
          </h1>
          <p className="hero-desc animate-slide-up-delay">
            '찜! 대모험'은 GPS를 이용해 실제 전 세계 지도를 무대로 영토를 넓혀가는 위치 기반 전술 게임입니다. 
            단순히 바라보기만 하는 맵이 아닙니다. 당신의 모든 발걸음, 조깅, 여행이 곧 실시간 전술 기동이자 정복의 흔적이 됩니다.
          </p>

          <div className="download-badges animate-slide-up-delay-2">
            <a href="#googleplay" onClick={(e) => e.preventDefault()} className="badge-link">
              <img
                src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg"
                alt="Get it on Google Play"
                className="badge-img"
              />
            </a>
            <a href="#appstore" onClick={(e) => e.preventDefault()} className="badge-link">
              <img
                src="https://upload.wikimedia.org/wikipedia/commons/3/3c/Download_on_the_App_Store_Badge.svg"
                alt="Download on the App Store"
                className="badge-img"
              />
            </a>
          </div>
        </div>

        {/* 폰 목업 */}
        <div className="hero-mockup-container">
          <div className="glow-ring-decoration" />
          <div className="phone-mockup">
            <div className="phone-notch" />
            <div className="phone-screen-inner">
              <img
                src="/game_screen.png"
                alt="Game Screen"
                className="screen-shot-img"
              />
            </div>
          </div>
        </div>
      </section>

      {/* 라이프스타일 유스케이스 섹션 */}
      <section className="features-section">
        <div className="features-header">
          <h2 className="section-title">일상 속에서 시작되는 영토 정복</h2>
          <p className="section-subtitle">
            러닝, 출퇴근, 여행, 동네 산책까지. 일상적인 모든 움직임이 흥미진진한 전술 라이프스타일로 변화합니다.
          </p>
        </div>

        <div className="features-grid">
          {/* 카드 1: 러닝 */}
          <div className="feature-premium-card card-running">
            <div className="card-icon-wrapper red">
              <Zap size={22} />
            </div>
            <h3 className="card-heading">🏃‍♂️ 러닝 & 조깅 페이스메이커</h3>
            <p className="card-body-text">
              매일 똑같은 코스를 달리는 지루한 운동 시간은 끝났습니다. 내가 딛고 올라선 모든 미터가 실시간으로 영토로 전환됩니다. 영토 점령 페이스와 랭킹을 모니터링하며 완벽한 운동 동기를 부여받으세요.
            </p>
          </div>

          {/* 카드 2: 출퇴근 */}
          <div className="feature-premium-card card-bus">
            <div className="card-icon-wrapper cyan">
              <Navigation size={22} style={{ transform: 'rotate(45deg)' }} />
            </div>
            <h3 className="card-heading">🚌 출퇴근길을 나만의 정찰로</h3>
            <p className="card-body-text">
              매일 타는 버스와 전철 노선이 강력한 영토 정찰 루트로 거듭납니다. 백그라운드 모드를 가동해 주머니에 넣어두기만 하면 지나치는 대중교통 경로에 맞춰 점령 구역이 자동으로 칠해집니다.
            </p>
          </div>

          {/* 카드 3: 여행 */}
          <div className="feature-premium-card card-travel">
            <div className="card-icon-wrapper blue">
              <Globe size={22} />
            </div>
            <h3 className="card-heading">🚗 여행과 드라이브의 흔적 소유</h3>
            <p className="card-body-text">
              새로운 휴양지로 떠나거나 고속도로 드라이브를 나설 때, 내가 다녀간 여정을 영토로 굳건히 소유해 보세요. 낯선 여행지에 나만의 본진 깃발을 꽂고 정복 랜드마크를 완성하는 소장 가치를 느껴보세요.
            </p>
          </div>

          {/* 카드 4: 산책 */}
          <div className="feature-premium-card card-walk">
            <div className="card-icon-wrapper gold">
              <Coins size={22} />
            </div>
            <h3 className="card-heading">🪙 골목 산책의 보물찾기 재미</h3>
            <p className="card-body-text">
              단순한 걷기가 입체적인 보물찾기 모험으로 바뀝니다. 매일 본진 기지 주변 영역에 임의로 출현하는 골드 자원 노드를 획득하기 위해 이전에 가보지 않았던 동네의 좁고 낯선 골목길을 새로이 개척하고 탐색해보세요.
            </p>
          </div>

          {/* 카드 5: 원격 점령 */}
          <div className="feature-premium-card card-remote">
            <div className="card-icon-wrapper purple">
              <MapPin size={22} />
            </div>
            <h3 className="card-heading">🛋️ 집콕이나 날씨가 나쁠 때의 원격 점령</h3>
            <p className="card-body-text">
              폭우가 쏟아지거나 부상·피로로 집 밖을 나설 수 없는 날에도 점령은 멈추지 않습니다. 또는 강 너머, 사유지 등 직접 걸어서 진입할 수 없는 지형적 한계 구역도 그동안 비축한 골드를 사용해 방에 누워서 손끝 하나로 원격 점령하여 철벽 방어선을 완성해 보세요.
            </p>
          </div>
        </div>
      </section>

      {/* 푸터 */}
      <footer className="premium-footer">
        <div className="footer-container">
          <div className="footer-brand">
            <div className="logo-group">
              <img src="/app_icon.png" alt="Logo" style={{ width: '24px', height: '24px', objectFit: 'contain', borderRadius: '4px' }} />
              <span className="brand-title">찜! 대모험</span>
            </div>
            <p className="copy-text">
              &copy; {new Date().getFullYear()} 찜! 대모험 Project. All rights reserved.
            </p>
          </div>
          <div className="footer-links">
            <span onClick={() => navigate('/terms')} className="footer-link">서비스 이용약관</span>
            <span onClick={() => navigate('/privacy')} className="footer-link">개인정보 처리방침</span>
          </div>
        </div>
      </footer>

      {/* 스타일 태그 */}
      <style dangerouslySetInnerHTML={{
        __html: `
        /* 프리미엄 리셋 및 베이스 */
        .premium-landing-root {
          background-color: #060913;
          color: #f1f5f9;
          font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          min-height: 100vh;
          position: relative;
          overflow-x: hidden;
          line-height: 1.5;
        }

        /* 구글 폰트 적용 */
        .logo-text, .hero-title, .section-title, .card-heading {
          font-family: 'Outfit', sans-serif;
        }

        /* 백그라운드 오라 빛무리 */
        .bg-glow-orb {
          position: absolute;
          border-radius: 50%;
          pointer-events: none;
          filter: blur(140px);
          opacity: 0.15;
          z-index: 0;
        }
        .orb-1 {
          width: 500px;
          height: 500px;
          background: radial-gradient(circle, #3b82f6 0%, transparent 80%);
          top: -100px;
          left: 20%;
        }
        .orb-2 {
          width: 600px;
          height: 600px;
          background: radial-gradient(circle, #8b5cf6 0%, transparent 80%);
          top: 30%;
          right: -100px;
        }
        .orb-3 {
          width: 400px;
          height: 400px;
          background: radial-gradient(circle, #10b981 0%, transparent 80%);
          bottom: 10%;
          left: -50px;
        }

        /* 글래스 헤더 */
        .glass-header {
          position: sticky;
          top: 0;
          z-index: 100;
          background: rgba(6, 9, 19, 0.7);
          backdrop-filter: blur(12px);
          -webkit-backdrop-filter: blur(12px);
          border-bottom: 1px solid rgba(255, 255, 255, 0.04);
        }
        .header-container {
          max-width: 1200px;
          margin: 0 auto;
          padding: 1.2rem 2rem;
          display: flex;
          justify-content: space-between;
          align-items: center;
        }
        .logo-group {
          display: flex;
          align-items: center;
          gap: 0.6rem;
        }
        .logo-glow-icon {
          color: #3b82f6;
          display: flex;
          align-items: center;
          justify-content: center;
          filter: drop-shadow(0 0 10px rgba(59, 130, 246, 0.8));
          animation: logoFloat 3s ease-in-out infinite alternate;
        }
        .logo-text {
          font-weight: 800;
          font-size: 1.4rem;
          letter-spacing: 0.02em;
          background: linear-gradient(135deg, #60a5fa, #a78bfa);
          WebkitBackgroundClip: text;
          WebkitTextFillColor: transparent;
        }
        .admin-gate-btn {
          background: rgba(255, 255, 255, 0.03);
          border: 1px solid rgba(255, 255, 255, 0.06);
          padding: 0.6rem 1.2rem;
          border-radius: 24px;
          color: #94a3b8;
          font-size: 0.85rem;
          font-weight: 600;
          cursor: pointer;
          transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
          display: flex;
          align-items: center;
          gap: 0.5rem;
        }
        .admin-gate-btn:hover {
          background: rgba(59, 130, 246, 0.1);
          border-color: rgba(59, 130, 246, 0.3);
          color: #60a5fa;
          box-shadow: 0 0 15px rgba(59, 130, 246, 0.25);
          transform: translateY(-2px);
        }

        /* 히어로 섹션 */
        .hero-section {
          position: relative;
          z-index: 10;
          max-width: 1200px;
          width: 100%;
          margin: 0 auto;
          padding: 6rem 2rem 8rem 2rem;
          display: grid;
          grid-template-columns: 1.25fr 0.75fr;
          gap: 4rem;
          align-items: center;
        }
        .tag-badge {
          display: inline-flex;
          align-items: center;
          gap: 0.5rem;
          background: rgba(59, 130, 246, 0.08);
          border: 1px solid rgba(59, 130, 246, 0.15);
          color: #60a5fa;
          padding: 0.5rem 1.1rem;
          border-radius: 30px;
          font-size: 0.85rem;
          font-weight: 700;
          width: fit-content;
          margin-bottom: 1.5rem;
          box-shadow: inset 0 0 8px rgba(59, 130, 246, 0.1);
        }
        .glow-icon {
          animation: pulseGlowIcon 1.5s infinite alternate;
        }
        .hero-title {
          font-size: 4rem;
          font-weight: 800;
          line-height: 1.12;
          letter-spacing: -0.03em;
          margin: 0 0 1.5rem 0;
        }
        .gradient-text {
          background: linear-gradient(135deg, #3b82f6 30%, #8b5cf6 70%, #10b981 100%);
          WebkitBackgroundClip: text;
          WebkitTextFillColor: transparent;
          filter: drop-shadow(0 2px 20px rgba(59, 130, 246, 0.15));
        }
        .hero-desc {
          font-size: 1.2rem;
          line-height: 1.7;
          color: #94a3b8;
          max-width: 580px;
          margin: 0 0 2.5rem 0;
        }
        .download-badges {
          display: flex;
          gap: 1.2rem;
          align-items: center;
        }
        .badge-link {
          transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }
        .badge-link:hover {
          transform: translateY(-4px) scale(1.02);
          filter: drop-shadow(0 8px 20px rgba(0, 0, 0, 0.5));
        }
        .badge-img {
          height: 52px;
          display: block;
        }

        /* 폰 목업 */
        .hero-mockup-container {
          display: flex;
          justify-content: center;
          position: relative;
        }
        .glow-ring-decoration {
          position: absolute;
          width: 380px;
          height: 380px;
          border: 1px dashed rgba(59, 130, 246, 0.3);
          border-radius: 50%;
          z-index: 1;
          pointer-events: none;
          animation: rotateRing 30s linear infinite;
          top: 50%;
          left: 50%;
          transform: translate(-50%, -50%);
        }
        .phone-mockup {
          width: 290px;
          height: 580px;
          border-radius: 44px;
          border: 9px solid #1e293b;
          background-color: #0b0f19;
          box-shadow: 0 30px 60px -15px rgba(0, 0, 0, 0.8), 
                      0 0 50px rgba(59, 130, 246, 0.15),
                      inset 0 0 10px rgba(255, 255, 255, 0.05);
          position: relative;
          overflow: hidden;
          z-index: 2;
          display: flex;
          flex-direction: column;
          transform: perspective(1000px) rotateY(-5deg) rotateX(5deg);
          transition: transform 0.6s cubic-bezier(0.4, 0, 0.2, 1);
        }
        .phone-mockup:hover {
          transform: perspective(1000px) rotateY(0deg) rotateX(0deg) translateY(-8px);
          box-shadow: 0 35px 70px -10px rgba(0, 0, 0, 0.9), 
                      0 0 60px rgba(59, 130, 246, 0.25);
        }
        .phone-notch {
          width: 130px;
          height: 24px;
          background-color: #1e293b;
          border-radius: 0 0 16px 16px;
          position: absolute;
          top: 0;
          left: 50%;
          transform: translateX(-50%);
          z-index: 10;
        }
        .phone-screen-inner {
          flex: 1;
          position: relative;
          background: #090d16;
        }
        .screen-shot-img {
          width: 100%;
          height: 100%;
          object-fit: cover;
        }

        /* 주요 기능 섹션 */
        .features-section {
          position: relative;
          z-index: 10;
          background: linear-gradient(to bottom, #090d16 0%, #060913 100%);
          border-top: 1px solid rgba(255, 255, 255, 0.03);
          border-bottom: 1px solid rgba(255, 255, 255, 0.03);
          padding: 8rem 2rem;
        }
        .features-header {
          text-align: center;
          margin-bottom: 5rem;
        }
        .section-title {
          font-size: 2.6rem;
          font-weight: 800;
          margin-bottom: 1.2rem;
          letter-spacing: -0.02em;
        }
        .section-subtitle {
          color: #94a3b8;
          font-size: 1.1rem;
          max-width: 650px;
          margin: 0 auto;
          line-height: 1.6;
        }
        .features-grid {
          max-width: 1200px;
          margin: 0 auto;
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
          gap: 2.5rem;
        }
        
        /* 프리미엄 카드 디자인 */
        .feature-premium-card {
          background: rgba(30, 41, 59, 0.25);
          border: 1px solid rgba(255, 255, 255, 0.04);
          border-radius: 20px;
          padding: 2.5rem;
          display: flex;
          flex-direction: column;
          gap: 1.2rem;
          box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
          backdrop-filter: blur(10px);
          -webkit-backdrop-filter: blur(10px);
          transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
          position: relative;
          overflow: hidden;
        }
        .feature-premium-card::before {
          content: '';
          position: absolute;
          top: 0;
          left: 0;
          width: 100%;
          height: 100%;
          background: linear-gradient(135deg, rgba(255,255,255,0.05) 0%, transparent 100%);
          pointer-events: none;
          z-index: 1;
        }
        .feature-premium-card:hover {
          transform: translateY(-8px);
          border-color: rgba(255, 255, 255, 0.1);
          box-shadow: 0 20px 40px rgba(0, 0, 0, 0.4);
        }

        /* 개별 호버 효과 틴트 */
        .feature-premium-card.card-running:hover {
          box-shadow: 0 20px 40px rgba(239, 68, 68, 0.1);
          border-color: rgba(239, 68, 68, 0.25);
        }
        .feature-premium-card.card-bus:hover {
          box-shadow: 0 20px 40px rgba(6, 182, 212, 0.1);
          border-color: rgba(6, 182, 212, 0.25);
        }
        .feature-premium-card.card-travel:hover {
          box-shadow: 0 20px 40px rgba(59, 130, 246, 0.1);
          border-color: rgba(59, 130, 246, 0.25);
        }
        .feature-premium-card.card-walk:hover {
          box-shadow: 0 20px 40px rgba(251, 191, 36, 0.1);
          border-color: rgba(251, 191, 36, 0.25);
        }
        .feature-premium-card.card-remote:hover {
          box-shadow: 0 20px 40px rgba(167, 139, 250, 0.1);
          border-color: rgba(167, 139, 250, 0.25);
        }

        .card-icon-wrapper {
          width: 48px;
          height: 48px;
          border-radius: 14px;
          display: flex;
          align-items: center;
          justify-content: center;
          font-weight: bold;
        }
        .card-icon-wrapper.red {
          background: rgba(239, 68, 68, 0.12);
          color: #ef4444;
          border: 1px solid rgba(239, 68, 68, 0.2);
        }
        .card-icon-wrapper.cyan {
          background: rgba(6, 182, 212, 0.12);
          color: #06b6d4;
          border: 1px solid rgba(6, 182, 212, 0.2);
        }
        .card-icon-wrapper.blue {
          background: rgba(59, 130, 246, 0.12);
          color: #3b82f6;
          border: 1px solid rgba(59, 130, 246, 0.2);
        }
        .card-icon-wrapper.gold {
          background: rgba(251, 191, 36, 0.12);
          color: #fbbf24;
          border: 1px solid rgba(251, 191, 36, 0.2);
        }
        .card-icon-wrapper.purple {
          background: rgba(167, 139, 250, 0.12);
          color: #a78bfa;
          border: 1px solid rgba(167, 139, 250, 0.2);
        }

        .card-heading {
          font-size: 1.3rem;
          font-weight: 700;
          margin: 0;
          color: #f8fafc;
        }
        .card-body-text {
          color: #94a3b8;
          font-size: 0.95rem;
          line-height: 1.65;
          margin: 0;
        }

        /* 푸터 */
        .premium-footer {
          border-top: 1px solid rgba(255, 255, 255, 0.04);
          padding: 4rem 2rem;
          background: #04060d;
          position: relative;
          z-index: 10;
        }
        .footer-container {
          max-width: 1200px;
          margin: 0 auto;
          display: flex;
          justify-content: space-between;
          align-items: center;
          flex-wrap: wrap;
          gap: 2rem;
        }
        .brand-title {
          font-weight: 800;
          font-size: 1.2rem;
        }
        .copy-text {
          font-size: 0.85rem;
          color: #475569;
          margin: 0.5rem 0 0 0;
        }
        .footer-links {
          display: flex;
          gap: 2rem;
          flex-wrap: wrap;
        }
        .footer-link {
          font-size: 0.88rem;
          color: #64748b;
          cursor: pointer;
          transition: all 0.2s ease;
        }
        .footer-link:hover {
          color: #60a5fa;
        }

        /* 키프레임 애니메이션 */
        @keyframes logoFloat {
          0% { transform: translateY(0); }
          100% { transform: translateY(-4px); }
        }
        @keyframes rotateRing {
          0% { transform: translate(-50%, -50%) rotate(0deg); }
          100% { transform: translate(-50%, -50%) rotate(360deg); }
        }
        @keyframes pulseGlowIcon {
          0% { transform: scale(1); filter: drop-shadow(0 0 2px rgba(96, 165, 250, 0.4)); }
          100% { transform: scale(1.1); filter: drop-shadow(0 0 8px rgba(96, 165, 250, 0.8)); }
        }
        
        .animate-fade-in {
          animation: fadeIn 0.8s ease-out forwards;
        }
        .animate-slide-up {
          animation: slideUp 0.8s cubic-bezier(0.2, 0.8, 0.2, 1) forwards;
        }
        .animate-slide-up-delay {
          opacity: 0;
          animation: slideUp 0.8s cubic-bezier(0.2, 0.8, 0.2, 1) 0.2s forwards;
        }
        .animate-slide-up-delay-2 {
          opacity: 0;
          animation: slideUp 0.8s cubic-bezier(0.2, 0.8, 0.2, 1) 0.4s forwards;
        }

        @keyframes fadeIn {
          from { opacity: 0; }
          to { opacity: 1; }
        }
        @keyframes slideUp {
          from { opacity: 0; transform: translateY(20px); }
          to { opacity: 1; transform: translateY(0); }
        }

        /* 모바일 반응형 대응 */
        @media (max-width: 968px) {
          .hero-section {
            grid-template-columns: 1fr;
            text-align: center;
            padding: 4rem 1.5rem 6rem 1.5rem;
            gap: 3.5rem;
          }
          .tag-badge {
            margin-left: auto;
            margin-right: auto;
          }
          .hero-title {
            font-size: 2.8rem;
          }
          .hero-desc {
            max-width: 100%;
          }
          .download-badges {
            justify-content: center;
          }
          .phone-mockup {
            transform: none !important;
          }
          .glow-ring-decoration {
            width: 320px;
            height: 320px;
          }
          .section-title {
            font-size: 2.1rem;
          }
        }
      `}} />
    </div>
  );
}
