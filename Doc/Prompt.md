Act as a Principal Mobile & Backend Architect (Flutter + Python FastAPI). Build a complete, production-ready corporate intelligence system named "CorpNexus Android", composed of a native Android Application built in Flutter and a Graph & Persistent Caching Backend deployed on Railway (Python FastAPI + PostgreSQL + NetworkX).

The entire project must be structured as a clean GitHub Monorepo with automated Android APK build workflows and one-click Railway deployment.

---

### 1. STRICT DATA INTEGRITY & ZERO-INFERENCE POLICY (NON-NEGOTIABLE)
1. **Zero Fabrication / Zero Inference:** NEVER generate mock data, simulated fallbacks, interpolations, or deduced relationships. Every node, edge, date, coordinate, and financial metric must come strictly from authoritative API responses.
2. **Missing Data Handling:** If data (such as 5-year revenue, officer dates, or address coordinates) is unavailable in the official registries, report nothing or show `"Dato non disponibile nei registri ufficiali"`. Never render empty or estimated charts.
3. **Mandatory Source Provenance:** Every node, edge, and financial figure stored in the database and displayed in the Android app must expose its official source (`source_publisher`, `source_url`, `filing_id`, `retrieved_at`) inspectable via an on-demand "Fonti Ufficiali" bottom-sheet popup.

---

### 2. PERMANENT CACHE, ON-DEMAND REFRESH & GUIDED BYOK WIZARD

#### 2.1 Permanent Database Cache & Strictly Manual Refresh (Zero Unnecessary API Calls)
- Every API response fetched from official registries is normalized and permanently stored in the central **PostgreSQL database on Railway** (`verified_nodes`, `verified_edges`, `node_financials`, `source_citations`, `historical_snapshots`).
- **No Automatic Expiration:** Never trigger automatic background refreshes based on record age. If an entity exists in PostgreSQL, ALWAYS serve it immediately from the database (consuming 0 external API calls), regardless of how old the record is.
- **Explicit Retrieval Timestamp & On-Demand Update:**
  - Prominently display the exact reading date on every node and company card: `"Dati rilevati il: DD/MM/YYYY alle HH:MM"`.
  - Provide an explicit `"Richiedi Aggiornamento Live"` button. Tapping it opens a confirmation dialog warning the user that 1 API call from their personal key will be used.
  - Upon confirmation, fetch the fresh data from the official API, archive the previous state into `historical_snapshots` (preserving temporal history for date-based queries), and update `last_fetched_at`.

#### 2.2 Guided API Key Onboarding Wizard & Legal Clauses Acceptance
Build a dedicated multi-step **Onboarding & API Key Wizard Screen** in the Flutter Android app:
- **Step 1 — Mandatory Clauses & Consent:** Display scrollable legal and operational terms. The user must explicitly check three mandatory checkboxes before proceeding:
  1. * Dichiaro che la API Key inserita è personale e mi assumo la responsabilità del rispetto dei termini d'uso del fornitore (OpenCorporates / Registri Ufficiali).*
  2. *Acconsento che i dati pubblici estratti tramite le mie interrogazioni vengano memorizzati con citazione della fonte nel database condiviso per ridurre le chiamate di rete e consentire l'analisi storica.*
  3. *Prendo atto che l'applicazione mostra esclusivamente dati ufficiali senza alcuna deduzione e che l'aggiornamento dei dati già archiviati avviene solo su mia richiesta esplicita.*
  - Store the user's acceptance timestamp and terms version in PostgreSQL (`user_consents` table).
- **Step 2 — Guided Token Acquisition:** Step-by-step visual guide with direct external browser links to register and copy the API key from OpenCorporates (and optional INSEE Sirene token).
- **Step 3 — Live Verification & Secure Storage:** Input field with a `"Verifica e Salva"` button that tests the key against the API, displays the key status, and saves it inside `flutter_secure_storage` (and encrypted on the user session). Users without a key can select `"Continua in Sola Lettura (Solo Database Condiviso)"` to browse existing cached nodes at zero cost.

---

### 3. DEGREES OF SEPARATION CONTROL & EXPONENTIAL GUARDRAILS
Allow the user to choose the **Degree of Separation (Grado di Separazione: from 1 to 6 hops)** via a dedicated UI Slider, separating local graph traversal from live API fetching:
1. **Pathfinding between 2 Entities (Corporate A ↔ Corporate B or Officer A ↔ Officer B):**
   - Execute **Bidirectional Breadth-First Search (Bidirectional BFS)** in Python (`NetworkX`) over the PostgreSQL graph up to the user-selected degree `D` (1 to 6). Because bidirectional search reduces complexity from $O(B^D)$ to $O(B^{D/2})$ and runs entirely on the local database, up to 6 degrees of separation execute instantaneously with **0 API calls**.
2. **Graph Neighborhood Expansion Guardrail:**
   - When expanding a single node on the visual canvas from the local database, allow rendering 1 to 3 degrees of separation (capping the visual canvas at max 250 simultaneous nodes for 60fps mobile rendering, with a warning badge if truncated).
   - If the user requests a **Live API Expansion** for uncached nodes, strictly restrict live external fetching to **1 degree (1 hop) at a time**, displaying an explicit confirmation prompt with the exact number of API calls required before executing.

---

