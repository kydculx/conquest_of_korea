import React, { useState, useEffect } from 'react';
import { Routes, Route, Navigate, useNavigate, useLocation, Outlet } from 'react-router-dom';
import DashboardTab from './components/DashboardTab';
import RankingTab from './components/RankingTab';
import UsersTab from './components/UsersTab';
import NotificationsTab from './components/NotificationsTab';
import MapEditorTab from './components/MapEditorTab';
import TileAttributeEditorTab from './components/TileAttributeEditorTab';
import UserTilesTab from './components/UserTilesTab';
import GalleryTab from './components/GalleryTab';
import LandingPage from './components/LandingPage';
import PromoPage from './components/PromoPage';
import TermsPage from './components/TermsPage';
import PrivacyPage from './components/PrivacyPage';
import LoginPage from './components/LoginPage';
import { supabase } from './supabase';
import {
  Users,
  Bell,
  Terminal,
  LayoutDashboard,
  Trophy,
  Menu,
  X,
  Map,
  Layers,
  Image,
  LogOut,
  Sun,
  Moon,
  ChevronsLeft,
  ChevronsRight,
  ChevronRight
} from 'lucide-react';

const THEME_KEY = 'conquest-admin-theme';
const SIDEBAR_KEY = 'conquest-admin-sidebar';

