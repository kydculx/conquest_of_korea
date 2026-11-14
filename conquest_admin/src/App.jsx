import { lazy, Suspense } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import LandingPage from './components/LandingPage';

const PromoPage = lazy(() => import('./components/PromoPage'));
const TermsPage = lazy(() => import('./components/TermsPage'));
const PrivacyPage = lazy(() => import('./components/PrivacyPage'));
const AdminApp = lazy(() => import('./AdminApp'));

const spinner = <div className="tactical-spinner" style={{ margin: '20vh auto' }} />;

export default function App() {
  return (
    <Suspense fallback={spinner}>
      <Routes>
        <Route path="/" element={<LandingPage />} />
        <Route path="/promo" element={<PromoPage />} />
        <Route path="/terms" element={<TermsPage />} />
        <Route path="/privacy" element={<PrivacyPage />} />

        <Route path="/admin/*" element={<AdminApp />} />

        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </Suspense>
  );
}
