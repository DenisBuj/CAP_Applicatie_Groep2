using { TravelService } from './travel-service';

//
// Fiori Elements UI-annotaties voor alle TravelService-entiteiten.
//
// Leesbare entiteiten (Explorer, read-only):
//   Employees, Trips, Flights, Airlines, Airports
// Bewerkbare extensie-entiteiten (draft, CRUD):
//   TripExtensions (Status + CostCenter), EmployeeExtensions (Projectcode),
//   AirlineExtensions (PreferredVendor)
//
// NB: filteren (SelectionFields) werkt alleen op velden die op DB- of remote-niveau
// gefilterd kunnen worden. Virtual-velden staan als kolom maar niet als filter.
//

// ============================================================================
// Employees  (TripPin People + EmployeeExtension)
// ============================================================================
annotate TravelService.Employees with @(
  UI: {
    HeaderInfo: {
      $Type          : 'UI.HeaderInfoType',
      TypeName       : 'Medewerker',
      TypeNamePlural : 'Medewerkers',
      Title          : { $Type: 'UI.DataField', Value: FirstName },
      Description    : { $Type: 'UI.DataField', Value: UserName }
    },
    // FR-003/FR-004: zoeken op naam + projectcode
    SelectionFields : [ FirstName, LastName, PrimePathProjectCode ],
    LineItem : [
      { $Type: 'UI.DataField', Value: UserName,             Label: 'Gebruikersnaam' },
      { $Type: 'UI.DataField', Value: FirstName,            Label: 'Voornaam' },
      { $Type: 'UI.DataField', Value: LastName,             Label: 'Achternaam' },
      { $Type: 'UI.DataField', Value: PrimePathProjectCode, Label: 'Projectcode' }
    ],
    // ---- Object Page ----
    Facets : [
      { $Type: 'UI.ReferenceFacet', ID: 'GegevensFacet',
        Label: 'Gegevens',          Target: '@UI.FieldGroup#Details' },
      { $Type: 'UI.ReferenceFacet', ID: 'ReizenFacet',
        Label: 'Reisgeschiedenis',  Target: 'Trips/@UI.LineItem' }
    ],
    FieldGroup #Details : {
      Data : [
        { $Type: 'UI.DataField', Value: UserName,             Label: 'Gebruikersnaam' },
        { $Type: 'UI.DataField', Value: FirstName,            Label: 'Voornaam' },
        { $Type: 'UI.DataField', Value: LastName,             Label: 'Achternaam' },
        { $Type: 'UI.DataField', Value: Gender,               Label: 'Geslacht' },
        { $Type: 'UI.DataField', Value: Age,                  Label: 'Leeftijd' },
        { $Type: 'UI.DataField', Value: PrimePathProjectCode, Label: 'Projectcode' }
      ]
    }
  }
) {
  UserName             @title: 'Gebruikersnaam';
  FirstName            @title: 'Voornaam';
  LastName             @title: 'Achternaam';
  MiddleName           @title: 'Tweede naam';
  Gender               @title: 'Geslacht';
  Age                  @title: 'Leeftijd';
  PrimePathProjectCode @title: 'Projectcode';
};

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
    // FR-002/FR-006: filterbaar op periode, status en kostenplaats
    SelectionFields : [ StartsAt, EndsAt, Status, CostCenter ],
    LineItem : [
      { $Type: 'UI.DataField', Value: TripId,              Label: 'Reis-ID' },
      { $Type: 'UI.DataField', Value: Name,                Label: 'Naam' },
      { $Type: 'UI.DataField', Value: Employee.FirstName,  Label: 'Voornaam' },
      { $Type: 'UI.DataField', Value: Employee.LastName,   Label: 'Achternaam' },
      { $Type: 'UI.DataField', Value: Status,              Label: 'Status',      Criticality: StatusCriticality },
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
        { $Type: 'UI.DataField', Value: Name,        Label: 'Naam' },
        { $Type: 'UI.DataField', Value: Description, Label: 'Omschrijving' },
        { $Type: 'UI.DataField', Value: Owner,       Label: 'Medewerker' },
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
// Airports  (TripPin Airports — read-only)  FR-010
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
// EmployeeExtensions  (draft editing: PrimePathProjectCode)  FR-005
// ============================================================================
annotate TravelService.EmployeeExtensions with @(
  UI: {
    HeaderInfo: {
      $Type          : 'UI.HeaderInfoType',
      TypeName       : 'Medewerkerextensie',
      TypeNamePlural : 'Medewerkerextensies',
      Title          : { $Type: 'UI.DataField', Value: UserName },
      Description    : { $Type: 'UI.DataField', Value: PrimePathProjectCode }
    },
    LineItem : [
      { $Type: 'UI.DataField', Value: UserName,             Label: 'Gebruikersnaam' },
      { $Type: 'UI.DataField', Value: PrimePathProjectCode, Label: 'Projectcode' }
    ],
    Facets : [
      { $Type: 'UI.ReferenceFacet', ID: 'EditFacet',
        Label: 'Projectgegevens', Target: '@UI.FieldGroup#EditFields' }
    ],
    // FR-005: Team Lead stelt projectcode in per medewerker
    FieldGroup #EditFields : {
      Data : [
        { $Type: 'UI.DataField', Value: UserName,             Label: 'Gebruikersnaam' },
        { $Type: 'UI.DataField', Value: PrimePathProjectCode, Label: 'Projectcode' }
      ]
    }
  }
) {
  UserName             @title: 'Gebruikersnaam'  @readonly;
  PrimePathProjectCode @title: 'Projectcode';
};

// ============================================================================
// AirlineExtensions  (draft editing: PreferredVendor)  FR-009
// ============================================================================
annotate TravelService.AirlineExtensions with @(
  UI: {
    HeaderInfo: {
      $Type          : 'UI.HeaderInfoType',
      TypeName       : 'Airline-extensie',
      TypeNamePlural : 'Airline-extensies',
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
    // FR-009: HR/Admin markeert airline als voorkeursleverancier
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
