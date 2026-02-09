import { Routes, Route } from 'react-router-dom'
import { Layout } from '@/components/Layout'
import { DashboardHome } from '@/pages/DashboardHome'
import { ServiceDetail } from '@/pages/ServiceDetail'
import { SwaggerEmbed } from '@/pages/SwaggerEmbed'
import { FeatureUsageEmbed } from '@/pages/FeatureUsageEmbed'
import { PATHS } from '@/routes'

export default function App() {
  return (
    <Layout>
      <Routes>
        <Route index element={<DashboardHome />} />
        <Route path="service/:service" element={<ServiceDetail />} />
        <Route path={PATHS.swagger.slice(1)} element={<SwaggerEmbed />} />
        <Route path={PATHS.featureUsage.slice(1)} element={<FeatureUsageEmbed />} />
      </Routes>
    </Layout>
  )
}
