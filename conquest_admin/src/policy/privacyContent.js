export const privacyContent = {
  "ko": {
    "title": "개인정보 처리방침",
    "effective": "시행일자: 2026년 11월 12일",
    "sections": [
      {
        "title": "1. 개인정보의 처리 목적",
        "blocks": [
          {
            "type": "p",
            "text": "본 서비스는 회원 가입 및 계정 관리, 위치기반 서비스 제공(실시간 영토 점령 연산 및 본진 기지 좌표 계산), 인게임 랭킹 산출, 실시간 영토 변동 푸시 알림 발송 및 플레이어 민원 처리를 목적으로 최소한의 개인정보를 처리합니다."
          }
        ]
      },
      {
        "title": "2. 개인정보의 수집 및 이용 항목",
        "blocks": [
          {
            "type": "p",
            "text": "회사는 서비스 제공을 위해 아래와 같은 개인정보 항목을 수집하고 있습니다."
          },
          {
            "type": "ul",
            "items": [
              {
                "text": "**회원가입 시 수집 항목:** 이메일 주소, 외부 인증 플랫폼(Google, Apple 등) 식별 고유키, 프로필 닉네임",
                "danger": false,
                "indent": false
              },
              {
                "text": "**자동 수집 및 처리 항목:** 단말기 고유 식별값(UUID), 접속 로그, OS 버전 및 기기 모델 정보",
                "danger": false,
                "indent": false
              },
              {
                "text": "**위치기반 서비스 수집 항목:** 플레이어 단말기의 실시간 GPS 위도·경도 좌표 데이터 및 이동 속도 정보 (백그라운드 모드 실행 시 백그라운드 수집 정보 포함)",
                "danger": false,
                "indent": false
              }
            ]
          },
          {
            "type": "p",
            "text": "백그라운드 위치: 앱이 화면에 표시되지 않거나 사용 중이 아닐 때도 실시간 영토 확보·동기화를 위해 위치 정보를 수집합니다. 사용자가 백그라운드 위치 권한을 허용한 경우에만 수집하며, 앱 내 고지와 시스템 권한 화면을 통해 동의를 받습니다. 수집된 위치는 영토 점령·동기화 외 목적으로 사용하지 않습니다."
          }
        ]
      },
      {
        "title": "3. 개인정보의 보유 및 이용 기간",
        "blocks": [
          {
            "type": "p",
            "text": "회원의 개인정보 및 영토 데이터는 회원 탈퇴 시 실서버 데이터베이스에서 즉시 100% 영구 삭제(Cascade Delete) 및 영토 중립화 처리됩니다."
          }
        ]
      },
      {
        "title": "4. 개인정보의 파기 절차 및 방법",
        "blocks": [
          {
            "type": "p",
            "text": "회사는 개인정보 보유기간의 경과, 처리목적 달성 등 개인정보가 불필요하게 되었을 때에는 지체 없이 해당 개인정보를 파기합니다. 전자적 파일 형태의 정보는 기록을 재생할 수 없는 기술적 방법을 사용하여 삭제하며, 종이 문서 등은 분쇄하거나 소각합니다."
          }
        ]
      },
      {
        "title": "5. 개인정보의 제3자 제공 및 위탁",
        "blocks": [
          {
            "type": "p",
            "text": "회사는 서비스 제공을 위해 아래와 같이 전문 업체에 개인정보 처리를 위탁하고 있습니다."
          },
          {
            "type": "ul",
            "items": [
              {
                "text": "**Supabase:** 실시간 분산형 클라우드 데이터베이스 인프라 제공 및 데이터 저장/처리 위탁 (보유기간: 회원 탈퇴 시 즉시 파기)",
                "danger": false,
                "indent": false
              },
              {
                "text": "**Firebase Cloud Messaging (Google LLC):** 영토 변동 및 서비스 중요 이벤트 관련 실시간 푸시 알림 발송 처리 위탁 (보유기간: 푸시 발송 완료 시 즉시 파기)",
                "danger": false,
                "indent": false
              }
            ]
          }
        ]
      },
      {
        "title": "6. 플레이어의 계정 및 데이터 삭제 권리 (Account Deletion & Data Erasure)",
        "blocks": [
          {
            "type": "ul",
            "items": [
              {
                "text": "1. 플레이어는 앱 내 설정 메뉴(계정 탈퇴) 또는 지정 지원 메일(kydculx@gmail.com)을 통해 언제든지 계정의 영구 탈퇴 및 수집된 데이터의 완전 말소를 요청할 권리가 있습니다.",
                "danger": true,
                "indent": false
              },
              {
                "text": "2. 탈퇴 및 삭제 요청이 접수되는 즉시, 플레이어의 개인 식별 데이터, 보유 골드 재화, 활동 전적 통계 및 확보했던 지도 내 영토 데이터는 실서버 데이터베이스에서 영구적으로 즉시 완전 삭제(Cascade Delete) 및 중립화되어 재사용이나 복구가 절대 불가능합니다.",
                "danger": true,
                "indent": false
              }
            ]
          }
        ]
      },
      {
        "title": "7. 정보주체 및 법정대리인의 권리·의무",
        "blocks": [
          {
            "type": "p",
            "text": "플레이어는 회사에 대해 언제든지 개인정보 열람 요구, 오류 등의 정정 요구, 삭제 요구, 처리정지 요구 등의 권리를 행사할 수 있으며, 이메일을 통해 접수 시 회사는 이에 대해 지체 없이 조치합니다."
          }
        ]
      },
      {
        "title": "8. 개인정보 자동 수집 장치의 설치·운영 및 거부",
        "blocks": [
          {
            "type": "p",
            "text": "본 서비스는 이용자의 이용정보를 수시로 저장하고 불러오는 웹 브라우저 쿠키(cookie)나 광고 식별자를 사용하지 않는 것을 원칙으로 합니다. 플레이어는 단말기 설정을 통해 언제든지 수집 동의를 제어할 수 있습니다."
          }
        ]
      },
      {
        "title": "9. 개인정보의 기술적·관리적 보호 대책",
        "blocks": [
          {
            "type": "p",
            "text": "회사는 개인정보의 안전성 확보를 위해 다음과 같은 조치를 취하고 있습니다."
          },
          {
            "type": "ul",
            "items": [
              {
                "text": "**개인정보 암호화:** 이메일 주소는 데이터베이스 저장 시 암호화 처리되며, 단말기 식별자 역시 복호화 불가능한 해시 함수로 암호화하여 관리됩니다.",
                "danger": false,
                "indent": false
              },
              {
                "text": "**접근 통제 및 전송 보안:** 모든 통신은 SSL/TLS 보안 프로토콜을 통하여 암호화 전송되며, Supabase Row Level Security(RLS) 보안 규칙을 적용하여 비인가된 제3자의 데이터 접근을 차단합니다.",
                "danger": false,
                "indent": false
              }
            ]
          }
        ]
      },
      {
        "title": "10. 아동의 개인정보 보호",
        "blocks": [
          {
            "type": "p",
            "text": "회사는 만 14세 미만 아동의 개인정보를 원칙적으로 수집하지 않습니다. 만약 법정대리인의 동의 없이 만 14세 미만 아동의 개인정보가 수집된 사실이 확인될 경우 즉시 해당 계정을 삭제하고 개인정보를 파기합니다."
          }
        ]
      },
      {
        "title": "11. 개인정보 보호책임자 및 권익침해 구제방법",
        "blocks": [
          {
            "type": "p",
            "text": "서비스 이용 중 발생하는 모든 개인정보 관련 문의 및 피해 구제는 아래의 메일로 문의주시면 성실히 답변해 드리겠습니다.\n- 개인정보 담당 부서 및 이메일: **kydculx@gmail.com**\n- 침해 신고 관련 정부 기관: **개인정보침해신고센터 (privacy.kisa.or.kr)**"
          }
        ]
      }

    ]
  },
  "en": {
    "title": "Privacy Policy",
    "effective": "Effective Date: November 12, 2026",
    "sections": [
      {
        "title": "1. Purpose of Processing Personal Information",
        "blocks": [
          {
            "type": "p",
            "text": "This Service processes the minimum amount of personal information for the purposes of member registration and account management, providing location-based services (calculating real-time territory captures and base coordinates), compiling in-game rankings, sending real-time push notifications of territory changes, and handling Player inquiries."
          }
        ]
      },
      {
        "title": "2. Items of Personal Information Collected and Used",
        "blocks": [
          {
            "type": "p",
            "text": "The Company collects the following personal information items to provide the Service:"
          },
          {
            "type": "ul",
            "items": [
              {
                "text": "**Collected at Signup:** Email address, unique identifier from external authentication platforms (Google, Apple, etc.), and profile nickname.",
                "danger": false,
                "indent": false
              },
              {
                "text": "**Automatically Collected & Processed:** Unique Device Identifier (UUID), access logs, OS version, and device model information.",
                "danger": false,
                "indent": false
              },
              {
                "text": "**Location-based Services:** Real-time GPS latitude and longitude coordinates of the Player's terminal and movement speed data (including background collections when background mode is active).",
                "danger": false,
                "indent": false
              }
            ]
          },
          {
            "type": "p",
            "text": "Background location: The app collects location information to capture and sync territories in real time even when the app is not visible or in use. Collection occurs only when the user grants background location permission, and consent is obtained through the in-app disclosure and the system permission screen. Collected location is not used for any purpose other than territory capture and synchronization."
          }
        ]
      },
      {
        "title": "3. Period of Retention and Use of Personal Information",
        "blocks": [
          {
            "type": "p",
            "text": "The Member's personal information and territory data will be permanently and completely deleted (Cascade Delete) from the production server database immediately upon account withdrawal, and the captured territories will be neutralized."
          }
        ]
      },
      {
        "title": "4. Procedures and Methods of Destruction of Personal Information",
        "blocks": [
          {
            "type": "p",
            "text": "The Company will destroy the personal information without delay when it becomes unnecessary, such as the expiration of the retention period or completion of the processing purpose. Information in electronic file formats is deleted using technical methods that make the records unrecoverable, while paper documents are shredded or incinerated."
          }
        ]
      },
      {
        "title": "5. Provision and Consignment of Personal Information to Third Parties",
        "blocks": [
          {
            "type": "p",
            "text": "The Company consigns personal information processing to professional entities for service delivery as follows:"
          },
          {
            "type": "ul",
            "items": [
              {
                "text": "**Supabase:** Consignment of storage and processing on real-time distributed cloud database infrastructure (Retention period: Destroyed immediately upon account withdrawal).",
                "danger": false,
                "indent": false
              },
              {
                "text": "**Firebase Cloud Messaging (Google LLC):** Consignment of sending real-time push notifications for territory modifications and important service events (Retention period: Destroyed immediately upon push notification completion).",
                "danger": false,
                "indent": false
              }
            ]
          }
        ]
      },
      {
        "title": "6. Player's Rights to Account Deletion & Data Erasure",
        "blocks": [
          {
            "type": "ul",
            "items": [
              {
                "text": "1. Players have the right to request permanent account deletion and complete erasure of collected data at any time via the in-app settings menu (Delete Account) or the designated support email (kydculx@gmail.com).",
                "danger": true,
                "indent": false
              },
              {
                "text": "2. Immediately upon receipt of the withdrawal and erasure request, the Player's personally identifiable data, virtual currencies, statistics, and captured territories on the map will be permanently deleted (Cascade Delete) and neutralized from the production database, and cannot be recovered or reused.",
                "danger": true,
                "indent": false
              }
            ]
          }
        ]
      },
      {
        "title": "7. Rights and Obligations of Data Subjects and Legal Representatives",
        "blocks": [
          {
            "type": "p",
            "text": "Players may exercise their rights against the Company to inspect, correct, delete, or suspend processing of their personal information at any time, and the Company will take action without delay upon receiving the request via email."
          }
        ]
      },
      {
        "title": "8. Installation, Operation, and Rejection of Automatic Personal Information Collection Devices",
        "blocks": [
          {
            "type": "p",
            "text": "In principle, this Service does not use web browser cookies or advertising identifiers that store and load user usage information. Players can control collection consent at any time through their device settings."
          }
        ]
      },
      {
        "title": "9. Technical and Administrative Protection Measures for Personal Information",
        "blocks": [
          {
            "type": "p",
            "text": "The Company takes the following actions to secure the safety of personal information:"
          },
          {
            "type": "ul",
            "items": [
              {
                "text": "**Encryption of Personal Information:** Email addresses are encrypted when stored in the database, and device identifiers are managed with irreversible hash functions.",
                "danger": false,
                "indent": false
              },
              {
                "text": "**Access Control & Transport Security:** All communications are transmitted securely via SSL/TLS protocols, and Supabase Row Level Security (RLS) policies are applied to block unauthorized third-party access.",
                "danger": false,
                "indent": false
              }
            ]
          }
        ]
      },
      {
        "title": "10. Protection of Personal Information of Children",
        "blocks": [
          {
            "type": "p",
            "text": "In principle, the Company does not collect personal information from children under the age of 14. If it is verified that personal information has been collected from a child under 14 without legal representative consent, the account and data will be destroyed immediately."
          }
        ]
      },
      {
        "title": "11. Personal Information Protection Officer and Remedies for Infringement of Rights",
        "blocks": [
          {
            "type": "p",
            "text": "For all inquiries regarding personal information and remedies for infringement during service use, please contact the email below:\n- Department & Email: **kydculx@gmail.com**\n- Government Agency for Infringement Reports: **Personal Information Infringement Report Center (privacy.kisa.or.kr)**"
          }
        ]
      }

    ]
  },
  "ja": {
    "title": "個人情報処理方針",
    "effective": "施行日：2026年11月7日",
    "sections": [
      {
        "title": "1. 個人情報の処理目的",
        "blocks": [
          {
            "type": "p",
            "text": "本サービスは、会員登録及びアカウント管理、位置基盤サービス提供（リアルタイム領土占領演算及び本拠地座標計算）、インゲームランキング算出、リアルタイム領土変動プッシュ通知発送及びプレイヤー苦情処理 を目的に最小限の個人情報を処理します。"
          }
        ]
      },
      {
        "title": "2. 個人情報の収集及び利用項目",
        "blocks": [
          {
            "type": "p",
            "text": "当社は、サービス提供のために下記の個人情報項目を収集しています。"
          },
          {
            "type": "ul",
            "items": [
              {
                "text": "**会員登録時の収集項目：**メールアドレス、外部認証プラットフォーム（Google、Appleなど）識別固有キー、プロファイルニックネーム",
                "danger": false,
                "indent": false
              },
              {
                "text": "**自動収集および処理項目：**端末固有識別値（UUID）、接続ログ、OSバージョン、および機器モデル情報",
                "danger": false,
                "indent": false
              },
              {
                "text": "**位置基盤サービス収集項目：**プレーヤー端末のリアルタイムGPS緯度・経度座標データおよび移動速度情報（バックグラウンドモード実行時のバックグラウンド収集情報含む）",
                "danger": false,
                "indent": false
              }
            ]
          },
          {
            "type": "p",
            "text": "バックグラウンド位置：アプリが画面に表示されない場合や使用中でない場合でも、リアルタイムの領土確保・同期のために位置情報を収集します。ユーザーがバックグラウンドロケーションの権限を許可した場合にのみ収集し、アプリ内の告知とシステムの権限画面で同意を得ます。収集された位置は、領土占領・同期化以外の目的には使用しません。"
          }
        ]
      },
      {
        "title": "3. 個人情報の保有及び利用期間",
        "blocks": [
          {
            "type": "p",
            "text": "会員の個人情報および領土データは、会員脱退時にシルサーバーデータベースから直ちに100%永久削除(Cascade Delete)および領土中立化処理されます。"
          }
        ]
      },
      {
        "title": "4. 個人情報の破棄手順及び方法",
        "blocks": [
          {
            "type": "p",
            "text": "当社は、個人情報保有期間の経過、処理目的達成など個人情報が不要になったときは、遅滞なく当該個人情報を破棄します。電子ファイル形式の情報は、記録を再生できない技術的な方法を使用して削除し、紙文書などは粉砕または焼却します。"
          }
        ]
      },
      {
        "title": "5. 個人情報の第三者提供及び委託",
        "blocks": [
          {
            "type": "p",
            "text": "当社は、サービス提供のために下記のように専門業者に個人情報処理を委託しています。"
          },
          {
            "type": "ul",
            "items": [
              {
                "text": "**Supabase:**リアルタイム分散型クラウドデータベースインフラストラクチャの提供とデータの保存/処理の委託",
                "danger": false,
                "indent": false
              },
              {
                "text": "**Firebase Cloud Messaging (Google LLC):** 領土変動およびサービス 重要イベント関連リアルタイムプッシュ通知発送処理委託（保有期間：プッシュ発送完了時に直ちに破棄）",
                "danger": false,
                "indent": false
              }
            ]
          }
        ]
      },
      {
        "title": "6. プレイヤーのアカウントとデータを削除する権利 (Account Deletion & Data Erasure)",
        "blocks": [
          {
            "type": "ul",
            "items": [
              {
                "text": "1. プレイヤーは、アプリ内設定メニュー（アカウントの退会）または指定サポートメール（kydculx@gmail.com）を通じて、いつでもアカウントの永久脱退および収集されたデータの完全な削除を要求する権利を有します。",
                "danger": true,
                "indent": false
              },
              {
                "text": "2. 退会および削除要求が受け付けられるとすぐに、プレイヤーの個人識別データ、保有金財貨、活動全統計および確保した地図内の領土データは、シルサーバーデータベースから永久的に直ちに完全削除(Cascade Delete)および中立化され、再使用や復旧が絶対不可能です。",
                "danger": true,
                "indent": false
              }
            ]
          }
        ]
      },
      {
        "title": "7. 情報主体及び法定代理人の権利・義務",
        "blocks": [
          {
            "type": "p",
            "text": "プレイヤーは会社に対していつでも個人情報閲覧要求、エラーなどの訂正要求、削除要求、処理停止要求などの権利を行使することができ、電子メールを通じて受付時に会社はこれに対して遅滞なく措置します。"
          }
        ]
      },
      {
        "title": "8. 個人情報自動収集装置の設置・運営及び拒否",
        "blocks": [
          {
            "type": "p",
            "text": "本サービスは、利用者の利用情報を随時保存し、読み込むWebブラウザクッキーや広告識別子を使用しないことを原則とします。プレイヤーは端末設定を使用していつでも収集の同意を制御できます。"
          }
        ]
      },
      {
        "title": "9. 個人情報の技術的・管理的保護対策",
        "blocks": [
          {
            "type": "p",
            "text": "当社は、個人情報の安全性確保のため、次の措置を講じています。"
          },
          {
            "type": "ul",
            "items": [
              {
                "text": "**個人情報の暗号化:** 電子メールアドレスはデータベースの保存時に暗号化処理され、端末識別子も復号化不可能なハッシュ関数で暗号化して管理されます。",
                "danger": false,
                "indent": false
              },
              {
                "text": "**アクセス制御と転送セキュリティ：**すべての通信はSSL/TLSセキュリティプロトコルを介して暗号化され、SupabaseRow Level Security（RLS）セキュリティルールを適用して、許可されていない第三者からのデータアクセスをブロックします。",
                "danger": false,
                "indent": false
              }
            ]
          }
        ]
      },
      {
        "title": "10. 児童の個人情報保護",
        "blocks": [
          {
            "type": "p",
            "text": "会社は14歳未満の子供の個人情報を原則として収集しません。法定代理人の同意なしに14歳未満の子供の個人情報が収集されたことが確認された場合は、直ちに当該アカウントを削除して個人情報を破棄します。"
          }
        ]
      },
      {
        "title": "11. 個人情報保護責任者及び権益侵害救済方法",
        "blocks": [
          {
            "type": "p",
            "text": "サービス利用中に発生するすべての個人情報に関するお問い合わせおよび被害救済は、下記のメールでお問い合わせいただければ誠実にお答えいたします。\n- 個人情報担当部署およびメール: **kydculx@gmail.com**\n- 侵害申告関連政府機関：**個人情報侵害申告センター（privacy.kisa.or.kr）**"
          }
        ]
      }

    ]
  },
  "zh": {
    "title": "隐私政策",
    "effective": "生效日期：2026 年 11 月 7 日",
    "sections": [
      {
        "title": "1. 处理个人信息的目的",
        "blocks": [
          {
            "type": "p",
            "text": "该服务处理最低限度的个人信息，用于会员注册和账户管理、基于位置的服务提供（实时领土占领计算和基地坐标计算）、计算游戏内排名、发送实时领土变更推送通知以及处理玩家投诉。"
          }
        ]
      },
      {
        "title": "2. 个人信息的收集和使用项目",
        "blocks": [
          {
            "type": "p",
            "text": "本公司为了提供服务而收集以下个人信息。"
          },
          {
            "type": "ul",
            "items": [
              {
                "text": "**注册时收集的项目：** 电子邮件地址、识别外部认证平台的唯一密钥（Google、Apple等）、个人资料昵称",
                "danger": false,
                "indent": false
              },
              {
                "text": "**自动收集和处理的项目：**终端唯一标识值（UUID）、访问日志、操作系统版本和设备型号信息",
                "danger": false,
                "indent": false
              },
              {
                "text": "**基于位置的服务采集项目：** 玩家终端的实时GPS经纬度坐标数据和移动速度信息（包括运行后台模式时的后台采集信息）",
                "danger": false,
                "indent": false
              }
            ]
          },
          {
            "type": "p",
            "text": "后台位置：即使不在屏幕上或未使用时，该应用程序也会收集位置信息以实现实时领土获取与同步。仅当用户授予后台位置权限时才会收集，并通过应用内通知和系统权限屏幕获得同意。收集的位置不用于领土占领和同步之外的任何目的。"
          }
        ]
      },
      {
        "title": "3. 个人信息的保留和使用期限",
        "blocks": [
          {
            "type": "p",
            "text": "当会员退会时，该会员的个人信息和地域数据将被100%永久删除（Cascade Delete），并立即从真实服务器数据库中中和地域。"
          }
        ]
      },
      {
        "title": "4. 销毁个人信息的程序和方法",
        "blocks": [
          {
            "type": "p",
            "text": "当个人信息的保存期限已过或达到处理目的等不再需要个人信息时，公司将立即销毁个人信息。电子文件形式的信息将使用导致记录无法恢复的技术方法删除，纸质文件则被粉碎或焚烧。"
          }
        ]
      },
      {
        "title": "5. 向第三方提供和委托个人信息",
        "blocks": [
          {
            "type": "p",
            "text": "为了提供服务，公司将个人信息的处理委托给专业公司如下。"
          },
          {
            "type": "ul",
            "items": [
              {
                "text": "**Supabase：**提供实时分布式云数据库基础设施，并委托数据存储/处理（保留期限：退会立即销毁）",
                "danger": false,
                "indent": false
              },
              {
                "text": "**Firebase Cloud Messaging (Google LLC)：**委托处理涉及地域变更、重要服务事件的实时推送通知的发送（保存期限：推送完成后立即销毁）",
                "danger": false,
                "indent": false
              }
            ]
          }
        ]
      },
      {
        "title": "6. 玩家删除账户和数据的权利（账户删除和数据擦除）",
        "blocks": [
          {
            "type": "ul",
            "items": [
              {
                "text": "1. 玩家有权随时通过应用内设置菜单（帐户注销）或指定的支持电子邮件（kydculx@gmail.com）请求永久取消帐户并彻底删除收集的数据。",
                "danger": true,
                "indent": false
              },
              {
                "text": "2. 一旦收到注销或删除请求，玩家的个人身份数据、持有的金币、活动统计数据和安全地图领土数据将立即永久删除（Cascade Delete）并从真实服务器数据库中消除，绝对不可能再使用或恢复。",
                "danger": true,
                "indent": false
              }
            ]
          }
        ]
      },
      {
        "title": "七、信息主体及法定代表人的权利和义务",
        "blocks": [
          {
            "type": "p",
            "text": "玩家可以随时向本公司行使权利，例如要求访问个人信息、要求更正错误等、要求删除或要求暂停处理，如果通过电子邮件收到，本公司将立即采取行动。"
          }
        ]
      },
      {
        "title": "8. 个人信息自动收集装置的安装、运行及拒绝",
        "blocks": [
          {
            "type": "p",
            "text": "原则上，本服务不使用网络浏览器cookie或广告标识符来频繁存储和检索用户使用信息。玩家可以随时通过设备设置控制对收集的同意。"
          }
        ]
      },
      {
        "title": "九、个人信息的技术和管理保护措施",
        "blocks": [
          {
            "type": "p",
            "text": "公司正在采取以下措施来确保个人信息的安全。"
          },
          {
            "type": "ul",
            "items": [
              {
                "text": "**个人信息加密：** 电子邮件地址在存储到数据库时会被加密，终端标识符也通过使用无法解密的哈希函数进行加密来管理。",
                "danger": false,
                "indent": false
              },
              {
                "text": "**访问控制和传输安全：** 所有通信均通过 SSL/TLS 安全协议进行加密和传输，并应用 Supabase 行级安全 (RLS) 安全规则来阻止未经授权的第三方访问数据。",
                "danger": false,
                "indent": false
              }
            ]
          }
        ]
      },
      {
        "title": "10.儿童个人信息的保护",
        "blocks": [
          {
            "type": "p",
            "text": "公司原则上不收集14岁以下儿童的个人信息。如确认未经法定代表人同意而收集14岁以下儿童的个人信息，将立即删除该账户，并销毁其个人信息。"
          }
        ]
      },
      {
        "title": "11. 个人信息保护负责人和侵权补救措施",
        "blocks": [
          {
            "type": "p",
            "text": "对于在使用服务时出现的所有与个人信息相关的咨询和损害赔偿，请通过下面的电子邮件与我们联系，我们将忠实地回复。\n- 个人信息部门和电子邮件：**kydculx@gmail.com**\n- 参与举报侵权行为的政府机构：**个人信息侵权举报中心（privacy.kisa.or.kr）**"
          }
        ]
      }

    ]
  },
  "zh-TW": {
    "title": "隱私權政策",
    "effective": "生效日期：2026 年 11 月 7 日",
    "sections": [
      {
        "title": "1. 處理個人資訊的目的",
        "blocks": [
          {
            "type": "p",
            "text": "該服務處理最低限度的個人信息，用於會員註冊和帳戶管理、基於位置的服務提供（實時領土佔領計算和基地坐標計算）、計算遊戲內排名、發送實時領土變更推送通知以及處理玩家投訴。"
          }
        ]
      },
      {
        "title": "2. 個人資訊的收集和使用項目",
        "blocks": [
          {
            "type": "p",
            "text": "本公司為了提供服務而收集以下個人資料。"
          },
          {
            "type": "ul",
            "items": [
              {
                "text": "**註冊時收集的項目：** 電子郵件地址、識別外部認證平台的唯一密鑰（Google、Apple等）、個人資料暱稱",
                "danger": false,
                "indent": false
              },
              {
                "text": "**自動收集和處理的項目：**終端唯一識別值（UUID）、存取日誌、作業系統版本和設備型號信息",
                "danger": false,
                "indent": false
              },
              {
                "text": "**基於位置的服務擷取項目：** 玩家終端的即時GPS經緯度座標資料和移動速度資訊（包括運行後台模式時的後台擷取資訊）",
                "danger": false,
                "indent": false
              }
            ]
          },
          {
            "type": "p",
            "text": "後台位置：即使不在螢幕上或未使用時，應用程式也會收集位置資訊以實現即時區域安全性和同步。僅當使用者授予後台位置權限時才會收集，並透過應用程式內通知和系統權限畫面獲得同意。收集的位置不用於領土佔領和同步之外的任何目的。"
          }
        ]
      },
      {
        "title": "3. 個人資訊的保留與使用期限",
        "blocks": [
          {
            "type": "p",
            "text": "當會員退會時，該會員的個人資料和地理資料將被100%永久刪除（Cascade Delete），並立即從真實伺服器資料庫中中和地理。"
          }
        ]
      },
      {
        "title": "4. 銷毀個人資料的程序和方法",
        "blocks": [
          {
            "type": "p",
            "text": "當個人資訊的保質期已過或達到處理目的等不再需要個人資訊時，公司將立即銷毀個人資訊。電子文件形式的資訊將使用導致記錄無法恢復的技術方法刪除，紙本文件則被粉碎或焚燒。"
          }
        ]
      },
      {
        "title": "5. 向第三方提供和委託個人資訊",
        "blocks": [
          {
            "type": "p",
            "text": "為了提供服務，公司將個人資訊的處理委託給專業公司如下。"
          },
          {
            "type": "ul",
            "items": [
              {
                "text": "**Supabase：**提供即時分散式雲端資料庫基礎設施，並委託資料儲存/處理（保留期限：退會立即銷毀）",
                "danger": false,
                "indent": false
              },
              {
                "text": "**Firebase Cloud Messaging (Google LLC)：**委託處理涉及地域變更、重要服務事件的即時推播通知的發送（保存期限：推播完成後立即銷毀）",
                "danger": false,
                "indent": false
              }
            ]
          }
        ]
      },
      {
        "title": "6. 玩家刪除帳戶和資料的權利（帳戶刪除和資料擦除）",
        "blocks": [
          {
            "type": "ul",
            "items": [
              {
                "text": "1. 玩家有權隨時透過應用程式內設定選單（帳戶註銷）或指定的支援電子郵件（kydculx@gmail.com）請求永久取消帳戶並徹底刪除收集的資料。",
                "danger": true,
                "indent": false
              },
              {
                "text": "2. 一旦收到註銷或刪除請求，玩家的個人識別資料、持有的金幣、活動統計資料和安全地圖領土資料將立即永久刪除（Cascade Delete）並從真實伺服器資料庫中消除，絕對不可能再使用或恢復。",
                "danger": true,
                "indent": false
              }
            ]
          }
        ]
      },
      {
        "title": "七、資訊主體及法定代理人的權利義務",
        "blocks": [
          {
            "type": "p",
            "text": "玩家可以隨時向本公司行使權利，例如要求存取個人資訊、要求更正錯誤等、要求刪除或要求暫停處理，如果透過電子郵件收到，本公司將立即採取行動。"
          }
        ]
      },
      {
        "title": "8. 個人資料自動收集裝置的安裝、運作及拒絕",
        "blocks": [
          {
            "type": "p",
            "text": "原則上，本服務不使用網頁瀏覽器cookie或廣告識別碼來頻繁儲存和檢索使用者使用資訊。玩家可以隨時透過裝置設定控制對收集的同意。"
          }
        ]
      },
      {
        "title": "九、個人資訊的技術和管理保護措施",
        "blocks": [
          {
            "type": "p",
            "text": "本公司正在採取以下措施來確保個人資訊的安全。"
          },
          {
            "type": "ul",
            "items": [
              {
                "text": "**個人資訊加密：** 電子郵件地址在儲存到資料庫時會被加密，終端識別碼也透過使用無法解密的雜湊函數進行加密來管理。",
                "danger": false,
                "indent": false
              },
              {
                "text": "**存取控制和傳輸安全：** 所有通訊均透過 SSL/TLS 安全協定進行加密和傳輸，並應用 Supabase 行級安全性 (RLS) 安全性規則來阻止未經授權的第三方存取資料。",
                "danger": false,
                "indent": false
              }
            ]
          }
        ]
      },
      {
        "title": "10.兒童個人資訊的保護",
        "blocks": [
          {
            "type": "p",
            "text": "公司原則上不收集14歲以下兒童的個人資料。如確認未經法定代表人同意而收集14歲以下兒童的個人資訊，將立即刪除該帳戶，並銷毀其個人資訊。"
          }
        ]
      },
      {
        "title": "11. 個人資訊保護負責人和侵權補救措施",
        "blocks": [
          {
            "type": "p",
            "text": "對於在使用服務時出現的所有與個人資訊相關的諮詢和損害賠償，請透過下面的電子郵件與我們聯繫，我們將忠實地回覆。\n- 個人資訊部門與電子郵件：**kydculx@gmail.com**\n- 參與舉報侵權行為的政府機構：**個人資訊侵權行為檢舉中心（privacy.kisa.or.kr）**"
          }
        ]
      }

    ]
  },
  "es": {
    "title": "Política de privacidad",
    "effective": "Fecha de vigencia: 7 de noviembre de 2026",
    "sections": [
      {
        "title": "1. Finalidad del tratamiento de la información personal",
        "blocks": [
          {
            "type": "p",
            "text": "Este servicio procesa una cantidad mínima de información personal para fines de registro de membresía y administración de cuentas, prestación de servicios basados en la ubicación (cálculo de ocupación del territorio en tiempo real y cálculo de coordenadas de la base), cálculo de clasificaciones en el juego, envío de notificaciones automáticas de cambios de territorio en tiempo real y manejo de quejas de los jugadores."
          }
        ]
      },
      {
        "title": "2. Recopilación y uso de datos personales",
        "blocks": [
          {
            "type": "p",
            "text": "La empresa recopila los siguientes elementos de información personal para proporcionar servicios."
          },
          {
            "type": "ul",
            "items": [
              {
                "text": "**Elementos recopilados al registrarse:** Dirección de correo electrónico, clave única para identificar plataformas de autenticación externas (Google, Apple, etc.), apodo de perfil",
                "danger": false,
                "indent": false
              },
              {
                "text": "**Elementos recopilados y procesados automáticamente:** Valor de identificación único del terminal (UUID), registro de acceso, versión del sistema operativo e información del modelo del dispositivo.",
                "danger": false,
                "indent": false
              },
              {
                "text": "**Elementos de recopilación de servicios basados en la ubicación:** Datos de coordenadas de latitud/longitud GPS en tiempo real e información de velocidad de movimiento del terminal del jugador (incluida información de recopilación en segundo plano cuando se ejecuta el modo en segundo plano)",
                "danger": false,
                "indent": false
              }
            ]
          },
          {
            "type": "p",
            "text": "Ubicación en segundo plano: la aplicación recopila información de ubicación para la captura y sincronización del territorio en tiempo real, incluso cuando no está en la pantalla o en uso. Se recopila solo cuando el usuario otorga permiso de ubicación en segundo plano y el consentimiento se obtiene a través de un aviso en la aplicación y una pantalla de permiso del sistema. Los datos de ubicación recopilados no se utilizan para ningún otro propósito que la captura y sincronización del territorio."
          }
        ]
      },
      {
        "title": "3. Plazo de conservación y uso de la información personal",
        "blocks": [
          {
            "type": "p",
            "text": "Cuando un miembro retira su membresía, la información personal y los datos territoriales del miembro se eliminarán permanentemente (Cascade Delete) y el territorio se neutralizará inmediatamente de la base de datos del servidor real."
          }
        ]
      },
      {
        "title": "4. Procedimientos y métodos para destruir información personal",
        "blocks": [
          {
            "type": "p",
            "text": "La empresa destruye la información personal sin demora cuando la información personal se vuelve innecesaria, como cuando ha pasado el período de retención de la información personal o se ha logrado el propósito del procesamiento. La información en forma de archivos electrónicos se elimina utilizando métodos técnicos que hacen que los registros sean irrecuperables, y los documentos en papel se trituran o incineran."
          }
        ]
      },
      {
        "title": "5. Suministro y encomienda de información personal a terceros",
        "blocks": [
          {
            "type": "p",
            "text": "Para prestar servicios, la empresa confía el procesamiento de datos personales a una empresa profesional de la siguiente manera."
          },
          {
            "type": "ul",
            "items": [
              {
                "text": "**Supabase:** Proporciona infraestructura de base de datos en la nube distribuida en tiempo real y confía el almacenamiento/procesamiento de datos (período de retención: destrucción inmediata al retirar la membresía)",
                "danger": false,
                "indent": false
              },
              {
                "text": "**Firebase Cloud Messaging (Google LLC):** Encomendar el procesamiento del envío de notificaciones push en tiempo real relacionadas con cambios de territorio y eventos de servicio importantes (Período de retención: destrucción inmediata al finalizar el envío push)",
                "danger": false,
                "indent": false
              }
            ]
          }
        ]
      },
      {
        "title": "6. Derecho del jugador a la eliminación de cuentas y datos (Eliminación de cuenta y borrado de datos)",
        "blocks": [
          {
            "type": "ul",
            "items": [
              {
                "text": "1. Los jugadores tienen derecho a solicitar la cancelación permanente de la cuenta y la eliminación completa de los datos recopilados en cualquier momento a través del menú de configuración de la aplicación (retiro de cuenta) o el correo electrónico de soporte designado (kydculx@gmail.com).",
                "danger": true,
                "indent": false
              },
              {
                "text": "2. Tan pronto como se recibe una solicitud de retiro o eliminación, los datos de identificación personal del jugador, el oro retenido, las estadísticas de actividad y los datos del territorio del mapa seguro se eliminan inmediata y permanentemente (Cascade Delete) y se neutralizan de la base de datos del servidor real, lo que hace que la reutilización o recuperación sea absolutamente imposible.",
                "danger": true,
                "indent": false
              }
            ]
          }
        ]
      },
      {
        "title": "7. Derechos y obligaciones de los sujetos de información y representantes legales",
        "blocks": [
          {
            "type": "p",
            "text": "Los jugadores pueden ejercer sus derechos contra la empresa en cualquier momento, como solicitar acceso a información personal, solicitar la corrección de errores, etc., solicitar la eliminación o solicitar la suspensión del procesamiento, y si se recibe por correo electrónico, la empresa tomará medidas sin demora."
          }
        ]
      },
      {
        "title": "8. Instalación, funcionamiento y rechazo de dispositivos automáticos de recogida de información personal.",
        "blocks": [
          {
            "type": "p",
            "text": "En principio, este servicio no utiliza cookies del navegador web ni identificadores de publicidad para almacenar y recuperar con frecuencia información de uso del usuario. Los jugadores pueden controlar su consentimiento para la recopilación en cualquier momento a través de la configuración de su dispositivo."
          }
        ]
      },
      {
        "title": "9. Medidas técnicas y administrativas de protección de datos personales",
        "blocks": [
          {
            "type": "p",
            "text": "La empresa está tomando las siguientes medidas para garantizar la seguridad de la información personal."
          },
          {
            "type": "ul",
            "items": [
              {
                "text": "**Cifrado de información personal:** Las direcciones de correo electrónico se cifran cuando se almacenan en la base de datos y los identificadores de terminal también se administran al cifrarse con una función hash que no se puede descifrar.",
                "danger": false,
                "indent": false
              },
              {
                "text": "**Control de acceso y seguridad de transmisión:** Todas las comunicaciones se cifran y se transmiten a través del protocolo de seguridad SSL/TLS, y se aplican reglas de seguridad de seguridad de nivel de fila (RLS) de Supabase para bloquear el acceso a los datos por parte de terceros no autorizados.",
                "danger": false,
                "indent": false
              }
            ]
          }
        ]
      },
      {
        "title": "10. Protección de la información personal de los niños",
        "blocks": [
          {
            "type": "p",
            "text": "En principio, la empresa no recopila información personal de niños menores de 14 años. Si se confirma que se ha recopilado información personal de un niño menor de 14 años sin el consentimiento del representante legal, la cuenta se eliminará inmediatamente y la información personal será destruida."
          }
        ]
      },
      {
        "title": "11. Delegado de protección de datos personales y recursos en caso de infracción de derechos",
        "blocks": [
          {
            "type": "p",
            "text": "Para todas las consultas relacionadas con información personal y reparación de daños que surjan al utilizar el servicio, contáctenos por correo electrónico a continuación y le responderemos fielmente.\n- Departamento de información personal y correo electrónico: **kydculx@gmail.com**\n- Agencia gubernamental involucrada en la denuncia de infracciones: **Centro de denuncia de infracciones de información personal (privacy.kisa.or.kr)**"
          }
        ]
      }

    ]
  },
  "fr": {
    "title": "Politique de confidentialité",
    "effective": "Date d'entrée en vigueur : 7 novembre 2026",
    "sections": [
      {
        "title": "1. Finalité du traitement des informations personnelles",
        "blocks": [
          {
            "type": "p",
            "text": "Ce service traite une quantité minimale d'informations personnelles à des fins d'enregistrement des membres et de gestion des comptes, de fourniture de services basés sur la localisation (calcul de l'occupation du territoire en temps réel et calcul des coordonnées de la base d'origine), du calcul des classements en jeu, de l'envoi de notifications push de changement de territoire en temps réel et du traitement des plaintes des joueurs."
          }
        ]
      },
      {
        "title": "2. Collecte et utilisation d'informations personnelles",
        "blocks": [
          {
            "type": "p",
            "text": "La société collecte les informations personnelles suivantes pour fournir des services."
          },
          {
            "type": "ul",
            "items": [
              {
                "text": "**Éléments collectés lors de l'inscription :** Adresse email, clé unique d'identification des plateformes d'authentification externes (Google, Apple, etc.), pseudonyme de profil",
                "danger": false,
                "indent": false
              },
              {
                "text": "**Éléments collectés et traités automatiquement :** Valeur d'identification unique du terminal (UUID), journal d'accès, version du système d'exploitation et informations sur le modèle de l'appareil",
                "danger": false,
                "indent": false
              },
              {
                "text": "**Éléments de collecte de services basés sur la localisation :** Données de coordonnées de latitude/longitude GPS en temps réel et informations sur la vitesse de déplacement du terminal du lecteur (y compris les informations de collecte en arrière-plan lors de l'exécution du mode en arrière-plan)",
                "danger": false,
                "indent": false
              }
            ]
          },
          {
            "type": "p",
            "text": "Localisation en arrière-plan : l'application collecte des informations de localisation pour la capture et la synchronisation du territoire en temps réel, même lorsqu'elle n'est pas à l'écran ou en cours d'utilisation. Elles sont collectées uniquement lorsque l'utilisateur accorde l'autorisation de localisation en arrière-plan et que le consentement est obtenu via une notification dans l'application et un écran d'autorisation du système. Les données de localisation collectées ne sont utilisées à aucune autre fin que la capture et la synchronisation du territoire."
          }
        ]
      },
      {
        "title": "3. Durée de conservation et d'utilisation des informations personnelles",
        "blocks": [
          {
            "type": "p",
            "text": "Lorsqu'un membre se retire de son adhésion, les informations personnelles et les données territoriales du membre seront supprimées définitivement à 100 % (Cascade Delete) et le territoire neutralisé immédiatement de la base de données du serveur réel."
          }
        ]
      },
      {
        "title": "4. Procédures et méthodes de destruction des informations personnelles",
        "blocks": [
          {
            "type": "p",
            "text": "La société détruit les informations personnelles sans délai lorsque les informations personnelles deviennent inutiles, par exemple lorsque la période de conservation des informations personnelles est écoulée ou que la finalité du traitement a été atteinte. Les informations sous forme de fichiers électroniques sont supprimées à l'aide de méthodes techniques qui rendent les enregistrements irrécupérables, et les documents papier sont déchiquetés ou incinérés."
          }
        ]
      },
      {
        "title": "5. Fourniture et transmission d'informations personnelles à des tiers",
        "blocks": [
          {
            "type": "p",
            "text": "Pour fournir des services, la société confie le traitement des informations personnelles à une société professionnelle de la manière suivante."
          },
          {
            "type": "ul",
            "items": [
              {
                "text": "**Supabase :** Fournit une infrastructure de base de données cloud distribuée en temps réel et confie le stockage/le traitement des données (durée de conservation : destruction immédiate lors du retrait de l'adhésion)",
                "danger": false,
                "indent": false
              },
              {
                "text": "**Firebase Cloud Messaging (Google LLC) :** Confier le traitement de l'envoi des notifications push en temps réel liées aux changements de territoire et aux événements importants de service (Durée de conservation : Destruction immédiate dès la fin de l'envoi push)",
                "danger": false,
                "indent": false
              }
            ]
          }
        ]
      },
      {
        "title": "6. Droit du joueur à la suppression du compte et des données (suppression du compte et effacement des données)",
        "blocks": [
          {
            "type": "ul",
            "items": [
              {
                "text": "1. Les joueurs ont le droit de demander l'annulation permanente de leur compte et la suppression complète des données collectées à tout moment via le menu des paramètres de l'application (retrait du compte) ou l'e-mail d'assistance désigné (kydculx@gmail.com).",
                "danger": true,
                "indent": false
              },
              {
                "text": "2. Dès qu'une demande de retrait ou de suppression est reçue, les données d'identification personnelles du joueur, l'or détenu, les statistiques d'activité et les données du territoire cartographique sécurisé sont immédiatement et définitivement supprimées (Cascade Delete) et neutralisées de la base de données du serveur réel, rendant la réutilisation ou la récupération absolument impossible.",
                "danger": true,
                "indent": false
              }
            ]
          }
        ]
      },
      {
        "title": "7. Droits et obligations des personnes concernées et des représentants légaux",
        "blocks": [
          {
            "type": "p",
            "text": "Les joueurs peuvent exercer leurs droits contre la société à tout moment, comme demander l'accès aux informations personnelles, demander la correction d'erreurs, etc., demander la suppression ou demander la suspension du traitement, et s'ils sont reçus par e-mail, la société prendra des mesures sans délai."
          }
        ]
      },
      {
        "title": "8. Installation, fonctionnement et refus des dispositifs automatiques de collecte d'informations personnelles",
        "blocks": [
          {
            "type": "p",
            "text": "En principe, ce service n'utilise pas de cookies de navigateur Web ni d'identifiants publicitaires pour stocker et récupérer fréquemment des informations sur l'utilisation des utilisateurs. Les joueurs peuvent contrôler leur consentement à la collecte à tout moment via les paramètres de leur appareil."
          }
        ]
      },
      {
        "title": "9. Mesures techniques et administratives de protection des informations personnelles",
        "blocks": [
          {
            "type": "p",
            "text": "L'entreprise prend les mesures suivantes pour assurer la sécurité des informations personnelles."
          },
          {
            "type": "ul",
            "items": [
              {
                "text": "**Cryptage des informations personnelles :** Les adresses e-mail sont cryptées lorsqu'elles sont stockées dans la base de données, et les identifiants des terminaux sont également gérés en étant cryptés avec une fonction de hachage qui ne peut être déchiffrée.",
                "danger": false,
                "indent": false
              },
              {
                "text": "**Contrôle d'accès et sécurité de la transmission :** Toutes les communications sont cryptées et transmises via le protocole de sécurité SSL/TLS, et les règles de sécurité Supabase Row Level Security (RLS) sont appliquées pour bloquer l'accès aux données par des tiers non autorisés.",
                "danger": false,
                "indent": false
              }
            ]
          }
        ]
      },
      {
        "title": "10. Protection des informations personnelles des enfants",
        "blocks": [
          {
            "type": "p",
            "text": "En principe, la société ne collecte pas d'informations personnelles sur des enfants de moins de 14 ans. S'il est confirmé que des informations personnelles d'un enfant de moins de 14 ans ont été collectées sans le consentement du représentant légal, le compte sera immédiatement supprimé et les informations personnelles seront détruites."
          }
        ]
      },
      {
        "title": "11. Délégué à la protection des renseignements personnels et recours en cas de violation des droits",
        "blocks": [
          {
            "type": "p",
            "text": "Pour toutes les demandes relatives aux informations personnelles et à l'indemnisation des dommages survenant lors de l'utilisation du service, veuillez nous contacter par e-mail ci-dessous et nous vous répondrons fidèlement.\n- Service des informations personnelles et email : **kydculx@gmail.com**\n- Agence gouvernementale impliquée dans le signalement des violations : **Centre de signalement des violations d'informations personnelles (privacy.kisa.or.kr)**"
          }
        ]
      }

    ]
  },
  "de": {
    "title": "Datenschutzrichtlinie",
    "effective": "Datum des Inkrafttretens: 7. November 2026",
    "sections": [
      {
        "title": "1. Zweck der Verarbeitung personenbezogener Daten",
        "blocks": [
          {
            "type": "p",
            "text": "Dieser Dienst verarbeitet eine Mindestmenge an personenbezogenen Daten für die Zwecke der Mitgliedschaftsregistrierung und Kontoverwaltung, der standortbasierten Dienstbereitstellung (Berechnung der Gebietsbelegung in Echtzeit und Berechnung der Koordinaten der Heimatbasis), der Berechnung von Ranglisten im Spiel, dem Versenden von Push-Benachrichtigungen über Gebietsänderungen in Echtzeit und der Bearbeitung von Spielerbeschwerden."
          }
        ]
      },
      {
        "title": "2. Erhebung und Verwendung personenbezogener Daten",
        "blocks": [
          {
            "type": "p",
            "text": "Das Unternehmen erhebt zur Erbringung seiner Dienstleistungen die folgenden personenbezogenen Daten."
          },
          {
            "type": "ul",
            "items": [
              {
                "text": "**Bei der Registrierung gesammelte Elemente:** E-Mail-Adresse, eindeutiger Schlüssel zur Identifizierung externer Authentifizierungsplattformen (Google, Apple usw.), Profil-Nickname",
                "danger": false,
                "indent": false
              },
              {
                "text": "**Automatisch erfasste und verarbeitete Elemente:** Eindeutiger Identifikationswert des Terminals (UUID), Zugriffsprotokoll, Informationen zur Betriebssystemversion und zum Gerätemodell",
                "danger": false,
                "indent": false
              },
              {
                "text": "**Standortbasierte Diensterfassungselemente:** GPS-Breiten-/Längenkoordinatendaten und Bewegungsgeschwindigkeitsinformationen des Player-Terminals in Echtzeit (einschließlich Hintergrunderfassungsinformationen bei Ausführung des Hintergrundmodus)",
                "danger": false,
                "indent": false
              }
            ]
          },
          {
            "type": "p",
            "text": "Hintergrundstandort: Die App sammelt Standortinformationen für die Gebietserfassung und -synchronisierung in Echtzeit, auch wenn sie nicht auf dem Bildschirm angezeigt oder verwendet wird. Sie werden nur erfasst, wenn der Benutzer im Hintergrund eine Ortungserlaubnis erteilt und die Einwilligung über einen In-App-Hinweis und einen Systemberechtigungsbildschirm eingeholt wird. Die erfassten Standortdaten werden zu keinem anderen Zweck als der Gebietserfassung und -synchronisierung verwendet."
          }
        ]
      },
      {
        "title": "3. Aufbewahrungs- und Nutzungsdauer personenbezogener Daten",
        "blocks": [
          {
            "type": "p",
            "text": "Wenn ein Mitglied die Mitgliedschaft widerruft, werden die persönlichen Daten und Gebietsdaten des Mitglieds zu 100 % dauerhaft gelöscht (Cascade Delete) und das Gebiet sofort aus der Datenbank des echten Servers neutralisiert."
          }
        ]
      },
      {
        "title": "4. Verfahren und Methoden zur Vernichtung personenbezogener Daten",
        "blocks": [
          {
            "type": "p",
            "text": "Das Unternehmen vernichtet personenbezogene Daten unverzüglich, wenn personenbezogene Daten unnötig werden, beispielsweise wenn die Aufbewahrungsfrist für personenbezogene Daten abgelaufen ist oder der Zweck der Verarbeitung erreicht wurde. Informationen in Form elektronischer Dateien werden mit technischen Methoden gelöscht, die die Aufzeichnungen unwiederbringlich machen, und Papierdokumente werden geschreddert oder verbrannt."
          }
        ]
      },
      {
        "title": "5. Bereitstellung und Weitergabe personenbezogener Daten an Dritte",
        "blocks": [
          {
            "type": "p",
            "text": "Zur Erbringung von Dienstleistungen vertraut das Unternehmen die Verarbeitung personenbezogener Daten einem professionellen Unternehmen wie folgt an."
          },
          {
            "type": "ul",
            "items": [
              {
                "text": "**Supabase:** Stellt eine verteilte Cloud-Datenbank-Infrastruktur in Echtzeit bereit und beauftragt die Datenspeicherung/-verarbeitung (Aufbewahrungsdauer: sofortige Zerstörung bei Austritt aus der Mitgliedschaft)",
                "danger": false,
                "indent": false
              },
              {
                "text": "**Firebase Cloud Messaging (Google LLC):** Betrauen Sie die Verarbeitung des Sendens von Echtzeit-Push-Benachrichtigungen im Zusammenhang mit Gebietsänderungen und wichtigen Serviceereignissen (Aufbewahrungsfrist: Sofortige Zerstörung nach Abschluss des Push-Versands)",
                "danger": false,
                "indent": false
              }
            ]
          }
        ]
      },
      {
        "title": "6. Das Recht des Spielers auf Konto- und Datenlöschung (Kontolöschung und Datenlöschung)",
        "blocks": [
          {
            "type": "ul",
            "items": [
              {
                "text": "1. Spieler haben das Recht, jederzeit über das In-App-Einstellungsmenü (Kontoauflösung) oder die angegebene Support-E-Mail-Adresse (kydculx@gmail.com) eine dauerhafte Kontokündigung und vollständige Löschung der gesammelten Daten zu beantragen.",
                "danger": true,
                "indent": false
              },
              {
                "text": "2. Sobald ein Antrag auf Auszahlung oder Löschung eingeht, werden die persönlichen Identifikationsdaten, das gehaltene Gold, die Aktivitätsstatistiken und die gesicherten Kartengebietsdaten des Spielers sofort und dauerhaft gelöscht (Cascade Delete) und aus der Datenbank des echten Servers neutralisiert, was eine Wiederverwendung oder Wiederherstellung absolut unmöglich macht.",
                "danger": true,
                "indent": false
              }
            ]
          }
        ]
      },
      {
        "title": "7. Rechte und Pflichten der Informationssubjekte und gesetzlichen Vertreter",
        "blocks": [
          {
            "type": "p",
            "text": "Spieler können ihre Rechte jederzeit gegenüber dem Unternehmen geltend machen, z. B. den Zugriff auf personenbezogene Daten, die Korrektur von Fehlern usw., die Löschung oder die Aussetzung der Verarbeitung beantragen. Bei Erhalt per E-Mail wird das Unternehmen unverzüglich Maßnahmen ergreifen."
          }
        ]
      },
      {
        "title": "8. Installation, Betrieb und Ablehnung automatischer Geräte zur Erfassung personenbezogener Daten",
        "blocks": [
          {
            "type": "p",
            "text": "Grundsätzlich verwendet dieser Dienst keine Webbrowser-Cookies oder Werbekennungen, um regelmäßig Nutzungsinformationen des Benutzers zu speichern und abzurufen. Spieler können ihre Einwilligung zur Datenerfassung jederzeit über ihre Geräteeinstellungen steuern."
          }
        ]
      },
      {
        "title": "9. Technische und verwaltungstechnische Schutzmaßnahmen für personenbezogene Daten",
        "blocks": [
          {
            "type": "p",
            "text": "Das Unternehmen ergreift die folgenden Maßnahmen, um die Sicherheit personenbezogener Daten zu gewährleisten."
          },
          {
            "type": "ul",
            "items": [
              {
                "text": "**Verschlüsselung persönlicher Daten:** E-Mail-Adressen werden verschlüsselt, wenn sie in der Datenbank gespeichert werden, und Terminal-IDs werden ebenfalls verwaltet, indem sie mit einer Hash-Funktion verschlüsselt werden, die nicht entschlüsselt werden kann.",
                "danger": false,
                "indent": false
              },
              {
                "text": "**Zugriffskontrolle und Übertragungssicherheit:** Die gesamte Kommunikation wird verschlüsselt und über das Sicherheitsprotokoll SSL/TLS übertragen, und die Sicherheitsregeln Supabase Row Level Security (RLS) werden angewendet, um den Zugriff auf Daten durch unbefugte Dritte zu blockieren.",
                "danger": false,
                "indent": false
              }
            ]
          }
        ]
      },
      {
        "title": "10. Schutz personenbezogener Daten von Kindern",
        "blocks": [
          {
            "type": "p",
            "text": "Das Unternehmen erhebt grundsätzlich keine personenbezogenen Daten von Kindern unter 14 Jahren. Sollte sich bestätigen, dass personenbezogene Daten eines Kindes unter 14 Jahren ohne Zustimmung des gesetzlichen Vertreters erfasst wurden, wird das Konto unverzüglich gelöscht und die personenbezogenen Daten vernichtet."
          }
        ]
      },
      {
        "title": "11. Datenschutzbeauftragter und Rechtsmittel bei Rechtsverletzungen",
        "blocks": [
          {
            "type": "p",
            "text": "Für alle Anfragen zu personenbezogenen Daten und Schadensersatz, die bei der Nutzung des Dienstes auftreten, kontaktieren Sie uns bitte per E-Mail unten und wir werden Ihnen zuverlässig antworten.\n- Abteilung für persönliche Informationen und E-Mail: **kydculx@gmail.com**\n- An der Meldung von Verstößen beteiligte Regierungsbehörde: **Personal Information Infringement Reporting Center (privacy.kisa.or.kr)**"
          }
        ]
      }

    ]
  },
  "pt": {
    "title": "Política de Privacidade",
    "effective": "Data de vigência: 7 de novembro de 2026",
    "sections": [
      {
        "title": "1. Finalidade do processamento de informações pessoais",
        "blocks": [
          {
            "type": "p",
            "text": "Este serviço processa uma quantidade mínima de informações pessoais para fins de registro de membros e gerenciamento de contas, prestação de serviços baseados em localização (cálculo de ocupação de território em tempo real e cálculo de coordenadas de base), cálculo de classificações no jogo, envio de notificações push de alteração de território em tempo real e tratamento de reclamações de jogadores."
          }
        ]
      },
      {
        "title": "2. Coleta e uso de informações pessoais",
        "blocks": [
          {
            "type": "p",
            "text": "A empresa coleta os seguintes itens de informações pessoais para fornecer serviços."
          },
          {
            "type": "ul",
            "items": [
              {
                "text": "**Itens coletados no cadastro:** Endereço de e-mail, chave exclusiva para identificação de plataformas de autenticação externa (Google, Apple, etc.), apelido do perfil",
                "danger": false,
                "indent": false
              },
              {
                "text": "**Itens coletados e processados automaticamente:** Valor de identificação exclusivo do terminal (UUID), log de acesso, versão do sistema operacional e informações do modelo do dispositivo",
                "danger": false,
                "indent": false
              },
              {
                "text": "**Itens de coleta de serviço com base em localização:** Dados de coordenadas de latitude/longitude GPS em tempo real e informações de velocidade de movimento do terminal do jogador (incluindo informações de coleta de segundo plano ao executar o modo de segundo plano)",
                "danger": false,
                "indent": false
              }
            ]
          },
          {
            "type": "p",
            "text": "Localização em segundo plano: o aplicativo coleta informações de localização para a captura e sincronização do território em tempo real, mesmo quando não está na tela ou em uso. Esses dados são coletados somente quando o usuário concede permissão de localização em segundo plano, e o consentimento é obtido por meio de um aviso no aplicativo e uma tela de permissão do sistema. Os dados de localização coletados não são utilizados para nenhum outro propósito além da captura e sincronização do território."
          }
        ]
      },
      {
        "title": "3. Período de retenção e utilização de informações pessoais",
        "blocks": [
          {
            "type": "p",
            "text": "Quando um membro cancela a adesão, as informações pessoais e os dados territoriais do membro serão 100% excluídos permanentemente (Cascade Delete) e o território neutralizado imediatamente do banco de dados do servidor real."
          }
        ]
      },
      {
        "title": "4. Procedimentos e métodos para destruição de informações pessoais",
        "blocks": [
          {
            "type": "p",
            "text": "A empresa destrói informações pessoais sem demora quando as informações pessoais se tornam desnecessárias, como quando o período de retenção de informações pessoais tiver passado ou o objetivo do processamento for alcançado. As informações na forma de arquivos eletrônicos são excluídas por meio de métodos técnicos que tornam os registros irrecuperáveis, e os documentos em papel são triturados ou incinerados."
          }
        ]
      },
      {
        "title": "5. Fornecimento e entrega de informações pessoais a terceiros",
        "blocks": [
          {
            "type": "p",
            "text": "Para a prestação de serviços, a empresa confia o processamento de informações pessoais a uma empresa profissional da seguinte forma."
          },
          {
            "type": "ul",
            "items": [
              {
                "text": "**Supabase:** Fornece infraestrutura de banco de dados em nuvem distribuída em tempo real e confia o armazenamento/processamento de dados (período de retenção: destruição imediata após a retirada da associação)",
                "danger": false,
                "indent": false
              },
              {
                "text": "**Firebase Cloud Messaging (Google LLC):** Confiar o processamento do envio de notificações push em tempo real relacionadas a mudanças territoriais e eventos importantes de serviço (Período de retenção: Destruição imediata após a conclusão do envio push)",
                "danger": false,
                "indent": false
              }
            ]
          }
        ]
      },
      {
        "title": "6. Direito do jogador à exclusão de conta e dados (exclusão de conta e eliminação de dados)",
        "blocks": [
          {
            "type": "ul",
            "items": [
              {
                "text": "1. Os jogadores têm o direito de solicitar o cancelamento permanente da conta e a exclusão completa dos dados coletados a qualquer momento através do menu de configurações do aplicativo (retirada da conta) ou do e-mail de suporte designado (kydculx@gmail.com).",
                "danger": true,
                "indent": false
              },
              {
                "text": "2. Assim que um pedido de retirada ou exclusão for recebido, os dados de identificação pessoal do jogador, o ouro mantido, as estatísticas de atividade e os dados seguros do território do mapa são imediata e permanentemente excluídos (Cascade Delete) e neutralizados do banco de dados do servidor real, tornando a reutilização ou recuperação absolutamente impossível.",
                "danger": true,
                "indent": false
              }
            ]
          }
        ]
      },
      {
        "title": "7. Direitos e obrigações dos titulares da informação e dos representantes legais",
        "blocks": [
          {
            "type": "p",
            "text": "Os jogadores podem exercer seus direitos contra a empresa a qualquer momento, como solicitar acesso a informações pessoais, solicitar correção de erros, etc., solicitar exclusão ou solicitar suspensão de processamento e, caso seja recebido por e-mail, a empresa tomará medidas sem demora."
          }
        ]
      },
      {
        "title": "8. Instalação, operação e recusa de dispositivos automáticos de coleta de informações pessoais",
        "blocks": [
          {
            "type": "p",
            "text": "Em princípio, este serviço não utiliza cookies de navegador web ou identificadores de publicidade para armazenar e recuperar frequentemente informações de utilização do utilizador. Os jogadores podem controlar seu consentimento para coleta a qualquer momento através das configurações do dispositivo."
          }
        ]
      },
      {
        "title": "9. Medidas técnicas e administrativas de proteção de informações pessoais",
        "blocks": [
          {
            "type": "p",
            "text": "A empresa está tomando as seguintes medidas para garantir a segurança das informações pessoais."
          },
          {
            "type": "ul",
            "items": [
              {
                "text": "**Criptografia de informações pessoais:** Os endereços de e-mail são criptografados quando armazenados no banco de dados, e os identificadores de terminal também são gerenciados por meio de criptografia com uma função hash que não pode ser descriptografada.",
                "danger": false,
                "indent": false
              },
              {
                "text": "**Controle de acesso e segurança de transmissão:** Todas as comunicações são criptografadas e transmitidas por meio do protocolo de segurança SSL/TLS, e regras de segurança Supabase Row Level Security (RLS) são aplicadas para bloquear o acesso aos dados por terceiros não autorizados.",
                "danger": false,
                "indent": false
              }
            ]
          }
        ]
      },
      {
        "title": "10. Proteção das informações pessoais das crianças",
        "blocks": [
          {
            "type": "p",
            "text": "Em princípio, a empresa não coleta informações pessoais de crianças menores de 14 anos. Se for confirmado que as informações pessoais de uma criança menor de 14 anos foram coletadas sem o consentimento do representante legal, a conta será excluída imediatamente e as informações pessoais serão destruídas."
          }
        ]
      },
      {
        "title": "11. Oficial de proteção de informações pessoais e soluções para violação de direitos",
        "blocks": [
          {
            "type": "p",
            "text": "Para todas as dúvidas relacionadas a informações pessoais e reparação de danos que surjam durante a utilização do serviço, entre em contato conosco pelo e-mail abaixo e responderemos fielmente.\n- Departamento de informações pessoais e e-mail: **kydculx@gmail.com**\n- Agência governamental envolvida na denúncia de infrações: **Centro de denúncia de infrações de informações pessoais (privacy.kisa.or.kr)**"
          }
        ]
      }

    ]
  },
  "it": {
    "title": "Informativa sulla privacy",
    "effective": "Data di entrata in vigore: 7 novembre 2026",
    "sections": [
      {
        "title": "1. Finalità del trattamento dei dati personali",
        "blocks": [
          {
            "type": "p",
            "text": "Questo servizio elabora una quantità minima di informazioni personali ai fini della registrazione dell'iscrizione e della gestione dell'account, della fornitura di servizi basati sulla posizione (calcolo dell'occupazione del territorio in tempo reale e calcolo delle coordinate della base di partenza), calcolo delle classifiche di gioco, invio di notifiche push di modifica del territorio in tempo reale e gestione dei reclami dei giocatori."
          }
        ]
      },
      {
        "title": "2. Raccolta e utilizzo dei dati personali",
        "blocks": [
          {
            "type": "p",
            "text": "La società raccoglie i seguenti dati personali per fornire i servizi."
          },
          {
            "type": "ul",
            "items": [
              {
                "text": "**Elementi raccolti al momento della registrazione:** Indirizzo email, chiave univoca per identificare le piattaforme di autenticazione esterne (Google, Apple, ecc.), nickname del profilo",
                "danger": false,
                "indent": false
              },
              {
                "text": "**Elementi raccolti ed elaborati automaticamente:** Valore di identificazione univoco del terminale (UUID), registro di accesso, informazioni sulla versione del sistema operativo e sul modello del dispositivo",
                "danger": false,
                "indent": false
              },
              {
                "text": "**Elementi di raccolta del servizio basati sulla posizione:** Dati sulle coordinate di latitudine/longitudine GPS in tempo reale e informazioni sulla velocità di movimento del terminale del giocatore (incluse informazioni sulla raccolta in background durante l'esecuzione della modalità background)",
                "danger": false,
                "indent": false
              }
            ]
          },
          {
            "type": "p",
            "text": "Posizione in background: l'app raccoglie informazioni sulla posizione per la sicurezza e la sincronizzazione del territorio in tempo reale anche quando non è sullo schermo o non è in uso. Vengono raccolti solo quando l'utente concede l'autorizzazione alla posizione in background e il consenso viene ottenuto tramite un avviso in-app e una schermata di autorizzazione del sistema. Le posizioni raccolte non vengono utilizzate per scopi diversi dall'occupazione e dalla sincronizzazione del territorio."
          }
        ]
      },
      {
        "title": "3. Periodo di conservazione e utilizzo dei dati personali",
        "blocks": [
          {
            "type": "p",
            "text": "Quando un membro ritira l'iscrizione, le informazioni personali del membro e i dati del territorio verranno eliminati definitivamente al 100% (Cascade Delete) e il territorio verrà immediatamente neutralizzato dal database del server reale."
          }
        ]
      },
      {
        "title": "4. Procedure e metodi per la distruzione delle informazioni personali",
        "blocks": [
          {
            "type": "p",
            "text": "La società distrugge senza indugio le informazioni personali quando le informazioni personali diventano non necessarie, ad esempio quando è trascorso il periodo di conservazione delle informazioni personali o quando è stato raggiunto lo scopo del trattamento. Le informazioni sotto forma di file elettronici vengono cancellate utilizzando metodi tecnici che rendono i record irrecuperabili e i documenti cartacei vengono distrutti o inceneriti."
          }
        ]
      },
      {
        "title": "5. Fornitura e affidamento di dati personali a terzi",
        "blocks": [
          {
            "type": "p",
            "text": "Per fornire i servizi, la società affida il trattamento dei dati personali a una società professionale come segue."
          },
          {
            "type": "ul",
            "items": [
              {
                "text": "**Supabase:** Fornisce un'infrastruttura di database cloud distribuita in tempo reale e affida l'archiviazione/elaborazione dei dati (periodo di conservazione: distruzione immediata al momento del ritiro dell'iscrizione)",
                "danger": false,
                "indent": false
              },
              {
                "text": "**Firebase Cloud Messaging (Google LLC):** Affidare l'elaborazione dell'invio di notifiche push in tempo reale relative a modifiche del territorio ed eventi importanti del servizio (Periodo di conservazione: distruzione immediata al completamento dell'invio push)",
                "danger": false,
                "indent": false
              }
            ]
          }
        ]
      },
      {
        "title": "6. Diritto del giocatore all'account e alla cancellazione dei dati (cancellazione dell'account e cancellazione dei dati)",
        "blocks": [
          {
            "type": "ul",
            "items": [
              {
                "text": "1. I giocatori hanno il diritto di richiedere la cancellazione permanente dell'account e la cancellazione completa dei dati raccolti in qualsiasi momento tramite il menu delle impostazioni in-app (recesso dell'account) o l'e-mail di supporto designata (kydculx@gmail.com).",
                "danger": true,
                "indent": false
              },
              {
                "text": "2. Non appena viene ricevuta una richiesta di ritiro o cancellazione, i dati identificativi personali del giocatore, l'oro detenuto, le statistiche di attività e i dati del territorio della mappa protetta vengono immediatamente e permanentemente cancellati (Cascade Delete) e neutralizzati dal database del server reale, rendendo assolutamente impossibile il riutilizzo o il recupero.",
                "danger": true,
                "indent": false
              }
            ]
          }
        ]
      },
      {
        "title": "7. Diritti e obblighi degli interessati e dei legali rappresentanti",
        "blocks": [
          {
            "type": "p",
            "text": "I giocatori potranno esercitare in ogni momento i propri diritti nei confronti della società, come chiedere l'accesso ai propri dati personali, richiedere la correzione di errori, ecc., richiederne la cancellazione, oppure richiedere la sospensione del trattamento e, qualora ricevuti via email, la società prenderà provvedimenti senza ritardo."
          }
        ]
      },
      {
        "title": "8. Installazione, funzionamento e rifiuto di dispositivi automatici di raccolta dei dati personali",
        "blocks": [
          {
            "type": "p",
            "text": "In linea di principio, questo servizio non utilizza cookie del browser Web o identificatori pubblicitari per archiviare e recuperare frequentemente le informazioni sull'utilizzo dell'utente. I giocatori possono controllare il proprio consenso alla raccolta in qualsiasi momento attraverso le impostazioni del proprio dispositivo."
          }
        ]
      },
      {
        "title": "9. Misure tecniche e amministrative di protezione dei dati personali",
        "blocks": [
          {
            "type": "p",
            "text": "La società sta adottando le seguenti misure per garantire la sicurezza delle informazioni personali."
          },
          {
            "type": "ul",
            "items": [
              {
                "text": "**Crittografia delle informazioni personali:** gli indirizzi e-mail vengono crittografati quando archiviati nel database e anche gli identificatori dei terminali vengono gestiti crittografati con una funzione hash che non può essere decrittografata.",
                "danger": false,
                "indent": false
              },
              {
                "text": "**Controllo dell'accesso e sicurezza della trasmissione:** tutte le comunicazioni sono crittografate e trasmesse tramite il protocollo di sicurezza SSL/TLS e le regole di sicurezza Supabase Row Level Security (RLS) vengono applicate per bloccare l'accesso ai dati da parte di terze parti non autorizzate.",
                "danger": false,
                "indent": false
              }
            ]
          }
        ]
      },
      {
        "title": "10. Protezione dei dati personali dei bambini",
        "blocks": [
          {
            "type": "p",
            "text": "In linea di principio, la società non raccoglie informazioni personali da bambini di età inferiore a 14 anni. Se viene confermato che le informazioni personali di un bambino di età inferiore a 14 anni sono state raccolte senza il consenso del rappresentante legale, l'account verrà immediatamente cancellato e le informazioni personali verranno distrutte."
          }
        ]
      },
      {
        "title": "11. Responsabile della protezione dei dati personali e rimedi in caso di violazione dei diritti",
        "blocks": [
          {
            "type": "p",
            "text": "Per tutte le richieste relative alle informazioni personali e al risarcimento dei danni che si verificano durante l'utilizzo del servizio, ti preghiamo di contattarci tramite e-mail di seguito e risponderemo fedelmente.\n- Dipartimento dati personali ed e-mail: **kydculx@gmail.com**\n- Agenzia governativa coinvolta nella segnalazione di violazioni: **Centro di segnalazione delle violazioni delle informazioni personali (privacy.kisa.or.kr)**"
          }
        ]
      }

    ]
  }
};

export default privacyContent;
