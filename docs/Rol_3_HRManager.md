# Rol 3 — HR Manager / Administrator

**App (tegel):** **HR Manager** · *Vendor Insights & KPI's*
**Hoofdvraag:** *"Welke airline gebruiken we het meest?"* (rapportage & contractonderhandelingen)
**Kern:** kerncijfers en airline-gebruik raadplegen; de coördinator/HR markeert voorkeursairlines.

| Wat kan je doen | Waar vind je het | Type |
|---|---|---|
| **Airlines** zien, gesorteerd op **meest gebruikt** (aantal vluchten) | **Startscherm** van de app = de airlineslijst | Lezen |
| **Luchthavens** (airports) zien | Airports-lijst (ICAO / IATA / naam) | Lezen |
| **KPI's**: totaal aantal reizen, medewerkers **op reis nu**, meest gebruikte airlines | Knop **"Kerncijfers (KPI's)"** → KPI-overzicht | Lezen |
| **Preferred vendor** toekennen aan één airline | Open een airline → knop **"Preferred vendor instellen"** | **Bewerken** |
| Voorkeursairlines **in bulk** beheren | Knop **"Voorkeursairlines beheren"** (lijst met draft-editing) | **Bewerken** |

### Stap-voor-stap: meest gebruikte airline tonen
1. Open de **HR Manager**-tegel → de lijst staat al gesorteerd op **Aantal vluchten** (hoog → laag).
2. De bovenste airline is de meest gebruikte (bv. American Airlines).
3. Klik **"Kerncijfers (KPI's)"** voor totaal reizen + op-reis-nu.

### Stap-voor-stap: preferred vendor zetten
1. Klik een airline → knop **"Preferred vendor instellen"** → aan/uit → bevestig.
   *(of: knop "Voorkeursairlines beheren" om er meerdere na elkaar te beheren.)*

### Wat deze rol bewust **niet** kan
- Airlines, luchthavens of KPI's zélf aanmaken/bewerken/verwijderen — die zijn read-only (poging → HTTP 405). Enkel de **preferred-vendor**-vlag is bewerkbaar.

> Demo-noot: **"Op reis nu" = 0** met de huidige data — alle TripPin-demoreizen zijn uit **2014**, dus geen enkele reis loopt vandaag. De berekening (`startdatum ≤ vandaag ≤ einddatum`) klopt; het is een eigenschap van de demodataset.
