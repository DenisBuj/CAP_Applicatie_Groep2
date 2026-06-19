# Rol 2 — Team Lead

**App (tegel):** **Team Lead** · *Teambeschikbaarheid*
**Hoofdvraag:** *"Wie van mijn team is vrijdag beschikbaar?"*
**Kern:** beschikbaarheid van teamleden aflezen uit hun reisgeschiedenis en geplande reizen.

| Wat kan je doen | Waar vind je het | Type |
|---|---|---|
| **In één oogopslag zien wie op reis is / beschikbaar** (voor inplannen) | Medewerkerslijst → kolom **"Beschikbaarheid"**: oranje *Op reis* / groen *Beschikbaar* | Lezen |
| **Direct zien wie al een geplande reis heeft** | Medewerkerslijst → kolom **"Geplande reis"**: *Gepland* / *—* | Lezen |
| **Filteren op beschikbaarheid / planning** | Filterbalk → velden **"Op reis"** en **"Geplande reis"** (ja/nee) | Lezen |
| Medewerker **zoeken** op naam of gebruikersnaam | **Zoekveld** in de medewerkerslijst (startscherm) | Lezen |
| Filteren op voornaam / achternaam / projectcode | **Filterbalk** bovenaan de lijst | Lezen |
| **Reisgeschiedenis + geplande trips** chronologisch zien (om beschikbaarheid af te lezen) | Open een medewerker → sectie **"Reisgeschiedenis"** (gesorteerd op vertrekdatum, met status & data) | Lezen |
| **Alle planning: waar & wanneer iemand gepland is** | Open een medewerker → sectie **"Geplande reizen"** (enkel status *Gepland*) — toont per reis bestemming (land + luchthaven) en datums (vertrek/terug) | Lezen |
| **Volledige reisdetails** van één reis (alle velden + vluchten met airline/luchthavens) | Klik een reis in de **Reisgeschiedenis** → de volledige **reis-objectpagina** opent (secties Reisgegevens, Vluchten, Medewerker) | Lezen |
| **Projectcode** van een medewerker zien | Op het medewerkersprofiel + als kolom in de lijst | Lezen |
| **Projectcode** bijwerken | Open een medewerker → knop **"Projectcode bijwerken"** | **Bewerken** |

### Stap-voor-stap: beschikbaarheid checken
1. Open de **Team Lead**-tegel → zoek de medewerker (naam of gebruikersnaam).
2. Klik de medewerker → sectie **"Reisgeschiedenis"**.
3. Lees de reizen chronologisch af: status (Gepland/Onderweg/Afgerond) + vertrek-/terugdatum → zo zie je of iemand op een bepaalde dag onderweg of vrij is.

### Stap-voor-stap: projectcode wijzigen
1. Open het medewerkersprofiel → knop **"Projectcode bijwerken"**.
2. Typ de projectcode → bevestig. De wijziging staat meteen op het profiel én op de reizen van die medewerker.

### Hoe "Op reis" bepaald wordt
Een medewerker staat op **"Op reis"** zodra hij minstens één reis met status **"Onderweg"** heeft. Zet de Travel Coördinator een reis op *Onderweg*, dan springt die medewerker meteen op *Op reis* in de lijst. Zo plan je rond wie effectief weg is.

> Demo-tip: in de seed-data staat **Russell Whyte** op *Op reis*. Zet je nog een reis op *Onderweg* (Travel Coördinator-app), dan zie je die persoon live ook op *Op reis* verschijnen.

### Wat deze rol bewust **niet** kan
- Medewerkers aanmaken of verwijderen — de medewerkersdata komt read-only uit TripPin (poging → HTTP 405).
