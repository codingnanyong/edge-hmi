import { useParams, Link } from 'react-router-dom'
import { useEffect, useState, useMemo } from 'react'
import SwaggerUI from 'swagger-ui-react'
import 'swagger-ui-react/swagger-ui.css'
import { useLocale } from '@/contexts/LocaleContext'
import { SERVICE_INFO } from '@/i18n/translations'
import styles from '@/styles/ServiceDetail.module.css'

const TableApiSwaggerPlugin = () => ({
  wrapComponents: {
    Info: () => () => null,
    Models: () => () => null,
    VersionStamp: () => () => null,
    OpenAPIVersion: () => () => null,
  },
})

function filterSpecForService(fullSpec: Record<string, unknown>, service: string): Record<string, unknown> {
  const prefix = `/${service}`
  const paths: Record<string, unknown> = {}
  const pathObj = fullSpec.paths as Record<string, unknown> | undefined
  if (pathObj) {
    for (const [path, pathItem] of Object.entries(pathObj)) {
      if (path === prefix || path.startsWith(`${prefix}/`)) {
        paths[path] = pathItem
      }
    }
  }

  return {
    ...fullSpec,
    info: { title: '', version: '', description: '' },
    paths,
    tags: [{ name: service }],
  }
}

export function ServiceDetail() {
  const { service } = useParams<{ service: string }>()
  const [fullSpec, setFullSpec] = useState<Record<string, unknown> | null>(null)

  useEffect(() => {
    fetch('/openapi.json')
      .then((r) => r.json())
      .then(setFullSpec)
  }, [])

  const filteredSpec = useMemo(() => {
    if (!fullSpec || !service) return null
    return filterSpecForService(fullSpec, service)
  }, [fullSpec, service])

  const { locale, t } = useLocale()
  const serviceInfo = SERVICE_INFO[locale]
  const info = service ? serviceInfo[service] : null

  return (
    <div className={styles.page}>
      <nav className={styles.breadcrumb}>
        <Link to="/">{t('common.overview')}</Link>
        <span>/</span>
        <span>{info?.title ?? service}</span>
      </nav>
      <h1 className={styles.pageTitle}>{info?.title ?? service}</h1>
      <p className={styles.muted}>
        {info?.description ?? 'Table API'} —{' '}
        <Link to="/swagger">Swagger UI</Link> {t('serviceDetail.swaggerLink')}
      </p>

      {filteredSpec ? (
        <div className={styles.swaggerWrap}>
          <SwaggerUI
            spec={filteredSpec}
            docExpansion="list"
            defaultModelsExpandDepth={-1}
            persistAuthorization
            plugins={[TableApiSwaggerPlugin]}
          />
        </div>
      ) : (
        <p className={styles.loading}>{t('serviceDetail.loading')}</p>
      )}
    </div>
  )
}
