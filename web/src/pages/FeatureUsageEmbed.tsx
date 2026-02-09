import { useLocale } from '@/contexts/LocaleContext'
import { FEATURE_USAGE } from '@/data/feature-usage'
import { getFeatureForLocale } from '@/i18n/feature-i18n'
import { GROUP_TITLES } from '@/i18n/translations'
import styles from '@/styles/FeatureUsageEmbed.module.css'

const base = typeof window !== 'undefined' ? window.location.origin : FEATURE_USAGE.baseUrl

function renderLogicBlock(
  feat: { logic: string; formula?: string; note?: string },
  rawFeature: Record<string, unknown>,
  t: (key: string) => string
) {
  const f = rawFeature as { formula?: string; note?: string }
  const formula = feat.formula ?? f.formula ?? null
  const logic = feat.logic
  const note = feat.note ?? f.note ?? null
  const parts = [formula, logic && logic !== formula ? logic : null, note].filter(Boolean) as string[]
  if (parts.length === 0) return null
  return (
    <div className={styles.logicBlock}>
      <span className={styles.label}>{t('featureUsage.logic')}</span>
      <span>{parts.join(' · ')}</span>
    </div>
  )
}

export function FeatureUsageEmbed() {
  const { t, locale } = useLocale()
  const groupTitles = GROUP_TITLES[locale]

  return (
    <div className={styles.page}>
      <h1 className={styles.title}>{t('featureUsage.title')}</h1>
      <p className={styles.subtitle}>{t('featureUsage.subtitle')}</p>

      {FEATURE_USAGE.groups.map((group) => (
        <section key={group.id} className={styles.group}>
          <h2 className={styles.groupTitle}>{groupTitles[group.id] ?? group.title}</h2>
          {group.features.map((f) => {
            const feat = getFeatureForLocale(f, locale)
            return (
              <div key={f.id} className={styles.feature}>
                <h3 className={styles.featureTitle}>
                  <span className={styles.featureId}>{f.id}</span>
                  {feat.title}
                </h3>
                <p className={styles.purpose}>{feat.purpose}</p>
                <span className={styles.sectionLabel}>{t('featureUsage.apiEndpoints')}</span>
                <ul className={styles.steps}>
                  {f.steps.map((s, i) => (
                    <li key={i}>
                      <code className={styles.api}>{s.api}</code>
                      <code className={styles.curl}>{s.curl.replace(/\{\{BASE\}\}/g, base)}</code>
                    </li>
                  ))}
                </ul>
                {renderLogicBlock(feat, f, t)}
                {'code' in f && f.code && (
                  <>
                    <span className={styles.sectionLabel}>{t('featureUsage.code')}</span>
                    <pre className={styles.code}>{f.code}</pre>
                  </>
                )}
              </div>
            )
          })}
        </section>
      ))}
    </div>
  )
}
