# PrimePath Travel Dashboard — TODO & Taakverdeling

> Team: Denis Bujorean, Adam Yousfi, Adam Akkay
> Geverifieerd tegen: **Functionele Analyse FINAL + Technische Analyse FINAL** (Files/, 12 juni 2026)
> Laatst bijgewerkt: 13 juni 2026

---

## Haalbaarheid: ✅ JA

De architectuur uit de finale analyses (CAP-mashup TripPin + HANA-extensies, **drie**
Fiori Elements-apps per persona, Managed Approuter op BTP Trial) is het standaard
CAP-deploymentpad en ruim haalbaar. De codebase dekt al een groot deel, maar wijkt op
een aantal punten af van de **finale** analyses — die afwijkingen moeten worden
rechtgetrokken (zie hieronder), want de analyses zijn nu de definitieve blauwdruk.

**Grootste technische risico's:**
1. **Trips moeten uit álle TripPin-reizen komen** (People `$expand=Trips`, geaggregeerd tot één vlakke set). De code baseert `Trips` nu op de lokale `TripExtension`-rijen → alleen reizen mét extensie zijn zichtbaar. Dit moet om.
2. **Vluchten** (TripPin `PlanItems/Flights`) voor FR-007 en FR-009 — nog volledig onontgonnen.
3. **Datumfilters / chronologie** (FR-002/FR-006) werken niet op de huidige *virtual* velden.
4. BTP Trial verloopt elke 30 dagen — tijdig verlengen.

---

## ⚠️ Code wijkt af van de FINALE analyses — rechttrekken (eerst doen)

> Deze stonden vorige keer als "open beslissingen". De finale analyses hebben ze nu
> beslist, dus de actie is telkens: **code aanpassen zodat het overeenkomt met de docs.**

| # | Afwijking code ↔ finale analyse | Vereiste actie |
|---|----------------------------------|----------------|
| C1 | **Composite key ontbreekt** (NIEUW in finale TA): `TripExtensions` moet key `UserName + TripId` hebben omdat een TripId niet uniek is over gedeelde trips. Code heeft enkel `key TripId` en laat gedeelde trips vallen ("eerste eigenaar wint", `travel-service.js`) | Samengestelde key `UserName + TripId` invoeren; gedeelde trips niet meer droppen |
| C2 | **Trips-bron verkeerd**: TA wil `Trips` als geaggregeerde set van álle TripPin-reizen; code projecteert op lokale `TripExtension` (alleen geseede rijen zichtbaar) | `Trips` baseren op gerepliceerde/geaggregeerde TripPin-reizen, verrijkt met de extensie (zie D1) |
| C3 | **CostCenter ontbreekt, lokale Budget te veel**: finale TA = `TripExtensions {Status, CostCenter}`, Budget komt read-only uit TripPin | `CostCenter : String` toevoegen; lokaal `Budget`-veld verwijderen (TripPin-budget tonen) |
| C4 | **RBAC wordt afgedwongen** terwijl finale FA + TA RBAC **expliciet (2×) buiten de MVP** zetten ("alle gebruikers dezelfde toegang"). Erger: de `@restrict`/`@readonly` blokkeert het verplichte bewerken (FR-008/FR-011) | `@readonly` + `@restrict` op de service weghalen zodat iedereen kan bewerken (draft). XSUAA-scaffolding mag als gedocumenteerde "toekomstige uitbreiding" blijven, maar **niet afgedwongen** |
| C5 | **Verkeerd TripPin-endpoint**: TA kiest bewust `TripPinService`; `.cdsrc.json` wijst naar `TripPinRESTierService` | URL omzetten naar TripPinService en hertesten |
| C6 | **Timeline-app**: finale FA zet tijdlijnvisualisatie expliciet out of scope; finale TA schrijft **precies 3 apps** voor (Trips, Employees, Airlines/Insights). `app/explorer/timeline/` hoort er niet | Timeline-app verwijderen |
| C7 | **Department-veld** komt in géén FR voor (finale FA: medewerker = enkel projectcode); comments citeren FR-002/003 onterecht | `Department` schrappen uit `schema.cds` / `People` / annotaties |
| C8 | **Readme noemt "SAP Build Work Zone"**: finale TA schrijft Managed Approuter voor | Readme corrigeren (Managed Approuter) |
| C9 | **Airports**: finale TA = key `IcaoCode` + `Name, IataCode, Location`; code mist `Location` | `Location` toevoegen |

---

## Wat is er al (maar deels te corrigeren) 🟡

- [x] Datamodel met extensies + People-replica + seed-CSV's — *maar* key/CostCenter/Department fixen (C1, C3, C7)
- [x] TripPin remote service geïmporteerd (`cds import`)
- [x] Mashup-service met after-READ-verrijking + People-replicatie bij boot
- [x] Explorer List Reports + Object Pages: Employees, Trips, Airlines (+ annotaties) — *maar* herschikken naar 3 persona-apps, filters & editing toevoegen
- [x] StatusCriticality-kleurcodering op Trips
- [ ] ~~RBAC-fundament~~ — buiten MVP-scope, afdwinging weghalen (C4)

---

## 🔵 Denis Bujorean — Backend, Datamodel & Deployment

