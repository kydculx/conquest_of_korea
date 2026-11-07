export const policyLocales = [
  { code: 'ko', label: '한국어', htmlLang: 'ko', brand: '찜! 모험' },
  { code: 'en', label: 'English', htmlLang: 'en', brand: 'Dibs! Adventure' },
  { code: 'ja', label: '日本語', htmlLang: 'ja', brand: '早い者勝ち！アドベンチャ' },
  { code: 'zh', label: '简体中文', htmlLang: 'zh-Hans', brand: '先到先得！冒险' },
  { code: 'zh-TW', label: '繁體中文', htmlLang: 'zh-Hant', brand: '先到先得！冒險' },
  { code: 'es', label: 'Español', htmlLang: 'es', brand: '¡Me lo pido! Aventura' },
  { code: 'fr', label: 'Français', htmlLang: 'fr', brand: "Prem's ! Aventure" },
  { code: 'de', label: 'Deutsch', htmlLang: 'de', brand: 'Erster! Abenteuer' },
  { code: 'pt', label: 'Português', htmlLang: 'pt', brand: 'Primeiro! Aventura' },
  { code: 'it', label: 'Italiano', htmlLang: 'it', brand: 'Dibs! Avventura' },
];

export const DEFAULT_POLICY_LANG = 'ko';

export function isPolicyLocale(code) {
  return typeof code === 'string' && policyLocales.some((locale) => locale.code === code);
}

export function getPolicyLocale(code) {
  return policyLocales.find((locale) => locale.code === code) ?? policyLocales[0];
}
