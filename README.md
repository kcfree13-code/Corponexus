# CorpNexus Monorepo — Corporate Intelligence System

> **Piattaforma di Corporate Intelligence e Analisi Forense dei Grafi Societari**
> Monorepo composto da:
> 1. **Backend FastAPI & NetworkX** su Railway / Docker (`/apps/backend`)
> 2. **Applicazione Android Flutter** in tema Cyber-Forensic Obsidian (`/apps/mobile_android`)
> 3. **CI/CD GitHub Actions** per build automatica dell'APK e test di regressione

---

## 🏛️ 1. Principi Architetturali Chiave

1. **Strict Data Integrity & Zero Inference (Politica Non Negoziabile):**
   - Zero dati simulati o dedotti.
   - Tracciabilità obbligatoria della fonte ufficiale (`source_publisher`, `source_url`, `filing_id`, `retrieved_at`) ispezionabile dal bottom-sheet "Fonti Ufficiali".
   - Dati assenti segnalati esplicitamente con `"Dato non disponibile nei registri ufficiali"`.
2. **Permanent Cache & Aggiornamento su Richiesta (BYOK):**
   - Tutti i dati estratti vengono archiviati permanentemente nel PostgreSQL condiviso.
   - Nessuna scadenza automatica: se un'entità è presente a database, viene servita a **0 chiamate API esterne**.
   - Timestamp di lettura in evidenza: `"Dati rilevati il: DD/MM/YYYY alle HH:MM"`.
   - Pulsante `"Richiedi Aggiornamento Live"` con dialog di conferma che avvisa del consumo di 1 chiamata API dalla quota personale e archivia lo stato precedente in `historical_snapshots`.
3. **Guardrail Esponenziali & Pathfinder NetworkX:**
   - Ricerca di cammino minimo tra due soggetti (1..6 gradi) tramite **Bidirectional Breadth-First Search (Bidirectional BFS)** in Python NetworkX sul database locale (complessità ridotta a $O(B^{D/2})$, **0 chiamate API**).
   - Espansione grafica di vicinato limitata a 3 gradi con tetto massimo di 250 nodi simultanei per garantire 60fps su mobile.
4. **Onboarding Legale Obbligatorio (Step 1):**
   - 3 clausole legali con testi integrali in italiano e checkbox obbligatori, verificati e registrati con hash SHA-256 dell'IP in `user_legal_consents`.

---

## 🚀 2. Esecuzione e Test in Locale

### Opzione A: Avvio Completo con Docker Compose (Raccomandato)
Abbiamo configurato PostgreSQL sulla porta host **`5434`** per non entrare in conflitto con eventuali database locali già attivi sulle porte standard 5432 o 5433.

```powershell
# Dalla cartella principale del progetto:
docker compose up -d --build
```

- **FastAPI Backend:** [http://localhost:8000](http://localhost:8000)
- **Documentazione Swagger UI:** [http://localhost:8000/docs](http://localhost:8000/docs)
- **Healthcheck:** [http://localhost:8000/health](http://localhost:8000/health)
- **PostgreSQL:** `localhost:5434` (db: `corponexus`, user: `postgres`, pass: `postgrespassword`)

Per popolare il database con le entità di test certificate:
```powershell
docker compose exec backend python -m app.seed
```

---

### Opzione B: Esecuzione Backend in Virtual Environment Locale

```powershell
cd apps/backend

# 1. Creazione ed attivazione virtual environment
python -m venv venv
.\venv\Scripts\activate

# 2. Installazione dipendenze
pip install -r requirements.txt

# 3. Esecuzione suite di test automatizzati (Pytest)
pytest -v

# 4. Popolamento seed iniziale
python -m app.seed

# 5. Avvio server FastAPI
uvicorn app.main:app --reload --port 8000
```

---

## 📱 3. Applicazione Mobile Android (Flutter)

L'applicazione Flutter si trova in `/apps/mobile_android`:
- **Tema Cyber-Forensic Obsidian:** Sfondo `#090A0F`, nodi ciano neon per aziende, ambra neon per esponenti/amministratori, viola neon per titolari effettivi.
- **Workflow Onboarding Guidato:**
  - Passo 1: 3 Clausole legali obbligatorie in lingua italiana.
  - Passo 2: Guida al rilascio del token OpenCorporates BYOK.
  - Passo 3: Verifica live e salvataggio cifrato in `flutter_secure_storage` o modalità Sola Lettura.
- **Funzionalità Core:**
  1. *Grafo 2D Obsidian Interattivo* (Force layout, zoom/pan, HUD badge con data rilievo, manual refresh).
  2. *Pathfinder & Interferenze* (Ricerca percorso minimo 1..6 gradi con NetworkX).
  3. *Mappa 3D Sedi* (Coordinate Lat/Lon geocodificate con Nominatim in cache permanente).
  4. *Time-Machine Storica* (Ricostruzione societaria ad una data certificata).
  5. *Dossier Aziendale & Ricavi 5 Anni* (Bar chart con `fl_chart`, appalti ANAC e ispettore fonti ufficiali).

### Build APK via GitHub Actions
Ad ogni `git push` sul branch `main`, il workflow `.github/workflows/android-build.yml` compila automaticamente l'APK di produzione e lo rende disponibile per il download negli **Artifacts** di GitHub Actions.

---

## ☁️ 4. Deploy su Railway (One-Click)

Il repository include `railway.json` pronto per il deployment:
1. Accedi a [Railway](https://railway.app/) e collega il tuo repository GitHub `kcfree13-code/Corponexus`.
2. Aggiungi un plugin **PostgreSQL** nel progetto Railway.
3. Railway collegherà automaticamente la variabile d'ambiente `DATABASE_URL`.
4. L'endpoint backend sarà online con certificato HTTPS e healthcheck su `/health`.

---

## 📜 5. Licenza e Note Legali
CorpNexus è un'interfaccia tecnica di visualizzazione e normalizzazione di dati aperti ufficiali rilasciati da enti e registri pubblici (OpenCorporates, Open Ownership, SEC EDGAR, INSEE, ANAC). Tutte le citazioni sono corredate da link diretto alla fonte di origine.
