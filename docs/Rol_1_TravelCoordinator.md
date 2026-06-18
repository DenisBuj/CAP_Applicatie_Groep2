# Rol 1 — Travel Coördinator

**App (tegel):** **Travel Coördinator** · *Reisbeheer*
**Hoofdvraag:** *"Wie reist deze week naar de VS en via welke luchthaven?"*
**Kern:** dagelijkse gebruiker van de reisinformatie **én** beheerder van de reis-gerelateerde PrimePath-data.

| Wat kan je doen | Waar vind je het | Type |
|---|---|---|
| Alle reizen chronologisch zien (gesorteerd op vertrekdatum) | **Startscherm** van de app = de reizenlijst | Lezen |
| Filteren op **periode** (vertrek/terug), **reisstatus**, **projectcode**, **bestemming (land)** en **aankomstluchthaven** | **Filterbalk** bovenaan de reizenlijst → knop *Go* | Lezen |
| Zoeken/sorteren op kolommen, exporteren | Tabel-werkbalk (instellingen / export) | Lezen |
| Doorklikken naar de **medewerker** van een reis | Open een reis → sectie **"Medewerker"** | Lezen |
| Doorklikken naar de **vluchten** (met airline + vertrek-/aankomstluchthaven) | Open een reis → sectie **"Vluchten"** | Lezen |
| **Reisstatus** (Gepland → Onderweg → Afgerond) en **kostenplaats** bijwerken | Open een reis → knop **"Status & kostenplaats bijwerken"** | **Bewerken** |

### Stap-voor-stap: status/kostenplaats wijzigen
1. Open de **Travel Coördinator**-tegel → klik een reis in de lijst.
2. Klik rechtsboven op **"Status & kostenplaats bijwerken"**.
3. Kies de **status** uit de dropdown (Gepland / Onderweg / Afgerond) en typ de **kostenplaats**.
4. Bevestig → de reis is meteen bijgewerkt (en het projectcode-/statusfilter blijft kloppen).

### Wat deze rol bewust **niet** kan
- Reizen of vluchten zélf aanmaken/verwijderen — die komen read-only uit TripPin (poging → HTTP 405).
- Enkel de eigen PrimePath-velden (status, kostenplaats) zijn bewerkbaar.

> Demo-tip: filter op **Bestemming (land) = United States** om de hoofdvraag te tonen. (Slechts ~4 reizen hebben vluchtdata in TripPin, dus de bestemming is enkel daar ingevuld.)
