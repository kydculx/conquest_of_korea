import React from 'react';

const PLAY_URL = '#pre-register';
const APPLE_URL = 'https://apps.apple.com/kr/app/%EC%B0%9C-%EB%8C%80%EB%AA%A8%ED%97%98/id6769717240';

function StoreButtons({ dark = false }) {
  return (
    <div className="pp-stores">
      <a className="pp-badge" href={PLAY_URL}>
        <img src="/badge_google_play.svg" alt="Google Play 사전체험 신청" />
      </a>
      <a className="pp-badge" href={APPLE_URL} target="_blank" rel="noopener noreferrer">
        <img src="/badge_app_store.svg" alt="App Store에서 다운로드" />
      </a>
      {!dark && null}
    </div>
  );
}

const MODES = [
  { no: '01', title: '먼저 가서 남기기', desc: '아무도 다녀가지 않은 곳에 가장 먼저 내 영역 표시.' },
  { no: '02', title: '넓히고 지키기', desc: '매일 다니는 길은 내 영역으로. 자주 갈수록 단단해집니다.' },
  { no: '03', title: '뺏고 뺏기기', desc: '다른 사람의 영역도 가져올 수 있습니다. 빼앗기면 되찾으러 가세요.' },
  { no: '04', title: '사진으로 기록', desc: '다녀온 곳에서 찍은 사진이 영역과 함께 저장됩니다.' },
  { no: '05', title: '주변 보물 줍기', desc: '주변에 떨어진 보물을 주우세요. 영역을 넓히는 데 사용합니다.' },
];

