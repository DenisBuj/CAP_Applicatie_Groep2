using { TravelService } from '../../../srv/travel-service';

// ============================================================================
// Trips  (lokale TripPin-replica + Status/CostCenter uit TripExtension)
// ============================================================================
annotate TravelService.Trips with @(
  UI: {
    HeaderInfo: {
      $Type          : 'UI.HeaderInfoType',
      TypeName       : 'Reis',
      TypeNamePlural : 'Reizen',
      Title          : { $Type: 'UI.DataField', Value: Name },
      Description    : { $Type: 'UI.DataField', Value: Owner }
    },
    // FR-002/FR-006 + hoofdvraag: filterbaar op periode (datumbereik), reisstatus,
    // projectcode én bestemming (land + aankomstluchthaven — "naar de VS / via welke luchthaven").
    SelectionFields : [ StartsAt, EndsAt, Status, ProjectCode, DestinationCountry, DestinationAirport ],
    LineItem : [
      { $Type: 'UI.DataField', Value: TripId,              Label: 'Reis-ID' },
      { $Type: 'UI.DataField', Value: Name,                Label: 'Naam' },
      { $Type: 'UI.DataField', Value: Employee.FirstName,  Label: 'Voornaam' },
      { $Type: 'UI.DataField', Value: Employee.LastName,   Label: 'Achternaam' },
      { $Type: 'UI.DataField', Value: DestinationCountry,  Label: 'Bestemming (land)' },
      { $Type: 'UI.DataField', Value: DestinationAirport,  Label: 'Aankomstluchthaven' },
      { $Type: 'UI.DataField', Value: Status,              Label: 'Status',      Criticality: StatusCriticality },
      { $Type: 'UI.DataField', Value: ProjectCode,         Label: 'Projectcode' },
      { $Type: 'UI.DataField', Value: CostCenter,          Label: 'Kostenplaats' },
      { $Type: 'UI.DataField', Value: Budget,              Label: 'Budget' },
      { $Type: 'UI.DataField', Value: StartsAt,            Label: 'Vertrek' },
      { $Type: 'UI.DataField', Value: EndsAt,              Label: 'Terug' }
    ],
    // FR-006: standaard chronologisch gesorteerd op vertrekdatum
    PresentationVariant : {
      SortOrder      : [{ Property: StartsAt, Descending: false }],
      Visualizations : ['@UI.LineItem']
    },
    // ---- Object Page ----
    Facets : [
      { $Type: 'UI.ReferenceFacet', ID: 'ReisFacet',
        Label: 'Reisgegevens', Target: '@UI.FieldGroup#TripDetails' },
      // FR-007: vluchten per reis (airline + vertrek-/aankomstluchthaven)
      { $Type: 'UI.ReferenceFacet', ID: 'VluchtenFacet',
        Label: 'Vluchten',     Target: 'Flights/@UI.LineItem' },
      // FR-007: medewerkergegevens inline zodat de gebruiker kan doorklikken
      { $Type: 'UI.ReferenceFacet', ID: 'MedewerkerFacet',
        Label: 'Medewerker',   Target: 'Employee/@UI.FieldGroup#Details' }
    ],
    FieldGroup #TripDetails : {
      Data : [
        { $Type: 'UI.DataField', Value: TripId,      Label: 'Reis-ID' },
        { $Type: 'UI.DataField', Value: Name,               Label: 'Naam' },
        { $Type: 'UI.DataField', Value: Description,        Label: 'Omschrijving' },
        { $Type: 'UI.DataField', Value: Owner,              Label: 'Medewerker' },
        { $Type: 'UI.DataField', Value: DestinationCountry, Label: 'Bestemming (land)' },
        { $Type: 'UI.DataField', Value: DestinationAirport, Label: 'Aankomstluchthaven' },
        { $Type: 'UI.DataField', Value: ProjectCode,        Label: 'Projectcode' },
        { $Type: 'UI.DataField', Value: Status,      Label: 'Status',      Criticality: StatusCriticality },
        { $Type: 'UI.DataField', Value: CostCenter,  Label: 'Kostenplaats' },
        { $Type: 'UI.DataField', Value: Budget,      Label: 'Budget' },
        { $Type: 'UI.DataField', Value: StartsAt,    Label: 'Vertrek' },
        { $Type: 'UI.DataField', Value: EndsAt,      Label: 'Terug' }
      ]
    }
  }
) {
  TripId      @title: 'Reis-ID';
  Name        @title: 'Naam';
  Owner       @title: 'Medewerker';
  Status      @title: 'Status';
  CostCenter  @title: 'Kostenplaats';
  ProjectCode @title: 'Projectcode';
  DestinationCountry @title: 'Bestemming (land)';
  DestinationAirport @title: 'Aankomstluchthaven';
  Budget      @title: 'Budget'  @Measures.ISOCurrency: 'EUR';
  StartsAt    @title: 'Vertrek';
  EndsAt      @title: 'Terug';
  Description @title: 'Omschrijving';
};

