# PrimePath Travel Dashboard — TODO & Taakverdeling

> Team: Denis Bujorean, Adam Yousfi, Adam Akkay
> Geverifieerd tegen: **Functionele Analyse FINAL + Technische Analyse FINAL** (Files/, 12 juni 2026)
> Laatst bijgewerkt: 14 juni 2026 — backend-afwerkplan 
---

## Haalbaarheid: ✅ JA

De architectuur uit de finale analyses (CAP-mashup TripPin + HANA-extensies, **drie**
Fiori Elements-apps per persona, Managed Approuter op BTP Trial) is het standaard
CAP-deploymentpad en ruim haalbaar. De backend-fundering staat al; dit plan maakt de
**volledige backend** af, exact in lijn met de finale analyses.

**Grootste technische risico's (backend):**
1. **Trips moeten uit álle TripPin-reizen komen** (People `$expand=Trips`, geaggregeerd tot één vlakke, gerepliceerde set). De code baseert `Trips` nu op de lokale `TripExtension`-rijen → alleen reizen mét extensie zijn zichtbaar. Dit moet om. → 
2. **Vluchten** (TripPin `PlanItems/Flights`) voor FR-007 en FR-009 — nog onontgonnen. →
3. **KPI-aggregaties** (FR-001) — bestaan nog niet. → 
4. **`mta.yaml` is onvolledig én strijdig met de analyses**: bevat geen UI-apps, geen HTML5 App Repo, geen Managed Approuter, en vereist nog XSUAA. → 
5. BTP Trial verloopt elke 30 dagen — tijdig verlengen.

---

## Backend-afwerkplan — 

| Commit | Inhoud | FR / fix |
|--------|--------|----------|
| **1 — Model & service opschonen** | Schema-comments rechtzetten (coördinator beheert, niet HR); annotatie-filters corrigeren (Budget weg als SelectionField); `db.sqlite` uit git houden; service-laag consistent met analyses | C3, C4, FR-008, FR-011 |
| **2 — Trips als volledige geaggregeerde set** | Alle TripPin-reizen via People `$expand=Trips` repliceren naar een lokale `Trips`-tabel met echte kolommen (Name, StartsAt, EndsAt, Budget, Owner); verrijken met Status/CostCenter uit `TripExtension`; filteren/sorteren op periode werkt | C2, D1, FR-002, FR-006 |
| **3 — Vluchten & KPI's** | TripPin `PlanItems/Flights` ontsluiten en koppelen aan Trips (vlucht → airline → vertrek-/aankomstluchthaven); KPI-functie: totaal reizen, "op reis" (`StartsAt ≤ vandaag ≤ EndsAt`), meest gebruikte airlines op **aantal vluchten** | D4, D5, FR-001, FR-007, FR-009 |
| **4 — Service-annotaties afronden** | Service-niveau Fiori-annotaties consistent met de 3 persona-apps: Employees (zoeken op naam), Trips (filters periode/status/projectcode, draft-editing Status+CostCenter), Airlines (PreferredVendor draft-editing, "meest gebruikt"-kolom), Airports; KPI's exposed | FR-001..011 |
| **5 — Deployment-config** | `mta.yaml` herschrijven conform TA: CAP-srv + HANA-deployer + **3 HTML5 UI-modules** + **HTML5 App Repo (host+runtime)** + **Managed Approuter** + destination service; **XSUAA verwijderen** (MVP zonder RBAC); TripPin-destination documenteren | D7, deployment |

> **Nu is de volledige backend klaar en deploybaar.** De drie Fiori-apps zelf
> uitbouwen (taken Y1–Y5: list reports, object pages, filterbars, draft-UX) is een
> apart UI-blok.

---

## ⚠️ Reeds rechtgetrokken in eerdere foundation-batch

