import { useState, useEffect, lazy, Suspense } from 'react';
import { Routes, Route, Navigate, useNavigate, useLocation, Outlet } from 'react-router-dom';
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

const DashboardTab = lazy(() => import('./components/DashboardTab'));
const RankingTab = lazy(() => import('./components/RankingTab'));
const UsersTab = lazy(() => import('./components/UsersTab'));
const NotificationsTab = lazy(() => import('./components/NotificationsTab'));
const MapEditorTab = lazy(() => import('./components/MapEditorTab'));
const TileAttributeEditorTab = lazy(() => import('./components/TileAttributeEditorTab'));
const UserTilesTab = lazy(() => import('./components/UserTilesTab'));
const UserDailyRecordsTab = lazy(() => import('./components/UserDailyRecordsTab'));
const GalleryTab = lazy(() => import('./components/GalleryTab'));

const THEME_KEY = 'conquest-admin-theme';
const SIDEBAR_KEY = 'conquest-admin-sidebar';

const spinner = <div className="tactical-spinner" style={{ margin: '20vh auto' }} />;

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
    'user-daily': { title: '일일 이동 기록', desc: '사용자별 일일 이동 타일 기록입니다' },
    notifications: { title: '푸시 알림', desc: '전체 또는 개별 알림을 발송합니다' },
    gallery: { title: '갤러리', desc: '현장 사진 목록을 확인합니다' },
    'tile-editor': { title: '타일 속성 에디터', desc: '타일 속성을 직접 편집합니다' },
    'map-editor': { title: '패턴 에디터', desc: '지도 위에 패턴을 그립니다' },
  };

  const getPageMeta = () => {
    const currentPath = location.pathname;
    const item = allNavItems.find(m => currentPath.startsWith(m.path));
    if (item && pageMeta[item.id]) return pageMeta[item.id];
    if (currentPath.startsWith('/admin/user-daily')) return pageMeta['user-daily'];
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

        <section style={{ position: 'relative', zIndex: 1 }}>
          <Outlet />
        </section>
      </main>
    </div>
  );
}

export default function AdminApp() {
  const [adminUser, setAdminUser] = useState(null);
  const [authInitialized, setAuthInitialized] = useState(false);
  const navigate = useNavigate();

  useEffect(() => {
    let subscription;

    const initAuth = async () => {
      try {
        const { data: { session } } = await supabase.auth.getSession();
        if (session && session.user) {
          const user = session.user;
          let isAdmin = user.app_metadata?.role === 'admin';

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

    const { data } = supabase.auth.onAuthStateChange(async (event, session) => {
      if (event === 'SIGNED_OUT') {
        setAdminUser(null);
      } else if (event === 'SIGNED_IN' && session?.user) {
        const user = session.user;
        let isAdmin = user.app_metadata?.role === 'admin';

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
    subscription = data.subscription;

    return () => {
      subscription?.unsubscribe();
    };
  }, []);

  const handleLogout = async () => {
    await supabase.auth.signOut();
    setAdminUser(null);
    navigate('/admin');
  };

  if (!authInitialized) return spinner;
  if (!adminUser) return <LoginPage onLoginSuccess={setAdminUser} />;

  return (
    <Suspense fallback={spinner}>
      <Routes>
        <Route element={<AdminLayout user={adminUser} onLogout={handleLogout} />}>
          <Route index element={<Navigate to="dashboard" replace />} />
          <Route path="dashboard" element={<DashboardTab />} />
          <Route path="ranking" element={<RankingTab />} />
          <Route path="users" element={<UsersTab />} />
          <Route path="user-tiles" element={<UserTilesTab />} />
          <Route path="user-daily" element={<UserDailyRecordsTab />} />
          <Route path="notifications" element={<NotificationsTab />} />
          <Route path="gallery" element={<GalleryTab />} />
          <Route path="tile-editor" element={<TileAttributeEditorTab />} />
          <Route path="map-editor" element={<MapEditorTab />} />
          <Route path="*" element={<Navigate to="dashboard" replace />} />
        </Route>
      </Routes>
    </Suspense>
  );
}
