import React, { useEffect } from 'react';
import { Shield, Languages } from 'lucide-react';
import { getPolicyLocale, policyLocales } from '../policy/locales';

const ACCENT = {
  terms: '#3b82f6',
  privacy: '#8b5cf6',
};

function renderInline(text) {
  return text.split(/(\*\*[^*]+\*\*)/g).map((part, index) =>
    part.startsWith('**') && part.endsWith('**') ? (
      <strong key={index}>{part.slice(2, -2)}</strong>
    ) : (
      <React.Fragment key={index}>{part}</React.Fragment>
    ),
  );
}

export default function PolicyLayout({ doc, content, lang, onLangChange }) {
  const locale = getPolicyLocale(lang);
  const pageContent = content[locale.code] ?? content.ko;
  const accent = ACCENT[doc] ?? ACCENT.terms;

  useEffect(() => {
    document.documentElement.lang = locale.htmlLang;
  }, [locale.htmlLang]);

  return (
    <div
      style={{
        backgroundColor: '#0b0f19',
        color: '#f8fafc',
        minHeight: '100vh',
        fontFamily: 'var(--font-main)',
        display: 'flex',
        flexDirection: 'column',
        padding: '2rem 1rem',
      }}
    >
      <div style={{ maxWidth: '800px', width: '100%', margin: '0 auto' }}>
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            gap: '1rem',
            flexWrap: 'wrap',
            marginBottom: '3rem',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <Shield size={18} style={{ color: accent }} />
            <span
              style={{
                fontSize: '0.85rem',
                color: '#64748b',
                fontWeight: 600,
                fontFamily: 'var(--font-display)',
              }}
            >
              {locale.brand}
            </span>
          </div>

          <label
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.4rem',
              color: '#94a3b8',
            }}
          >
            <Languages size={16} aria-hidden="true" />
            <select
              aria-label="Language"
              value={locale.code}
              onChange={(event) => onLangChange(event.target.value)}
              style={{
                background: '#111827',
                border: '1px solid #334155',
                borderRadius: '0.5rem',
                color: '#e2e8f0',
                padding: '0.4rem 0.6rem',
                fontSize: '0.85rem',
                fontFamily: 'var(--font-main)',
                cursor: 'pointer',
              }}
            >
              {policyLocales.map((item) => (
                <option key={item.code} value={item.code}>
                  {item.label}
                </option>
              ))}
            </select>
          </label>
        </div>

        <article
          className="tactical-card"
          style={{
            background: '#111827',
            borderColor: '#1f2937',
            padding: '2.5rem',
            lineHeight: 1.7,
          }}
        >
          <h1
            style={{
              fontSize: '2rem',
              fontWeight: 800,
              marginBottom: '1.5rem',
              fontFamily: 'var(--font-display)',
            }}
          >
            {pageContent.title}
          </h1>

          {pageContent.effective && (
            <p style={{ color: '#94a3b8', fontSize: '0.9rem', marginBottom: '2rem' }}>
              {pageContent.effective}
            </p>
          )}

          <div style={{ display: 'flex', flexDirection: 'column', gap: '1.8rem', fontSize: '0.95rem' }}>
            {pageContent.sections.map((section, sectionIndex) => (
              <section key={sectionIndex}>
                <h3 style={{ fontSize: '1.15rem', color: accent, marginBottom: '0.6rem' }}>
                  {section.title}
                </h3>

                {section.blocks.map((block, blockIndex) =>
                  block.type === 'p' ? (
                    <p
                      key={blockIndex}
                      style={{ color: '#d1d5db', marginBottom: '0.5rem', whiteSpace: 'pre-line' }}
                    >
                      {renderInline(block.text)}
                    </p>
                  ) : (
                    <ul
                      key={blockIndex}
                      style={{
                        paddingLeft: '1.2rem',
                        color: '#d1d5db',
                        display: 'flex',
                        flexDirection: 'column',
                        gap: '0.4rem',
                      }}
                    >
                      {block.items.map((item, itemIndex) => (
                        <li
                          key={itemIndex}
                          style={{
                            color: item.danger ? '#fca5a5' : '#d1d5db',
                            paddingLeft: item.indent ? '1rem' : undefined,
                            whiteSpace: 'pre-line',
                          }}
                        >
                          {renderInline(item.text)}
                        </li>
                      ))}
                    </ul>
                  ),
                )}
              </section>
            ))}
          </div>
        </article>
      </div>
    </div>
  );
}
