/**
 * Edge HMI API - Feature Usage: render data-driven sections
 */
(function () {
  const BASE = window.location.origin;
  const data = typeof FEATURE_USAGE !== "undefined" ? FEATURE_USAGE : { baseUrl: BASE, groups: [] };

  function escapeHtml(s) {
    const div = document.createElement("div");
    div.textContent = s;
    return div.innerHTML;
  }

  function renderFeature(f) {
    let html = "";
    if (f.purpose) html += `<p class="feat-purpose">${escapeHtml(f.purpose)}</p>`;
    if (f.steps && f.steps.length) {
      html += '<table class="feat-table"><thead><tr><th>API</th><th>curl</th></tr></thead><tbody>';
      f.steps.forEach((s) => {
        const curl = (s.curl || "").replace(/\{\{BASE\}\}/g, BASE);
        html += `<tr><td><code>${escapeHtml(s.api)}</code></td><td><code class="feat-curl">${escapeHtml(curl)}</code></td></tr>`;
      });
      html += "</tbody></table>";
    }
    if (f.formula) html += `<p class="feat-formula"><strong>Formula:</strong> <code>${escapeHtml(f.formula)}</code></p>`;
    if (f.logic) html += `<p class="feat-logic">${escapeHtml(f.logic)}</p>`;
    if (f.note) html += `<p class="feat-note">${escapeHtml(f.note)}</p>`;
    if (f.code) html += `<pre class="feat-code"><code>${escapeHtml(f.code)}</code></pre>`;
    return html;
  }

  function render() {
    const container = document.getElementById("feat-content");
    if (!container || !data.groups.length) return;

    let html = "";
    data.groups.forEach((g) => {
      html += `<section class="feat-group"><h2 class="feat-group-title">${g.id}. ${escapeHtml(g.title)}</h2>`;
      g.features.forEach((f) => {
        html += `<details class="feat-card"><summary>${f.id} ${escapeHtml(f.title)}</summary><div class="feat-body">${renderFeature(f)}</div></details>`;
      });
      html += "</section>";
    });

    container.innerHTML = html;
    document.getElementById("feat-loading").style.display = "none";
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", render);
  } else {
    render();
  }
})();
