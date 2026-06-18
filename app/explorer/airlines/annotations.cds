using { TravelService } from '../../../srv/travel-service';

// ============================================================================
// Airlines  (TripPin Airlines + AirlineExtension)  FR-009
// ============================================================================
annotate TravelService.Airlines with @(
  UI: {
    HeaderInfo: {
      $Type          : 'UI.HeaderInfoType',
      TypeName       : 'Airline',
      TypeNamePlural : 'Airlines',
      Title          : { $Type: 'UI.DataField', Value: Name },
      Description    : { $Type: 'UI.DataField', Value: AirlineCode }
    },
    // FR-009: sorteren op meest gebruikt (FlightCount) → zichtbaar als kolom
    LineItem : [
      { $Type: 'UI.DataField', Value: AirlineCode,     Label: 'Code' },
      { $Type: 'UI.DataField', Value: Name,            Label: 'Naam' },
      { $Type: 'UI.DataField', Value: PreferredVendor, Label: 'Voorkeursleverancier' },
      { $Type: 'UI.DataField', Value: FlightCount,     Label: 'Aantal vluchten' }
    ],
    PresentationVariant : {
      SortOrder      : [{ Property: FlightCount, Descending: true }],
      Visualizations : ['@UI.LineItem']
    },
    // ---- Object Page ----
    Facets : [
      { $Type: 'UI.ReferenceFacet', ID: 'AirlineDetailsFacet',
        Label: 'Airline gegevens', Target: '@UI.FieldGroup#AirlineDetails' }
    ],
    FieldGroup #AirlineDetails : {
      Data : [
        { $Type: 'UI.DataField', Value: AirlineCode,     Label: 'Code' },
        { $Type: 'UI.DataField', Value: Name,            Label: 'Naam' },
        { $Type: 'UI.DataField', Value: PreferredVendor, Label: 'Voorkeursleverancier' },
        { $Type: 'UI.DataField', Value: FlightCount,     Label: 'Aantal vluchten' }
      ]
    }
  }
) {
  AirlineCode     @title: 'Code';
  Name            @title: 'Naam';
  PreferredVendor @title: 'Voorkeursleverancier';
  FlightCount     @title: 'Aantal vluchten';
};

// ============================================================================
// Airports  (TripPin Airports — read-only)  FR-009
// ============================================================================
annotate TravelService.Airports with @(
  UI: {
    HeaderInfo: {
      $Type          : 'UI.HeaderInfoType',
      TypeName       : 'Luchthaven',
      TypeNamePlural : 'Luchthavens',
      Title          : { $Type: 'UI.DataField', Value: Name },
      Description    : { $Type: 'UI.DataField', Value: IcaoCode }
    },
    SelectionFields : [ IcaoCode, IataCode ],
    LineItem : [
      { $Type: 'UI.DataField', Value: IcaoCode, Label: 'ICAO-code' },
      { $Type: 'UI.DataField', Value: IataCode, Label: 'IATA-code' },
      { $Type: 'UI.DataField', Value: Name,     Label: 'Naam' }
    ]
  }
) {
  IcaoCode @title: 'ICAO-code';
  IataCode @title: 'IATA-code';
  Name     @title: 'Naam';
};

// NB: het BEWERKEN van PreferredVendor (AirlineExtensions) zit bewust NIET in
// deze HR/Admin-app. De Functionele Analyse §3 stelt HR/Admin uitdrukkelijk
// "uitsluitend raadplegend (read-only)" en legt het beheer van de
// voorkeursairlines bij de Travel Coördinator (FR-010/FR-011). Het bewerken
// gebeurt daarom in de Trips-app (zie app/explorer/trips/annotations.cds).
// Hier wordt PreferredVendor enkel getoond ("zichtbaar voor alle gebruikers").

// ============================================================================
// KPISummary  (singleton — HR/Admin startoverzicht)  FR-001
// ============================================================================
annotate TravelService.KPISummary with @(
  UI: {
    HeaderInfo: {
      $Type          : 'UI.HeaderInfoType',
      TypeName       : 'KPI-overzicht',
      TypeNamePlural : 'KPI-overzichten',
      Title          : { $Type: 'UI.DataField', Value: TotalTrips },
      Description    : { $Type: 'UI.DataField', Value: TravelersNow }
    },
    // KPI-tegels bovenaan de pagina (Fiori Elements DataPoint kaarten)
    DataPoint #TotalTrips: {
      Value       : TotalTrips,
      Title       : 'Totaal reizen',
      Description : 'Alle reizen in het systeem'
    },
    DataPoint #TravelersNow: {
      Value       : TravelersNow,
      Title       : 'Op reis nu',
      Description : 'Medewerkers momenteel onderweg'
    },
    HeaderFacets: [
      { $Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#TotalTrips',   Label: 'Totaal reizen' },
      { $Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#TravelersNow', Label: 'Op reis nu'    }
    ],
    Facets: [
      { $Type: 'UI.ReferenceFacet', ID: 'KPIFacet',
        Label: 'Reisstatistieken', Target: '@UI.FieldGroup#KPIs' }
    ],
    FieldGroup #KPIs : {
      Data: [
        { $Type: 'UI.DataField', Value: TotalTrips,   Label: 'Totaal aantal reizen' },
        { $Type: 'UI.DataField', Value: TravelersNow, Label: 'Momenteel op reis' }
      ]
    }
  }
) {
  TotalTrips   @title: 'Totaal reizen';
  TravelersNow @title: 'Momenteel op reis';
};
