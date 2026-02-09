export const PATHS = {
  home: '/',
  swagger: '/swagger',
  featureUsage: '/feature-usage',
  service: (id: string) => `/service/${id}`,
} as const

export const NAV_ITEMS = [
  { to: PATHS.home, labelKey: 'common.overview' },
  { to: PATHS.swagger, labelKey: 'common.swaggerUi' },
  { to: PATHS.featureUsage, labelKey: 'common.featureUsage' },
] as const
