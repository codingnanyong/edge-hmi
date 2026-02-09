import { Link } from 'react-router-dom'
import { useEffect, useState } from 'react'
import { useLocale } from '@/contexts/LocaleContext'
import { TABLE_SERVICES } from '@/constants'
import { SERVICE_INFO } from '@/i18n/translations'
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

      <section className={styles.quickLinks}>
        <Link to={PATHS.swagger} className={`${styles.serviceCard} ${styles.quickLinkCard}`}>
          <span className={styles.cardIcon} aria-hidden>📄</span>
          <div className={styles.cardContent}>
            <span className={styles.cardTitle}>{t('common.swaggerUi')}</span>
            <span className={styles.cardDesc}>{t('dashboard.swaggerCard')}</span>
          </div>
          <span className={styles.chevron}>›</span>
        </Link>
        <Link to={PATHS.featureUsage} className={`${styles.serviceCard} ${styles.quickLinkCard}`}>
          <span className={styles.cardIcon} aria-hidden>📖</span>
          <div className={styles.cardContent}>
            <span className={styles.cardTitle}>{t('common.featureUsage')}</span>
            <span className={styles.cardDesc}>{t('dashboard.featureCard')}</span>
          </div>
          <span className={styles.chevron}>›</span>
        </Link>
      </section>

      <section className={styles.section}>
        <h2 className={styles.sectionTitle}>{t('common.tableApis')}</h2>
        <p className={styles.sectionDesc}>{t('dashboard.sectionDesc')}</p>
        <div className={styles.cardGrid}>
          {TABLE_SERVICES.map((svc) => {
            const info = serviceInfo[svc] ?? { title: svc, description: `${svc} API` }
            return (
              <Link key={svc} to={PATHS.service(svc)} className={styles.serviceCard}>
                <span className={styles.cardTitle}>{info.title}</span>
                <span className={styles.cardDesc}>{info.description}</span>
                <span className={styles.chevron}>›</span>
              </Link>
            )
          })}
        </div>
      </section>
    </div>
  )
}
