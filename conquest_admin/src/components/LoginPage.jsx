import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../supabase';
import { Lock, Mail, ShieldAlert, Terminal, Eye, EyeOff } from 'lucide-react';

export default function LoginPage({ onLoginSuccess }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const navigate = useNavigate();

  const handleLogin = async (e) => {
    e.preventDefault();
    if (!email || !password) {
      setError('이메일과 비밀번호를 모두 입력해 주세요.');
      return;
    }

    setLoading(true);
    setError('');

    try {
      // 1. Supabase Auth 로그인 시도
      const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
        email,
        password
      });

      if (authError) throw authError;

      const user = authData.user;
      if (!user) {
        throw new Error('사용자 정보를 가져올 수 없습니다.');
      }

      // 2. 어드민 권한 체크 (Auth Metadata 또는 Profiles 테이블)
      let isAdmin = user.app_metadata?.role === 'admin' || user.user_metadata?.role === 'admin';

      if (!isAdmin) {
        // profiles 테이블에서 role 조회 시도
        const { data: profile, error: profileError } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single();

        if (!profileError && profile) {
          isAdmin = profile.role === 'admin';
        }
      }

      if (!isAdmin) {
        // 관리자가 아니면 즉시 로그아웃 처리
        await supabase.auth.signOut();
        throw new Error('관리자 권한이 없는 계정입니다. 시스템 접근이 거부되었습니다.');
      }

      // 로그인 성공 콜백 및 페이지 이동
      onLoginSuccess(user);
      navigate('/admin/dashboard');

    } catch (err) {
      console.error('Login error:', err);
      setError(err.message || '로그인 중 오류가 발생했습니다.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-root">
      {/* 구글 폰트 로드 */}
      <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;800&family=Plus+Jakarta+Sans:wght@400;600;700&display=swap" rel="stylesheet" />

      {/* 네온 글로우 오라 */}
      <div className="login-bg-orb orb-purple" />
      <div className="login-bg-orb orb-cyan" />

      <div className="login-card">
        <div className="login-header">
          <div className="login-logo">
            <Terminal size={28} style={{ color: 'var(--accent-cyan)' }} />
          </div>
          <h1 className="login-title">찜! 대모험</h1>
          <p className="login-subtitle">ADMIN SYSTEM GATEWAY</p>
        </div>

        {error && (
          <div className="login-error-box">
            <ShieldAlert size={16} />
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleLogin} className="login-form">
          <div className="input-group">
            <label className="input-label">관리자 계정 이메일</label>
            <div className="input-wrapper">
              <Mail size={18} className="input-icon" />
              <input
                type="email"
                className="login-input"
                placeholder="admin@example.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                disabled={loading}
              />
            </div>
          </div>

          <div className="input-group">
            <label className="input-label">비밀번호</label>
            <div className="input-wrapper">
              <Lock size={18} className="input-icon" />
              <input
                type={showPassword ? 'text' : 'password'}
                className="login-input"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                disabled={loading}
              />
              <button
                type="button"
                className="password-toggle"
                onClick={() => setShowPassword(!showPassword)}
                disabled={loading}
              >
                {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>
          </div>

          <button type="submit" className="login-submit-btn" disabled={loading}>
            {loading ? (
              <span className="spinner" />
            ) : (
              <span>보안 원격 로그인</span>
            )}
          </button>
        </form>

        <div className="login-footer">
          <span>인증되지 않은 IP 또는 권한이 없는 계정의 접속 시도는 보안 통제 및 로깅 대상이 됩니다.</span>
        </div>
      </div>

      <style dangerouslySetInnerHTML={{
        __html: `
        .login-root {
          background-color: #04060d;
          color: #f1f5f9;
          font-family: 'Plus Jakarta Sans', sans-serif;
          min-height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
          position: relative;
          overflow: hidden;
          padding: 1.5rem;
        }

        .login-title, .login-subtitle, .login-submit-btn {
          font-family: 'Outfit', sans-serif;
        }

        .login-bg-orb {
          position: absolute;
          border-radius: 50%;
          filter: blur(120px);
          opacity: 0.12;
          pointer-events: none;
          z-index: 0;
        }
        .orb-purple {
          width: 450px;
          height: 450px;
          background: #8b5cf6;
          top: -100px;
          left: -100px;
        }
        .orb-cyan {
          width: 500px;
          height: 500px;
          background: #06b6d4;
          bottom: -150px;
          right: -100px;
        }

        .login-card {
          width: 100%;
          max-width: 420px;
          background: rgba(15, 23, 42, 0.45);
          border: 1px solid rgba(255, 255, 255, 0.04);
          box-shadow: 0 30px 60px rgba(0, 0, 0, 0.5), 
                      inset 0 0 12px rgba(255, 255, 255, 0.02);
          border-radius: 24px;
          padding: 3rem 2.5rem;
          backdrop-filter: blur(15px);
          -webkit-backdrop-filter: blur(15px);
          z-index: 10;
          display: flex;
          flex-direction: column;
          gap: 2rem;
        }

        .login-header {
          text-align: center;
          display: flex;
          flex-direction: column;
          align-items: center;
          gap: 0.5rem;
        }
        .login-logo {
          width: 56px;
          height: 56px;
          background: rgba(6, 182, 212, 0.08);
          border: 1px solid rgba(6, 182, 212, 0.15);
          border-radius: 16px;
          display: flex;
          align-items: center;
          justify-content: center;
          margin-bottom: 0.6rem;
          filter: drop-shadow(0 0 10px rgba(6, 182, 212, 0.3));
        }
        .login-title {
          font-size: 1.8rem;
          font-weight: 800;
          letter-spacing: 0.02em;
          background: linear-gradient(135deg, #60a5fa, #a78bfa);
          WebkitBackgroundClip: text;
          WebkitTextFillColor: transparent;
          margin: 0;
        }
        .login-subtitle {
          font-size: 0.75rem;
          font-weight: 700;
          color: #475569;
          letter-spacing: 0.15em;
          margin: 0;
        }

        .login-error-box {
          background: rgba(239, 68, 68, 0.08);
          border: 1px solid rgba(239, 68, 68, 0.25);
          border-radius: 12px;
          padding: 0.8rem 1rem;
          display: flex;
          align-items: center;
          gap: 0.6rem;
          color: #f87171;
          font-size: 0.8rem;
          line-height: 1.4;
        }

        .login-form {
          display: flex;
          flex-direction: column;
          gap: 1.2rem;
        }
        .input-group {
          display: flex;
          flex-direction: column;
          gap: 0.5rem;
        }
        .input-label {
          font-size: 0.75rem;
          font-weight: 600;
          color: #94a3b8;
          padding-left: 0.2rem;
        }
        .input-wrapper {
          position: relative;
          display: flex;
          align-items: center;
        }
        .input-icon {
          position: absolute;
          left: 14px;
          color: #475569;
          pointer-events: none;
          transition: color 0.3s ease;
        }
        .login-input {
          width: 100%;
          background: rgba(6, 9, 19, 0.6);
          border: 1px solid rgba(255, 255, 255, 0.05);
          border-radius: 12px;
          padding: 0.85rem 1rem 0.85rem 2.8rem;
          color: #f1f5f9;
          font-size: 0.9rem;
          transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }
        .login-input:focus {
          border-color: rgba(6, 182, 212, 0.4);
          background: rgba(6, 9, 19, 0.8);
          box-shadow: 0 0 15px rgba(6, 182, 212, 0.15);
          outline: none;
        }
        .login-input:focus + .input-icon {
          color: #06b6d4;
        }
        .password-toggle {
          position: absolute;
          right: 14px;
          background: none;
          border: none;
          color: #475569;
          cursor: pointer;
          padding: 0;
          display: flex;
          align-items: center;
          justify-content: center;
          transition: color 0.2s ease;
        }
        .password-toggle:hover {
          color: #94a3b8;
        }

        .login-submit-btn {
          margin-top: 1rem;
          background: linear-gradient(135deg, #3b82f6, #8b5cf6);
          border: none;
          color: #ffffff;
          padding: 0.9rem;
          border-radius: 12px;
          font-weight: 700;
          font-size: 0.95rem;
          cursor: pointer;
          transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
          display: flex;
          align-items: center;
          justify-content: center;
          box-shadow: 0 4px 20px rgba(59, 130, 246, 0.3);
        }
        .login-submit-btn:hover {
          transform: translateY(-2px);
          box-shadow: 0 8px 25px rgba(59, 130, 246, 0.45);
        }
        .login-submit-btn:disabled {
          background: #1e293b;
          color: #475569;
          cursor: not-allowed;
          box-shadow: none;
          transform: none;
        }

        .login-footer {
          text-align: center;
          font-size: 0.7rem;
          color: #334155;
          line-height: 1.5;
          padding: 0 0.5rem;
        }

        /* 스피너 */
        .spinner {
          width: 20px;
          height: 20px;
          border: 2px solid rgba(255, 255, 255, 0.1);
          border-top-color: #ffffff;
          border-radius: 50%;
          animation: spin 0.8s infinite linear;
        }
        @keyframes spin {
          to { transform: rotate(360deg); }
        }
      `}} />
    </div>
  );
}