### 4. FEDERATED OPEN DATA SOURCES (BACKEND CONNECTORS)
The Railway FastAPI backend must integrate and normalize data from:
1. **OpenCorporates API (`opencorporates.com`):** Corporate registry data, company status, officers/directors, and parent/subsidiary statements.
2. **Open Ownership Register (`openownership.org` - BODS):** Ultimate Beneficial Owners (Titolari Effettivi) via API or bulk ingestion.
3. **SEC EDGAR API (`sec.gov/edgar` - XBRL JSON):** Certified 5-Year Annual Revenue (`Revenues` / `SalesRevenueNet`) from official 10-K / 20-F filings (100% free, requires compliant `User-Agent`).
4. **INSEE SIRENE API (`insee.fr`):** Official French corporate registry data.
5. **ANAC Portale Trasparenza (`anticorruzione.it` - OCDS) & OpenCoesione (`opencoesione.gov.it`):** Public procurement contracts (CIG) and public cohesion funds for Italian companies.
6. **Wikidata SPARQL (`query.wikidata.org`):** Corporate group hierarchies (`P749`/`P355`) strictly filtered for statements containing an official external reference URL.
7. **OpenStreetMap Nominatim (`openstreetmap.org`):** Geocode verified company `registered_address_in_full` strings into Lat/Lon coordinates (strictly cached in PostgreSQL so an address is never geocoded twice).

---

### 5. MONOREPO ARCHITECTURE (GITHUB + RAILWAY + ANDROID)

#### A. `/apps/backend` — Railway Python FastAPI & PostgreSQL Engine
- **Stack:** Python 3.11+, FastAPI, SQLAlchemy 2.0 (AsyncPG), PostgreSQL, NetworkX, Pydantic v2.
- **Deployment:** Include `Dockerfile`, `railway.json`, and `alembic` migrations.
- **Core Endpoints:**
  - `POST /api/v1/auth/consent` (Logs user acceptance of the API & Data Integrity clauses).
  - `POST /api/v1/auth/verify-key` (Validates user's personal API key).
  - `GET /api/v1/graph/entity/{id}?degrees={1..3}` (Returns node + neighborhood from PostgreSQL cache; includes `last_fetched_at` metadata; fetches live 1st-degree only if entity is completely absent from DB and user provides a valid API key).
  - `POST /api/v1/graph/refresh/{id}` (Explicit user-triggered live re-fetch; archives previous state to `historical_snapshots` and updates `last_fetched_at`).
  - `GET /api/v1/graph/shortest-path?source={idA}&target={idB}&max_degrees={1..6}` (Runs Bidirectional BFS in NetworkX to isolate all nodes and edges connecting the two targets within `max_degrees`).
  - `GET /api/v1/graph/historical?entity_id={id}&date=YYYY-MM-DD` (Reconstructs the exact network active on the requested date using documented `start_date`, `end_date`, and archived snapshots).
  - `GET /api/v1/company/{id}/dossier` (Returns full metadata, 5-year certified revenue array, ANAC public tenders, retrieval timestamp, and full `source_citations` array).

#### B. `/apps/mobile_android` — Flutter Android Application
- **Stack:** Flutter (Dart), Riverpod, `dio`, `flutter_secure_storage`, `fl_chart`, `flutter_earth_globe` (or Three.js WebView controller), `screenshot` + `share_plus` + `csv`.
- **UI/UX Theme (Cyber-Forensic Obsidian Dark):**
  - Deep obsidian background (`#090A0F`), glassmorphic bottom sheets and HUD controls, neon cyan (`#00F0FF`) for Companies, neon amber (`#FFB800`) for Directors/Officers (with pulsing rings for interlocking directors), purple (`#A855F7`) for Beneficial Owners.
- **Core Android Screens & Features:**
  1. **Guided API Key & Legal Consent Wizard:** Step-by-step onboarding with mandatory clause checkboxes, browser helper links, and key validation.
  2. **Interactive Obsidian 2D Graph Canvas:**
     - Force-directed physics graph with touch gestures (pinch-to-zoom, pan, node dragging, single-tap to inspect, double-tap to expand).
     - Degree of Separation selector (`1..3` for visual expansion) and top HUD badge displaying `"Lettura del: DD/MM/YYYY"` + manual `"Aggiorna Ora"` button with API cost confirmation.
  3. **Shortest Path / Interference Finder ("Verifica Collegamenti"):**
     - Dual search bar for **Corporate/Admin A** and **Corporate/Admin B** + **Degree of Separation Slider (`1..6` gradi)**.
     - Isolates strictly the connecting chain of nodes and relationships, with clickable edges showing the official filing proving each link.
  4. **3D World Globe View ("Mappa 3D Sedi"):**
     - Toggle switch to a 3D Earth Globe displaying glowing pins at verified headquarters and 3D arcs for cross-border connections.
  5. **Time-Machine Date Picker ("Estrazione Storica per Data"):**
     - Date selector (`YYYY-MM-DD`) filtering the graph to show only companies and administrators in office on that exact historical date.
  6. **Company Dossier Popup & 5-Year Revenue:**
     - Sliding Glassmorphism Bottom Sheet with Registry Details, Officers, **5-Year Certified Annual Revenue Bar Chart** (`fl_chart`), Italian Public Contracts (ANAC), and the **"Fonti Certificati" Inspector**.
  7. **Export Suite (Tabular & Image):**
     - Export visible nodes, edges, retrieval dates, and source URLs as **CSV** or **JSON**.
     - Capture high-resolution **PNG snapshot** of the 2D Graph or 3D Globe with date/source watermark.

---

### 6. GITHUB REPOSITORY & CI/CD DELIVERABLES
1. Generate the complete directory structure (`/apps/backend`, `/apps/mobile_android`).
2. Create the SQLAlchemy database models implementing permanent storage, `user_consents`, `historical_snapshots`, and mandatory `SourceCitation` foreign keys.
3. Include `.github/workflows/android-build.yml` to automatically build the Android `.apk` on GitHub Actions.
4. Provide a comprehensive `README.md` with step-by-step instructions to deploy the backend + PostgreSQL on Railway and build the Flutter Android app.