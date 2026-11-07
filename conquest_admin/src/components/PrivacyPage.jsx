import { useSearchParams } from 'react-router-dom';
import PolicyLayout from './PolicyLayout';
import { privacyContent } from '../policy/privacyContent';
import { DEFAULT_POLICY_LANG, isPolicyLocale } from '../policy/locales';

export default function PrivacyPage() {
  const [searchParams, setSearchParams] = useSearchParams();
  const requestedLang = searchParams.get('lang');
  const lang = isPolicyLocale(requestedLang) ? requestedLang : DEFAULT_POLICY_LANG;

  const handleLanguageChange = (code) => {
    const next = new URLSearchParams(searchParams);
    next.set('lang', code);
    setSearchParams(next, { replace: true });
  };

  return (
    <PolicyLayout
      doc="privacy"
      content={privacyContent}
      lang={lang}
      onLangChange={handleLanguageChange}
    />
  );
}
