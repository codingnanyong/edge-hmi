import { Outlet } from 'react-router-dom'
import { useLocale } from '@/contexts/LocaleContext'
import { useTheme } from '@/contexts/ThemeContext'
import { Sidebar } from '@/components/Sidebar'
import styles from '@/styles/Layout.module.css'

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
            >
              {theme === 'light' ? '🌙' : '☀️'}
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
