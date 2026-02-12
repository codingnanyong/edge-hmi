import { Outlet } from 'react-router-dom'
import { useLocale } from '@/contexts/LocaleContext'
import { useTheme } from '@/contexts/ThemeContext'
import { Sidebar } from '@/components/Sidebar'
import styles from '@/styles/Layout.module.css'

function SunIcon({ className }: { className?: string }) {
  return (
    <svg className={className} width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
      <circle cx="12" cy="12" r="4" />
      <path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M6.34 17.66l-1.41 1.41M19.07 4.93l-1.41 1.41" />
    </svg>
  )
}

function MoonIcon({ className }: { className?: string }) {
  return (
    <svg className={className} width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
      <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
    </svg>
  )
}

export function Layout({ children }: { children?: React.ReactNode }) {
  const { theme, toggleTheme } = useTheme()
  const { locale, toggleLocale, t } = useLocale()
  return (
    <div className={styles.wrapper}>
      <div className={styles.layout}>
        <Sidebar />
        <main className={styles.main}>
          <header className={styles.mainHeader}>
            <button
              type="button"
              onClick={toggleLocale}
              className={styles.langToggle}
              title={locale === 'ko' ? t('common.switchToEnglish') : t('common.switchToKorean')}
            >
              {locale === 'ko' ? 'KOR' : 'ENG'}
            </button>
            <button
              type="button"
              onClick={toggleTheme}
              className={styles.themeToggle}
              title={theme === 'light' ? t('common.darkMode') : t('common.lightMode')}
              aria-label={theme === 'light' ? t('common.darkMode') : t('common.lightMode')}
            >
              {theme === 'light' ? (
                <MoonIcon className={styles.themeIcon} />
              ) : (
                <SunIcon className={styles.themeIcon} />
              )}
            </button>
          </header>
          <div className={styles.mainContent}>
            {children ?? <Outlet />}
          </div>
        </main>
      </div>
    </div>
  )
}
