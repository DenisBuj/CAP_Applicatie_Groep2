# PrimePath Travel Dashboard — SAP BTP deployment

Deployment naar **SAP BTP Cloud Foundry** (trial) via een **MTA**.
Architectuur (zie `mta.yaml`): CAP-backend + HANA HDI-deployer + 3 HTML5-apps +
HTML5 App Repository (host + runtime) + standalone Approuter (`auth: none`, MVP zonder XSUAA)
+ Destination-service.

---

## 0. Tooling (lokaal) — reeds aanwezig ✅

| Tool | Status |
|------|--------|
| `cf` CLI | ✅ geïnstalleerd |
| `multiapps` cf-plugin (`cf deploy`) | ✅ 3.11.1 |
| `mbt` (Cloud MTA Build Tool) | ✅ 1.2.47 |
| `@sap/cds-dk` | ✅ 9.9.2 |

Ontbreekt er iets: `cf install-plugin multiapps` / `npm i -g mbt`.

---

## 1. Inloggen op Cloud Foundry

> Het cf-token is **verlopen** — opnieuw inloggen is vereist.

```bash
cf login -a https://api.cf.us10-001.hana.ondemand.com
# org:   cc04186dtrial
# space: dev
```

Controleer: `cf target`

---

## 2. Eenmalige BTP-side voorbereiding (cockpit)

### 2a. HANA Cloud instance — moet AAN staan
De `primepath-db` (hdi-shared) vereist een **draaiende HANA Cloud**.
Trial stopt HANA automatisch elke nacht → vóór deploy starten:

- BTP Cockpit → subaccount → **SAP HANA Cloud** → instance → **Start** (duurt enkele minuten).
- Of via CLI (na `cf install-plugin hana-cli` of via de cockpit).

### 2b. TripPin-destination — handmatig aanmaken
De CAP-backend praat in **productie** met TripPin via een destination genaamd `TripPin`
(zie `.cdsrc.json` → `[production]`). Maak die aan op **subaccount-niveau**:

| Veld | Waarde |
|------|--------|
| Name | `TripPin` |
| URL | `https://services.odata.org/TripPinRESTierService` |
| Type | `HTTP` |
| Proxy Type | `Internet` |
| Authentication | `NoAuthentication` |

> De `primepath-srv-api`-destination wordt **automatisch** aangemaakt door de
> destination-service in `mta.yaml` (init_data) — die hoef je niet zelf te maken.

### 2c. Entitlements (eenmalig, normaal al aanwezig op trial)
Subaccount → Entitlements → toevoegen indien nodig:
- `SAP HANA Cloud` (tools) / `hdi-shared`
- `HTML5 Application Repository Service` — `app-host` + `app-runtime`
- `Destination Service` — `lite`

---

## 3. Bouwen (lokaal)

```bash
mbt build
# → mta_archives/primepath-travel-dashboard_1.0.0.mtar   (✅ reeds gebouwd)
```

---

## 4. Deployen

```bash
cf deploy mta_archives/primepath-travel-dashboard_1.0.0.mtar
```

Duurt ~10–15 min (services worden gecreëerd, HANA-tabellen gedeployed, apps geüpload).

---

## 5. Openen

```bash
cf apps
# open de route van 'primepath-approuter' in de browser
```

De approuter `welcomeFile` opent de **Fiori Launchpad** (`/launchpad/flp.html`) met
de drie apps als tegels. Vandaaruit start je elke app via zijn tegel.

Rechtstreekse app-URL's (zonder launchpad) blijven ook werken:
- `/primepath.explorer.trips/index.html`
- `/primepath.explorer.employees/index.html`
- `/primepath.explorer.airlines/index.html`

> De launchpad laadt SAPUI5 + de ushell-sandbox van de publieke UI5-CDN
> (`https://ui5.sap.com`). De drie apps worden uit de HTML5 App Repository geladen
> op hun repo-pad (= `sap.app.id`). Komt er na deploy geen tegel tevoorschijn,
> controleer dan in de browser-console of de app-componenten (`/primepath.explorer.*`)
> een 200 geven via de approuter-route naar `html5-apps-repo-rt`.

---

## 6. Bijwerken / opnieuw deployen

```bash
mbt build && cf deploy mta_archives/primepath-travel-dashboard_1.0.0.mtar
```

Verwijderen: `cf undeploy primepath-travel-dashboard --delete-services`

---

## Troubleshooting

| Symptoom | Oorzaak / fix |
|----------|---------------|
| Deploy faalt op `primepath-db` | HANA Cloud staat **uit** → start (2a) en deploy opnieuw |
| Airlines/Airports leeg in prod | `TripPin`-destination ontbreekt of fout (2b) |
| `token expired` | `cf login` (stap 1) |
| Wit scherm na deploy | Browser-cache → hard refresh (Cmd+Shift+R) / incognito |
| Lege launchpad / geen tegels | App-componenten geven geen 200 via `html5-apps-repo-rt`, of UI5-CDN geblokkeerd → check browser-console (Network) |
| Trial verlopen | BTP-trial verloopt elke 30 dagen → in cockpit verlengen |