| # | Taak | FR / fix | Prio |
|---|------|----------|------|
| D1 | **Trips als volledige geaggregeerde set**: alle TripPin-reizen via People `$expand=Trips` ontsluiten, gerepliceerd zodat `StartsAt`/`EndsAt`/`Name` echte (filterbare, sorteerbare) kolommen worden; verrijken met `Status`/`CostCenter` uit de extensie | C2, FR-002, FR-006 | Hoog |
| D2 | **Datamodel-fixes**: composite key `UserName+TripId`, `CostCenter` toevoegen, lokale `Budget` weg, `Department` weg, `Airports.Location` toevoegen | C1, C3, C7, C9 | Hoog |
| D3 | **RBAC-afdwinging weghalen**: `@readonly`/`@restrict` van de service af zodat draft-editing voor iedereen werkt; XSUAA enkel als gedocumenteerde toekomst-optie laten staan | C4, FR-008, FR-011 | Hoog |
| D4 | **Vluchten ontsluiten**: TripPin `PlanItems/Flights` modelleren en koppelen aan Trips (vlucht → airline → vertrek-/aankomstluchthaven) | FR-007 | Hoog |
| D5 | **KPI-handler**: aggregaties in de CAP-service — totaal reizen, aantal medewerkers "op reis" (`StartsAt ≤ vandaag ≤ EndsAt`), meest gebruikte airlines (op **aantal vluchten**) | FR-001, FR-009 | Hoog |
| D6 | **TripPin-endpoint omzetten** naar TripPinService; lokaal hertesten | C5 | Middel |
| D7 | **`mta.yaml` afmaken**: HTML5-modules voor de **3 UI-apps**, HTML5 App Repo (host), **Managed Approuter**, destination service; TripPin-destination aanmaken in BTP | — | Middel |
| D8 | Deploy `mbt build` + `cf deploy` naar CF Trial; HANA-binding verifiëren; trial-verlenging inplannen (elke 30 d.) | — | Middel |
| D9 | `db.sqlite` uit git + `.gitignore`; verifiëren dat repo **private** op GitHub staat (verplicht volgens TA) | — | Laag |

## 🟢 Adam Yousfi — Frontend (3 Fiori Elements-apps per persona)

> Finale TA: precies 3 apps, elk één kernobject + persona. Bewerken via **draft-enabled
> editing** in de app waar het veld thuishoort.

| # | Taak | FR | Prio |
|---|------|-----|------|
| Y1 | **Trips-app (Travel Coördinator)**: List Report op de geaggregeerde Trips (chronologisch gesorteerd), FilterBar op **periode (datumbereik), status én projectcode**; draft-editing van **Status + CostCenter**; vereist D1/D2/D3 | FR-002, FR-006, FR-008, FR-011 | Hoog |
| Y2 | **Trip Object Page** uitbreiden met vluchten-facet (airline + vertrek-/aankomstluchthaven per vlucht) + drill-down naar medewerker; vereist D4 | FR-007 | Hoog |
| Y3 | **Employees-app (Team Lead)**: List Report met **zoeken op naam/gebruikersnaam** (`@cds.search`); Object Page met chronologische reisgeschiedenis + draft-editing van **PrimePathProjectCode** | FR-003, FR-004, FR-005 | Hoog |
| Y4 | **Airlines/Insights-app (HR/Admin)**: overzicht Airlines + Airports, "meest gebruikt"-kolom/sortering, draft-editing van **PreferredVendor**, en de **KPI's** uit D5 op de startpagina | FR-001, FR-009, FR-010 | Hoog |
| Y5 | **Timeline-app verwijderen** (out of scope); i18n-labels overal invullen | C6 | Laag |

## 🟠 Adam Akkay — Insights-logica, Kwaliteit & Documentatie

| # | Taak | FR / fix | Prio |
|---|------|----------|------|
| A1 | **Vendor-insights definiëren**: precieze regels voor "meest gebruikte airline" (telling op aantal vluchten, niet budget) samen met D5; valideren in de Airlines/Insights-app | FR-009 | Hoog |
| A2 | **Code ↔ docs sluitend maken**: na C1–C9 de finale analyses naast de app leggen en bevestigen dat alles 1-op-1 klopt (deze lijst afvinken) | C1–C9 | Hoog |
| A3 | **Tests** met `cds.test`: mashup-verrijking, Trips-aggregatie + composite key (gedeelde trips!), KPI-aggregaties | — | Middel |
| A4 | **End-to-end demoscript**: coördinator zoekt reis → drill-down medewerker/vlucht/luchthaven → bewerkt status/kostenplaats/projectcode/preferred vendor → KPI's tonen het effect | alle | Middel |
| A5 | **Documentatie**: readme corrigeren (C8), deployment-stappen; controleren dat logo's EHB & Flexso in de analyses staan (✅ aanwezig in finale PDF's) | C8 | Laag |

## 🤝 Samen

- [ ] Korte sync over C1–C9 vóór er verder gebouwd wordt (model-fixes eerst)
- [ ] Code review van elkaars onderdelen vóór oplevering
- [ ] Demo/presentatie voorbereiden (begeleiders: Nico Goossens Verelst, Babeth Velghe, Stijn Verdoodt)

---

## Aanbevolen volgorde

1. **Eerst (fundament):** D2 + D3 + C5/D6 → daarna D1 (Trips-bron). Niemand bouwt UI op een fout model.
2. **Sprint 1:** D1 + D4 (trips & vluchten) ∥ Y3 (Employees-app) ∥ A1
3. **Sprint 2:** D5 + D7 (KPI's & deployment-config) ∥ Y1 + Y2 (Trips-app & vluchten-UI) ∥ A2
4. **Sprint 3:** D8/D9 (deploy) ∥ Y4 + Y5 (Insights-app & opschoning) ∥ A3/A4/A5 → gezamenlijke demo