| # | Afwijking code ↔ finale analyse | Status |
|---|----------------------------------|--------|
| C1 | **Composite key** `TripExtension` = `Owner + TripId` | ✅ gedaan |
| C3 | **CostCenter i.p.v. lokale Budget**; Budget read-only uit TripPin | ✅ gedaan |
| C4 | **RBAC-afdwinging weg** (`@restrict` van de service); extensie-entiteiten vrije CRUD (MVP) | ✅ gedaan |
| C6 | **Timeline-app verwijderd**; 3 apps over: trips, employees, airlines | ✅ gedaan |
| C7 | **Department-veld geschrapt** uit schema/annotaties/seed | ✅ gedaan |
| C8 | **Readme**: Managed Approuter i.p.v. "SAP Build Work Zone" | ✅ gedaan |
| C9 | `*.sqlite` in `.gitignore` ✅. **Airports.Location** weer verwijderd: TripPin's geneste complex-type breekt de $select-delegatie (502) → geneste Location-support is een follow-up | ⏳ Location open |

### Nog te corrigeren restpunten 
- ⏳ **C2** Trips-bron = geaggregeerde set i.p.v. lokale extensie → **commit 2**
- ⏳ **mta.yaml** onvolledig + strijdig (geen UI/approuter, nog XSUAA) → **commit 5**
- ⏳ Schema-comments zeggen nog "HR/Admin" waar coördinator bedoeld is → **commit 1**
- ⏳ Annotatie `SelectionFields` filtert op `Budget` (niet filterbaar) → **commit 1**

> **Nota TripPin-endpoint (C5):** de CAP-remote-service heet `TripPinService`; de dev-URL
> wijst naar het sessieloze `TripPinRESTierService`-endpoint (geen `(S(...))`-sessiekey),
> wat exact is wat de TA bedoelt met "geen sessie-keys in de URL". Productie gebruikt de
> BTP-destination `TripPin`. Bewust niet gewijzigd. Read-only volstaat.

---

## 🟢 Adam Yousfi — Frontend (3 Fiori Elements-apps) — 
| # | Taak | FR | Prio |
|---|------|-----|------|
| Y1 | **Trips-app (Travel Coördinator)**: List Report op geaggregeerde Trips (chronologisch), FilterBar op periode/status/projectcode; draft-editing Status + CostCenter | FR-002, FR-006, FR-008, FR-011 | Hoog |
| Y2 | **Trip Object Page** + vluchten-facet (airline + luchthavens per vlucht) + drill-down medewerker | FR-007 | Hoog |
| Y3 | **Employees-app (Team Lead)**: zoeken op naam/gebruikersnaam; Object Page met reisgeschiedenis + draft-editing PrimePathProjectCode | FR-003, FR-004, FR-005 | Hoog |
| Y4 | **Airlines/Insights-app (HR/Admin)**: Airlines + Airports, "meest gebruikt"-sortering, draft-editing PreferredVendor, KPI's op startpagina | FR-001, FR-009, FR-010 | Hoog |
| Y5 | i18n-labels overal invullen | — | Laag |

## 🟠 Adam Akkay — Kwaliteit & Documentatie

| # | Taak | FR / fix | Prio |
|---|------|----------|------|
| A1 | Vendor-insights valideren (telling op aantal vluchten) samen met commit 3 | FR-009 | Hoog |
| A2 | Code ↔ finale analyses 1-op-1 bevestigen na elke commit | C1–C9 | Hoog |
| A3 | Tests (`cds.test`): mashup-verrijking, Trips-aggregatie, composite key, KPI's | — | Middel |
| A4 | End-to-end demoscript (coördinator → drill-down → bewerken → KPI-effect) | alle | Middel |
| A5 | Deployment-stappen documenteren; trial-verlenging inplannen | — | Laag |

## 🤝 Samen
- [ ] Na elke backend-commit kort syncen + in GitHub Desktop committen vóór de volgende
- [ ] Code review vóór oplevering
- [ ] Demo/presentatie voorbereiden (begeleiders: Nico Goossens Verelst, Babeth Velghe, Stijn Verdoodt)