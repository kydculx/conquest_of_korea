import jwt
import time
import os
from dotenv import load_dotenv

# .env 파일에서 정보를 읽어오거나 직접 입력할 수 있도록 구성합니다.
load_dotenv()

def generate_apple_client_secret():
    # --- [이 부분을 본인의 정보로 수정하거나 .env에 넣으세요] ---
    team_id = os.getenv('APPLE_TEAM_ID', '34KFLKWWQL')
    client_id = 'com.watercherry.conquestofkorea'
    key_id = os.getenv('APPLE_KEY_ID', 'U26P2NHV6H')
    
    # .p8 파일 경로 또는 직접 문자열 입력
    private_key_path = 'assets/auth/AuthKey_U26P2NHV6H.p8' 
    
    try:
        if os.path.exists(private_key_path):
            with open(private_key_path, 'r') as f:
                private_key = f.read()
        else:
            print(f"Error: {private_key_path} 파일을 찾을 수 없습니다.")
            print("대신 코드를 수정하여 PRIVATE_KEY 변수에 직접 문자열을 넣으세요.")
            return

        headers = {
            'alg': 'ES256',
            'kid': key_id,
        }

        payload = {
            'iss': team_id,
            'iat': int(time.time()),
            'exp': int(time.time()) + (86400 * 180), # 180일 (6개월)
            'aud': 'https://appleid.apple.com',
            'sub': client_id,
        }

        client_secret = jwt.encode(
            payload, 
            private_key, 
            algorithm='ES256', 
            headers=headers
        )

        print("\n" + "="*50)
        print("Apple Client Secret (JWT) 생성 완료!")
        print("="*50)
        print("\n아래 문자열을 복사하여 Supabase [비밀 키(OAuth용)] 칸에 붙여넣으세요:\n")
        print(client_secret)
        print("\n" + "="*50)

    except Exception as e:
        print(f"오류 발생: {e}")

if __name__ == "__main__":
    generate_apple_client_secret()