// ============================================================================
// Flights  (lokale replica van TripPin PlanItems/Flights)  FR-007
// ============================================================================
annotate TravelService.Flights with @(
  UI: {
    HeaderInfo: {
      $Type          : 'UI.HeaderInfoType',
      TypeName       : 'Vlucht',
      TypeNamePlural : 'Vluchten',
      Title          : { $Type: 'UI.DataField', Value: FlightNumber },
      Description    : { $Type: 'UI.DataField', Value: AirlineCode }
    },
    LineItem : [
      { $Type: 'UI.DataField', Value: FlightNumber,    Label: 'Vluchtnummer' },
      { $Type: 'UI.DataField', Value: AirlineName,     Label: 'Airline' },
      { $Type: 'UI.DataField', Value: FromAirportName, Label: 'Vertrek' },
      { $Type: 'UI.DataField', Value: ToAirportName,   Label: 'Aankomst' },
      { $Type: 'UI.DataField', Value: StartsAt,        Label: 'Vertrekdatum' },
      { $Type: 'UI.DataField', Value: EndsAt,          Label: 'Aankomstdatum' }
    ]
  }
) {
  FlightNumber    @title: 'Vluchtnummer';
  AirlineCode     @title: 'Airline (code)';
  AirlineName     @title: 'Airline';
  FromAirport     @title: 'Vertrek (ICAO)';
  FromAirportName @title: 'Vertrek';
  ToAirport       @title: 'Aankomst (ICAO)';
  ToAirportName   @title: 'Aankomst';
  StartsAt        @title: 'Vertrekdatum';
  EndsAt          @title: 'Aankomstdatum';
};

// ============================================================================
// TripExtensions  (draft editing: Status + CostCenter per reis)  FR-008/FR-011
// ============================================================================
annotate TravelService.TripExtensions with @(
  UI: {
    HeaderInfo: {
      $Type          : 'UI.HeaderInfoType',
      TypeName       : 'Reisextensie',
      TypeNamePlural : 'Reisextensies',
      Title          : { $Type: 'UI.DataField', Value: Owner },
      Description    : { $Type: 'UI.DataField', Value: TripId }
    },
    LineItem : [
      { $Type: 'UI.DataField', Value: Owner,      Label: 'Medewerker' },
      { $Type: 'UI.DataField', Value: TripId,     Label: 'Reis-ID' },
      { $Type: 'UI.DataField', Value: Status,     Label: 'Status' },
      { $Type: 'UI.DataField', Value: CostCenter, Label: 'Kostenplaats' }
    ],
    Facets : [
      { $Type: 'UI.ReferenceFacet', ID: 'EditFacet',
        Label: 'Reisgegevens', Target: '@UI.FieldGroup#EditFields' }
    ],
    // FR-008: Travel Coördinator stelt Status en CostCenter in
    FieldGroup #EditFields : {
      Data : [
        { $Type: 'UI.DataField', Value: Owner,      Label: 'Medewerker' },
        { $Type: 'UI.DataField', Value: TripId,     Label: 'Reis-ID' },
        { $Type: 'UI.DataField', Value: Status,     Label: 'Status' },
        { $Type: 'UI.DataField', Value: CostCenter, Label: 'Kostenplaats' }
      ]
    }
  }
) {
  Owner      @title: 'Medewerker'   @readonly;
  TripId     @title: 'Reis-ID'      @readonly;
  Status     @title: 'Status';
  CostCenter @title: 'Kostenplaats';
};

// ============================================================================
// AirlineExtensions  (draft editing: PreferredVendor)  FR-010/FR-011
// ----------------------------------------------------------------------------
// De Travel Coördinator beheert de voorkeursairlines (FA §3: "hij houdt de
// reisstatus, projectcodes, kostenplaatsen en voorkeursairlines up-to-date";
// FR-010: "beheerd door de travel coördinator"). Daarom hoort dit beheer in de
// Trips-app van de coördinator en NIET in de read-only HR/Admin-app.
// ============================================================================
annotate TravelService.AirlineExtensions with @(
  UI: {
    HeaderInfo: {
      $Type          : 'UI.HeaderInfoType',
      TypeName       : 'Voorkeursairline',
      TypeNamePlural : 'Voorkeursairlines',
      Title          : { $Type: 'UI.DataField', Value: AirlineCode },
      Description    : { $Type: 'UI.DataField', Value: PreferredVendor }
    },
    LineItem : [
      { $Type: 'UI.DataField', Value: AirlineCode,     Label: 'Code' },
      { $Type: 'UI.DataField', Value: PreferredVendor, Label: 'Voorkeursleverancier' }
    ],
    Facets : [
      { $Type: 'UI.ReferenceFacet', ID: 'EditFacet',
        Label: 'Airline-gegevens', Target: '@UI.FieldGroup#EditFields' }
    ],
    // FR-010: Travel Coördinator markeert airline als voorkeursleverancier
    FieldGroup #EditFields : {
      Data : [
        { $Type: 'UI.DataField', Value: AirlineCode,     Label: 'Code' },
        { $Type: 'UI.DataField', Value: PreferredVendor, Label: 'Voorkeursleverancier' }
      ]
    }
  }
) {
  AirlineCode     @title: 'Code'                  @readonly;
  PreferredVendor @title: 'Voorkeursleverancier';
};
