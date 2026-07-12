import React from 'react';
import { useSearchParams } from 'react-router-dom';
import { Shield } from 'lucide-react';

export default function PrivacyPage() {
  const [searchParams] = useSearchParams();
  const isEnglish = searchParams.get('lang') === 'en';

  const renderKorean = () => (
    <article className="tactical-card" style={{ background: '#111827', borderColor: '#1f2937', padding: '2.5rem', lineHeight: 1.7 }}>
      <h1 style={{ fontSize: '2rem', fontWeight: 800, marginBottom: '1.5rem', fontFamily: 'var(--font-display)' }}>
        개인정보 처리방침
      </h1>
      <p style={{ color: '#94a3b8', fontSize: '0.9rem', marginBottom: '2rem' }}>
        시행일자: 2026년 6월 7일
      </p>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '1.8rem', fontSize: '0.95rem' }}>
        <section>
          <h3 style={{ fontSize: '1.15rem', color: '#8b5cf6', marginBottom: '0.6rem' }}>1. 개인정보의 처리 목적</h3>
          <p style={{ color: '#d1d5db' }}>
            본 서비스는 회원 가입 및 계정 관리, 위치기반 서비스 제공(실시간 영토 점령 연산 및 본진 기지 좌표 계산), 인게임 랭킹 산출, 실시간 영토 변동 푸시 알림 발송 및 플레이어 민원 처리를 목적으로 최소한의 개인정보를 처리합니다.
          </p>
        </section>

        <section>
          <h3 style={{ fontSize: '1.15rem', color: '#8b5cf6', marginBottom: '0.6rem' }}>2. 개인정보의 수집 및 이용 항목</h3>
          <p style={{ color: '#d1d5db', marginBottom: '0.5rem' }}>
            회사는 서비스 제공을 위해 아래와 같은 개인정보 항목을 수집하고 있습니다.
          </p>
          <ul style={{ paddingLeft: '1.2rem', color: '#d1d5db', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
            <li><strong>회원가입 시 수집 항목:</strong> 이메일 주소, 외부 인증 플랫폼(Google, Apple 등) 식별 고유키, 프로필 닉네임</li>
            <li><strong>자동 수집 및 처리 항목:</strong> 단말기 고유 식별값(UUID), 접속 로그, OS 버전 및 기기 모델 정보</li>
            <li><strong>위치기반 서비스 수집 항목:</strong> 플레이어 단말기의 실시간 GPS 위도·경도 좌표 데이터 및 이동 속도 정보 (백그라운드 모드 실행 시 백그라운드 수집 정보 포함)</li>
          </ul>
        </section>

        <section>
          <h3 style={{ fontSize: '1.15rem', color: '#8b5cf6', marginBottom: '0.6rem' }}>3. 개인정보의 보유 및 이용 기간</h3>
          <p style={{ color: '#d1d5db' }}>
            회원의 개인정보 및 영토 데이터는 회원 탈퇴 시 실서버 데이터베이스에서 즉시 100% 영구 삭제(Cascade Delete) 및 영토 중립화 처리됩니다.
          </p>
        </section>

        <section>
          <h3 style={{ fontSize: '1.15rem', color: '#8b5cf6', marginBottom: '0.6rem' }}>4. 개인정보의 파기 절차 및 방법</h3>
          <p style={{ color: '#d1d5db' }}>
            회사는 개인정보 보유기간의 경과, 처리목적 달성 등 개인정보가 불필요하게 되었을 때에는 지체 없이 해당 개인정보를 파기합니다. 전자적 파일 형태의 정보는 기록을 재생할 수 없는 기술적 방법을 사용하여 삭제하며, 종이 문서 등은 분쇄하거나 소각합니다.
          </p>
        </section>

        <section>
          <h3 style={{ fontSize: '1.15rem', color: '#8b5cf6', marginBottom: '0.6rem' }}>5. 개인정보의 제3자 제공 및 위탁</h3>
          <p style={{ color: '#d1d5db', marginBottom: '0.5rem' }}>
            회사는 서비스 제공을 위해 아래와 같이 전문 업체에 개인정보 처리를 위탁하고 있습니다.
          </p>
          <ul style={{ paddingLeft: '1.2rem', color: '#d1d5db', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
            <li><strong>Supabase:</strong> 실시간 분산형 클라우드 데이터베이스 인프라 제공 및 데이터 저장/처리 위탁 (보유기간: 회원 탈퇴 시 즉시 파기)</li>
            <li><strong>Firebase Cloud Messaging (Google LLC):</strong> 영토 변동 및 서비스 중요 이벤트 관련 실시간 푸시 알림 발송 처리 위탁 (보유기간: 푸시 발송 완료 시 즉시 파기)</li>
          </ul>
        </section>

        <section>
          <h3 style={{ fontSize: '1.15rem', color: '#8b5cf6', marginBottom: '0.6rem' }}>6. 플레이어의 계정 및 데이터 삭제 권리 (Account Deletion & Data Erasure)</h3>
          <ul style={{ paddingLeft: '1.2rem', color: '#d1d5db', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
            <li style={{ color: '#fca5a5' }}>1. 플레이어는 앱 내 설정 메뉴(계정 탈퇴) 또는 지정 지원 메일(kydculx@gmail.com)을 통해 언제든지 계정의 영구 탈퇴 및 수집된 데이터의 완전 말소를 요청할 권리가 있습니다.</li>
            <li style={{ color: '#fca5a5' }}>2. 탈퇴 및 삭제 요청이 접수되는 즉시, 플레이어의 개인 식별 데이터, 보유 골드 재화, 활동 전적 통계 및 확보했던 지도 내 영토 데이터는 실서버 데이터베이스에서 영구적으로 즉시 완전 삭제(Cascade Delete) 및 중립화되어 재사용이나 복구가 절대 불가능합니다.</li>
          </ul>
        </section>

        <section>
          <h3 style={{ fontSize: '1.15rem', color: '#8b5cf6', marginBottom: '0.6rem' }}>7. 정보주체 및 법정대리인의 권리·의무</h3>
          <p style={{ color: '#d1d5db' }}>
            플레이어는 회사에 대해 언제든지 개인정보 열람 요구, 오류 등의 정정 요구, 삭제 요구, 처리정지 요구 등의 권리를 행사할 수 있으며, 이메일을 통해 접수 시 회사는 이에 대해 지체 없이 조치합니다.
          </p>
        </section>

        <section>
          <h3 style={{ fontSize: '1.15rem', color: '#8b5cf6', marginBottom: '0.6rem' }}>8. 개인정보 자동 수집 장치의 설치·운영 및 거부</h3>
          <p style={{ color: '#d1d5db' }}>
            본 서비스는 이용자의 이용정보를 수시로 저장하고 불러오는 웹 브라우저 쿠키(cookie)나 광고 식별자를 사용하지 않는 것을 원칙으로 합니다. 플레이어는 단말기 설정을 통해 언제든지 수집 동의를 제어할 수 있습니다.
          </p>
        </section>

        <section>
          <h3 style={{ fontSize: '1.15rem', color: '#8b5cf6', marginBottom: '0.6rem' }}>9. 개인정보의 기술적·관리적 보호 대책</h3>
          <p style={{ color: '#d1d5db', marginBottom: '0.5rem' }}>
            회사는 개인정보의 안전성 확보를 위해 다음과 같은 조치를 취하고 있습니다.
          </p>
          <ul style={{ paddingLeft: '1.2rem', color: '#d1d5db', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
            <li><strong>개인정보 암호화:</strong> 이메일 주소는 데이터베이스 저장 시 암호화 처리되며, 단말기 식별자 역시 복호화 불가능한 해시 함수로 암호화하여 관리됩니다.</li>
            <li><strong>접근 통제 및 전송 보안:</strong> 모든 통신은 SSL/TLS 보안 프로토콜을 통하여 암호화 전송되며, Supabase Row Level Security(RLS) 보안 규칙을 적용하여 비인가된 제3자의 데이터 접근을 차단합니다.</li>
          </ul>
        </section>

        <section>
          <h3 style={{ fontSize: '1.15rem', color: '#8b5cf6', marginBottom: '0.6rem' }}>10. 아동의 개인정보 보호</h3>
          <p style={{ color: '#d1d5db' }}>
            회사는 만 14세 미만 아동의 개인정보를 원칙적으로 수집하지 않습니다. 만약 법정대리인의 동의 없이 만 14세 미만 아동의 개인정보가 수집된 사실이 확인될 경우 즉시 해당 계정을 삭제하고 개인정보를 파기합니다.
          </p>
        </section>

        <section>
          <h3 style={{ fontSize: '1.15rem', color: '#8b5cf6', marginBottom: '0.6rem' }}>11. 개인정보 보호책임자 및 권익침해 구제방법</h3>
          <p style={{ color: '#d1d5db' }}>
            서비스 이용 중 발생하는 모든 개인정보 관련 문의 및 피해 구제는 아래의 메일로 문의주시면 성실히 답변해 드리겠습니다.
            <br />
            - 개인정보 담당 부서 및 이메일: <strong>kydculx@gmail.com</strong>
            <br />
            - 침해 신고 관련 정부 기관: <strong>개인정보침해신고센터 (privacy.kisa.or.kr)</strong>
          </p>
        </section>
      </div>
    </article>
  );

  const renderEnglish = () => (
    <article className="tactical-card" style={{ background: '#111827', borderColor: '#1f2937', padding: '2.5rem', lineHeight: 1.7 }}>
      <h1 style={{ fontSize: '2rem', fontWeight: 800, marginBottom: '1.5rem', fontFamily: 'var(--font-display)' }}>
        Privacy Policy
      </h1>
      <p style={{ color: '#94a3b8', fontSize: '0.9rem', marginBottom: '2rem' }}>
        Effective Date: June 7, 2026
      </p>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '1.8rem', fontSize: '0.95rem' }}>
        <section>
          <h3 style={{ fontSize: '1.15rem', color: '#8b5cf6', marginBottom: '0.6rem' }}>1. Purpose of Processing Personal Information</h3>
          <p style={{ color: '#d1d5db' }}>
            This Service processes the minimum amount of personal information for the purposes of member registration and account management, providing location-based services (calculating real-time territory captures and base coordinates), compiling in-game rankings, sending real-time push notifications of territory changes, and handling Player inquiries.
          </p>
        </section>

        <section>
          <h3 style={{ fontSize: '1.15rem', color: '#8b5cf6', marginBottom: '0.6rem' }}>2. Items of Personal Information Collected and Used</h3>
          <p style={{ color: '#d1d5db', marginBottom: '0.5rem' }}>
            The Company collects the following personal information items to provide the Service:
          </p>
          <ul style={{ paddingLeft: '1.2rem', color: '#d1d5db', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
            <li><strong>Collected at Signup:</strong> Email address, unique identifier from external authentication platforms (Google, Apple, etc.), and profile nickname.</li>
            <li><strong>Automatically Collected & Processed:</strong> Unique Device Identifier (UUID), access logs, OS version, and device model information.</li>
            <li><strong>Location-based Services:</strong> Real-time GPS latitude and longitude coordinates of the Player's terminal and movement speed data (including background collections when background mode is active).</li>
          </ul>
        </section>

        <section>
          <h3 style={{ fontSize: '1.15rem', color: '#8b5cf6', marginBottom: '0.6rem' }}>3. Period of Retention and Use of Personal Information</h3>
          <p style={{ color: '#d1d5db' }}>
            The Member's personal information and territory data will be permanently and completely deleted (Cascade Delete) from the production server database immediately upon account withdrawal, and the captured territories will be neutralized.
          </p>
        </section>

        <section>
          <h3 style={{ fontSize: '1.15rem', color: '#8b5cf6', marginBottom: '0.6rem' }}>4. Procedures and Methods of Destruction of Personal Information</h3>
          <p style={{ color: '#d1d5db' }}>
            The Company will destroy the personal information without delay when it becomes unnecessary, such as the expiration of the retention period or completion of the processing purpose. Information in electronic file formats is deleted using technical methods that make the records unrecoverable, while paper documents are shredded or incinerated.
          </p>
        </section>

        <section>
          <h3 style={{ fontSize: '1.15rem', color: '#8b5cf6', marginBottom: '0.6rem' }}>5. Provision and Consignment of Personal Information to Third Parties</h3>
          <p style={{ color: '#d1d5db', marginBottom: '0.5rem' }}>
            The Company consigns personal information processing to professional entities for service delivery as follows:
          </p>
          <ul style={{ paddingLeft: '1.2rem', color: '#d1d5db', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
            <li><strong>Supabase:</strong> Consignment of storage and processing on real-time distributed cloud database infrastructure (Retention period: Destroyed immediately upon account withdrawal).</li>
            <li><strong>Firebase Cloud Messaging (Google LLC):</strong> Consignment of sending real-time push notifications for territory modifications and important service events (Retention period: Destroyed immediately upon push notification completion).</li>
          </ul>
        </section>

        <section>
          <h3 style={{ fontSize: '1.15rem', color: '#8b5cf6', marginBottom: '0.6rem' }}>6. Player's Rights to Account Deletion & Data Erasure</h3>
          <ul style={{ paddingLeft: '1.2rem', color: '#d1d5db', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
            <li style={{ color: '#fca5a5' }}>1. Players have the right to request permanent account deletion and complete erasure of collected data at any time via the in-app settings menu (Delete Account) or the designated support email (kydculx@gmail.com).</li>
            <li style={{ color: '#fca5a5' }}>2. Immediately upon receipt of the withdrawal and erasure request, the Player's personally identifiable data, virtual currencies, statistics, and captured territories on the map will be permanently deleted (Cascade Delete) and neutralized from the production database, and cannot be recovered or reused.</li>
          </ul>
        </section>

        <section>
          <h3 style={{ fontSize: '1.15rem', color: '#8b5cf6', marginBottom: '0.6rem' }}>7. Rights and Obligations of Data Subjects and Legal Representatives</h3>
          <p style={{ color: '#d1d5db' }}>
            Players may exercise their rights against the Company to inspect, correct, delete, or suspend processing of their personal information at any time, and the Company will take action without delay upon receiving the request via email.
          </p>
        </section>

        <section>
          <h3 style={{ fontSize: '1.15rem', color: '#8b5cf6', marginBottom: '0.6rem' }}>8. Installation, Operation, and Rejection of Automatic Personal Information Collection Devices</h3>
          <p style={{ color: '#d1d5db' }}>
            In principle, this Service does not use web browser cookies or advertising identifiers that store and load user usage information. Players can control collection consent at any time through their device settings.
          </p>
        </section>

        <section>
          <h3 style={{ fontSize: '1.15rem', color: '#8b5cf6', marginBottom: '0.6rem' }}>9. Technical and Administrative Protection Measures for Personal Information</h3>
          <p style={{ color: '#d1d5db', marginBottom: '0.5rem' }}>
            The Company takes the following actions to secure the safety of personal information:
          </p>
          <ul style={{ paddingLeft: '1.2rem', color: '#d1d5db', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
            <li><strong>Encryption of Personal Information:</strong> Email addresses are encrypted when stored in the database, and device identifiers are managed with irreversible hash functions.</li>
            <li><strong>Access Control & Transport Security:</strong> All communications are transmitted securely via SSL/TLS protocols, and Supabase Row Level Security (RLS) policies are applied to block unauthorized third-party access.</li>
          </ul>
        </section>

        <section>
          <h3 style={{ fontSize: '1.15rem', color: '#8b5cf6', marginBottom: '0.6rem' }}>10. Protection of Personal Information of Children</h3>
          <p style={{ color: '#d1d5db' }}>
            In principle, the Company does not collect personal information from children under the age of 14. If it is verified that personal information has been collected from a child under 14 without legal representative consent, the account and data will be destroyed immediately.
          </p>
        </section>

        <section>
          <h3 style={{ fontSize: '1.15rem', color: '#8b5cf6', marginBottom: '0.6rem' }}>11. Personal Information Protection Officer and Remedies for Infringement of Rights</h3>
          <p style={{ color: '#d1d5db' }}>
            For all inquiries regarding personal information and remedies for infringement during service use, please contact the email below:
            <br />
            - Department & Email: <strong>kydculx@gmail.com</strong>
            <br />
            - Government Agency for Infringement Reports: <strong>Personal Information Infringement Report Center (privacy.kisa.or.kr)</strong>
          </p>
        </section>
      </div>
    </article>
  );

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
            <Shield size={18} style={{ color: '#8b5cf6' }} />
            <span style={{ fontSize: '0.85rem', color: '#64748b', fontWeight: 600, fontFamily: 'var(--font-display)' }}>
              {isEnglish ? 'Dibs! Adventure' : '찜! 모험'}
            </span>
          </div>
        </div>

        {/* 본문 콘텐츠 */}
        {isEnglish ? renderEnglish() : renderKorean()}
      </div>
    </div>
  );
}
