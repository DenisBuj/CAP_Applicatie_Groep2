# Beschikbare maar (nog) ongebruikte TripPin-data

Data die de TripPin-bron aanbiedt en die we zouden kunnen tonen/verrijken, maar
die we in de huidige MVP bewust niet gebruiken (scope-keuze: exploratie + verrijking).

## Medewerkers (People)
- **E-mailadressen** (`Emails`) — meerdere per persoon
- **Adres / woonplaats / land** (`AddressInfo`, `HomeAddress` → stad, land, regio)
- **Sociaal netwerk** (`Friends`, `BestFriend`) — wie kent wie
- **Tweede naam** (`MiddleName`) — zit in het model, wordt niet getoond
- **Voorkeuren** (`FavoriteFeature`, `Features`)

## Reizen (Trip)
- **Tags / labels** op een reis (`Tags`)
- **ShareId** (`ShareId`) — gedeelde-reis-identificatie

## Vluchten (Flight / PlanItem)
- **Boekingscode** (`ConfirmationCode`)
- **Stoelnummer** (`SeatNumber`)
- **Vluchtduur** (`Duration`)

## Luchthavens (Airport)
- **Stad & regio** (`Location.City`)
- **Geo-coördinaten** (`Location.Loc`, lat/lon) — bruikbaar voor een **kaartweergave**

## Andere plan-items
- **Events** (niet-vlucht-items zoals conferenties, met locatie/`OccursAt`) — we
  repliceren enkel vluchten, geen events

## Org-structuur (TripPin-subtypes Employee/Manager)
- **Kostprijs** (`Employee.Cost`), **collega's** (`Peers`),
  **direct reports** (`Manager.DirectReports`) — organisatiehiërarchie

---

> Mooi voor de "future work"-slide: dit toont dat we de databron volledig kennen
> en bewust scope hebben gekozen (read-only exploratie + eigen PrimePath-verrijking),
> met duidelijke uitbreidingsmogelijkheden (kaart via geo-coördinaten, events,
> contactgegevens, org-structuur).
