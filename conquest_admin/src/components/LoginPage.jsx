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
      if (onLoginSuccess) {
        onLoginSuccess(user);
      }
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
      {/* 백그라운드 앰비언트 오라 */}
      <div className="login-bg-orb orb-indigo" />
      <div className="login-bg-orb orb-cyan" />

      <div className="login-card">
        <div className="login-header">
          <div className="login-logo">
            <Terminal size={24} />
          </div>
          <h1 className="login-title">찜! 모험</h1>
          <p className="login-subtitle">관리 콘솔 시스템</p>
        </div>

        {error && (
          <div className="login-error-box">
            <ShieldAlert size={18} style={{ flexShrink: 0 }} />
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleLogin} className="login-form">
          <div className="input-group">
            <label className="input-label">이메일 계정</label>
            <div className="input-wrapper">
              <Mail size={17} className="input-icon" />
              <input
                type="email"
                className="login-input"
                placeholder="admin@conquest.kr"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                disabled={loading}
                autoComplete="email"
              />
            </div>
          </div>

          <div className="input-group">
            <label className="input-label">비밀번호</label>
            <div className="input-wrapper">
              <Lock size={17} className="input-icon" />
              <input
                type={showPassword ? 'text' : 'password'}
                className="login-input"
                placeholder="••••••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                disabled={loading}
                autoComplete="current-password"
              />
              <button
                type="button"
                className="password-toggle"
                onClick={() => setShowPassword(!showPassword)}
                disabled={loading}
                aria-label={showPassword ? '비밀번호 숨기기' : '비밀번호 보기'}
              >
                {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
              </button>
            </div>
          </div>

          <button type="submit" className="login-submit-btn" disabled={loading}>
            {loading ? (
              <span className="login-spinner" />
            ) : (
              <span>관리자 로그인</span>
            )}
          </button>
        </form>

        <div className="login-footer">
          <span>인증된 관리자 계정만 접근 가능하며 비인가 접근은 제한됩니다.</span>
        </div>
      </div>

      <style dangerouslySetInnerHTML={{
        __html: `
        .login-root {
          background-color: #070b12;
          background-image:
            radial-gradient(900px 500px at 80% -10%, rgba(99, 102, 241, 0.12), transparent 60%),
            radial-gradient(800px 450px at -10% 100%, rgba(56, 189, 248, 0.08), transparent 55%);
          color: #f8fafc;
          font-family: 'Pretendard Variable', 'Plus Jakarta Sans', system-ui, sans-serif;
          min-height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
          position: relative;
          overflow: hidden;
          padding: 1.5rem;
        }

        .login-bg-orb {
          position: absolute;
          border-radius: 50%;
          filter: blur(140px);
          opacity: 0.18;
          pointer-events: none;
          z-index: 0;
        }
        .orb-indigo {
          width: 500px;
          height: 500px;
          background: #4f46e5;
          top: -120px;
          left: -120px;
        }
        .orb-cyan {
          width: 520px;
          height: 520px;
          background: #0284c7;
          bottom: -160px;
          right: -120px;
        }

        .login-card {
          width: 100%;
          max-width: 410px;
          background: rgba(15, 23, 42, 0.72);
          border: 1px solid rgba(255, 255, 255, 0.08);
          box-shadow: 0 30px 60px -12px rgba(0, 0, 0, 0.65), 
                      inset 0 1px 0 rgba(255, 255, 255, 0.06);
          border-radius: 24px;
          padding: 2.8rem 2.4rem;
          backdrop-filter: blur(20px);
          -webkit-backdrop-filter: blur(20px);
          z-index: 10;
          display: flex;
          flex-direction: column;
          gap: 1.8rem;
          animation: cardRise 0.4s cubic-bezier(0.16, 1, 0.3, 1) both;
        }

        @keyframes cardRise {
          from { opacity: 0; transform: translateY(12px) scale(0.98); }
          to { opacity: 1; transform: translateY(0) scale(1); }
        }

        .login-header {
          text-align: center;
          display: flex;
          flex-direction: column;
          align-items: center;
          gap: 0.45rem;
        }
        .login-logo {
          width: 52px;
          height: 52px;
          background: linear-gradient(135deg, #4f46e5 0%, #3b82f6 50%, #06b6d4 100%);
          border-radius: 15px;
          display: flex;
          align-items: center;
          justify-content: center;
          margin-bottom: 0.6rem;
          color: #ffffff;
          box-shadow: 0 6px 20px rgba(99, 102, 241, 0.4), inset 0 1px 0 rgba(255, 255, 255, 0.35);
        }
        .login-title {
          font-size: 1.75rem;
          font-weight: 800;
          letter-spacing: -0.02em;
          color: #f8fafc;
          margin: 0;
          font-family: 'Outfit', 'Pretendard Variable', sans-serif;
        }
        .login-subtitle {
          font-size: 0.78rem;
          font-weight: 600;
          color: #94a3b8;
          letter-spacing: 0.04em;
          margin: 0;
        }

        .login-error-box {
          background: rgba(239, 68, 68, 0.08);
          border: 1px solid rgba(239, 68, 68, 0.25);
          border-radius: 12px;
          padding: 0.8rem 1rem;
          display: flex;
          align-items: center;
          gap: 0.65rem;
          color: #f87171;
          font-size: 0.82rem;
          line-height: 1.45;
        }

        .login-form {
          display: flex;
          flex-direction: column;
          gap: 1.15rem;
        }
        .input-group {
          display: flex;
          flex-direction: column;
          gap: 0.45rem;
        }
        .input-label {
          font-size: 0.76rem;
          font-weight: 600;
          color: #cbd5e1;
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
          color: #64748b;
          pointer-events: none;
          transition: color 0.2s ease;
        }
        .login-input {
          width: 100%;
          background: rgba(10, 16, 28, 0.6);
          border: 1px solid rgba(255, 255, 255, 0.08);
          border-radius: 12px;
          padding: 0.8rem 1rem 0.8rem 2.8rem;
          color: #f8fafc;
          font-size: 0.9rem;
          outline: none;
          transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
        }
        .login-input:focus {
          border-color: #6366f1;
          background: rgba(10, 16, 28, 0.85);
          box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.22);
        }
        .login-input:focus ~ .input-icon {
          color: #818cf8;
        }
        .password-toggle {
          position: absolute;
          right: 14px;
          background: none;
          border: none;
          color: #64748b;
          cursor: pointer;
          padding: 0;
          display: flex;
          align-items: center;
          justify-content: center;
          transition: color 0.15s ease;
        }
        .password-toggle:hover {
          color: #cbd5e1;
        }

        .login-submit-btn {
          margin-top: 0.8rem;
          background: linear-gradient(135deg, #4f46e5 0%, #3b82f6 50%, #06b6d4 100%);
          border: 1px solid rgba(255, 255, 255, 0.1);
          color: #ffffff;
          padding: 0.85rem;
          border-radius: 12px;
          font-weight: 700;
          font-size: 0.92rem;
          letter-spacing: -0.01em;
          cursor: pointer;
          transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
          display: flex;
          align-items: center;
          justify-content: center;
          box-shadow: 0 4px 18px rgba(99, 102, 241, 0.35);
        }
        .login-submit-btn:hover:not(:disabled) {
          transform: translateY(-2px);
          box-shadow: 0 8px 24px rgba(99, 102, 241, 0.5);
          background: linear-gradient(135deg, #4338ca 0%, #2563eb 50%, #0891b2 100%);
        }
        .login-submit-btn:active:not(:disabled) {
          transform: scale(0.98);
        }
        .login-submit-btn:disabled {
          background: #1e293b;
          color: #64748b;
          cursor: not-allowed;
          box-shadow: none;
          transform: none;
        }

        .login-footer {
          text-align: center;
          font-size: 0.72rem;
          color: #64748b;
          line-height: 1.5;
        }

        .login-spinner {
          width: 20px;
          height: 20px;
          border: 2px solid rgba(255, 255, 255, 0.2);
          border-top-color: #ffffff;
          border-radius: 50%;
          animation: spin 0.8s linear infinite;
        }
        @keyframes spin {
          to { transform: rotate(360deg); }
        }
      `}} />
    </div>
  );
}
