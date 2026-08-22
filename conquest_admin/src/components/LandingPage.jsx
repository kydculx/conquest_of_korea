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
  Sparkles,
  Globe,
  Trophy,
  Layers,
  Award
} from 'lucide-react';

export default function LandingPage() {
  const navigate = useNavigate();
  const [currentImageIndex, setCurrentImageIndex] = React.useState(0);
  const screenshots = [
    '/screenshot_splash.jpg',
    '/screenshot_satellite.jpg',
    '/screenshot_neon.jpg'
  ];
  const heroImages = ['/game_screen.png'];

  React.useEffect(() => {
    const timer = setInterval(() => {
      setCurrentImageIndex((prev) => (prev + 1) % heroImages.length);
    }, 4000);
    return () => clearInterval(timer);
  }, []);

  const identity = [
    { icon: <MapPin size={18} />, text: '지도 기반 실시간 점령' },
    { icon: <Navigation size={18} />, text: '이동만으로 자동 성장' },
    { icon: <Palette size={18} />, text: '맵 아트 & 갤러리' },
    { icon: <Globe size={18} />, text: '전 세계 어디서나 점령' }
  ];

  const steps = [
    { no: '01', icon: <Smartphone size={22} />, title: '앱 설치 후 위치 권한을 켜세요', desc: '스마트폰 하나면 준비 끝. 이동 경로를 지도 위에 그대로 옮깁니다.' },
    { no: '02', icon: <MapPin size={22} />, title: '움직일수록 영토가 늘어납니다', desc: '러닝, 출퇴근, 산책까지 모든 이동이 실시간으로 내 점령지가 됩니다.' },
    { no: '03', icon: <Sparkles size={22} />, title: '나만의 지도를 완성하세요', desc: '점령 타일로 맵 아트를 그리고, 사진을 남기고, 기록을 비교해보세요.' }
  ];

  const rows = [
    {
      img: screenshots[0],
      items: [
        { icon: <Zap size={20} />, title: '🏃 러닝 & 조깅 페이스메이커', text: '달리는 매 순간이 내 영토로 바뀝니다. 내가 그은 러닝 루트가 지도 위 점령지가 되고, 매일의 운동이 게임처럼 즐거워집니다.' },
        { icon: <Navigation size={20} style={{ transform: 'rotate(45deg)' }} />, title: '🚌 출퇴근길 자동 영토 점령', text: '출퇴근 버스·지하철 이동이 자동으로 점령지가 됩니다. 앱을 켜두기만 하면 매일의 통근이 눈에 보이는 영토로 쌓입니다.' }
      ]
    },
    {
      img: screenshots[1],
      reverse: true,
      items: [
        { icon: <Palette size={20} />, title: '🎨 내 발자국으로 그리는 맵 아트', text: '점령한 타일을 이어 하트·글자 등 나만의 무늬를 완성하세요. 지도가 점점 나만의 작품으로 채워집니다.' },
        { icon: <Coins size={20} />, title: '🪙 골목 산책과 보물찾기', text: '안 가본 골목을 돌다 보면 숨겨진 골드가 나타납니다. 일상 속 작은 탐험이 보상이 되는 경험을 줍니다.' }
      ]
    },
    {
      img: screenshots[2],
      items: [
        { icon: <MapPin size={20} />, title: '🛋️ 집 안에서 즐기는 원격 점령', text: '강 건너나 먼 곳, 날씨가 안 좋은 날엔 모아둔 골드로 원격 점령합니다. 직접 가지 않아도 내 영토는 계속 넓어집니다.' },
        { icon: <Camera size={20} />, title: '📸 내 주변 현장 촬영 및 갤러리 공유', text: '점령한 타일에서 찍은 사진이 지도 갤러리에 남습니다. 내 발자국이 남긴 풍경을 다른 플레이어와 나눌 수 있습니다.' }
      ]
    }
  ];

  const systems = [
    { icon: <Trophy size={22} />, title: '전 세계 랭킹', text: '내 점령 면적은 전 세계 랭킹에 기록됩니다. 동네를 넘어 전 세계 플레이어와 기록을 겨룰 수 있습니다.' },
    { icon: <Layers size={22} />, title: '헥스 타일 정복', text: '지도는 육각 타일로 이루어져 있습니다. 한 칸씩 방문해 채우며 전 세계를 내 영토로 만들어가세요.' },
    { icon: <Award size={22} />, title: '골드 & 업적', text: '이동과 탐험으로 골드를 모으고, 다양한 업적을 달성하며 성장의 보상을 얻으세요.' }
  ];

  return (
    <div className="premium-landing-root">
      <link rel="preconnect" href="https://fonts.googleapis.com" />
      <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="true" />
      <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;800&family=Plus+Jakarta+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet" />

      <div className="bg-glow-orb orb-1" />
      <div className="bg-glow-orb orb-2" />
      <div className="bg-glow-orb orb-3" />

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
          <div className="download-badges animate-slide-up-delay-2">
            <a href="https://play.google.com/store/apps/details?id=com.watercherry.conquestofkorea" target="_blank" rel="noopener noreferrer" className="badge-link">
              <img src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg" alt="Get it on Google Play" className="badge-img" />
            </a>
            <a href="https://apps.apple.com/kr/app/%EC%B0%9C-%EB%8C%80%EB%AA%A8%ED%97%98/id6769717240" target="_blank" rel="noopener noreferrer" className="badge-link">
              <img src="https://upload.wikimedia.org/wikipedia/commons/3/3c/Download_on_the_App_Store_Badge.svg" alt="Download on the App Store" className="badge-img" />
            </a>
          </div>
        </div>

        <div className="hero-visual animate-fade-in">
          <div className="map-view-card">
            <div className="map-grid-bg" />
            {heroImages.map((src, index) => (
              <img
                key={src}
                src={src}
                alt="게임 화면 미리보기"
                className="map-shot-img"
                style={{ opacity: index === currentImageIndex ? 1 : 0, zIndex: index === currentImageIndex ? 2 : 1 }}
              />
            ))}
            <div className="map-pin"><span className="pin-core" /></div>
          </div>
        </div>
      </section>

      <section className="identity-strip">
        {identity.map((it) => (
          <div key={it.text} className="identity-item">
            <span className="identity-icon">{it.icon}</span>
            <span>{it.text}</span>
          </div>
        ))}
      </section>

      <section className="features-section">
        <div className="features-header">
          <span className="eyebrow">플레이 특징</span>
          <h2 className="section-title">일상이 영토가 되는 순간들</h2>
        </div>
        <div className="feature-rows">
          {rows.flatMap((row) => row.items).map((it) => (
            <div key={it.title} className="mini-feature">
              <div className="mini-icon">{it.icon}</div>
              <div>
                <h3 className="mini-title">{it.title}</h3>
                <p className="mini-text">{it.text}</p>
              </div>
            </div>
          ))}
        </div>
      </section>

      <section className="systems-section">
        <div className="features-header">
          <span className="eyebrow">핵심 시스템</span>
          <h2 className="section-title">점령을 완성하는 세 가지 축</h2>
        </div>
        <div className="systems-grid">
          {systems.map((s) => (
            <div key={s.title} className="system-card">
              <div className="system-icon">{s.icon}</div>
              <h3 className="system-title">{s.title}</h3>
              <p className="system-text">{s.text}</p>
            </div>
          ))}
        </div>
      </section>

      <section className="how-section">
        <div className="how-header">
          <span className="eyebrow">시작하는 방법</span>
          <h2 className="section-title">세 단계로 끝나는 점령 라이프</h2>
        </div>
        <div className="timeline">
          {steps.map((s) => (
            <div key={s.no} className="tl-node">
              <div className="tl-circle">{s.icon}</div>
              <div className="tl-no">{s.no}</div>
              <h3 className="tl-title">{s.title}</h3>
              <p className="tl-desc">{s.desc}</p>
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
        .logo-text,.hero-title,.section-title,.mini-title,.cta-title,.tl-title{font-family:'Outfit',sans-serif}
        .bg-glow-orb{position:absolute;border-radius:50%;pointer-events:none;filter:blur(170px);opacity:.14;mix-blend-mode:screen;z-index:0}
        .orb-1{width:540px;height:540px;background:radial-gradient(circle,#38bdf8 0%,transparent 70%);top:-140px;left:12%}
        .orb-2{width:640px;height:640px;background:radial-gradient(circle,#a78bfa 0%,transparent 70%);top:26%;right:-140px}
        .orb-3{width:440px;height:440px;background:radial-gradient(circle,#34d399 0%,transparent 70%);bottom:6%;left:-70px}

        .glass-header{position:sticky;top:0;z-index:100;background:rgba(5,7,15,.65);backdrop-filter:blur(16px) saturate(140%);-webkit-backdrop-filter:blur(16px) saturate(140%);border-bottom:1px solid rgba(255,255,255,.05)}
        .header-container{max-width:1200px;margin:0 auto;padding:1.1rem 2rem;display:flex;justify-content:space-between;align-items:center}
        .logo-group{display:flex;align-items:center;gap:.6rem}
        .logo-glow-icon{display:flex;align-items:center;justify-content:center;filter:drop-shadow(0 0 10px rgba(59,130,246,.6));animation:logoFloat 3s ease-in-out infinite alternate}
        .logo-text{font-weight:800;font-size:1.4rem;letter-spacing:.02em;background:linear-gradient(135deg,#60a5fa,#a78bfa);-webkit-background-clip:text;WebkitBackgroundClip:text;-webkit-text-fill-color:transparent;background-clip:text}
        .admin-gate-btn{background:rgba(255,255,255,.03);border:1px solid rgba(255,255,255,.07);padding:.6rem 1.2rem;border-radius:24px;color:#94a3b8;font-size:.85rem;font-weight:600;cursor:pointer;transition:all .3s cubic-bezier(.4,0,.2,1);display:flex;align-items:center;gap:.5rem}
        .admin-gate-btn:hover{background:rgba(59,130,246,.1);border-color:rgba(59,130,246,.3);color:#60a5fa;box-shadow:0 0 15px rgba(59,130,246,.25);transform:translateY(-2px)}

        .hero-section{position:relative;z-index:10;max-width:1200px;width:100%;margin:0 auto;padding:6rem 2rem 5rem 2rem;display:grid;grid-template-columns:1.05fr .95fr;gap:4rem;align-items:center}
        .tag-badge{display:inline-flex;align-items:center;gap:.5rem;background:rgba(59,130,246,.08);border:1px solid rgba(59,130,246,.15);color:#60a5fa;padding:.5rem 1.1rem;border-radius:30px;font-size:.85rem;font-weight:700;width:fit-content;margin-bottom:1.5rem;box-shadow:inset 0 0 8px rgba(59,130,246,.1)}
        .glow-icon{animation:pulseGlowIcon 1.5s infinite alternate}
        .hero-title{font-size:4.2rem;font-weight:800;line-height:1.08;letter-spacing:-.03em;margin:0 0 1.5rem 0}
        .gradient-text{background:linear-gradient(135deg,#38bdf8 25%,#a78bfa 65%,#34d399 100%);-webkit-background-clip:text;WebkitBackgroundClip:text;-webkit-text-fill-color:transparent;background-clip:text;filter:drop-shadow(0 2px 24px rgba(56,189,248,.18))}
        .hero-desc{font-size:1.15rem;line-height:1.7;color:#9fb0c9;max-width:520px;margin:0 0 2.2rem 0}
        .download-badges{display:flex;gap:1.2rem;align-items:center}
        .download-badges.center{justify-content:center}
        .badge-link{transition:all .3s cubic-bezier(.4,0,.2,1)}
        .badge-link:hover{transform:translateY(-4px) scale(1.02);filter:drop-shadow(0 8px 20px rgba(0,0,0,.5))}
        .badge-img{height:52px;display:block}

        .hero-visual{position:relative;display:flex;justify-content:center}
        .map-view-card{position:relative;width:100%;max-width:260px;aspect-ratio:1284/2778;border-radius:26px;overflow:hidden;border:1px solid rgba(255,255,255,.1);background:#0b0f19;box-shadow:0 30px 60px -15px rgba(0,0,0,.85),0 0 50px rgba(56,189,248,.12);animation:mockupFloat 6s ease-in-out infinite}
        .map-grid-bg{position:absolute;inset:0;z-index:1;background-image:radial-gradient(rgba(56,189,248,.18) 1px,transparent 1px);background-size:22px 22px;mask-image:radial-gradient(circle at 50% 45%,#000,transparent 78%);-webkit-mask-image:radial-gradient(circle at 50% 45%,#000,transparent 78%);pointer-events:none}
        .map-shot-img{position:absolute;inset:0;width:100%;height:100%;object-fit:contain;opacity:1;transition:opacity 1s ease-in-out}
        .map-live-chip{position:absolute;top:14px;left:14px;z-index:3;display:inline-flex;align-items:center;gap:.45rem;background:rgba(10,14,24,.7);border:1px solid rgba(255,255,255,.12);backdrop-filter:blur(10px);padding:.4rem .8rem;border-radius:12px;font-size:.76rem;font-weight:600;color:#e2e8f0}
        .live-dot{width:8px;height:8px;border-radius:50%;background:#34d399;box-shadow:0 0 10px #34d399;animation:pulseGlowIcon 1.4s infinite alternate}
        .map-pin{position:absolute;top:42%;left:50%;transform:translate(-50%,-50%);z-index:3;width:26px;height:26px;border-radius:50%;background:rgba(56,189,248,.25);display:flex;align-items:center;justify-content:center;animation:pinPulse 2s ease-out infinite}
        .pin-core{width:10px;height:10px;border-radius:50%;background:#38bdf8;box-shadow:0 0 14px #38bdf8}
        .hero-stat-chip{position:absolute;bottom:14px;right:14px;z-index:5;display:inline-flex;align-items:center;gap:.5rem;background:rgba(10,14,24,.8);border:1px solid rgba(255,255,255,.12);backdrop-filter:blur(10px);padding:.55rem 1rem;border-radius:14px;font-size:.8rem;font-weight:600;color:#e2e8f0;box-shadow:0 10px 30px rgba(0,0,0,.5)}
        .hero-stat-chip svg{color:#34d399}

        .identity-strip{position:relative;z-index:10;max-width:1100px;margin:1rem auto 0;padding:1.4rem 2rem;display:grid;grid-template-columns:repeat(4,1fr);gap:1rem;border-top:1px solid rgba(255,255,255,.05);border-bottom:1px solid rgba(255,255,255,.05)}
        .identity-item{display:flex;align-items:center;gap:.6rem;justify-content:center;color:#cbd5e1;font-size:.92rem;font-weight:600}
        .identity-icon{display:inline-flex;align-items:center;justify-content:center;width:36px;height:36px;border-radius:10px;background:linear-gradient(135deg,rgba(56,189,248,.15),rgba(167,139,250,.15));color:#7dd3fc}
        .features-section{position:relative;z-index:10;padding:6rem 2rem}
        .features-header{text-align:center;margin-bottom:4rem}
        .eyebrow{display:inline-block;font-size:.8rem;font-weight:700;letter-spacing:.18em;text-transform:uppercase;color:#60a5fa;margin-bottom:1rem}
        .section-title{font-size:2.6rem;font-weight:800;margin:0;letter-spacing:-.02em;color:#f1f5f9}
        .feature-rows{max-width:1100px;margin:0 auto;display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:1.5rem}
        .feature-row{display:grid;grid-template-columns:1fr 1fr;gap:3.5rem;align-items:center}
        .feature-row.reverse .feature-visual{order:2}
        .visual-frame{position:relative;border-radius:22px;overflow:hidden;border:1px solid rgba(255,255,255,.08);box-shadow:0 24px 50px -15px rgba(0,0,0,.7)}
        .visual-img{width:100%;height:100%;object-fit:cover;display:block;aspect-ratio:16/11}
        .visual-badge{position:absolute;top:14px;left:14px;width:40px;height:40px;border-radius:12px;display:flex;align-items:center;justify-content:center;background:rgba(10,14,24,.7);border:1px solid rgba(255,255,255,.12);backdrop-filter:blur(8px);font-family:'Outfit',sans-serif;font-weight:800;color:#7dd3fc}
        .feature-text-col{display:flex;flex-direction:column;gap:1.6rem}
        .mini-feature{display:flex;gap:1rem;align-items:flex-start;background:rgba(255,255,255,.03);border:1px solid rgba(255,255,255,.06);border-radius:16px;padding:1.3rem;transition:all .35s cubic-bezier(.4,0,.2,1)}
        .mini-feature:hover{transform:translateY(-4px);border-color:rgba(99,179,237,.22);background:rgba(255,255,255,.05)}
        .mini-icon{flex-shrink:0;width:42px;height:42px;border-radius:12px;display:flex;align-items:center;justify-content:center;background:linear-gradient(135deg,rgba(56,189,248,.15),rgba(167,139,250,.15));color:#e2e8f0}
        .mini-title{font-size:1.05rem;font-weight:700;margin:0 0 .4rem 0;color:#f1f5f9}
        .mini-text{font-size:.9rem;line-height:1.6;margin:0;color:#9fb0c9}

        .systems-section{position:relative;z-index:10;padding:6rem 2rem;background:linear-gradient(to bottom,#05070f,#090d16)}
        .systems-grid{max-width:1100px;margin:0 auto;display:grid;grid-template-columns:repeat(3,1fr);gap:1.5rem}
        .system-card{background:linear-gradient(160deg,rgba(30,41,59,.35),rgba(15,23,42,.25));border:1px solid rgba(255,255,255,.06);border-radius:20px;padding:2rem;transition:all .4s cubic-bezier(.4,0,.2,1)}
        .system-card:hover{transform:translateY(-6px);border-color:rgba(99,179,237,.25);box-shadow:0 20px 40px rgba(0,0,0,.4)}
        .system-icon{width:48px;height:48px;border-radius:14px;display:flex;align-items:center;justify-content:center;background:linear-gradient(135deg,rgba(56,189,248,.15),rgba(167,139,250,.15));color:#7dd3fc;margin-bottom:1rem}
        .system-title{font-size:1.15rem;font-weight:700;margin:0 0 .6rem 0;color:#f1f5f9}
        .system-text{font-size:.9rem;line-height:1.6;margin:0;color:#9fb0c9}

        .how-section{position:relative;z-index:10;max-width:1100px;margin:0 auto;padding:5rem 2rem}
        .how-header{text-align:center;margin-bottom:3.5rem}
        .timeline{position:relative;display:grid;grid-template-columns:repeat(3,1fr);gap:2rem}
        .timeline::before{content:'';position:absolute;top:30px;left:16%;right:16%;height:2px;background:linear-gradient(90deg,transparent,#38bdf8,#a78bfa,transparent);z-index:0}
        .tl-node{position:relative;text-align:center;z-index:1;padding:0 1rem}
        .tl-circle{width:60px;height:60px;border-radius:50%;margin:0 auto 1rem;display:flex;align-items:center;justify-content:center;background:linear-gradient(135deg,#0b1220,#111a2e);border:1px solid rgba(99,179,237,.35);color:#7dd3fc;box-shadow:0 0 24px rgba(56,189,248,.2)}
        .tl-no{font-family:'Outfit',sans-serif;font-weight:800;color:#38bdf8;opacity:.5;font-size:1.1rem;margin-bottom:.3rem}
        .tl-title{font-size:1.1rem;font-weight:700;margin:0 0 .6rem 0;color:#f1f5f9}
        .tl-desc{color:#9fb0c9;font-size:.9rem;line-height:1.6;margin:0}

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
        @keyframes pulseGlowIcon{0%{transform:scale(1);filter:drop-shadow(0 0 2px rgba(96,165,250,.4))}100%{transform:scale(1.1);filter:drop-shadow(0 0 8px rgba(96,165,250,.8))}}
        @keyframes mockupFloat{0%,100%{transform:translateY(0)}50%{transform:translateY(-12px)}}
        @keyframes pinPulse{0%{box-shadow:0 0 0 0 rgba(56,189,248,.4)}100%{box-shadow:0 0 0 18px rgba(56,189,248,0)}}
        .animate-fade-in{animation:fadeIn .8s ease-out forwards}
        .animate-slide-up{animation:slideUp .8s cubic-bezier(.2,.8,.2,1) forwards}
        .animate-slide-up-delay{opacity:0;animation:slideUp .8s cubic-bezier(.2,.8,.2,1) .2s forwards}
        .animate-slide-up-delay-2{opacity:0;animation:slideUp .8s cubic-bezier(.2,.8,.2,1) .4s forwards}
        @keyframes fadeIn{from{opacity:0}to{opacity:1}}
        @keyframes slideUp{from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)}}

        @media (max-width:968px){
          .hero-section{grid-template-columns:1fr;text-align:center;padding:4rem 1.5rem 4rem 1.5rem;gap:3rem}
          .tag-badge{margin-left:auto;margin-right:auto}
          .hero-title{font-size:3rem}
          .hero-desc{max-width:100%}
          .download-badges{justify-content:center}
          .map-view-card{animation:none}
          .identity-strip{grid-template-columns:repeat(2,1fr);gap:1.2rem}
          .feature-row{grid-template-columns:1fr;gap:2rem}
          .feature-row.reverse .feature-visual{order:0}
          .timeline{grid-template-columns:1fr;gap:2.5rem}
          .timeline::before{display:none}
          .section-title{font-size:2.1rem}
          .cta-title{font-size:1.9rem}
          .systems-grid{grid-template-columns:repeat(2,1fr)}
        }
      ` }} />
    </div>
  );
}
