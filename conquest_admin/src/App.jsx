import React, { useState, useEffect } from 'react';
import { Routes, Route, Navigate, useNavigate, useLocation, Outlet } from 'react-router-dom';
import DashboardTab from './components/DashboardTab';
import RankingTab from './components/RankingTab';
import UsersTab from './components/UsersTab';
import NotificationsTab from './components/NotificationsTab';
import MapEditorTab from './components/MapEditorTab';
import LandingPage from './components/LandingPage';
import TermsPage from './components/TermsPage';
import PrivacyPage from './components/PrivacyPage';
import LoginPage from './components/LoginPage';
import { supabase } from './supabase';
import {
  ShieldAlert,
  Users,
  Bell,
  Terminal,
  Cpu,
  Trophy,
  Menu,
  X,
  Map,
  LogOut
} from 'lucide-react';

function AdminLayout({ user, onLogout }) {
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const location = useLocation();
  const navigate = useNavigate();

  const menuItems = [
    { id: 'dashboard', label: '대시보드', icon: Cpu, path: '/admin/dashboard' },
    { id: 'ranking', label: '사용자 랭킹', icon: Trophy, path: '/admin/ranking' },
    { id: 'users', label: '사용자 관리', icon: Users, path: '/admin/users' },
    { id: 'notifications', label: '푸시 알림', icon: Bell, path: '/admin/notifications' },
    { id: 'map-editor', label: '맵 에디터', icon: Map, path: '/admin/map-editor' },
  ];

  const getPageTitle = () => {
    const currentPath = location.pathname;
    const item = menuItems.find(m => currentPath.startsWith(m.path));
    if (item) return item.label;
    if (currentPath === '/admin') return '대시보드';
    return 'ADMIN CONSOLE';
  };

  return (
    <div className="app-container">
      {/* 모바일 화면에서 사이드바가 열렸을 때 뒷배경 오버레이 클릭 시 닫기 */}
      {isSidebarOpen && (
        <div className="sidebar-backdrop" onClick={() => setIsSidebarOpen(false)} />
      )}

      {/* 1. 사이드바 내비게이션 */}
      <aside className={`sidebar ${isSidebarOpen ? 'open' : ''}`}>
        {/* 로고 및 모바일 닫기 버튼 */}
        <div style={{ display: 'flex', alignItems: 'center', justifyBetween: 'space-between', paddingBottom: '1rem', borderBottom: '1px solid var(--border-color)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.8rem' }}>
            <Terminal size={24} style={{ color: 'var(--accent-cyan)' }} />
            <div>
              <h1 style={{ fontSize: '1.1rem', fontWeight: 800, fontFamily: 'var(--font-display)', letterSpacing: '0.05em' }}>
                찜! 모험
              </h1>
              <span style={{ fontSize: '0.65rem', color: 'var(--text-muted)', fontWeight: 'bold', fontFamily: 'monospace' }}>
                관리자 시스템 v1.0
              </span>
            </div>
          </div>
          <button 
            className="mobile-only" 
            onClick={() => setIsSidebarOpen(false)}
            style={{ background: 'none', border: 'none', color: 'var(--text-secondary)', cursor: 'pointer', display: 'flex', alignItems: 'center' }}
          >
            <X size={20} />
          </button>
        </div>

        {/* 내비게이션 메뉴 */}
        <nav style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', flex: 1, marginTop: '1rem' }}>
          {menuItems.map(item => {
            const Icon = item.icon;
            const isActive = location.pathname === item.path || (item.id === 'dashboard' && location.pathname === '/admin');
            return (
              <button
                key={item.id}
                onClick={() => {
                  navigate(item.path);
                  setIsSidebarOpen(false); // 이동 후 사이드바 자동으로 닫기
                }}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '1rem',
                  width: '100%',
                  padding: '0.8rem 1rem',
                  background: isActive ? 'rgba(59, 130, 246, 0.08)' : 'transparent',
                  border: 'none',
                  borderLeft: isActive ? '3px solid var(--accent-cyan)' : '3px solid transparent',
                  borderRadius: '0 8px 8px 0',
                  color: isActive ? 'var(--accent-cyan)' : 'var(--text-secondary)',
                  fontFamily: 'var(--font-display)',
                  fontWeight: 600,
                  fontSize: '0.9rem',
                  cursor: 'pointer',
                  textAlign: 'left',
                  transition: 'all 0.2s ease',
                }}
              >
                <Icon size={18} style={{ color: isActive ? 'var(--accent-cyan)' : 'var(--text-muted)' }} />
                {item.label}
              </button>
            );
          })}
        </nav>

        {/* 푸터 - 사용자 정보 및 로그아웃 */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.8rem', padding: '0.8rem', background: 'var(--bg-primary)', borderRadius: '8px', border: '1px solid var(--border-color)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
            <ShieldAlert size={16} style={{ color: 'var(--accent-gold)' }} />
            <span style={{ fontSize: '0.7rem', color: 'var(--text-secondary)', fontFamily: 'monospace', textOverflow: 'ellipsis', overflow: 'hidden', whiteSpace: 'nowrap', flex: 1 }} title={user?.email}>
              {user?.email || '보안 접속 상태'}
            </span>
          </div>
          <button 
            onClick={onLogout}
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '0.5rem',
              width: '100%',
              padding: '0.5rem',
              background: 'rgba(239, 68, 68, 0.08)',
              border: '1px solid rgba(239, 68, 68, 0.15)',
              borderRadius: '6px',
              color: '#f87171',
              fontSize: '0.75rem',
              fontWeight: 600,
              cursor: 'pointer',
              transition: 'all 0.2s ease'
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.background = 'rgba(239, 68, 68, 0.15)';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.background = 'rgba(239, 68, 68, 0.08)';
            }}
          >
            <LogOut size={12} />
            <span>보안 세션 로그아웃</span>
          </button>
        </div>
      </aside>

      {/* 2. 메인 콘텐츠 */}
      <main className="main-content">
        <header className="page-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.8rem' }}>
            <button 
              className="menu-toggle-btn" 
              onClick={() => setIsSidebarOpen(true)}
              style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}
            >
              <Menu size={20} />
            </button>
            <div>
              <h2 className="page-title">{getPageTitle()}</h2>
              <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)', marginTop: '0.2rem', fontFamily: 'monospace' }}>
                시스템 제어 게이트웨이
              </p>
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.8rem' }} className="desktop-only">
            <span style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: 'var(--accent-cyan)', display: 'inline-block' }} />
            <span style={{ fontSize: '0.75rem', fontFamily: 'monospace', color: 'var(--text-secondary)' }}>
              시스템 상태: 정상
            </span>
          </div>
        </header>

        {/* 탭 페이지 마운트 */}
        <section style={{ position: 'relative', zIndex: 1 }}>
          <Outlet />
        </section>
      </main>
    </div>
  );
}

