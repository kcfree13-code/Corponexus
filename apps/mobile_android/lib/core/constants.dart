class AppConstants {
  // Production Railway Backend URL
  static const String defaultBackendUrl = "https://corponexus-production.up.railway.app";
  static const String termsVersion = "v1.0-2026-10";

  // Legal Clauses - Card 1 (Titolarità API Key & Termini Fornitori)
  static const String legalTitle1 = "1. Titolarità API Key & Termini Fornitori";
  static const String legalBody1 =
      "L'utente prende atto che l'applicazione opera come semplice interfaccia tecnica di visualizzazione e consente l'inserimento di credenziali personali (API Key) rilasciate da fornitori terzi (es. OpenCorporates). La chiave API resta di esclusiva titolarità dell'utente, che si assume la piena responsabilità per il consumo della propria quota e per il rispetto dei Termini di Servizio e delle licenze (ODbL / CC-BY) del fornitore terzo.";
  static const String legalCheckbox1 =
      "Dichiaro di essere il legittimo titolare della API Key inserita, di utilizzarla nel rispetto dei Termini di Servizio del fornitore terzo e di sollevare i gestori dell'app da ogni responsabilità legata all'uso della mia chiave.";

  // Legal Clauses - Card 2 (Storicizzazione Collaborativa dei Dati Pubblici)
  static const String legalTitle2 = "2. Storicizzazione Collaborativa dei Dati Pubblici";
  static const String legalBody2 =
      "Per evitare interrogazioni ridondanti e consentire l'analisi storica, i metadati societari pubblici restituiti dalle interrogazioni vengono memorizzati nel database condiviso dell'applicazione, corredati dalla fonte ufficiale e dalla data di estrazione. La chiave API personale non viene mai condivisa con altri utenti.";
  static const String legalCheckbox2 =
      "Acconsento che i dati societari pubblici estratti tramite le mie interrogazioni vengano archiviati, con citazione della fonte ufficiale e senza mai esporre la mia API Key, nel database condiviso per il riuso analitico e storico.";

  // Legal Clauses - Card 3 (Politica Zero Deduzioni & Aggiornamento su Richiesta)
  static const String legalTitle3 = "3. Politica Zero Deduzioni & Aggiornamento su Richiesta";
  static const String legalBody3 =
      "L'applicazione mostra esclusivamente dati ufficiali senza alcuna stima o deduzione. I dati archiviati riflettono lo stato del registro alla data indicata in 'Dati rilevati il' e vengono aggiornati solo su richiesta esplicita dell'utente ('Richiedi Aggiornamento Live'). Le informazioni non costituiscono consulenza legale o finanziaria; verificare sempre il link diretto nella scheda 'Fonti Ufficiali'.";
  static const String legalCheckbox3 =
      "Prendo atto che i dati mostrati riflettono quanto presente nei registri ufficiali alla data di rilevazione indicata, che l'aggiornamento avviene solo su richiesta esplicita e che i gestori dell'app non rispondono di eventuali disallineamenti dei registri o dell'uso delle informazioni.";

  // External Helper Links
  static const String openCorporatesRegisterUrl = "https://opencorporates.com/users/sign_up";
  static const String inseeRegisterUrl = "https://portail-api.insee.fr/";
}
