import { useEffect, useMemo, useState } from 'react'
import SwaggerUI from 'swagger-ui-react'
import 'swagger-ui-react/swagger-ui.css'
import { useLocale } from '@/contexts/LocaleContext'
import styles from '@/styles/SwaggerEmbed.module.css'

const SWAGGER_INFO_KO = {
  title: 'Edge HMI API 문서',
  descriptionTemplate: '프록시 게이트웨이. {{count}}개 테이블 API 연동.',
}
const SWAGGER_INFO_EN = {
  title: 'Edge HMI API Documentation',
  descriptionTemplate: 'Proxy gateway. {{count}} table APIs integrated.',
}

function applyLocaleToSpec(spec: object, locale: 'ko' | 'en'): object {
  const info = (spec as { info?: { description?: string } }).info
  const countMatch = info?.description?.match(/(\d+)/)
  const count = countMatch ? countMatch[1] : '0'
  const lang = locale === 'ko' ? SWAGGER_INFO_KO : SWAGGER_INFO_EN
  const description = lang.descriptionTemplate.replace('{{count}}', count)
  return {
    ...spec,
    info: {
      ...(typeof info === 'object' ? info : {}),
      title: lang.title,
      description,
    },
  }
}

export function SwaggerEmbed() {
  const { t, locale } = useLocale()
  const [spec, setSpec] = useState<object | null>(null)

  useEffect(() => {
    fetch('/openapi.json')
      .then((r) => r.json())
      .then(setSpec)
  }, [])

  const displaySpec = useMemo(
    () => (spec ? applyLocaleToSpec(spec, locale) : null),
    [spec, locale]
  )

  return (
    <div className={styles.wrapper}>
      <h1 className={styles.title}>{t('swaggerEmbed.title')}</h1>
      {displaySpec ? (
        <div className={styles.swagger} key={locale}>
          <SwaggerUI spec={displaySpec} docExpansion="none" />
        </div>
      ) : (
        <p className={styles.loading}>{t('swaggerEmbed.loading')}</p>
      )}
    </div>
  )
}