function AdminLayout({ user, onLogout }) {
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const [isCollapsed, setIsCollapsed] = useState(() => {
    try {
      return localStorage.getItem(SIDEBAR_KEY) === 'collapsed';
    } catch {
      return false;
    }
  });
  const [theme, setTheme] = useState(() => {
    try {
      return localStorage.getItem(THEME_KEY) || 'dark';
    } catch {
      return 'dark';
    }
  });
  const location = useLocation();
  const navigate = useNavigate();

  useEffect(() => {
    try {
      localStorage.setItem(SIDEBAR_KEY, isCollapsed ? 'collapsed' : 'expanded');
    } catch {
      return;
    }
  }, [isCollapsed]);

  useEffect(() => {
    document.documentElement.dataset.theme = theme;
    try {
      localStorage.setItem(THEME_KEY, theme);
    } catch {
      return;
    }
  }, [theme]);

  const navGroups = [
    {
      label: '모니터링',
      items: [
        { id: 'dashboard', label: '대시보드', icon: LayoutDashboard, path: '/admin/dashboard' },
      ],
    },
    {
      label: '사용자',
      items: [
        { id: 'users', label: '사용자 관리', icon: Users, path: '/admin/users' },
        { id: 'ranking', label: '사용자 랭킹', icon: Trophy, path: '/admin/ranking' },
      ],
    },
    {
      label: '운영',
      items: [
        { id: 'notifications', label: '푸시 알림', icon: Bell, path: '/admin/notifications' },
        { id: 'gallery', label: '갤러리', icon: Image, path: '/admin/gallery' },
      ],
    },
    {
      label: '지도 도구',
      items: [
        { id: 'tile-editor', label: '타일 속성 에디터', icon: Layers, path: '/admin/tile-editor' },
        { id: 'map-editor', label: '패턴 에디터', icon: Map, path: '/admin/map-editor' },
      ],
    },
  ];
  const allNavItems = navGroups.flatMap((g) => g.items);

  const pageMeta = {
    dashboard: { title: '대시보드', desc: '실시간 현황을 한눈에 확인합니다' },
    ranking: { title: '사용자 랭킹', desc: '점령과 이동 기록 기준 순위입니다' },
    users: { title: '사용자 관리', desc: '가입자 정보와 재화를 관리합니다' },
    notifications: { title: '푸시 알림', desc: '전체 또는 개별 알림을 발송합니다' },
    gallery: { title: '갤러리', desc: '현장 사진 목록을 확인합니다' },
    'tile-editor': { title: '타일 속성 에디터', desc: '타일 속성을 직접 편집합니다' },
    'map-editor': { title: '패턴 에디터', desc: '지도 위에 패턴을 그립니다' },
  };

  const getPageMeta = () => {
    const currentPath = location.pathname;
    const item = allNavItems.find(m => currentPath.startsWith(m.path));
    if (item && pageMeta[item.id]) return pageMeta[item.id];
    if (currentPath === '/admin') return pageMeta.dashboard;
    return { title: '관리 콘솔', desc: '서비스 운영을 위한 도구 모음입니다' };
  };
  const meta = getPageMeta();
  const userInitial = ((user?.email || '관')[0] || '관').toUpperCase();

  return (
    <div className={`app-container ${isCollapsed ? 'sidebar-collapsed' : ''}`}>
      {isSidebarOpen && (
        <div className="sidebar-backdrop" onClick={() => setIsSidebarOpen(false)} />
      )}

      <aside className={`sidebar ${isSidebarOpen ? 'open' : ''}`}>
        <div className="admin-brand">
          <div className="admin-brand-mark">
            <Terminal size={20} />
          </div>
          <div className="admin-brand-text">
            <h1 className="admin-brand-name">
              찜! 모험
            </h1>
            <div className="admin-brand-sub">
              관리 콘솔 v1.0
            </div>
          </div>
          <button
            className="mobile-only"
            onClick={() => setIsSidebarOpen(false)}
            style={{ background: 'none', border: 'none', color: 'var(--text-secondary)', cursor: 'pointer', display: 'flex', alignItems: 'center' }}
            aria-label="메뉴 닫기"
          >
            <X size={20} />
          </button>
        </div>

        <nav className="sidebar-nav">
          {navGroups.map((group) => (
            <div key={group.label} className="nav-group">
              <div className="nav-group-label">{group.label}</div>
              {group.items.map((item) => {
                const Icon = item.icon;
                const isActive = location.pathname === item.path || (item.id === 'dashboard' && location.pathname === '/admin');
                return (
                  <button
                    key={item.id}
                    onClick={() => {
                      navigate(item.path);
                      setIsSidebarOpen(false);
                    }}
                    className={`nav-item ${isActive ? 'active' : ''}`}
                    title={item.label}
                  >
                    <Icon size={18} />
                    <span className="nav-label">{item.label}</span>
                  </button>
                );
              })}
            </div>
          ))}
        </nav>

        <div className="sidebar-footer">
          <div className="sidebar-user">
            <div className="user-chip" title={user?.email}>{userInitial}</div>
            <div className="sidebar-user-meta">
              <div className="sidebar-user-name">관리자</div>
              <span className="sidebar-user-email" title={user?.email}>
                {user?.email || '로그인 상태'}
              </span>
            </div>
          </div>
          <button
            onClick={onLogout}
            className="logout-btn"
            title="로그아웃"
          >
            <LogOut size={13} />
            <span>로그아웃</span>
          </button>
        </div>
      </aside>

      <main className="main-content">
        <div className="topbar">
          <div className="topbar-left">
            <button
              className="menu-toggle-btn"
              onClick={() => setIsSidebarOpen(true)}
              aria-label="메뉴 열기"
            >
              <Menu size={18} />
            </button>
            <button
              type="button"
              className="collapse-btn"
              onClick={() => setIsCollapsed(!isCollapsed)}
              aria-label={isCollapsed ? '사이드바 펼치기' : '사이드바 접기'}
              title={isCollapsed ? '사이드바 펼치기' : '사이드바 접기'}
            >
              {isCollapsed ? <ChevronsRight size={16} /> : <ChevronsLeft size={16} />}
            </button>
            <nav className="breadcrumb" aria-label="현재 위치">
              관리 콘솔
              <ChevronRight size={13} />
              <strong>{meta.title}</strong>
            </nav>
          </div>
          <div className="header-right">
            <button
              type="button"
              className="theme-toggle"
              onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
              aria-label={theme === 'dark' ? '라이트 모드로 전환' : '다크 모드로 전환'}
              title={theme === 'dark' ? '라이트 모드로 전환' : '다크 모드로 전환'}
            >
              {theme === 'dark' ? <Sun size={16} /> : <Moon size={16} />}
            </button>
            <span className="status-pill">
              <span className="status-dot" />
              정상 운영 중
            </span>
            <div className="user-chip" title={user?.email}>{userInitial}</div>
          </div>
        </div>

        <div className="content-head">
          <h1 className="content-title">{meta.title}</h1>
          <p className="content-desc">{meta.desc}</p>
        </div>

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
      <Route path="/promo" element={<PromoPage />} />
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
        <Route path="user-tiles" element={<UserTilesTab />} />
        <Route path="notifications" element={<NotificationsTab />} />
        <Route path="gallery" element={<GalleryTab />} />
        <Route path="tile-editor" element={<TileAttributeEditorTab />} />
        <Route path="map-editor" element={<MapEditorTab />} />
      </Route>

      {/* 정의되지 않은 주소는 메인 홈페이지로 리다이렉트 */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
