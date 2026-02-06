/**
 * Edge HMI API - main (Docker-compose: /info -> services, then Swagger UI)
 */
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeApp);
} else {
  initializeApp();
}

async function initializeApp() {
  if (window._appInitialized) return;
  window._appInitialized = true;

  try {
    showLoading();
    const r = await fetch('/info');
    if (r.ok) {
      const info = await r.json();
      const services = info.services || [];
      AppState.availableServices = {};
      services.forEach(s => {
        AppState.availableServices[s] = { is_available: true };
      });
    }
  } catch (e) {
    console.warn('Could not fetch /info:', e);
  }

  try {
    AppState.swaggerUI = initSwaggerUI('/openapi.json', '🏭 Edge HMI API Documentation');
  } catch (e) {
    console.error('Swagger UI init failed:', e);
    showError('Swagger UI 초기화 실패: ' + (e.message || String(e)));
    hideLoading();
  }
}
