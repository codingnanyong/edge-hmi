import { Link } from 'react-router-dom'
import { useEffect, useState, useMemo } from 'react'
import { useLocale } from '@/contexts/LocaleContext'
import { TABLE_SERVICES } from '@/constants'
import { SERVICE_INFO } from '@/i18n/translations'
import { SERVICE_ICONS } from '@/data/service-icons'
import { PATHS } from '@/routes'
import styles from '@/styles/DashboardHome.module.css'

type Info = {
  service: string
  version: string
  integrated_services_count: number
  services: string[]
}

export function DashboardHome() {
  const { t, locale } = useLocale()
  const serviceInfo = SERVICE_INFO[locale]
  const [info, setInfo] = useState<Info | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [search, setSearch] = useState('')

  const filteredServices = useMemo(() => {
    if (!search.trim()) return TABLE_SERVICES
    const q = search.trim().toLowerCase()
    return TABLE_SERVICES.filter((svc) => {
      const s = serviceInfo[svc]
      const title = (s?.title ?? svc).toLowerCase()
      const desc = (s?.description ?? '').toLowerCase()
      return title.includes(q) || desc.includes(q)
    })
  }, [search, serviceInfo])

  useEffect(() => {
    fetch('/info')
      .then((r) => r.json())
      .then(setInfo)
      .catch((e) => setError(String(e)))
      .finally(() => setLoading(false))
  }, [])

  return (
    <div className={styles.page}>
      <div className={styles.hero}>
        <h1 className={styles.pageTitle}>{t('dashboard.title')}</h1>
        <p className={styles.subtitle}>
          {t('dashboard.subtitle')}
          {info && <span className={styles.version}> v{info.version}</span>}
        </p>
        {info && (
          <p className={styles.stats}>
            {info.integrated_services_count}
            {t('dashboard.servicesCount')}
          </p>
        )}
      </div>

      {loading && <p className={styles.muted}>{t('dashboard.loading')}</p>}
      {error && <p className={styles.error}>{t('dashboard.error')}: {error}</p>}

      <section className={styles.quickLinksSection}>
        <h2 className={styles.quickLinksTitle}>{t('common.quickLinks')}</h2>
        <div className={styles.quickLinks}>
        <Link to={PATHS.swagger} className={styles.quickLinkCard}>
          <span className={styles.cardIconWrap} aria-hidden>📄</span>
          <div className={styles.cardContent}>
            <span className={styles.cardTitle}>{t('common.swaggerUi')}</span>
            <span className={styles.cardDesc}>{t('dashboard.swaggerCard')}</span>
          </div>
        </Link>
        <Link to={PATHS.featureUsage} className={styles.quickLinkCard}>
          <span className={styles.cardIconWrap} aria-hidden>📖</span>
          <div className={styles.cardContent}>
            <span className={styles.cardTitle}>{t('common.featureUsage')}</span>
            <span className={styles.cardDesc}>{t('dashboard.featureCard')}</span>
          </div>
        </Link>
        </div>
      </section>

      <section className={styles.section}>
        <div className={styles.sectionHeader}>
          <div>
            <h2 className={styles.sectionTitle}>{t('common.tableApis')}</h2>
            <p className={styles.sectionDesc}>{t('dashboard.sectionDesc')}</p>
          </div>
          <div className={styles.searchWrap}>
            <span className={styles.searchIcon} aria-hidden>🔍</span>
            <input
              type="search"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder={t('dashboard.searchPlaceholder')}
              className={styles.searchInput}
              aria-label={t('dashboard.searchPlaceholder')}
            />
          </div>
        </div>
        <div className={styles.iconGrid}>
          {filteredServices.map((svc) => {
            const s = serviceInfo[svc] ?? { title: svc, description: `${svc} API` }
            const icon = SERVICE_ICONS[svc] ?? '📄'
            return (
              <Link key={svc} to={PATHS.service(svc)} className={styles.iconCard}>
                <span className={styles.iconCardIcon} aria-hidden>{icon}</span>
                <span className={styles.iconCardLabel}>{s.title}</span>
              </Link>
            )
          })}
        </div>
        {filteredServices.length === 0 && (
          <p className={styles.noResults}>{t('dashboard.noResults')}</p>
        )}
      </section>
    </div>
  )
}