export default function App() {
  const [adminUser, setAdminUser] = useState(null);
  const [authInitialized, setAuthInitialized] = useState(false);
  const navigate = useNavigate();

  useEffect(() => {
    // 1. 초기 세션 체크
    const initAuth = async () => {
      try {
        const { data: { session } } = await supabase.auth.getSession();
        if (session && session.user) {
          const user = session.user;
          // 어드민 여부 확인 (Auth Metadata)
          let isAdmin = user.app_metadata?.role === 'admin' || user.user_metadata?.role === 'admin';
          
          // Fallback: profiles 테이블 조회
          if (!isAdmin) {
            const { data: profile } = await supabase
              .from('profiles')
              .select('role')
              .eq('id', user.id)
              .single();
            if (profile) {
              isAdmin = profile.role === 'admin';
            }
          }

          if (isAdmin) {
            setAdminUser(user);
          } else {
            await supabase.auth.signOut();
          }
        }
      } catch (err) {
        console.error('Session check error:', err);
      } finally {
        setAuthInitialized(true);
      }
    };

    initAuth();

    // 2. Auth 상태 변화 감지 리스너
    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, session) => {
      if (event === 'SIGNED_OUT') {
        setAdminUser(null);
      } else if (event === 'SIGNED_IN' && session?.user) {
        const user = session.user;
        let isAdmin = user.app_metadata?.role === 'admin' || user.user_metadata?.role === 'admin';
        
        if (!isAdmin) {
          const { data: profile } = await supabase
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .single();
          if (profile) {
            isAdmin = profile.role === 'admin';
          }
        }

        if (isAdmin) {
          setAdminUser(user);
        } else {
          setAdminUser(null);
          await supabase.auth.signOut();
        }
      }
    });

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  const handleLogout = async () => {
    await supabase.auth.signOut();
    setAdminUser(null);
    navigate('/');
  };

  if (!authInitialized) {
    return <div className="tactical-spinner" style={{ margin: '20vh auto' }} />;
  }

  return (
    <Routes>
      {/* 1. 메인 홈페이지 게임 소개 랜딩페이지 */}
      <Route path="/" element={<LandingPage />} />
      <Route path="/terms" element={<TermsPage />} />
      <Route path="/privacy" element={<PrivacyPage />} />

      {/* 2. 관리자 로그인 게이트웨이 */}
      <Route 
        path="/admin/login" 
        element={
          adminUser ? (
            <Navigate to="/admin/dashboard" replace />
          ) : (
            <LoginPage onLoginSuccess={(user) => setAdminUser(user)} />
          )
        } 
      />

      {/* 3. 관리자 페이지 하위 주소 (보호된 라우트) */}
      <Route 
        path="/admin" 
        element={
          adminUser ? (
            <AdminLayout user={adminUser} onLogout={handleLogout} />
          ) : (
            <Navigate to="/admin/login" replace />
          )
        }
      >
        {/* /admin 접속 시 /admin/dashboard로 리다이렉트 */}
        <Route index element={<Navigate to="dashboard" replace />} />
        <Route path="dashboard" element={<DashboardTab />} />
        <Route path="ranking" element={<RankingTab />} />
        <Route path="users" element={<UsersTab />} />
        <Route path="notifications" element={<NotificationsTab />} />
        <Route path="map-editor" element={<MapEditorTab />} />
      </Route>

      {/* 정의되지 않은 주소는 메인 홈페이지로 리다이렉트 */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
