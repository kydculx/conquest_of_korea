import React from 'react';
import { Shield } from 'lucide-react';

export default function TermsPage() {
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
        <div style={{ display: 'flex', justifyContent: 'flex-end', alignItems: 'center', marginBottom: '3rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <Shield size={18} style={{ color: '#3b82f6' }} />
            <span style={{ fontSize: '0.85rem', color: '#64748b', fontWeight: 600, fontFamily: 'var(--font-display)' }}>
              찜! 대모험
            </span>
          </div>
        </div>

        {/* 본문 콘텐츠 */}
        <article className="tactical-card" style={{ background: '#111827', borderColor: '#1f2937', padding: '2.5rem', lineHeight: 1.7 }}>
          <h1 style={{ fontSize: '2rem', fontWeight: 800, marginBottom: '1.5rem', fontFamily: 'var(--font-display)' }}>
            서비스 이용약관
          </h1>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1.8rem', fontSize: '0.95rem' }}>
            <section>
              <h3 style={{ fontSize: '1.15rem', color: '#3b82f6', marginBottom: '0.6rem' }}>제 1 조 (목적)</h3>
              <p style={{ color: '#d1d5db' }}>
                본 약관은 '찜! 대모험'(이하 '회사' 또는 '서비스')이 제공하는 모바일 위치기반 게임 서비스 및 이에 부수되는 제반 서비스(이하 '서비스')를 이용하는 플레이어(이하 '플레이어' 또는 '회원')와 회사 간의 서비스 이용에 관한 권리, 의무 및 책임 사항, 기타 필요한 사항을 규정함을 목적으로 합니다.
              </p>
            </section>

            <section>
              <h3 style={{ fontSize: '1.15rem', color: '#3b82f6', marginBottom: '0.6rem' }}>제 2 조 (약관의 효력 및 변경)</h3>
              <ul style={{ paddingLeft: '1.2rem', color: '#d1d5db', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                <li>1. 본 약관은 서비스 가입 시 동의함으로써 효력이 발생하며, 회사는 플레이어가 본 약관의 내용을 쉽게 알 수 있도록 게임 서비스 초기화면이나 공식 웹사이트에 게시합니다.</li>
                <li>2. 회사는 관련 법령을 위배하지 않는 범위에서 본 약관을 개정할 수 있습니다.</li>
                <li>3. 약관이 개정되는 경우 변경예정일 7일 전(플레이어에게 불리하거나 중요한 변경의 경우 30일 전)에 서비스 내 공지사항 또는 웹페이지를 통해 공지합니다. 플레이어가 개정 약관의 적용일 이후에도 서비스를 계속 이용하는 경우 변경된 약관에 동의한 것으로 봅니다. 동의하지 않는 플레이어는 회원 탈퇴를 통해 이용계약을 해지할 수 있습니다.</li>
              </ul>
            </section>

            <section>
              <h3 style={{ fontSize: '1.15rem', color: '#3b82f6', marginBottom: '0.6rem' }}>제 3 조 (약관 외 준칙)</h3>
              <p style={{ color: '#d1d5db' }}>
                본 약관에 명시되지 않은 사항과 본 약관의 해석에 관하여는 「모바일게임 표준약관」, 「위치정보의 보호 및 이용 등에 관한 법률」, 「개인정보 보호법」 및 관계법령 또는 상관례에 따릅니다.
              </p>
            </section>

            <section>
              <h3 style={{ fontSize: '1.15rem', color: '#3b82f6', marginBottom: '0.6rem' }}>제 4 조 (이용계약의 성립 및 신청)</h3>
              <ul style={{ paddingLeft: '1.2rem', color: '#d1d5db', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                <li>1. 이용계약은 플레이어가 본 약관 및 개인정보 처리방침에 동의하고 계정 생성을 신청하여 회사가 이를 승인함으로써 성립합니다.</li>
                <li>2. 가입신청자는 실제 본인의 단말기 고유 식별값(UUID) 또는 외부 인증 플랫폼(Google, Apple 등)을 연동하여 정상적인 가입 정보를 제공해야 합니다. 타인의 개인정보를 도용하거나 허위 정보를 등록한 플레이어는 본 약관에 따른 권리를 주장할 수 없으며, 회사는 이용계약을 해지하거나 가입을 취소할 수 있습니다.</li>
                <li>3. 만 14세 미만 아동의 회원가입은 원칙적으로 허용되지 않으며, 법정대리인의 동의가 있는 예외적인 경우에 한하여 회원가입이 승인될 수 있습니다.</li>
              </ul>
            </section>

            <section>
              <h3 style={{ fontSize: '1.15rem', color: '#3b82f6', marginBottom: '0.6rem' }}>제 5 조 (개인정보의 보호 및 관리)</h3>
              <ul style={{ paddingLeft: '1.2rem', color: '#d1d5db', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                <li>1. 회사는 관련 법령이 정하는 바에 따라 플레이어의 개인정보를 보호하기 위해 노력하며, 개인정보의 보호 및 사용에 대해서는 관련 법령 및 회사의 별도 '개인정보 처리방침'이 적용됩니다.</li>
                <li>2. 서비스의 특성상 플레이어가 설정한 닉네임과 확보한 영토의 현황 등 게임 내에서 다른 플레이어에게 공개되도록 설정된 정보는 플레이어 간의 원활한 상호작용을 위해 제한적으로 노출될 수 있습니다.</li>
              </ul>
            </section>

            <section>
              <h3 style={{ fontSize: '1.15rem', color: '#3b82f6', marginBottom: '0.6rem' }}>제 6 조 (위치기반 서비스의 내용 및 이용)</h3>
              <p style={{ color: '#d1d5db', marginBottom: '0.5rem' }}>
                회사가 제공하는 위치기반 서비스는 다음과 같으며, 플레이어의 실시간 기기 GPS 정보 및 네트워크 기지국 위치 정보를 수신하여 처리합니다.
              </p>
              <ul style={{ paddingLeft: '1.2rem', color: '#d1d5db', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                <li>1. 실시간 영토 점령 처리: 플레이어가 모바일 기기를 지참하고 특정 헥사곤(H3 그리드) 영역에 진입하였을 때 해당 위치의 위경도 좌표를 연산하여 해당 플레이어의 영토로 확보 및 기록하는 서비스.</li>
                <li>2. 거리 비례 재화 연산 및 본진 기지 설정: 플레이어가 지정한 본진 기지 좌표로부터의 직선거리를 산출하여 게임 내 가상 재화인 골드(GP) 획득 속도 등을 조절하고 원격 기능 수행 범위를 제어하는 서비스.</li>
              </ul>
            </section>

            <section>
              <h3 style={{ fontSize: '1.15rem', color: '#3b82f6', marginBottom: '0.6rem' }}>제 7 조 (개인위치정보주체의 권리 및 행사방법)</h3>
              <ul style={{ paddingLeft: '1.2rem', color: '#d1d5db', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                <li>1. 플레이어는 언제든지 위치정보 수집·이용·제공 동의의 전부 또는 일부를 철회할 수 있습니다. 동의를 철회하는 경우, 위치 기반 서비스의 제공이 즉시 중단되며 회원은 계정 삭제 또는 서비스 이용 불가를 선택할 수 있습니다.</li>
                <li>2. 플레이어는 언제든지 위치정보의 수집·이용·제공의 일시적인 중지를 요구할 수 있으며, 회사는 이를 위한 기술적 수단을 제공하고 즉시 이행합니다.</li>
                <li>3. 플레이어는 회사에 대해 본인에 대한 위치정보 수집/이용/제공사실 확인자료 및 제3자 제공 내역에 대한 열람 또는 고지를 요구할 수 있으며 오류가 있는 경우 정정을 요구할 수 있습니다.</li>
              </ul>
            </section>

            <section>
              <h3 style={{ fontSize: '1.15rem', color: '#3b82f6', marginBottom: '0.6rem' }}>제 8 조 (사용자 생성 콘텐츠 (UGC)에 관한 정책)</h3>
              <ul style={{ paddingLeft: '1.2rem', color: '#d1d5db', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                <li>1. 플레이어가 게임 내에서 생성하는 닉네임, 프로필 등 모든 항목은 사용자 생성 콘텐츠(UGC)로 분류됩니다.</li>
                <li>2. 음란, 욕설, 타인 비방, 광고 등 사회 통념상 부적절하거나 타인의 권리를 침해하는 유해한 콘텐츠 생성 행위는 엄격히 금지됩니다.</li>
                <li style={{ color: '#fca5a5' }}>3. 플레이어는 다른 회원의 유해 콘텐츠 및 불적절한 행위를 앱 내 신고 또는 차단 기능을 통해 즉각 접수할 수 있습니다.</li>
                <li style={{ color: '#fca5a5' }}>4. 회사는 신고가 접수된 유해 콘텐츠를 24시간 이내에 검토 및 모니터링하여 삭제, 정정 조치하고, 해당 유해 콘텐츠를 게시한 플레이어의 앱 이용을 즉각 제한(임시/영구 이용정지 등)하여 정화된 서비스 환경을 보장합니다.</li>
              </ul>
            </section>

            <section>
              <h3 style={{ fontSize: '1.15rem', color: '#3b82f6', marginBottom: '0.6rem' }}>제 9 조 (회사의 의무)</h3>
              <ul style={{ paddingLeft: '1.2rem', color: '#d1d5db', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                <li>1. 회사는 관련 법령과 본 약관이 금지하거나 미풍양속에 반하는 행위를 하지 않으며, 계속적이고 안정적인 서비스를 제공하기 위하여 최선을 다합니다.</li>
                <li>2. 회사는 플레이어가 안전하게 서비스를 이용할 수 있도록 개인정보 및 위치정보 보호를 위한 보안 시스템을 구축하고 운영합니다.</li>
                <li>3. 회사는 서비스 이용과 관련하여 플레이어로부터 제기된 의견이나 불만이 정당하다고 인정할 경우에는 지체 없이 이를 처리합니다.</li>
              </ul>
            </section>

            <section>
              <h3 style={{ fontSize: '1.15rem', color: '#3b82f6', marginBottom: '0.6rem' }}>제 10 조 (플레이어의 의무 및 금지행위)</h3>
              <p style={{ color: '#d1d5db', marginBottom: '0.5rem' }}>
                플레이어는 서비스 이용과 관련하여 다음 각 호에 해당하는 행위를 하여서는 안 됩니다.
              </p>
              <ul style={{ paddingLeft: '1.2rem', color: '#d1d5db', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                <li>1. 회원 가입 또는 정보 변경 시 타인의 이메일, 계정 정보, 기기 고유 식별값(UUID)을 무단 조용하거나 도용하여 허위 정보를 등록하는 행위.</li>
                <li style={{ color: '#fca5a5' }}>2. 실제 현장에 방문하지 않고 GPS 위조 소프트웨어(GPS Spoofing), 에뮬레이터 위치 조작 도구 등을 사용하여 비정상적인 방법으로 가상의 위치 좌표를 전송해 영토를 획득하는 행위.</li>
                <li>3. 회사가 제공하는 게임 클라이언트 프로그램을 개조하거나 서버 통신 데이터를 조작, 위조하는 행위.</li>
                <li>4. 게임 내의 오류나 버그를 의도적으로 악용하여 비정상적으로 골드(GP)를 획득하거나 비정상적인 영토 점령 상태를 유도하는 행위.</li>
              </ul>
            </section>

            <section>
              <h3 style={{ fontSize: '1.15rem', color: '#3b82f6', marginBottom: '0.6rem' }}>제 11 조 (비정상 플레이에 대한 제재 및 패널티)</h3>
              <ul style={{ paddingLeft: '1.2rem', color: '#d1d5db', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                <li>1. 회사는 금지행위를 위반한 플레이어에 대해 위반 행위의 경중에 따라 아래의 제재를 단계적 또는 즉각적으로 적용할 수 있습니다.</li>
                <li style={{ paddingLeft: '1rem' }}>가. 경고: 1차 경고 및 비정상 행동 중단 요구.</li>
                <li style={{ paddingLeft: '1rem', color: '#fca5a5' }}>나. 영토 몰수 및 초기화: 비정상적인 위치 조작이나 버그 악용을 통해 확보된 모든 영토는 사전 통지 없이 강제 회수되며 즉시 중립 영토로 전환 및 초기화됩니다.</li>
                <li style={{ paddingLeft: '1rem' }}>다. 계정 이용 제한: 일정 기간 동안 게임 접속 및 영토 점령 등의 전체 서비스 이용을 정지합니다.</li>
                <li style={{ paddingLeft: '1rem', color: '#fca5a5' }}>라. 영구 탈퇴 및 재가입 제한: 불법 프로그램 제작, 유포, 반복적인 위치 위조 등 악의적인 어뷰징이 확인된 경우 계정을 영구 삭제하며 해당 기기 식별자를 차단하여 재가입을 원천 제한합니다.</li>
                <li>2. 플레이어는 본 조의 제재에 대해 불복할 경우, 제재 고지를 받은 날로부터 7일 이내에 이메일을 통해 이의신청을 제출할 수 있습니다.</li>
              </ul>
            </section>

            <section>
              <h3 style={{ fontSize: '1.15rem', color: '#3b82f6', marginBottom: '0.6rem' }}>제 12 조 (인앱 결제 및 청약 철회)</h3>
              <ul style={{ paddingLeft: '1.2rem', color: '#d1d5db', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                <li>1. 게임 내 유료 상품이나 인앱 결제가 도입될 경우, 플레이어는 구매일로부터 7일 이내에 미사용 콘텐츠에 대해 청약 철회(구매 취소)를 요청할 수 있습니다.</li>
                <li style={{ color: '#fca5a5' }}>2. 만 14세 이상의 미성년자 플레이어가 법정대리인의 동의 없이 인앱 결제를 진행한 경우, 미성년자 본인 또는 법정대리인은 결제를 취소할 수 있습니다. 단, 미성년자가 속임수를 사용해 회사가 성년자로 믿게 한 경우 등은 취소가 제한됩니다.</li>
                <li>3. 인앱 결제 및 환불은 Apple App Store 및 Google Play Store 등 플랫폼 오픈마켓 사업자의 정책 및 환불 가이드라인을 최우선적으로 적용하여 공정하게 처리됩니다.</li>
              </ul>
            </section>

            <section>
              <h3 style={{ fontSize: '1.15rem', color: '#3b82f6', marginBottom: '0.6rem' }}>제 13 조 (게임 내 가상 재화 및 콘텐츠)</h3>
              <ul style={{ paddingLeft: '1.2rem', color: '#d1d5db', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                <li>1. '골드(GP)'는 게임 서비스 내에서 영토 확보 및 특정 모드를 구동하기 위해 사용되는 무상의 가상 데이터 재화입니다.</li>
                <li>2. 골드(GP)는 회원 가입 유지, 영토 점령 수 및 점령 지속 시간 등에 비례하여 시스템적으로 자동 누적 제공되며, 현실의 재화가 아닙니다.</li>
                <li>3. 플레이어는 골드(GP) 및 영토 등의 게임 내 데이터를 타인에게 유상으로 판매, 양도, 대여하거나 실제 현금으로 환전하는 모든 거래 행위를 할 수 없습니다.</li>
                <li>4. 서비스 해지(회원 탈퇴) 시 플레이어가 보유 중이던 골드(GP)와 점령 영토 데이터는 전부 소멸하며 복구할 수 없습니다.</li>
              </ul>
            </section>

            <section>
              <h3 style={{ fontSize: '1.15rem', color: '#3b82f6', marginBottom: '0.6rem' }}>제 14 조 (서비스의 변경 및 중단)</h3>
              <ul style={{ paddingLeft: '1.2rem', color: '#d1d5db', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                <li>1. 회사는 운영상, 기술상의 필요 또는 서비스 활성화를 위한 패치, 시스템 점검 등의 사유로 제공 중인 서비스의 전부 또는 일부를 변경하거나 일시 중단할 수 있습니다.</li>
                <li>2. 서비스 점검 및 정기 패치의 경우 사전에 서비스 공지사항 또는 웹페이지를 통해 중단 시간과 사유를 고지합니다. 단, 긴급 서버 장애, 해킹 사고 등 부득이한 사유가 있는 경우 사후에 고지할 수 있습니다.</li>
                <li>3. 회사는 무료로 제공되는 서비스의 변경 또는 중단으로 인해 플레이어에게 발생하는 손해에 대해 관련 법령에 특별한 규정이 없는 한 어떠한 책임을 지지 않습니다.</li>
              </ul>
            </section>

            <section>
              <h3 style={{ fontSize: '1.15rem', color: '#3b82f6', marginBottom: '0.6rem' }}>제 15 조 (손해배상 및 면책)</h3>
              <ul style={{ paddingLeft: '1.2rem', color: '#d1d5db', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                <li>1. 회사는 천재지변, 전쟁, 국가 비상사태, 기간통신사업자의 회선 장애 또는 GPS 위성 신호 장애 등 불가항력적인 외부 요인으로 인해 서비스를 제공할 수 없는 경우 책임이 면제됩니다.</li>
                <li>2. 회사는 플레이어 개개인의 단말기 성능, 기기 설정(위치 권한 미허용, 절전 모드 등), GPS 오차 또는 통신 상태 불량으로 인하여 발생한 영토 획득 판정 실패, 골드 누적 오류 및 데이터 지연에 대하여 책임을 지지 않습니다.</li>
                <li>3. 플레이어는 실제 야외 도보 및 이동을 통해 영토를 확보하는 위치기반 게임의 성격을 충분히 인지해야 하며, 주변 환경의 위험성에 대비하여 모든 안전 수칙을 스스로 준수해야 합니다. 회사는 플레이어 본인의 부주의로 발생한 어떠한 신체적 상해, 사고에 대해서도 책임을 지지 않습니다.</li>
              </ul>
            </section>

            <section>
              <h3 style={{ fontSize: '1.15rem', color: '#3b82f6', marginBottom: '0.6rem' }}>제 16 조 (이용계약의 해지 및 탈퇴)</h3>
              <ul style={{ paddingLeft: '1.2rem', color: '#d1d5db', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                <li>1. 플레이어는 언제든지 게임 내 설정 메뉴 of '계정 삭제' 기능을 통해 서비스 이용 계약 해지(탈퇴)를 신청할 수 있습니다.</li>
                <li style={{ color: '#fca5a5' }}>2. 회원 탈퇴 시 플레이어가 점령했던 모든 헥사곤 영토는 즉시 중립화 상태로 전환되어 다른 플레이어가 자유롭게 획득할 수 있게 되며, 보유하고 있던 모든 가상 재화와 전적 통계, 수집된 식별 데이터는 복구 불가능한 상태로 실서버 DB에서 즉시 완전 삭제(Cascade Delete)됩니다.</li>
              </ul>
            </section>

            <section>
              <h3 style={{ fontSize: '1.15rem', color: '#3b82f6', marginBottom: '0.6rem' }}>제 17 조 (준거법 및 관할법원)</h3>
              <ul style={{ paddingLeft: '1.2rem', color: '#d1d5db', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                <li>1. 본 약관은 대한민국 법률에 따라 해석되고 적용됩니다.</li>
                <li>2. 회사와 플레이어 간에 서비스 이용과 관련하여 발생한 분쟁에 대해 소송이 제기될 경우, 대한민국 민사소송법상 관할 법원을 합의 관할 법원으로 합니다.</li>
              </ul>
            </section>
          </div>
        </article>
      </div>
    </div>
  );
}
