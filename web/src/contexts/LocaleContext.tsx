import { createContext, useContext, useEffect, useState } from 'react'

export type Locale = 'ko' | 'en'

const STORAGE_KEY = 'edge-hmi-locale'

const LocaleContext = createContext<{
  locale: Locale
  setLocale: (l: Locale) => void
  toggleLocale: () => void
  t: (key: string) => string
} | null>(null)

function getInitialLocale(): Locale {
  if (typeof window === 'undefined') return 'ko'
  const stored = localStorage.getItem(STORAGE_KEY) as Locale | null
  if (stored === 'ko' || stored === 'en') return stored
  return 'ko'
}

export function LocaleProvider({ children }: { children: React.ReactNode }) {
  const [locale, setLocaleState] = useState<Locale>(getInitialLocale)

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, locale)
  }, [locale])

  const setLocale = (l: Locale) => setLocaleState(l)
  const toggleLocale = () => setLocaleState((prev) => (prev === 'ko' ? 'en' : 'ko'))

  const t = (key: string) => {
    const keys = key.split('.')
    let value: unknown = TRANSLATIONS[locale]
    for (const k of keys) {
      value = (value as Record<string, unknown>)?.[k]
    }
    return (typeof value === 'string' ? value : key) as string
  }

  return (
    <LocaleContext.Provider value={{ locale, setLocale, toggleLocale, t }}>
      {children}
    </LocaleContext.Provider>
  )
}

export function useLocale() {
  const ctx = useContext(LocaleContext)
  if (!ctx) throw new Error('useLocale must be used within LocaleProvider')
  return ctx
}

const TRANSLATIONS: Record<Locale, Record<string, unknown>> = {
  ko: {
    common: {
      overview: 'Overview',
      swaggerUi: 'Swagger UI',
      featureUsage: 'Feature Usage',
      quickLinks: '빠른 링크',
      tableApis: '테이블 API',
      darkMode: '다크 모드',
      lightMode: '라이트 모드',
      korean: '한글',
      english: '영어',
      switchToEnglish: '영어로 전환',
      switchToKorean: '한글로 전환',
    },
    dashboard: {
      title: 'Edge HMI API Services',
      subtitle: 'Edge HMI API Gateway — 테이블 API 프록시 서비스',
      servicesCount: '개 서비스 통합',
      swaggerCard: 'API 문서 및 Try it out',
      featureCard: 'Feature API 사용 가이드',
      sectionDesc: '마스터 데이터·설정·이력 API — 카드 클릭 시 상세 Swagger 문서로 이동',
      searchPlaceholder: '서비스 검색…',
      noResults: '검색 결과 없음',
      loading: '로딩 중…',
      error: '오류',
    },
    featureUsage: {
      title: 'Feature API 사용 가이드',
      subtitle: '각 기능별 API·curl·로직 사용 방법',
      tableCategory: '구분',
      tableFunction: '기능',
      tableOverview: '개요',
      tableDataSource: '데이터 소스',
      apiEndpoints: 'API 엔드포인트',
      logic: '로직',
      code: '예시 코드',
    },
    serviceDetail: {
      swaggerLink: '에서 전체 스펙 확인',
      loading: '로딩 중…',
    },
    swaggerEmbed: {
      title: 'API Documentation',
      loading: 'Loading OpenAPI spec…',
    },
  },
  en: {
    common: {
      overview: 'Overview',
      swaggerUi: 'Swagger UI',
      featureUsage: 'Feature Usage',
      quickLinks: 'Quick Links',
      tableApis: 'Table APIs',
      darkMode: 'Dark mode',
      lightMode: 'Light mode',
      korean: 'Korean',
      english: 'English',
      switchToEnglish: 'Switch to English',
      switchToKorean: 'Switch to Korean',
    },
    dashboard: {
      title: 'Edge HMI API Services',
      subtitle: 'Edge HMI API Gateway — Table API proxy service',
      servicesCount: ' services integrated',
      swaggerCard: 'API docs and Try it out',
      featureCard: 'Feature API usage guide',
      sectionDesc: 'Master data · Config · History APIs — Click card for Swagger docs',
      searchPlaceholder: 'Search services…',
      noResults: 'No results',
      loading: 'Loading…',
      error: 'Error',
    },
    featureUsage: {
      title: 'Feature API Usage Guide',
      subtitle: 'How to use each feature — APIs, curl, logic',
      tableCategory: 'Category',
      tableFunction: 'Function',
      tableOverview: 'Overview',
      tableDataSource: 'Data Source',
      apiEndpoints: 'API Endpoints',
      logic: 'Logic',
      code: 'Code',
    },
    serviceDetail: {
      swaggerLink: ' for full spec',
      loading: 'Loading…',
    },
    swaggerEmbed: {
      title: 'API Documentation',
      loading: 'Loading OpenAPI spec…',
    },
  },
}
