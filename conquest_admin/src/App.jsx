import React, { useState } from 'react';
import DashboardTab from './components/DashboardTab';
import RankingTab from './components/RankingTab';
import UsersTab from './components/UsersTab';
import NotificationsTab from './components/NotificationsTab';
import {
  ShieldAlert,
  Users,
  Bell,
  Terminal,
  Cpu,
  Trophy,
  Menu,
  X
} from 'lucide-react';

export default function App() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);

  const menuItems = [
    { id: 'dashboard', label: '대시보드', icon: Cpu },
    { id: 'ranking', label: '사용자 랭킹', icon: Trophy },
    { id: 'users', label: '사용자 관리', icon: Users },
    { id: 'notifications', label: '푸시 알림', icon: Bell },
  ];

  const renderContent = () => {
    switch (activeTab) {
      case 'dashboard':
        return <DashboardTab />;
      case 'ranking':
        return <RankingTab />;
      case 'users':
        return <UsersTab />;
      case 'notifications':
        return <NotificationsTab />;
      default:
        return <DashboardTab />;
    }
  };

  const getPageTitle = () => {
    const item = menuItems.find(m => m.id === activeTab);
    return item ? item.label : 'ADMIN CONSOLE';
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
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', paddingBottom: '1rem', borderBottom: '1px solid var(--border-color)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.8rem' }}>
            <Terminal size={24} style={{ color: 'var(--accent-cyan)' }} />
            <div>
              <h1 style={{ fontSize: '1.1rem', fontWeight: 800, fontFamily: 'var(--font-display)', letterSpacing: '0.05em' }}>
                찜! 대모험
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
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => {
                  setActiveTab(item.id);
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

        {/* 푸터 */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', padding: '0.8rem', background: 'var(--bg-primary)', borderRadius: '8px', border: '1px solid var(--border-color)' }}>
          <ShieldAlert size={16} style={{ color: 'var(--accent-gold)' }} />
          <span style={{ fontSize: '0.7rem', color: 'var(--text-secondary)', fontFamily: 'monospace' }}>
            보안 접속 상태
          </span>
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
          {renderContent()}
        </section>
      </main>
    </div>
  );
}
