# PrimePath Travel Dashboard

Full-stack SAP CAP applicatie voor reismanagement.
Erasmushogeschool Brussel / Flexso — Denis Bujorean, Adam Yousfi & Adam Akkay.

## Tech stack
- SAP CAP (Node.js) op SAP BTP Cloud Foundry
- SAP HANA Cloud (productie) / SQLite (lokaal)
- TripPin OData V4 als externe databron (mashup)
- SAP Fiori Elements UI + SAP Build Work Zone
- XSUAA Role-Based Access Control

## Lokaal starten
```bash
npm install
cds watch
```

## Projectstructuur
| Map/bestand | Doel |
|-------------|------|
| `db/` | HANA-extensie entiteiten (domeinmodel) |
| `srv/` | CAP services + custom handlers |
| `srv/external/` | Geïmporteerde TripPin remote service |
| `app/` | Fiori Elements UI (explorer + admin) |
| `external/` | TripPin OData metadata (bron-EDMX) |
| `.cdsrc.json` | CDS runtime configuratie (db, auth, remote services) |
| `mta.yaml` | BTP deployment descriptor |

Learn more at <https://cap.cloud.sap>.
