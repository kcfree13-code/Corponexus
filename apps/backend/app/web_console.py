WEB_CONSOLE_HTML = """<!DOCTYPE html>
<html lang="it">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>CorpNexus - Cyber-Forensic Corporate Intelligence Console</title>
  <!-- Google Fonts & Icons -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600;700&family=Inter:wght@400;600;700&display=swap" rel="stylesheet">
  <!-- Vis.js Network for 2D Graph -->
  <script type="text/javascript" src="https://unpkg.com/vis-network/standalone/umd/vis-network.min.js"></script>
  <!-- Leaflet for Interactive Dark Map -->
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>

  <style>
    :root {
      --bg-obsidian: #090A0F;
      --bg-surface: #131722;
      --bg-surface-high: #1C2234;
      --border-subtle: #242C43;
      --border-glow: #3B486E;
      --neon-cyan: #00F0FF;
      --neon-amber: #FFB800;
      --neon-purple: #A855F7;
      --neon-green: #10B981;
      --alert-red: #EF4444;
      --text-primary: #F8FAFC;
      --text-muted: #94A3B8;
    }

    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background-color: var(--bg-obsidian);
      color: var(--text-primary);
      font-family: 'Inter', -apple-system, sans-serif;
      overflow-x: hidden;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
    }

    /* Top Navigation HUD */
    header {
      background-color: var(--bg-surface);
      border-bottom: 1px solid var(--border-glow);
      padding: 14px 24px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      flex-wrap: wrap;
      gap: 12px;
    }
    .brand {
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .brand-icon {
      width: 34px;
      height: 34px;
      background: radial-gradient(circle, rgba(0,240,255,0.2) 0%, rgba(9,10,15,1) 100%);
      border: 1.5px solid var(--neon-cyan);
      border-radius: 8px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: bold;
      color: var(--neon-cyan);
      box-shadow: 0 0 10px rgba(0,240,255,0.3);
    }
    .brand-text h1 {
      font-size: 18px;
      font-weight: 700;
      letter-spacing: 1.2px;
      color: var(--text-primary);
    }
    .brand-text span {
      font-size: 11px;
      color: var(--neon-cyan);
      font-family: 'JetBrains Mono', monospace;
    }

    .hud-pills {
      display: flex;
      gap: 10px;
      align-items: center;
      flex-wrap: wrap;
    }
    .pill {
      font-family: 'JetBrains Mono', monospace;
      font-size: 11px;
      padding: 5px 10px;
      border-radius: 6px;
      border: 1px solid var(--border-subtle);
      background-color: var(--bg-surface-high);
      display: flex;
      align-items: center;
      gap: 6px;
    }
    .dot {
      width: 7px;
      height: 7px;
      border-radius: 50%;
      background-color: var(--neon-green);
      box-shadow: 0 0 6px var(--neon-green);
    }
    .btn-action {
      background-color: var(--neon-cyan);
      color: var(--bg-obsidian);
      font-weight: 700;
      border: none;
      padding: 7px 14px;
      border-radius: 6px;
      cursor: pointer;
      text-decoration: none;
      font-size: 12px;
      display: inline-flex;
      align-items: center;
      gap: 6px;
      transition: all 0.2s;
    }
    .btn-action:hover {
      box-shadow: 0 0 12px var(--neon-cyan);
    }

    /* Main Container */
    main {
      flex: 1;
      display: flex;
      flex-direction: column;
      padding: 20px 24px;
      gap: 18px;
    }

    /* Search Bar Bar */
    .search-panel {
      background: var(--bg-surface);
      border: 1px solid var(--border-subtle);
      border-radius: 12px;
      padding: 12px 18px;
      display: flex;
      gap: 12px;
      align-items: center;
    }
    .search-input {
      flex: 1;
      background: transparent;
      border: none;
      color: var(--text-primary);
      font-size: 14px;
      outline: none;
      font-family: inherit;
    }
    .search-input::placeholder { color: var(--text-muted); }
    .search-btn {
      background: var(--bg-surface-high);
      border: 1px solid var(--neon-cyan);
      color: var(--neon-cyan);
      padding: 6px 16px;
      border-radius: 6px;
      font-weight: 600;
      cursor: pointer;
    }
    .quick-chip {
      background: rgba(0, 240, 255, 0.08);
      border: 1px solid rgba(0, 240, 255, 0.25);
      color: var(--text-primary);
      padding: 3px 10px;
      border-radius: 14px;
      cursor: pointer;
      font-size: 11px;
      transition: all 0.2s;
    }
    .quick-chip:hover {
      background: rgba(0, 240, 255, 0.2);
      border-color: var(--neon-cyan);
      color: var(--neon-cyan);
    }

    /* Tab Switcher */
    .tabs-bar {
      display: flex;
      gap: 10px;
      border-bottom: 1px solid var(--border-subtle);
      padding-bottom: 8px;
    }
    .tab-btn {
      background: transparent;
      border: 1px solid transparent;
      color: var(--text-muted);
      padding: 8px 16px;
      border-radius: 8px;
      font-size: 13px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s;
    }
    .tab-btn.active {
      color: var(--neon-cyan);
      background: var(--bg-surface);
      border-color: var(--neon-cyan);
      box-shadow: 0 0 10px rgba(0,240,255,0.15);
    }

    /* Tab Content Panes */
    .tab-pane {
      display: none;
      flex: 1;
      min-height: 520px;
      background: var(--bg-surface);
      border: 1px solid var(--border-subtle);
      border-radius: 12px;
      position: relative;
      overflow: hidden;
    }
    .tab-pane.active {
      display: flex;
      flex-direction: column;
    }

    /* Graph Canvas */
    #graph-container {
      width: 100%;
      height: 540px;
      background-color: var(--bg-obsidian);
    }
    /* Map Canvas */
    #map-container {
      width: 100%;
      height: 540px;
      background-color: var(--bg-obsidian);
    }

    /* Pathfinder Controls */
    .path-controls {
      padding: 16px;
      background: var(--bg-surface-high);
      border-bottom: 1px solid var(--border-subtle);
      display: flex;
      gap: 14px;
      align-items: center;
      flex-wrap: wrap;
    }
    .select-box {
      background: var(--bg-obsidian);
      border: 1px solid var(--border-subtle);
      color: var(--text-primary);
      padding: 8px 12px;
      border-radius: 6px;
      font-size: 13px;
    }

    /* Dossier Modal / Drawer */
    .dossier-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: 16px;
      padding: 20px;
    }
    .card {
      background: var(--bg-surface-high);
      border: 1px solid var(--border-subtle);
      border-radius: 10px;
      padding: 16px;
    }
    .card h3 {
      font-size: 14px;
      color: var(--neon-cyan);
      margin-bottom: 10px;
      border-bottom: 1px solid var(--border-subtle);
      padding-bottom: 6px;
    }
    .data-row {
      display: flex;
      justify-content: space-between;
      font-size: 12px;
      padding: 6px 0;
      border-bottom: 1px dashed rgba(255,255,255,0.06);
    }
    .data-label { color: var(--text-muted); }
    .data-val { font-weight: 600; color: var(--text-primary); text-align: right; }

    footer {
      border-top: 1px solid var(--border-subtle);
      padding: 12px 24px;
      font-size: 11px;
      color: var(--text-muted);
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-family: 'JetBrains Mono', monospace;
    }
  </style>
</head>
<body>

  <!-- Top HUD Header -->
  <header>
    <div class="brand">
      <div class="brand-icon">CX</div>
      <div class="brand-text">
        <h1>CORPNEXUS INTELLIGENCE</h1>
        <span>ONLINE INVESTIGATION PLATFORM • ZERO-INFERENCE</span>
      </div>
    </div>
    <div class="hud-pills">
      <div class="pill"><span class="dot"></span> SERVER: ONLINE</div>
      <div class="pill"><span class="dot"></span> POSTGRES: VERCEL NEON</div>
      <a href="/docs" target="_blank" class="pill" style="color: var(--neon-amber); text-decoration: none;">SWAGGER API</a>
      <a href="https://github.com/kcfree13-code/Corponexus/actions" target="_blank" class="btn-action">
        SCARICA APK ANDROID
      </a>
    </div>
  </header>

  <!-- Main Workstation -->
  <main>
    <!-- Search Bar -->
    <div class="search-panel">
      <input type="text" id="searchInput" class="search-input" placeholder="Cerca azienda o amministratore (es. Ferrari, Eni, Apple, Barilla)..." value="Ferrari" onkeydown="if(event.key==='Enter') executeSearch()" />
      <button class="search-btn" onclick="executeSearch()">CERCA</button>
    </div>

    <!-- Quick Search Chips -->
    <div style="margin: 8px 0 12px 0; display: flex; flex-wrap: wrap; gap: 6px; align-items: center;">
      <span style="color: var(--text-muted); font-size: 11px;">Ricerche rapide:</span>
      <span class="quick-chip" onclick="quickSearch('Ferrari')">⚡ Ferrari</span>
      <span class="quick-chip" onclick="quickSearch('Apple')">⚡ Apple</span>
      <span class="quick-chip" onclick="quickSearch('Eni')">⚡ Eni</span>
      <span class="quick-chip" onclick="quickSearch('Stellantis')">⚡ Stellantis</span>
      <span class="quick-chip" onclick="quickSearch('Leonardo')">⚡ Leonardo</span>
      <span class="quick-chip" onclick="quickSearch('Barilla')">⚡ Barilla</span>
      <span class="quick-chip" onclick="quickSearch('Ferrero')">⚡ Ferrero</span>
      <span class="quick-chip" onclick="quickSearch('TIM')">⚡ TIM</span>
      <span class="quick-chip" onclick="quickSearch('John Elkann')">⚡ John Elkann</span>
    </div>

    <!-- Floating Search Results Container -->
    <div id="searchResultsBox" style="display: none; margin-bottom: 14px; background: rgba(18,24,38,0.95); border: 1px solid var(--neon-cyan); border-radius: 8px; padding: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.5);"></div>

    <!-- Tabs Navigation -->
    <div class="tabs-bar">
      <button class="tab-btn active" onclick="switchTab('tab-graph')">🌐 Grafo Relazionale 2D</button>
      <button class="tab-btn" onclick="switchTab('tab-map')">🗺️ Mappa Forense Sedi (CartoDB)</button>
      <button class="tab-btn" onclick="switchTab('tab-path')">⚡ Pathfinder (BFS 1..6 Gradi)</button>
      <button class="tab-btn" onclick="switchTab('tab-dossier')">📑 Dossier Aziendale & Bilanci</button>
    </div>

    <!-- TAB 1: 2D Interactive Force Graph -->
    <div id="tab-graph" class="tab-pane active">
      <div style="padding: 10px 16px; background: var(--bg-surface-high); border-bottom: 1px solid var(--border-subtle); display: flex; justify-content: space-between; align-items: center;">
        <span style="font-size: 12px; color: var(--neon-cyan); font-weight: bold;">CANVAS FORENSE AD ALTA RISOLUZIONE (Trascina e ingrandisci i nodi)</span>
        <button class="search-btn" style="padding: 4px 10px; font-size: 11px;" onclick="loadGraph('company:it:01234567890')">Ricarica Grafo Esempio</button>
      </div>
      <div id="graph-container"></div>
    </div>

    <!-- TAB 2: Interactive Dark Leaflet Map -->
    <div id="tab-map" class="tab-pane">
      <div style="padding: 10px 16px; background: var(--bg-surface-high); border-bottom: 1px solid var(--border-subtle); display: flex; justify-content: space-between; align-items: center;">
        <span style="font-size: 12px; color: var(--neon-cyan); font-weight: bold;">SEDI LEGALI GEOCODIFICATE (Nominatim) & ARCHI SOCIETARI TRANSFRONTALIERI</span>
        <span style="font-size: 11px; color: var(--text-muted);">CartoDB Dark Matter Tiles</span>
      </div>
      <div id="map-container"></div>
    </div>

    <!-- TAB 3: Shortest Path / Pathfinder -->
    <div id="tab-path" class="tab-pane">
      <div class="path-controls">
        <label style="font-size: 12px; color: var(--text-muted);">Origine:</label>
        <select id="pathSource" class="select-box">
          <option value="company:it:01234567890">Nexus Tech S.p.A. (Milano)</option>
          <option value="company:it:98765432100">Global Holdings Italia S.r.l. (Roma)</option>
          <option value="person:it:mario-rossi">Mario Rossi (Amministratore)</option>
        </select>

        <label style="font-size: 12px; color: var(--text-muted);">Destinazione:</label>
        <select id="pathTarget" class="select-box">
          <option value="company:it:98765432100">Global Holdings Italia S.r.l. (Roma)</option>
          <option value="company:it:01234567890">Nexus Tech S.p.A. (Milano)</option>
          <option value="person:it:elena-bianchi">Elena Bianchi (Socia)</option>
        </select>

        <label style="font-size: 12px; color: var(--text-muted);">Max Gradi:</label>
        <select id="pathDegrees" class="select-box">
          <option value="2">2 Gradi</option>
          <option value="4">4 Gradi</option>
          <option value="6" selected>6 Gradi (BFS Completa)</option>
        </select>

        <button class="search-btn" onclick="calculatePath()">CALCOLA PERCORSO (0 API)</button>
      </div>
      <div id="pathResult" style="padding: 20px; font-size: 13px; color: var(--text-muted);">
        Seleziona i due soggetti e clicca su "Calcola Percorso" per eseguire il Bidirectional BFS nel database condiviso.
      </div>
    </div>

    <!-- TAB 4: Company Dossier & 5-Year Financials -->
    <div id="tab-dossier" class="tab-pane">
      <div style="padding: 10px 16px; background: var(--bg-surface-high); border-bottom: 1px solid var(--border-subtle); display: flex; justify-content: space-between; align-items: center;">
        <span style="font-size: 12px; color: var(--neon-cyan); font-weight: bold;">SCHEDA INTELLIGENCE AZIENDALE CERTIFICATA (Zero-Inference)</span>
        <button class="search-btn" style="padding: 4px 10px; font-size: 11px;" onclick="loadDossier('company:it:01234567890')">Aggiorna Dossier</button>
      </div>
      <div id="dossierContent" class="dossier-grid">
        <div class="card">
          <h3>Dati Ufficiali Registro Imprese</h3>
          <div id="companyMeta">Caricamento dati in corso...</div>
        </div>
        <div class="card">
          <h3>Bilanci Certificati SEC / XBRL (5 Anni)</h3>
          <div id="financialsMeta">Caricamento bilanci...</div>
        </div>
        <div class="card">
          <h3>Appalti Pubblici ANAC (OCDS)</h3>
          <div id="contractsMeta">Caricamento gare...</div>
        </div>
        <div class="card">
          <h3>Fonti Ufficiali & Provenienza</h3>
          <div id="sourcesMeta">Caricamento citazioni...</div>
        </div>
      </div>
    </div>
  </main>

  <!-- Footer -->
  <footer>
    <span>CorpNexus Platform • Politica Zero-Deduzioni & Storicizzazione Permanente</span>
    <span>PostgreSQL Engine • NetworkX Graph Analytics • Flutter Native</span>
  </footer>

  <!-- Scripts -->
  <script>
    let network = null;
    let map = null;

    function switchTab(tabId) {
      document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
      document.querySelectorAll('.tab-pane').forEach(p => p.classList.remove('active'));
      event.target.classList.add('active');
      document.getElementById(tabId).classList.add('active');

      if (tabId === 'tab-map') {
        setTimeout(initMap, 200);
      }
    }

    // 1. Vis.js Network Graph Loader
    async function loadGraph(entityId) {
      const container = document.getElementById('graph-container');
      try {
        const res = await fetch(`/api/v1/graph/entity/${entityId}?degrees=2`);
        const data = await res.json();

        const nodes = data.nodes.map(n => {
          const isComp = n.node_type === 'company';
          return {
            id: n.id,
            label: n.name,
            shape: isComp ? 'box' : 'ellipse',
            color: {
              background: isComp ? '#003B46' : '#4D3800',
              border: isComp ? '#00F0FF' : '#FFB800',
              highlight: { background: '#00F0FF', border: '#FFFFFF' }
            },
            font: { color: '#F8FAFC', face: 'Inter', size: 13, bold: true },
            margin: 10,
            borderWidth: 2
          };
        });

        const edges = data.edges.map(e => ({
          from: e.source_node_id,
          to: e.target_node_id,
          label: e.relationship_type,
          color: { color: '#3B486E', highlight: '#00F0FF' },
          font: { color: '#94A3B8', size: 10, strokeWidth: 0 },
          arrows: 'to',
          width: 2
        }));

        const graphData = { nodes: new vis.DataSet(nodes), edges: new vis.DataSet(edges) };
        const options = {
          physics: {
            stabilization: true,
            barnesHut: { gravitationalConstant: -3000, springLength: 120 }
          },
          interaction: { hover: true, zoomView: true }
        };

        if (network) network.destroy();
        network = new vis.Network(container, graphData, options);

        network.on("click", function (params) {
          if (params.nodes.length > 0) {
            const nodeId = params.nodes[0];
            if (nodeId.startsWith("company:")) {
              loadDossier(nodeId);
              switchTab('tab-dossier');
              document.querySelectorAll('.tab-btn')[3].classList.add('active');
            }
          }
        });
      } catch (err) {
        container.innerHTML = `<div style="padding: 20px; color: #EF4444;">Errore nel caricamento del grafo: ${err.message}</div>`;
      }
    }

    // 2. Leaflet Dark Map Loader
    function initMap() {
      if (map) {
        map.invalidateSize();
        return;
      }
      map = L.map('map-container').setView([43.5, 11.5], 6);

      // CartoDB Dark Matter tile layer
      L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
        attribution: '&copy; OpenStreetMap & CartoDB',
        maxZoom: 19
      }).addTo(map);

      // Sedi verificate: Milano e Roma
      const milano = [45.4697, 9.1952];
      const roma = [41.8978, 12.4764];

      // Custom Glowing Icon
      const cyanIcon = L.divIcon({
        className: 'custom-pin',
        html: `<div style="background-color: #00F0FF; width: 14px; height: 14px; border-radius: 50%; box-shadow: 0 0 12px #00F0FF; border: 2px solid #090A0F;"></div>`,
        iconSize: [14, 14]
      });

      const m1 = L.marker(milano, { icon: cyanIcon }).addTo(map)
        .bindPopup(`<b style="color: #000;">Nexus Tech S.p.A.</b><br>Via Montenapoleone 8, Milano<br><a href="javascript:void(0)" onclick="loadDossier('company:it:01234567890'); switchTab('tab-dossier');">Apri Dossier</a>`);

      const m2 = L.marker(roma, { icon: cyanIcon }).addTo(map)
        .bindPopup(`<b style="color: #000;">Global Holdings Italia S.r.l.</b><br>Corso Vittorio Emanuele II 10, Roma<br><a href="javascript:void(0)" onclick="loadDossier('company:it:98765432100'); switchTab('tab-dossier');">Apri Dossier</a>`);

      // Connecting Polyline
      const line = L.polyline([milano, roma], {
        color: '#00F0FF',
        weight: 3,
        opacity: 0.8,
        dashArray: '6, 8'
      }).addTo(map);
      line.bindTooltip("Collegamento societario tramite Amministratore Comune (Mario Rossi)");
    }

    // 3. Pathfinder Calculator
    async function calculatePath() {
      const src = document.getElementById('pathSource').value;
      const tgt = document.getElementById('pathTarget').value;
      const deg = document.getElementById('pathDegrees').value;
      const out = document.getElementById('pathResult');

      out.innerHTML = `<span style="color: var(--neon-cyan);">Esecuzione Bidirectional BFS in corso sul database...</span>`;
      try {
        const res = await fetch(`/api/v1/graph/shortest-path?source=${encodeURIComponent(src)}&target=${encodeURIComponent(tgt)}&max_degrees=${deg}`);
        const data = await res.json();

        if (!data.found) {
          out.innerHTML = `<div style="color: var(--alert-red); font-weight: bold;">Nessun percorso trovato entro ${deg} gradi nel database locale.</div>`;
          return;
        }

        let html = `<div style="background: var(--bg-surface-high); border: 1px solid var(--neon-cyan); border-radius: 8px; padding: 14px; margin-bottom: 14px;">
          <b style="color: var(--neon-cyan); font-size: 15px;">✓ Percorso Rilevato: ${data.length} Gradi di Separazione</b>
          <div style="margin-top: 6px; color: var(--text-muted); font-size: 12px;">${data.message}</div>
        </div>`;

        html += `<h4 style="color: var(--text-primary); margin-bottom: 8px;">Sequenza Nodi:</h4><ol style="padding-left: 20px;">`;
        data.path_nodes.forEach(n => {
          html += `<li style="margin-bottom: 6px;"><b>${n.name}</b> (${n.node_type}) - <span style="font-family: monospace; color: var(--neon-amber);">${n.id}</span></li>`;
        });
        html += `</ol>`;

        html += `<h4 style="color: var(--text-primary); margin: 12px 0 8px;">Relazioni Legali Verificate:</h4><ul style="padding-left: 20px;">`;
        data.path_edges.forEach(e => {
          html += `<li style="margin-bottom: 6px;"><b>${e.relationship_type}</b> tra <i>${e.source_node_id}</i> e <i>${e.target_node_id}</i> (Fonte: ${e.source_citation.source_publisher})</li>`;
        });
        html += `</ul>`;

        out.innerHTML = html;
      } catch (err) {
        out.innerHTML = `<div style="color: var(--alert-red);">Errore nel calcolo del percorso: ${err.message}</div>`;
      }
    }

    // 4. Dossier Loader
    async function loadDossier(companyId) {
      try {
        const res = await fetch(`/api/v1/company/${companyId}/dossier`);
        const data = await res.json();
        const comp = data.company;

        document.getElementById('companyMeta').innerHTML = `
          <div class="data-row"><span class="data-label">Ragione Sociale:</span><span class="data-val">${comp.name}</span></div>
          <div class="data-row"><span class="data-label">Codice Fiscale / REA:</span><span class="data-val">${comp.company_number}</span></div>
          <div class="data-row"><span class="data-label">Stato Registro:</span><span class="data-val" style="color: var(--neon-green);">${comp.status}</span></div>
          <div class="data-row"><span class="data-label">Costituzione:</span><span class="data-val">${comp.incorporation_date}</span></div>
          <div class="data-row"><span class="data-label">Sede Legale:</span><span class="data-val">${comp.registered_address_in_full}</span></div>
          <div class="data-row"><span class="data-label">Coordinate GPS:</span><span class="data-val">${comp.latitude}, ${comp.longitude}</span></div>
        `;

        let finHtml = '';
        if (data.financials && data.financials.length > 0) {
          data.financials.forEach(f => {
            finHtml += `<div class="data-row">
              <span class="data-label">Anno ${f.fiscal_year}:</span>
              <span class="data-val">€${Number(f.revenue).toLocaleString()} (EBITDA: €${Number(f.ebitda).toLocaleString()})</span>
            </div>`;
          });
        } else {
          finHtml = '<div style="color: var(--text-muted); font-size: 12px;">Nessun bilancio disponibile</div>';
        }
        document.getElementById('financialsMeta').innerHTML = finHtml;

        let contractsHtml = '';
        if (data.public_contracts && data.public_contracts.length > 0) {
          data.public_contracts.forEach(c => {
            contractsHtml += `<div class="data-row">
              <span class="data-label">CIG ${c.cig}:</span>
              <span class="data-val">€${Number(c.amount_eur).toLocaleString()} (${c.buyer_name})</span>
            </div>`;
          });
        } else {
          contractsHtml = '<div style="color: var(--text-muted); font-size: 12px;">Nessun appalto registrato</div>';
        }
        document.getElementById('contractsMeta').innerHTML = contractsHtml;

        let srcHtml = '';
        if (data.sources && data.sources.length > 0) {
          data.sources.forEach(s => {
            srcHtml += `<div style="font-size: 11px; margin-bottom: 8px; color: var(--text-muted);">
              <b style="color: var(--neon-cyan);">${s.source_publisher}</b>: ${s.raw_response_snippet || 'Fascicolo'}<br>
              <a href="${s.source_url}" target="_blank" style="color: var(--neon-amber);">${s.source_url}</a>
            </div>`;
          });
        }
        document.getElementById('sourcesMeta').innerHTML = srcHtml;
      } catch (err) {
        console.error("Dossier error:", err);
      }
    }

    // Quick Search Trigger
    function quickSearch(q) {
      document.getElementById('searchInput').value = q;
      executeSearch();
    }

    function selectEntity(id) {
      loadGraph(id);
      loadDossier(id);
      switchTab('tab-graph');
      document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
      document.querySelectorAll('.tab-btn')[0].classList.add('active');
    }

    // Search Trigger with Visual Results Box
    async function executeSearch() {
      const q = document.getElementById('searchInput').value.trim();
      const resultsBox = document.getElementById('searchResultsBox');
      if (!q) return;
      resultsBox.style.display = 'block';
      resultsBox.innerHTML = '<div style="color: var(--text-muted); font-size: 12px;">Ricerca in corso sul database certificato e SEC EDGAR...</div>';

      try {
        const res = await fetch(`/api/v1/search?q=${encodeURIComponent(q)}`);
        const data = await res.json();
        if (data.results && data.results.length > 0) {
          let html = `<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
            <span style="font-size: 12px; font-weight: bold; color: var(--neon-cyan);">Risultati Trovati (${data.results.length}):</span>
            <button onclick="document.getElementById('searchResultsBox').style.display='none'" style="background: none; border: none; color: var(--text-muted); cursor: pointer; font-size: 11px;">Chiudi ✕</button>
          </div>
          <div style="display: flex; flex-direction: column; gap: 6px; max-height: 220px; overflow-y: auto;">`;

          data.results.forEach(r => {
            const isComp = r.node_type === 'company';
            const icon = isComp ? '🏢' : '👤';
            html += `
              <div onclick="selectEntity('${r.id}')" style="cursor: pointer; padding: 8px 12px; border-radius: 6px; background: rgba(255,255,255,0.03); border: 1px solid rgba(255,255,255,0.08); display: flex; justify-content: space-between; align-items: center;" onmouseover="this.style.borderColor='var(--neon-cyan)'" onmouseout="this.style.borderColor='rgba(255,255,255,0.08)'">
                <div>
                  <div style="font-weight: bold; font-size: 13px; color: #fff;">${icon} ${r.name}</div>
                  <div style="font-size: 11px; color: var(--text-muted);">${r.id} • ${r.source_publisher || 'Registro Ufficiale'}</div>
                </div>
                <div style="color: var(--neon-cyan); font-size: 12px; font-weight: 600;">Esplora &rarr;</div>
              </div>
            `;
          });
          html += '</div>';
          resultsBox.innerHTML = html;

          // Also load the first result automatically
          loadGraph(data.results[0].id);
          loadDossier(data.results[0].id);
        } else {
          resultsBox.innerHTML = `
            <div style="display: flex; justify-content: space-between; align-items: center;">
              <span style="color: var(--neon-amber); font-size: 12px;">Nessuna entità trovata per "${q}". Prova con una delle ricerche rapide sopra.</span>
              <button onclick="document.getElementById('searchResultsBox').style.display='none'" style="background: none; border: none; color: var(--text-muted); cursor: pointer; font-size: 11px;">Chiudi ✕</button>
            </div>
          `;
        }
      } catch (e) {
        resultsBox.innerHTML = `<div style="color: var(--alert-red); font-size: 12px;">Errore ricerca: ${e.message}</div>`;
      }
    }

    // Initialize Default View
    window.addEventListener('DOMContentLoaded', () => {
      loadGraph('company:it:00159560366');
      loadDossier('company:it:00159560366');
    });
  </script>
</body>
</html>
"""
