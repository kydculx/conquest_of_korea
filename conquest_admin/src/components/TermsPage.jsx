import { useSearchParams } from 'react-router-dom';
import PolicyLayout from './PolicyLayout';
import { termsContent } from '../policy/termsContent';
import { DEFAULT_POLICY_LANG, isPolicyLocale } from '../policy/locales';

export default function TermsPage() {
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
      doc="terms"
      content={termsContent}
      lang={lang}
      onLangChange={handleLanguageChange}
    />
  );
}