export default function PromoPage() {
  const [email, setEmail] = React.useState('');
  const [status, setStatus] = React.useState('idle');

  const submitPreRegister = async (e) => {
    e.preventDefault();
    if (status === 'sending') return;
    const trimmed = email.trim();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(trimmed)) {
      setStatus('invalid');
      return;
    }
    setStatus('sending');
    try {
      const base = import.meta.env.VITE_SUPABASE_URL;
      const key = import.meta.env.VITE_SUPABASE_ANON_KEY;
      const res = await fetch(`${base}/functions/v1/pre-register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', apikey: key, Authorization: `Bearer ${key}` },
        body: JSON.stringify({ email: trimmed }),
      });
      const data = await res.json();
      setStatus(data && data.success ? 'done' : 'error');
    } catch {
      setStatus('error');
    }
  };

  return (
    <div className="pp">
      <style dangerouslySetInnerHTML={{ __html: `
.pp{--paper:#0b0e17;--ink:#f2f4f8;--muted:#9aa3b2;--sun:#ffb020;--leaf:#34d399;--sky:#3aa7ff;--berry:#e0497f;--card:#141a28;background:var(--paper);color:var(--ink);min-height:100vh;font-family:Pretendard,'Apple SD Gothic Neo',system-ui,sans-serif;scroll-behavior:smooth}
.pp-inner{max-width:1060px;margin:0 auto;padding:0 22px}
.pp-top{display:flex;align-items:center;justify-content:space-between;padding:20px 0}
.pp-brand{display:flex;align-items:center;gap:12px;font-weight:900;font-size:1.2rem}
.pp-brand img{width:40px;height:40px;border-radius:11px;box-shadow:0 4px 14px rgba(0,0,0,.5)}
.pp-back{color:var(--muted);text-decoration:none;font-size:.92rem;font-weight:600}
.pp-back:hover{color:var(--ink)}
.pp-hero{display:grid;grid-template-columns:1.05fr .95fr;gap:36px;align-items:center;padding:44px 0 30px}
.pp-kicker{display:inline-block;background:rgba(255,176,32,.14);color:var(--sun);font-size:.8rem;font-weight:800;border-radius:999px;padding:7px 15px;margin-bottom:20px;letter-spacing:.02em;border:1px solid rgba(255,176,32,.35)}
.pp-h1{font-size:clamp(2.1rem,5.4vw,3.3rem);line-height:1.22;font-weight:900;margin:0 0 18px;letter-spacing:-.02em}
.pp-h1 .u-sun{color:var(--sun)}
.pp-h1 .u-leaf{color:var(--leaf)}
.pp-lead{color:var(--muted);font-size:1.04rem;line-height:1.75;margin:0 0 28px}
.pp-stores{display:flex;align-items:center;justify-content:center;gap:12px;flex-wrap:wrap}
.pp-badge{display:block;transition:transform .2s ease}
.pp-badge:hover{transform:translateY(-2px)}
.pp-badge img{height:54px;display:block}
.pp-free{font-size:.85rem;font-weight:700;color:var(--leaf)}
.pp-hero-art{position:relative;display:flex;justify-content:center;perspective:1200px}
.pp-phone{position:relative;width:min(270px,68vw);border-radius:44px;padding:12px;background:linear-gradient(160deg,#2a3247,#0d1120);box-shadow:0 40px 90px rgba(0,0,0,.65),0 0 0 1px rgba(255,255,255,.12),0 0 90px rgba(255,176,32,.14);transform:rotateY(-14deg) rotateX(4deg);animation:pp-float 6s ease-in-out infinite}
.pp-phone::before{content:'';position:absolute;top:22px;left:50%;transform:translateX(-50%);width:96px;height:26px;background:#0b0e17;border-radius:999px;z-index:2}
.pp-phone img{width:100%;border-radius:34px;display:block;aspect-ratio:9/19.2;object-fit:cover}
.pp-screen-fake{border-radius:34px;aspect-ratio:9/19.2;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:12px;background:radial-gradient(circle at 50% 30%,#2b3a55,#0d1120 70%)}
.pp-screen-fake.f2{background:radial-gradient(circle at 50% 30%,#3a2b4d,#0d1120 70%)}
.pp-screen-fake img{width:84px !important;border-radius:22px !important;aspect-ratio:auto !important;box-shadow:0 14px 34px rgba(0,0,0,.5)}
.pp-screen-fake strong{font-size:1.2rem}
.pp-screen-fake span{color:var(--muted);font-size:.85rem}
.pp-phone.back{position:absolute;width:min(220px,56vw);opacity:.55;filter:blur(1px) brightness(.75);transform:rotateY(14deg) rotateX(4deg) translateX(56%) translateY(26px);animation:none;box-shadow:0 30px 70px rgba(0,0,0,.55)}
.pp-phone.back img{aspect-ratio:9/19.2}
@keyframes pp-float{0%,100%{transform:rotateY(-14deg) rotateX(4deg) translateY(0)}50%{transform:rotateY(-14deg) rotateX(4deg) translateY(-14px)}}
.pp-chip{position:absolute;background:#1c2333;color:#fff;border:1px solid rgba(255,255,255,.12);border-radius:14px;padding:10px 16px;font-weight:800;font-size:.9rem;box-shadow:0 12px 30px rgba(0,0,0,.5);z-index:3;animation:pp-float 6s ease-in-out infinite}
.pp-chip.c1{top:12%;left:0;transform:rotate(-4deg)}
.pp-chip.c2{bottom:14%;right:0;transform:rotate(3deg)}
.pp-sec{padding:56px 0 6px}
.pp-sec-h{font-size:1.55rem;font-weight:900;margin:0 0 8px}
.pp-sec-sub{color:var(--muted);margin:0 0 28px}
.pp-modes{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:14px}
.pp-mode{background:var(--card);border:1px solid rgba(255,255,255,.09);border-radius:18px;padding:26px 20px}
.pp-mode .no{font-weight:900;color:var(--sun);font-size:.85rem;letter-spacing:.1em}
.pp-mode h3{margin:10px 0 8px;font-size:1.08rem}
.pp-mode p{margin:0;color:var(--muted);font-size:.92rem;line-height:1.65}
.pp-perks{display:grid;grid-template-columns:repeat(2,1fr);gap:14px}
.pp-perk{display:flex;gap:14px;background:var(--card);border:1px solid rgba(255,255,255,.09);border-radius:18px;padding:22px 20px}
.pp-perk .e{font-size:1.7rem}
.pp-perk h3{margin:2px 0 6px;font-size:1rem}
.pp-perk p{margin:0;color:var(--muted);font-size:.89rem;line-height:1.6}
.pp-shots{display:flex;gap:26px;justify-content:center;perspective:1400px;flex-wrap:wrap}
.pp-shot{width:min(230px,60vw);border-radius:40px;padding:10px;background:linear-gradient(165deg,#2a3247,#0d1120);box-shadow:0 34px 70px rgba(0,0,0,.6),0 0 0 1px rgba(255,255,255,.1);position:relative}
.pp-shot::before{content:'';position:absolute;top:19px;left:50%;transform:translateX(-50%);width:80px;height:22px;background:#0b0e17;border-radius:999px;z-index:2}
.pp-shot img{width:100%;border-radius:30px;display:block;aspect-ratio:9/19.2;object-fit:cover}
.pp-shot:nth-child(odd){transform:rotateY(12deg) rotateX(3deg)}
.pp-shot:nth-child(even){transform:rotateY(-12deg) rotateX(3deg)}
.pp-faq{border-top:1px solid rgba(255,255,255,.1)}
.pp-qa{border-bottom:1px solid rgba(255,255,255,.1)}
.pp-qa button{width:100%;background:none;border:none;display:flex;justify-content:space-between;align-items:center;padding:20px 4px;font-size:1rem;font-weight:800;color:var(--ink);cursor:pointer;font-family:inherit}
.pp-qa p{margin:0 0 20px;padding:0 4px;color:var(--muted);line-height:1.7;font-size:.93rem}
.pp-cta{margin:60px 0;background:#141a28;border:1px solid rgba(255,176,32,.3);border-radius:24px;padding:52px 30px;text-align:center;position:relative;overflow:hidden}
.pp-cta::before{content:'';position:absolute;top:-90px;right:-90px;width:300px;height:300px;background:radial-gradient(circle,rgba(255,176,32,.25),transparent 65%)}
.pp-cta::after{content:'';position:absolute;bottom:-110px;left:-70px;width:320px;height:320px;background:radial-gradient(circle,rgba(58,167,255,.22),transparent 65%)}
.pp-cta h2{margin:0 0 10px;font-size:1.7rem;font-weight:900;position:relative;z-index:1}
.pp-cta p{margin:0 0 26px;color:var(--muted);position:relative;z-index:1}
.pp-cta .pp-stores{justify-content:center;position:relative;z-index:1}
.pp-cta .pp-store-btn{background:#fff;color:#0b0e17}
.pp-cta .pp-free{color:var(--sun)}
.pp-reglist{list-style:none;margin:0 auto 28px;padding:0;max-width:520px;position:relative;z-index:1;text-align:left;display:flex;flex-direction:column;gap:10px}
.pp-reglist li{display:flex;gap:14px;align-items:flex-start;background:rgba(255,255,255,.05);border:1px solid rgba(255,255,255,.1);border-radius:14px;padding:16px 18px}
.pp-reg-n{flex:none;width:30px;height:30px;border-radius:50%;background:var(--sun);color:#0b0e17;font-weight:900;font-size:.9rem;display:flex;align-items:center;justify-content:center}
.pp-reglist strong{display:block;font-size:.95rem;margin-bottom:4px}
.pp-reglist span{font-size:.85rem;color:var(--muted);line-height:1.55}
.pp-form{max-width:520px;margin:28px auto 0;position:relative;z-index:1;background:rgba(255,255,255,.05);border:1px solid rgba(255,255,255,.12);border-radius:20px;padding:30px 26px}
.pp-form-row{display:flex;gap:12px;margin-bottom:18px}
.pp-form input{flex:1;background:#0b0e17;border:1px solid rgba(255,255,255,.16);border-radius:13px;padding:15px 17px;color:#fff;font-size:.95rem;min-width:0;font-family:inherit;transition:border-color .2s ease}
.pp-form input:focus{outline:none;border-color:var(--sun)}
.pp-form input::placeholder{color:var(--muted)}
.pp-form button{background:linear-gradient(135deg,var(--sun),#ff8a3d);color:#0b0e17;font-weight:900;border:none;border-radius:13px;padding:15px 26px;font-size:.95rem;cursor:pointer;font-family:inherit;white-space:nowrap;transition:transform .2s ease,box-shadow .2s ease}
.pp-form button:hover:not(:disabled){transform:translateY(-2px);box-shadow:0 10px 26px rgba(255,176,32,.35)}
.pp-form button:disabled{opacity:.6;cursor:default}
.pp-form-hint{margin:14px 0 0;font-size:.82rem;color:var(--muted)}
.pp-form-ok{color:var(--leaf);font-weight:800;position:relative;z-index:1;font-size:1.05rem}
.pp-form-err{color:#ff7b8a;font-size:.85rem;margin:10px 0 0}
.pp-foot{display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:10px;padding:26px 0 44px;color:var(--muted);font-size:.83rem}
.pp-foot a{color:var(--muted);text-decoration:none;margin-left:16px}
.pp-foot a:hover{color:var(--ink)}
@media(max-width:820px){.pp-hero{grid-template-columns:1fr;padding:32px 0 20px}.pp-modes{grid-template-columns:1fr}.pp-perks{grid-template-columns:1fr}.pp-shots{grid-template-columns:1fr}.pp-steps{grid-template-columns:1fr}.pp-chip.c1{left:4px}.pp-chip.c2{right:4px}.pp-phone{width:min(230px,64vw)}.pp-phone.back{display:none}.pp-cta{padding:40px 20px;margin:44px 0}.pp-sec{padding:44px 0 4px}.pp-foot{flex-direction:column;align-items:flex-start}.pp-form-row{flex-direction:column}.pp-form button{width:100%}}
      ` }} />

      <div className="pp-inner">
        <nav className="pp-top">
          <div className="pp-brand">
            <img src="/app_icon.png" alt="찜! 모험" />
            <span>찜! 모험</span>
          </div>
        </nav>

        <header className="pp-hero">
          <div>
            <span className="pp-kicker">지나간 모든 곳이 내 영역</span>
            <h1 className="pp-h1">내가 이동하는 모든 곳이<br /><span className="u-sun">나의 영역</span>이 된다</h1>
            <p className="pp-lead">
              출근길, 산책길, 여행지까지.
              발길이 닿은 곳마다 지도 위에 내 영역으로 남습니다.
            </p>
            <StoreButtons />
          </div>
          <div className="pp-hero-art">
            <div className="pp-phone back"><div className="pp-screen-fake f2" /></div>
            <div className="pp-phone">
              <div className="pp-screen-fake">
                <img src="/app_icon.png" alt="찜! 모험" />
                <strong>찜! 모험</strong>
                <span>오늘 걸은 길을 저장하세요</span>
              </div>
            </div>
            <div className="pp-chip c1">🚶 오늘 영역 +12</div>
            <div className="pp-chip c2">📍 우리 집 앞도 내 영역</div>
          </div>
        </header>

        <section className="pp-sec">
          <h2>이렇게 사용하세요</h2>
          <p className="pp-sec-sub">평소대로 걸으면 됩니다.</p>
          <div className="pp-modes">
            {MODES.map((m) => (
              <div className="pp-mode" key={m.no}>
                <div className="no">MODE {m.no}</div>
                <h3>{m.title}</h3>
                <p>{m.desc}</p>
              </div>
            ))}
          </div>
        </section>

        <section className="pp-sec">
          <h2>이런 활동에 어울립니다</h2>
          <p className="pp-sec-sub">평소 즐기는 야외 활동 그대로.</p>
          <div className="pp-modes">
            <div className="pp-mode"><div className="no">RUN</div><h3>달리기</h3><p>러닝 코스마다 영역이 늘어납니다.</p></div>
            <div className="pp-mode"><div className="no">WALK</div><h3>산책</h3><p>동네 한 바퀴가 기록으로 남습니다.</p></div>
            <div className="pp-mode"><div className="no">HIKE</div><h3>등산</h3><p>오른 봉우리마다 내 영역으로.</p></div>
            <div className="pp-mode"><div className="no">RIDE</div><h3>자전거</h3><p>라이딩 경로가 길게 이어집니다.</p></div>
            <div className="pp-mode"><div className="no">DOG</div><h3>반려견 산책</h3><p>매일 같은 코스도 날짜마다 새 기록.</p></div>
            <div className="pp-mode"><div className="no">TRIP</div><h3>여행</h3><p>처음 가는 도시 전체가 내 영역으로.</p></div>
            <div className="pp-mode"><div className="no">HEALTH</div><h3>건강 걷기</h3><p>만보 목표와 영역 확장을 한 번에.</p></div>
          </div>
        </section>

        <section className="pp-cta" id="pre-register">
          <h2>Android 비공개 사전체험 모집 중</h2>
          <p>이메일 남기면 설치 안내 발송.</p>
          <ol className="pp-reglist">
            <li>
              <span className="pp-reg-n">1</span>
              <div>
                <strong>이메일 입력 후 신청</strong>
                <span>안내받을 주소 입력.</span>
              </div>
            </li>
            <li>
              <span className="pp-reg-n">2</span>
              <div>
                <strong>메일 확인</strong>
                <span>설치 링크 발송. 스팸함 확인.</span>
              </div>
            </li>
            <li>
              <span className="pp-reg-n">3</span>
              <div>
                <strong>설치 후 즐기기</strong>
                <span>안내대로 설치, 바로 시작.</span>
              </div>
            </li>
          </ol>
          {status === 'done' ? (
            <p className="pp-form-ok">신청 완료. 안내 메일을 보내드릴게요.</p>
          ) : (
            <form className="pp-form" onSubmit={submitPreRegister}>
              <div className="pp-form-row">
                <input
                  type="email"
                  placeholder="이메일 주소 입력"
                  value={email}
                  onChange={(e) => { setEmail(e.target.value); setStatus('idle'); }}
                />
                <button type="submit" disabled={status === 'sending'}>
                  {status === 'sending' ? '보내는 중…' : '신청하기'}
                </button>
              </div>
              {status === 'invalid' && <p className="pp-form-err">이메일 형식을 확인해주세요.</p>}
              {status === 'error' && <p className="pp-form-err">전송 실패. 잠시 후 다시 시도해주세요.</p>}
            </form>
          )}
        </section>

        <footer className="pp-foot">
          <span>© 찜! 모험 (Dibs! Adventure)</span>
        </footer>
      </div>
    </div>
  );
}
