import { Link, NavLink } from 'react-router-dom'
import { useLocale } from '@/contexts/LocaleContext'
import { TABLE_SERVICES } from '@/constants'
import { SERVICE_INFO } from '@/i18n/translations'
import { NAV_ITEMS, PATHS } from '@/routes'
import styles from '@/styles/Sidebar.module.css'

export function Sidebar() {
  const { t, locale } = useLocale()
  const serviceInfo = SERVICE_INFO[locale]
  return (
    <aside className={styles.sidebar}>
      <Link to={PATHS.home} className={styles.header}>
        <img src="/favicon.svg" alt="" className={styles.headerIcon} aria-hidden />
        <div className={styles.headerText}>
          <h1 className={styles.title}>Edge HMI</h1>
          <span className={styles.subtitle}>API Gateway</span>
        </div>
      </Link>

      <nav className={styles.nav}>
        <div className={styles.navGroup}>
          <span className={styles.navGroupTitle}>{t('common.quickLinks')}</span>
          {NAV_ITEMS.map(({ to, labelKey }) => (
            <NavLink
              key={to}
              to={to}
              end={to === PATHS.home}
              className={({ isActive }) =>
                `${styles.navLink} ${isActive ? styles.navLinkActive : ''}`
              }
            >
              <span className={styles.linkText}>{t(labelKey)}</span>
              {to !== PATHS.home && <span className={styles.chevron}>›</span>}
            </NavLink>
          ))}
        </div>

        <div className={styles.navGroup}>
          <span className={styles.navGroupTitle}>{t('common.tableApis')}</span>
          <div className={styles.serviceList}>
            {TABLE_SERVICES.map((svc) => {
              const info = serviceInfo[svc]
              return (
                <NavLink
                  key={svc}
                  to={PATHS.service(svc)}
                  className={({ isActive }) =>
                    `${styles.navLink} ${styles.serviceLink} ${isActive ? styles.navLinkActive : ''}`
                  }
                >
                  <span className={styles.linkText}>{info?.title ?? svc}</span>
                  <span className={styles.chevron}>›</span>
                </NavLink>
              )
            })}
          </div>
        </div>
      </nav>
    </aside>
  )
}
