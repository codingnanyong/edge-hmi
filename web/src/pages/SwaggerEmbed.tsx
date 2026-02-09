import { useEffect, useState } from 'react'
import SwaggerUI from 'swagger-ui-react'
import 'swagger-ui-react/swagger-ui.css'
import { useLocale } from '@/contexts/LocaleContext'
import styles from '@/styles/SwaggerEmbed.module.css'

export function SwaggerEmbed() {
  const { t } = useLocale()
  const [spec, setSpec] = useState<object | null>(null)

  useEffect(() => {
    fetch('/openapi.json')
      .then((r) => r.json())
      .then(setSpec)
  }, [])

  return (
    <div className={styles.wrapper}>
      <h1 className={styles.title}>{t('swaggerEmbed.title')}</h1>
      {spec ? (
        <div className={styles.swagger}>
          <SwaggerUI spec={spec} docExpansion="none" />
        </div>
      ) : (
        <p className={styles.loading}>{t('swaggerEmbed.loading')}</p>
      )}
    </div>
  )
}
