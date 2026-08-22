import React from 'react';
import { useNavigate } from 'react-router-dom';
import {
  MapPin,
  Zap,
  Shield,
  Coins,
  Navigation,
  Palette,
  Camera,
  Smartphone,
  Sparkles
} from 'lucide-react';

export default function LandingPage() {
  const navigate = useNavigate();
  const [currentImageIndex, setCurrentImageIndex] = React.useState(0);
  const screenshots = [
    '/screenshot_splash.jpg',
    '/screenshot_satellite.jpg',
    '/screenshot_neon.jpg'
  ];

  React.useEffect(() => {
    const timer = setInterval(() => {
      setCurrentImageIndex((prev) => (prev + 1) % screenshots.length);
    }, 4000);
    return () => clearInterval(timer);
  }, []);

  const steps = [
    { no: '01', icon: <Smartphone size={22} />, title: '앱 설치 후 위치 권한을 켜세요', desc: '스마트폰 하나면 준비 끝. 이동 경로를 지도 위에 그대로 옮깁니다.' },
    { no: '02', icon: <MapPin size={22} />, title: '움직일수록 영토가 늘어납니다', desc: '러닝, 출퇴근, 산책까지 모든 이동이 실시간으로 내 점령지가 됩니다.' },
    { no: '03', icon: <Sparkles size={22} />, title: '나만의 지도를 완성하세요', desc: '점령 타일로 맵 아트를 그리고, 사진을 남기고, 기록을 비교해보세요.' }
  ];

  const highlights = ['전국 실시간 맵 커버', '이동 기반 자동 점령', '사진 갤러리 공유'];

  return (
    <div className="premium-landing-root">
      <link rel="preconnect" href="https://fonts.googleapis.com" />
      <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="true" />
      <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;800&family=Plus+Jakarta+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet" />

      <div className="bg-glow-orb orb-1" />
      <div className="bg-glow-orb orb-2" />
      <div className="bg-glow-orb orb-3" />
      <div className="bg-grid-overlay" />

      <header className="glass-header">
        <div className="header-container">
          <div className="logo-group">
            <div className="logo-glow-icon">
              <img src="/app_icon.png" alt="Logo" style={{ width: '32px', height: '32px', objectFit: 'contain', borderRadius: '8px' }} />
            </div>
            <span className="logo-text">찜! 모험</span>
          </div>
          <button onClick={() => navigate('/admin')} className="admin-gate-btn">
            <Shield size={14} />
            <span>어드민 시스템</span>
          </button>
        </div>
      </header>

      <section className="hero-section">
        <div className="hero-content">
          <div className="tag-badge animate-fade-in">
            <Zap size={14} className="glow-icon" />
            <span>실시간 위치 기반 영토 점령 게임</span>
          </div>
          <h1 className="hero-title animate-slide-up">
            지루했던 일상을<br />
            <span className="gradient-text">나만의 영토</span>로!
          </h1>
          <p className="hero-desc animate-slide-up-delay">
            '찜! 모험'은 실시간 내 위치를 기반으로 지도를 점령해 나가는 영토 점령 게임입니다.
            꾸준한 일상의 이동으로 점령지를 넓히고 나만의 영토 기록을 완성해보세요.
          </p>

          <div className="highlight-pills animate-slide-up-delay">
            {highlights.map((h) => (
              <span key={h} className="pill">{h}</span>
            ))}
          </div>

          <div className="download-badges animate-slide-up-delay-2">
            <a href="https://play.google.com/store/apps/details?id=com.watercherry.conquestofkorea" target="_blank" rel="noopener noreferrer" className="badge-link">
              <img src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg" alt="Get it on Google Play" className="badge-img" />
            </a>
            <a href="https://apps.apple.com/kr/app/%EC%B0%9C-%EB%8C%80%EB%AA%A8%ED%97%98/id6769717240" target="_blank" rel="noopener noreferrer" className="badge-link">
              <img src="https://upload.wikimedia.org/wikipedia/commons/3/3c/Download_on_the_App_Store_Badge.svg" alt="Download on the App Store" className="badge-img" />
            </a>
          </div>
        </div>

        <div className="hero-mockup-container animate-fade-in">
          <div className="glow-ring-decoration" />
          <div className="phone-mockup">
            <div className="phone-notch" />
            <div className="phone-screen-inner" style={{ position: 'relative', overflow: 'hidden', width: '100%', height: '100%' }}>
              {screenshots.map((src, index) => (
                <img
                  key={src}
                  src={src}
                  alt={`Game Screen ${index + 1}`}
                  className="screen-shot-img"
                  style={{
                    position: 'absolute',
                    top: 0,
                    left: 0,
                    width: '100%',
                    height: '100%',
                    objectFit: 'cover',
                    opacity: index === currentImageIndex ? 1 : 0,
                    transition: 'opacity 1.0s ease-in-out',
                    zIndex: index === currentImageIndex ? 2 : 1
                  }}
                />
              ))}
            </div>
          </div>
          <div className="mockup-chip">
            <span className="chip-dot" />
            실시간 위치 기반 점령
          </div>
        </div>
      </section>

      <section className="features-section">
        <div className="features-header">
          <h2 className="section-title">일상 속 즐거운 영토 점령 플레이</h2>
          <p className="section-subtitle">
            러닝, 출퇴근, 동네 산책까지. 평범한 발걸음이 영토를 넓히는 가장 자연스러운 플레이가 됩니다.
          </p>
        </div>

        <div className="features-grid">
          <div className="feature-premium-card card-running bento-wide">
            <div className="card-icon-wrapper red"><Zap size={22} /></div>
            <h3 className="card-heading">🏃‍♂️ 러닝 & 조깅 페이스메이커</h3>
            <p className="card-body-text">달리는 모든 미터가 실시간으로 내 영토가 됩니다. 친구들과의 점령 경쟁을 통해 운동에 강력한 동기를 부여받으세요.</p>
          </div>

          <div className="feature-premium-card card-bus">
            <div className="card-icon-wrapper cyan"><Navigation size={22} style={{ transform: 'rotate(45deg)' }} /></div>
            <h3 className="card-heading">🚌 출퇴근길 자동 영토 점령</h3>
            <p className="card-body-text">대중교통 이동 경로에 맞춰 점령지가 자동으로 칠해집니다. 백그라운드 모드만 켜두면 일상의 이동이 곧 점령 루트가 됩니다.</p>
          </div>

          <div className="feature-premium-card card-travel">
            <div className="card-icon-wrapper blue"><Palette size={22} /></div>
            <h3 className="card-heading">🎨 내 발자국으로 그리는 맵 아트</h3>
            <p className="card-body-text">점령 타일들을 연결하여 지도 위에 하트, 문자 등 나만의 독창적인 모양을 그리고 이색적인 랜드마크를 완성해보세요.</p>
          </div>

          <div className="feature-premium-card card-walk">
            <div className="card-icon-wrapper gold"><Coins size={22} /></div>
            <h3 className="card-heading">🪙 골목 산책과 보물찾기</h3>
            <p className="card-body-text">동네 골목 구석구석을 탐험하며 무작위로 생성되는 골드를 획득하세요. 안 가본 길을 탐색하는 소소한 모험의 즐거움을 줍니다.</p>
          </div>

          <div className="feature-premium-card card-remote">
            <div className="card-icon-wrapper purple"><MapPin size={22} /></div>
            <h3 className="card-heading">🛋️ 집 안에서 즐기는 원격 점령</h3>
            <p className="card-body-text">직접 가기 힘든 강 너머나 사유지, 혹은 날씨가 나쁜 날에는 비축한 골드를 사용해 방 안에서 원격으로 영토를 넓혀보세요.</p>
          </div>

          <div className="feature-premium-card card-camera bento-wide">
            <div className="card-icon-wrapper red"><Camera size={22} /></div>
            <h3 className="card-heading">📸 내 주변 현장 촬영 및 갤러리 공유</h3>
            <p className="card-body-text">내가 밟고 서 있는 내 주변 구역에서 리얼한 현장 사진을 촬영해 갤러리에 업로드해 보세요. 내가 점령한 영토의 풍경 기록은 지도를 탐색하는 모든 유저가 자유롭게 볼 수 있습니다.</p>
          </div>
        </div>
      </section>

      <section className="how-section">
        <div className="how-header">
          <span className="eyebrow">시작하는 방법</span>
          <h2 className="section-title light">세 단계로 끝나는 점령 라이프</h2>
        </div>
        <div className="how-grid">
          {steps.map((s) => (
            <div key={s.no} className="how-card">
              <div className="how-no">{s.no}</div>
              <div className="how-icon">{s.icon}</div>
              <h3 className="how-title">{s.title}</h3>
              <p className="how-desc">{s.desc}</p>
            </div>
          ))}
        </div>
      </section>

      <section className="cta-section">
        <div className="cta-panel">
          <h2 className="cta-title">지금, 나만의 영토 점령을 시작하세요</h2>
          <p className="cta-desc">가까운 길부터 시작되는 실시간 위치 기반 점령 게임.</p>
          <div className="download-badges center">
            <a href="https://play.google.com/store/apps/details?id=com.watercherry.conquestofkorea" target="_blank" rel="noopener noreferrer" className="badge-link">
              <img src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg" alt="Get it on Google Play" className="badge-img" />
            </a>
            <a href="https://apps.apple.com/kr/app/%EC%B0%9C-%EB%8C%80%EB%AA%A8%ED%97%98/id6769717240" target="_blank" rel="noopener noreferrer" className="badge-link">
              <img src="https://upload.wikimedia.org/wikipedia/commons/3/3c/Download_on_the_App_Store_Badge.svg" alt="Download on the App Store" className="badge-img" />
            </a>
          </div>
        </div>
      </section>

      <footer className="premium-footer">
        <div className="footer-container">
          <div className="footer-brand">
            <div className="logo-group">
              <img src="/app_icon.png" alt="Logo" style={{ width: '24px', height: '24px', objectFit: 'contain', borderRadius: '4px' }} />
              <span className="brand-title">찜! 모험</span>
            </div>
            <p className="copy-text">&copy; {new Date().getFullYear()} 찜! 모험 Project. All rights reserved.</p>
          </div>
          <div className="footer-links">
            <span onClick={() => navigate('/terms')} className="footer-link">서비스 이용약관</span>
            <span onClick={() => navigate('/privacy')} className="footer-link">개인정보 처리방침</span>
          </div>
        </div>
      </footer>

      <style dangerouslySetInnerHTML={{ __html: `
        .premium-landing-root{background-color:#05070f;background-image:radial-gradient(1100px 620px at 12% -12%,rgba(56,189,248,.10),transparent 60%),radial-gradient(1000px 560px at 100% 6%,rgba(167,139,250,.10),transparent 55%),radial-gradient(900px 620px at 50% 115%,rgba(52,211,153,.07),transparent 60%);color:#e8edf6;font-family:'Plus Jakarta Sans',-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;min-height:100vh;position:relative;overflow-x:hidden;line-height:1.55}
        .logo-text,.hero-title,.section-title,.card-heading,.cta-title,.how-title{font-family:'Outfit',sans-serif}
        .bg-glow-orb{position:absolute;border-radius:50%;pointer-events:none;filter:blur(170px);opacity:.14;mix-blend-mode:screen;z-index:0}
        .orb-1{width:540px;height:540px;background:radial-gradient(circle,#38bdf8 0%,transparent 70%);top:-140px;left:12%}
        .orb-2{width:640px;height:640px;background:radial-gradient(circle,#a78bfa 0%,transparent 70%);top:26%;right:-140px}
        .orb-3{width:440px;height:440px;background:radial-gradient(circle,#34d399 0%,transparent 70%);bottom:6%;left:-70px}
        .bg-grid-overlay{position:absolute;inset:0;pointer-events:none;z-index:0;background-image:linear-gradient(rgba(255,255,255,.025) 1px,transparent 1px),linear-gradient(90deg,rgba(255,255,255,.025) 1px,transparent 1px);background-size:64px 64px;-webkit-mask-image:radial-gradient(circle at 50% 30%,#000 0%,transparent 75%);mask-image:radial-gradient(circle at 50% 30%,#000 0%,transparent 75%);opacity:.6}

        .glass-header{position:sticky;top:0;z-index:100;background:rgba(5,7,15,.65);backdrop-filter:blur(16px) saturate(140%);-webkit-backdrop-filter:blur(16px) saturate(140%);border-bottom:1px solid rgba(255,255,255,.05)}
        .header-container{max-width:1200px;margin:0 auto;padding:1.1rem 2rem;display:flex;justify-content:space-between;align-items:center}
        .logo-group{display:flex;align-items:center;gap:.6rem}
        .logo-glow-icon{display:flex;align-items:center;justify-content:center;filter:drop-shadow(0 0 10px rgba(59,130,246,.6));animation:logoFloat 3s ease-in-out infinite alternate}
        .logo-text{font-weight:800;font-size:1.4rem;letter-spacing:.02em;background:linear-gradient(135deg,#60a5fa,#a78bfa);-webkit-background-clip:text;WebkitBackgroundClip:text;-webkit-text-fill-color:transparent;background-clip:text}
        .admin-gate-btn{background:rgba(255,255,255,.03);border:1px solid rgba(255,255,255,.07);padding:.6rem 1.2rem;border-radius:24px;color:#94a3b8;font-size:.85rem;font-weight:600;cursor:pointer;transition:all .3s cubic-bezier(.4,0,.2,1);display:flex;align-items:center;gap:.5rem}
        .admin-gate-btn:hover{background:rgba(59,130,246,.1);border-color:rgba(59,130,246,.3);color:#60a5fa;box-shadow:0 0 15px rgba(59,130,246,.25);transform:translateY(-2px)}

        .hero-section{position:relative;z-index:10;max-width:1200px;width:100%;margin:0 auto;padding:6rem 2rem 7rem 2rem;display:grid;grid-template-columns:1.2fr .8fr;gap:4rem;align-items:center}
        .tag-badge{display:inline-flex;align-items:center;gap:.5rem;background:rgba(59,130,246,.08);border:1px solid rgba(59,130,246,.15);color:#60a5fa;padding:.5rem 1.1rem;border-radius:30px;font-size:.85rem;font-weight:700;width:fit-content;margin-bottom:1.5rem;box-shadow:inset 0 0 8px rgba(59,130,246,.1)}
        .glow-icon{animation:pulseGlowIcon 1.5s infinite alternate}
        .hero-title{font-size:4rem;font-weight:800;line-height:1.1;letter-spacing:-.03em;margin:0 0 1.5rem 0}
        .gradient-text{background:linear-gradient(135deg,#38bdf8 25%,#a78bfa 65%,#34d399 100%);-webkit-background-clip:text;WebkitBackgroundClip:text;-webkit-text-fill-color:transparent;background-clip:text;filter:drop-shadow(0 2px 24px rgba(56,189,248,.18))}
        .hero-desc{font-size:1.15rem;line-height:1.7;color:#9fb0c9;max-width:560px;margin:0 0 1.8rem 0}
        .highlight-pills{display:flex;flex-wrap:wrap;gap:.6rem;margin-bottom:2.2rem}
        .pill{background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.07);color:#cbd5e1;padding:.4rem .9rem;border-radius:20px;font-size:.8rem;font-weight:600;backdrop-filter:blur(6px)}
        .download-badges{display:flex;gap:1.2rem;align-items:center}
        .download-badges.center{justify-content:center}
        .badge-link{transition:all .3s cubic-bezier(.4,0,.2,1)}
        .badge-link:hover{transform:translateY(-4px) scale(1.02);filter:drop-shadow(0 8px 20px rgba(0,0,0,.5))}
        .badge-img{height:52px;display:block}

        .hero-mockup-container{display:flex;justify-content:center;position:relative}
        .glow-ring-decoration{position:absolute;width:380px;height:380px;border:1px dashed rgba(99,179,237,.3);border-radius:50%;z-index:1;pointer-events:none;animation:rotateRing 30s linear infinite;top:50%;left:50%;transform:translate(-50%,-50%)}
        .phone-mockup{width:290px;height:580px;border-radius:44px;border:9px solid #1e293b;background-color:#0b0f19;box-shadow:0 30px 60px -15px rgba(0,0,0,.8),0 0 50px rgba(56,189,248,.15),inset 0 0 10px rgba(255,255,255,.05);position:relative;overflow:hidden;z-index:2;display:flex;flex-direction:column;transform:perspective(1000px) rotateY(-5deg) rotateX(5deg);transition:transform .6s cubic-bezier(.4,0,.2,1);animation:mockupFloat 6s ease-in-out infinite}
        .phone-mockup:hover{transform:perspective(1000px) rotateY(0) rotateX(0) translateY(-8px);box-shadow:0 35px 70px -10px rgba(0,0,0,.9),0 0 60px rgba(56,189,248,.25)}
        .phone-notch{width:130px;height:24px;background-color:#1e293b;border-radius:0 0 16px 16px;position:absolute;top:0;left:50%;transform:translateX(-50%);z-index:10}
        .phone-screen-inner{flex:1;position:relative;background:#090d16}
        .screen-shot-img{width:100%;height:100%;object-fit:cover}
        .mockup-chip{position:absolute;bottom:34px;left:-14px;z-index:5;display:inline-flex;align-items:center;gap:.5rem;background:rgba(10,14,24,.7);border:1px solid rgba(255,255,255,.12);backdrop-filter:blur(10px);padding:.5rem .9rem;border-radius:14px;font-size:.78rem;font-weight:600;color:#e2e8f0;box-shadow:0 10px 30px rgba(0,0,0,.4)}
        .chip-dot{width:8px;height:8px;border-radius:50%;background:#34d399;box-shadow:0 0 10px #34d399}

        .features-section{position:relative;z-index:10;background:linear-gradient(to bottom,#090d16 0%,#05070f 100%);border-top:1px solid rgba(255,255,255,.03);border-bottom:1px solid rgba(255,255,255,.03);padding:7rem 2rem}
        .features-header{text-align:center;margin-bottom:4rem}
        .section-title{font-size:2.6rem;font-weight:800;margin:0 0 1.2rem 0;letter-spacing:-.02em}
        .section-title.light{color:#f1f5f9}
        .section-subtitle{color:#9fb0c9;font-size:1.1rem;max-width:650px;margin:0 auto;line-height:1.6}
        .features-grid{max-width:1200px;margin:0 auto;display:grid;grid-template-columns:repeat(6,1fr);gap:1.5rem}
        .feature-premium-card{background:linear-gradient(160deg,rgba(30,41,59,.35),rgba(15,23,42,.25));border:1px solid rgba(255,255,255,.06);border-radius:22px;padding:2.4rem;display:flex;flex-direction:column;gap:1.1rem;box-shadow:0 12px 30px rgba(0,0,0,.25);backdrop-filter:blur(10px);-webkit-backdrop-filter:blur(10px);transition:all .4s cubic-bezier(.4,0,.2,1);position:relative;overflow:hidden}
        .feature-premium-card::before{content:'';position:absolute;top:0;left:0;width:100%;height:100%;background:linear-gradient(135deg,rgba(255,255,255,.05) 0%,transparent 100%);pointer-events:none;z-index:1}
        .feature-premium-card:hover{transform:translateY(-8px);border-color:rgba(255,255,255,.14);box-shadow:0 24px 48px rgba(0,0,0,.45)}
        .feature-premium-card.card-running{grid-column:span 4}
        .feature-premium-card.card-camera{grid-column:span 4}
        .feature-premium-card.card-bus,.feature-premium-card.card-travel,.feature-premium-card.card-walk,.feature-premium-card.card-remote{grid-column:span 2}
        .feature-premium-card.card-running:hover{box-shadow:0 24px 48px rgba(239,68,68,.12);border-color:rgba(239,68,68,.25)}
        .feature-premium-card.card-bus:hover{box-shadow:0 24px 48px rgba(6,182,212,.12);border-color:rgba(6,182,212,.25)}
        .feature-premium-card.card-travel:hover{box-shadow:0 24px 48px rgba(59,130,246,.12);border-color:rgba(59,130,246,.25)}
        .feature-premium-card.card-walk:hover{box-shadow:0 24px 48px rgba(251,191,36,.12);border-color:rgba(251,191,36,.25)}
        .feature-premium-card.card-remote:hover{box-shadow:0 24px 48px rgba(167,139,250,.12);border-color:rgba(167,139,250,.25)}
        .card-icon-wrapper{width:48px;height:48px;border-radius:14px;display:flex;align-items:center;justify-content:center;font-weight:bold}
        .card-icon-wrapper.red{background:rgba(239,68,68,.12);color:#ef4444;border:1px solid rgba(239,68,68,.2)}
        .card-icon-wrapper.cyan{background:rgba(6,182,212,.12);color:#06b6d4;border:1px solid rgba(6,182,212,.2)}
        .card-icon-wrapper.blue{background:rgba(59,130,246,.12);color:#3b82f6;border:1px solid rgba(59,130,246,.2)}
        .card-icon-wrapper.gold{background:rgba(251,191,36,.12);color:#fbbf24;border:1px solid rgba(251,191,36,.2)}
        .card-icon-wrapper.purple{background:rgba(167,139,250,.12);color:#a78bfa;border:1px solid rgba(167,139,250,.2)}
        .card-heading{font-size:1.3rem;font-weight:700;margin:0;color:#f8fafc;z-index:2}
        .card-body-text{color:#9fb0c9;font-size:.95rem;line-height:1.65;margin:0;z-index:2}

        .how-section{position:relative;z-index:10;max-width:1200px;margin:0 auto;padding:7rem 2rem}
        .how-header{text-align:center;margin-bottom:3.5rem}
        .eyebrow{display:inline-block;font-size:.8rem;font-weight:700;letter-spacing:.18em;text-transform:uppercase;color:#60a5fa;margin-bottom:1rem}
        .how-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:2rem}
        .how-card{background:rgba(255,255,255,.03);border:1px solid rgba(255,255,255,.06);border-radius:20px;padding:2.4rem;transition:all .4s cubic-bezier(.4,0,.2,1)}
        .how-card:hover{transform:translateY(-6px);border-color:rgba(99,179,237,.25);background:rgba(255,255,255,.05)}
        .how-no{font-family:'Outfit',sans-serif;font-size:1.4rem;font-weight:800;color:#38bdf8;opacity:.5;margin-bottom:.6rem}
        .how-icon{width:52px;height:52px;border-radius:14px;display:flex;align-items:center;justify-content:center;background:linear-gradient(135deg,rgba(56,189,248,.15),rgba(167,139,250,.15));color:#e2e8f0;margin-bottom:1.2rem}
        .how-title{font-size:1.2rem;font-weight:700;margin:0 0 .8rem 0;color:#f1f5f9}
        .how-desc{color:#9fb0c9;font-size:.95rem;line-height:1.65;margin:0}

        .cta-section{position:relative;z-index:10;padding:2rem 2rem 8rem 2rem}
        .cta-panel{position:relative;max-width:1000px;margin:0 auto;text-align:center;padding:4.5rem 2rem;border-radius:32px;background:linear-gradient(160deg,rgba(56,189,248,.10),rgba(167,139,250,.08));border:1px solid rgba(255,255,255,.08);overflow:hidden}
        .cta-panel::before{content:'';position:absolute;inset:0;background:radial-gradient(600px 300px at 50% -20%,rgba(56,189,248,.25),transparent 70%);pointer-events:none}
        .cta-title{position:relative;font-size:2.4rem;font-weight:800;margin:0 0 1rem 0;letter-spacing:-.02em;background:linear-gradient(135deg,#e2e8f0,#a5b4fc);-webkit-background-clip:text;WebkitBackgroundClip:text;-webkit-text-fill-color:transparent;background-clip:text}
        .cta-desc{position:relative;color:#9fb0c9;font-size:1.1rem;margin:0 0 2.2rem 0}

        .premium-footer{border-top:1px solid rgba(255,255,255,.04);padding:4rem 2rem;background:#04060d;position:relative;z-index:10}
        .footer-container{max-width:1200px;margin:0 auto;display:flex;flex-direction:column;justify-content:center;align-items:center;text-align:center;gap:1.5rem}
        .footer-brand .logo-group{justify-content:center}
        .brand-title{font-weight:800;font-size:1.2rem}
        .copy-text{font-size:.85rem;color:#475569;margin:.5rem 0 0 0;text-align:center}
        .footer-links{display:flex;justify-content:center;gap:2rem;flex-wrap:wrap}
        .footer-link{font-size:.88rem;color:#64748b;cursor:pointer;transition:all .2s ease}
        .footer-link:hover{color:#60a5fa}

        @keyframes logoFloat{0%{transform:translateY(0)}100%{transform:translateY(-4px)}}
        @keyframes rotateRing{0%{transform:translate(-50%,-50%) rotate(0)}100%{transform:translate(-50%,-50%) rotate(360deg)}}
        @keyframes pulseGlowIcon{0%{transform:scale(1);filter:drop-shadow(0 0 2px rgba(96,165,250,.4))}100%{transform:scale(1.1);filter:drop-shadow(0 0 8px rgba(96,165,250,.8))}}
        @keyframes mockupFloat{0%,100%{transform:perspective(1000px) rotateY(-5deg) rotateX(5deg) translateY(0)}50%{transform:perspective(1000px) rotateY(-5deg) rotateX(5deg) translateY(-12px)}}
        .animate-fade-in{animation:fadeIn .8s ease-out forwards}
        .animate-slide-up{animation:slideUp .8s cubic-bezier(.2,.8,.2,1) forwards}
        .animate-slide-up-delay{opacity:0;animation:slideUp .8s cubic-bezier(.2,.8,.2,1) .2s forwards}
        .animate-slide-up-delay-2{opacity:0;animation:slideUp .8s cubic-bezier(.2,.8,.2,1) .4s forwards}
        @keyframes fadeIn{from{opacity:0}to{opacity:1}}
        @keyframes slideUp{from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)}}

        @media (max-width:968px){
          .hero-section{grid-template-columns:1fr;text-align:center;padding:4rem 1.5rem 5rem 1.5rem;gap:3.5rem}
          .tag-badge{margin-left:auto;margin-right:auto}
          .hero-title{font-size:2.8rem}
          .hero-desc{max-width:100%}
          .highlight-pills{justify-content:center}
          .download-badges{justify-content:center}
          .phone-mockup{animation:none;transform:none!important}
          .glow-ring-decoration{width:320px;height:320px}
          .features-grid{grid-template-columns:1fr}
          .feature-premium-card.card-running,.feature-premium-card.card-camera,.feature-premium-card.card-bus,.feature-premium-card.card-travel,.feature-premium-card.card-walk,.feature-premium-card.card-remote{grid-column:auto}
          .how-grid{grid-template-columns:1fr}
          .section-title{font-size:2.1rem}
          .cta-title{font-size:1.9rem}
        }
      ` }} />
    </div>
  );
}
