using { TravelService } from './travel-service';

//
// Fiori Elements UI-annotaties voor de Explorer-apps (read-only).
// Coördinator & Team Lead gebruiken deze List Reports.
//
// NB: filteren (SelectionFields) gebeurt alleen op velden die op DB-/remote-niveau
// gefilterd kunnen worden. Verrijkte (virtual) velden zoals PreferredVendor staan
// als kolom getoond maar (nog) niet als filter.
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
    SelectionFields : [ PrimePathProjectCode, Gender ],
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
// Trips  (lokale TripExtension + TripPin reisdetails)
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
    SelectionFields : [ Status, Budget ],
    LineItem : [
      { $Type: 'UI.DataField', Value: TripId,   Label: 'Reis-ID' },
      { $Type: 'UI.DataField', Value: Name,      Label: 'Naam' },
      { $Type: 'UI.DataField', Value: Owner,     Label: 'Medewerker' },
      { $Type: 'UI.DataField', Value: Status,     Label: 'Status', Criticality: StatusCriticality },
      { $Type: 'UI.DataField', Value: CostCenter, Label: 'Kostenplaats' },
      { $Type: 'UI.DataField', Value: Budget,     Label: 'Budget' },
      { $Type: 'UI.DataField', Value: StartsAt,   Label: 'Vertrek' },
      { $Type: 'UI.DataField', Value: EndsAt,     Label: 'Terug' }
    ],
    // ---- Object Page ----
    Facets : [
      { $Type: 'UI.ReferenceFacet', ID: 'ReisFacet',
        Label: 'Reisgegevens', Target: '@UI.FieldGroup#TripDetails' }
    ],
    FieldGroup #TripDetails : {
      Data : [
        { $Type: 'UI.DataField', Value: TripId,      Label: 'Reis-ID' },
        { $Type: 'UI.DataField', Value: Name,        Label: 'Naam' },
        { $Type: 'UI.DataField', Value: Description, Label: 'Omschrijving' },
        { $Type: 'UI.DataField', Value: Owner,       Label: 'Medewerker' },
        { $Type: 'UI.DataField', Value: Status,      Label: 'Status', Criticality: StatusCriticality },
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
// Airlines  (TripPin Airlines + AirlineExtension)
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
    LineItem : [
      { $Type: 'UI.DataField', Value: AirlineCode,     Label: 'Code' },
      { $Type: 'UI.DataField', Value: Name,            Label: 'Naam' },
      { $Type: 'UI.DataField', Value: PreferredVendor, Label: 'Voorkeursleverancier' }
    ]
  }
) {
  AirlineCode     @title: 'Code';
  Name            @title: 'Naam';
  PreferredVendor @title: 'Voorkeursleverancier';
};
